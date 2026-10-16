#!/usr/bin/env node
// Screenshots of a T3 Code dev server with headless Chromium. Use it where T3's own preview
// browser cannot start, for example a VPS where AppArmor blocks its sandbox.
//
// Usage: node t3-shot.mjs <worktree> <dev-log> <shots.json>
//   <worktree>   T3 Code checkout with node_modules. playwright-core loads from there.
//   <dev-log>    output of `vp run dev` in that worktree. The script reads the pairing URL from it.
//   <shots.json> [{ "name", "path"?, "viewport"?, "scheme"?, "localStorage"?, "waitFor"?, "css"?,
//                   "click"?: [selector | { "selector", "button": "right" }], "settleMs"?,
//                   "clip"?: selector, "clipRect"?: { x, y, width, height } }]
//
// Shots go to <dirname(shots.json)>/<name>.png. The browser session goes to
// <dirname(shots.json)>/.t3-shot-state.json, so one pairing token serves later runs. A browser
// restart loses the session cookie, and the token works once. That file holds the cookie: never
// commit or share it.
import { chmodSync, existsSync, readFileSync, readdirSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

const [worktree, devLog, shotsFile] = process.argv.slice(2);
if (!worktree || !devLog || !shotsFile) {
  console.error("usage: t3-shot.mjs <worktree> <dev-log> <shots.json>");
  process.exit(2);
}
const outDir = dirname(resolve(shotsFile));
const statePath = join(outDir, ".t3-shot-state.json");
const shots = JSON.parse(readFileSync(shotsFile, "utf8"));

const { chromium } = createRequire(join(resolve(worktree), "package.json"))(
  require_playwright_core(resolve(worktree)),
);

// The repo pins a playwright-core whose browser build can differ from the cached build. Use the
// newest cached headless shell, so the script downloads nothing.
function headlessShell() {
  const cache =
    process.platform === "darwin"
      ? join(homedir(), "Library", "Caches", "ms-playwright")
      : join(homedir(), ".cache", "ms-playwright");
  const prefix = "chromium_headless_shell-";
  const builds = existsSync(cache)
    ? readdirSync(cache)
        .filter((name) => name.startsWith(prefix))
        .sort((a, b) => Number(a.slice(prefix.length)) - Number(b.slice(prefix.length)))
    : [];
  const newest = builds.at(-1);
  if (newest === undefined) {
    throw new Error(`no ${prefix}* in ${cache}. Run \`npx playwright install chromium-headless-shell\`.`);
  }
  const platformDir = readdirSync(join(cache, newest)).find((name) =>
    name.startsWith("chrome-headless-shell-"),
  );
  if (platformDir === undefined) throw new Error(`no chrome-headless-shell-* in ${join(cache, newest)}`);
  return join(cache, newest, platformDir, "chrome-headless-shell");
}

function require_playwright_core(root) {
  const pnpmDir = join(root, "node_modules", ".pnpm");
  const entry = readdirSync(pnpmDir).find((name) => name.startsWith("playwright-core@"));
  if (entry === undefined) throw new Error(`playwright-core is not installed in ${root}`);
  return join(pnpmDir, entry, "node_modules", "playwright-core");
}

function pairingUrl() {
  const match = readFileSync(devLog, "utf8").match(/pairingUrl: (\S+)/g)?.at(-1);
  if (match === undefined) throw new Error(`no pairingUrl line in ${devLog}`);
  return match.slice("pairingUrl: ".length);
}

const origin = new URL(pairingUrl()).origin;
const browser = await chromium.launch({ executablePath: headlessShell() });
try {
  const context = await browser.newContext({
    storageState: existsSync(statePath) ? statePath : undefined,
  });
  const session = await (await context.request.get(`${origin}/api/auth/session`)).json();
  if (session.authenticated !== true) {
    const page = await context.newPage();
    await page.goto(pairingUrl());
    await page.waitForURL((url) => !url.pathname.startsWith("/pair"), { timeout: 60_000 });
    const after = await (await context.request.get(`${origin}/api/auth/session`)).json();
    if (after.authenticated !== true) {
      throw new Error("pairing failed: the token in the dev log is used up. Restart the dev server.");
    }
    await page.close();
  }
  await context.storageState({ path: statePath });
  chmodSync(statePath, 0o600);
  await context.close();

  for (const shot of shots) {
    const shotContext = await browser.newContext({
      storageState: statePath,
      viewport: shot.viewport ?? { width: 1280, height: 800 },
      deviceScaleFactor: 2,
      colorScheme: shot.scheme ?? "dark",
    });
    const page = await shotContext.newPage();
    const url = `${origin}${shot.path ?? "/"}`;
    await page.goto(url);
    if (shot.localStorage !== undefined) {
      // Values are JSON: an object merges into the stored object, anything else replaces it.
      await page.evaluate((entries) => {
        for (const [key, value] of Object.entries(entries)) {
          const current = JSON.parse(localStorage.getItem(key) ?? "null");
          const merged =
            current !== null && typeof current === "object" && typeof value === "object"
              ? { ...current, ...value }
              : value;
          localStorage.setItem(key, JSON.stringify(merged));
        }
      }, shot.localStorage);
      await page.goto(url);
    }
    await page.waitForSelector(shot.waitFor ?? "[data-sidebar='sidebar']", { timeout: 90_000 });
    // `css` hides noise that is not part of the shot, such as a provider error banner.
    if (shot.css !== undefined) await page.addStyleTag({ content: shot.css });
    for (const step of shot.click ?? []) {
      const { selector, button = "left" } = typeof step === "string" ? { selector: step } : step;
      await page.locator(selector).first().click({ button });
      // Menus and popovers animate in.
      await page.waitForTimeout(400);
    }
    // Fonts, icons and measured layouts settle after the first paint.
    await page.waitForTimeout(shot.settleMs ?? 1500);
    const out = join(outDir, `${shot.name}.png`);
    if (shot.clip === undefined) {
      // `clipRect` crops a page area in CSS pixels, for popovers that leave their anchor element.
      await page.screenshot({ path: out, clip: shot.clipRect });
    } else {
      await page.locator(shot.clip).first().screenshot({ path: out });
    }
    console.log(out);
    await shotContext.close();
  }
} finally {
  await browser.close();
}
