---
name: neo-brutalism
description: The user's neo-brutalism UI style, the "tick3d" look. Ink borders, hard offset shadows, yellow selection, purple accent, heavy Bricolage Grotesque headings, tilted stickers, a dots canvas, light and dark mode. Use when you build a web page, mockup, dashboard or app UI for the user. Also use when the user asks for the tick3d or neo-brutalism style. Do not use in a project that has its own design system.
license: MIT
---

# Neo-brutalism (tick3d)

Flat colour, thick ink lines, hard shadows. The values come from the T3 Code tick3d themes in this
repository: `.t3/userdata/themes/tick3d-{light,dark}.{json,css}`. If this skill and a theme file
disagree, the theme file is correct. Fix this skill in the same change.

A finished page in this style is the T3 machine map mockup at https://t3-map-mockup.yarden-zamir.com
(behind Cloudflare Access).

## When not to use

- The project has its own design system, component library theme or brand. Use that.
- The T3 Code app gets this look from the tick3d theme files. To change the app, edit those files.

## Steps

1. Put the font import and the tokens at the top of the page style.
2. Add the starter block. Build the page from cards on the dots canvas.
3. Check the page in light mode and in dark mode before you hand it over. For the dark check, emulate `prefers-color-scheme: dark`.

## Tokens

The import loads the fonts on machines that do not have them. Installed fonts still win.

```css
@import url("https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,600;12..96,800&family=JetBrains+Mono:wght@400;600&display=swap");

:root {
  color-scheme: light;
  --canvas: #E4E7FF;   --dots: #00000026;
  --surface: #FFFFFF;  --raised: #F1F2FF;    --code-bg: #FFFFFF;
  --ink: #000000;      --muted: #3D3D5C;
  --border: #000000;   --shadow-ink: #000000; /* shadows, sticker edges */
  --accent: #6C5CE7;   --accent-fg: #FFFFFF;
  --select: #FFE14D;   --select-fg: #000000;
  --error: #FF5277;    --error-fg: #B0002A;   --error-surface: #FFE3E9;
  --warning: #FFB347;  --warning-fg: #8A4B00; --warning-surface: #FFF6D1;
  --info: #00B3FF;     --info-fg: #005F87;    --info-surface: #E0F5FF; /* theme key "update" */
  --green: #7CFF8A;    --yellow: #FFE14D;     --pink: #FF9EB0;         /* stickers, both modes */
  --stamp: #8250DF;
  --radius: 0.25rem;   --bw: 2px;
  --shadow: 4px 4px 0 0 var(--shadow-ink);
  --sans: "Bricolage Grotesque", system-ui, sans-serif;
  --mono: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
}
@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    --canvas: #15122B;   --dots: #F3F0FF22;
    --surface: #262147;  --raised: #1D1938;    --code-bg: #1D1938;
    --ink: #F3F0FF;      --muted: #BDB6E6;
    --border: #F3F0FF;   --shadow-ink: #B9A8FF;
    --select: #6C5CE7;   --select-fg: #FFFFFF;
    --error-fg: #FF8A8A;   --error-surface: #3A1830;
    --warning-fg: #FFE14D; --warning-surface: #3A3018;
    --info-fg: #7FD9FF;    --info-surface: #132E45;
    --stamp: #A371F7;
  }
}
```

## Rules

- **Borders.** Give every surface, control and table cell a `var(--bw) solid var(--border)` border. Use full ink. Do not fade a border.
- **Shadows.** Use hard offset shadows only: `var(--shadow)` on cards, 3px on small controls, 2px on stickers. Never blur a shadow.
- **One shadow per stack.** If a surface sits inside another surface, only the inner surface casts a shadow.
- **Radius.** Use `var(--radius)`. Stickers use 4px. Only toggle switches are round.
- **Selection.** Fill the selected item with `--select` and `--select-fg`: yellow in light mode, accent purple in dark mode. This covers tabs, segments, cells and rows.
- **Selected list row.** Make it a flat `--select` block with a `--shadow-ink` border, an 8px left edge and no shadow.
- **Accent.** Use `--accent` for focus rings, links and the main action.
- **Type.** Use `--sans`. Set headings and labels to weight 800 with `letter-spacing: -0.01em`. Set buttons to weight 700.
- **Section labels.** Use uppercase, weight 800, 0.7rem, `letter-spacing: 0.06em` and `--muted`.
- **Code and ids.** Use `--mono` for code, ids, hashes, revisions and tokens.
- **Highlighter.** Put a `--select` marker band behind inline code. Give it no border and no box.
- **Stickers.** Show status, levels and tags as small tilted stickers with black text. Use green for working or done, yellow for waiting, pink for other states. For more states, use blue (`--info`), orange (`--warning`) or the accent with white text.
- **Tilt.** Rotate stickers between -4deg and 4deg. Give neighbours different angles.
- **Stamp.** Mark settled items with a tilted outline ✓ in `--stamp`: 2px border, weight 900, no fill.
- **Canvas.** Put the dots pattern on `--canvas` behind the page. Put content in cards on top.
- **Buttons.** On hover, lift the button 1px and show the shadow. On click, move it 3px down and right and remove the shadow. The button presses into its shadow.
- **Gradients.** Do not use colour gradients. The one exception is the send button, or the one main action of a page. Gradients that draw hard patterns (dots, highlighter, hatching) are allowed.
- **Motion.** Use transitions of 80ms for presses and 120ms for fades. Do not use continuous animations: no spinners, pulses or shimmer. Show progress with text or a sticker colour.
- **Dark mode.** Always support both modes through `prefers-color-scheme`. Change tokens only, not rules.

## Starter

```css
* { box-sizing: border-box; }
body {
  margin: 0; font: 14px/1.45 var(--sans); color: var(--ink);
  background-color: var(--canvas);
  background-image: radial-gradient(var(--dots) 1.2px, transparent 1.2px);
  background-size: 16px 16px;
}
h1, h2, h3 { font-weight: 800; letter-spacing: -0.01em; margin: 0; }
code, pre { font-family: var(--mono); font-size: 0.85em; }
:not(pre) > code {
  background: linear-gradient(transparent 35%, var(--select) 35%, var(--select) 88%, transparent 88%);
  padding: 0 2px;
}
pre {
  padding: 10px; overflow-x: auto; background: var(--code-bg);
  border: var(--bw) solid var(--border); border-radius: var(--radius);
  box-shadow: 3px 3px 0 0 var(--shadow-ink);
}
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; box-shadow: 0 0 0 6px #FF527766; }

.card {
  background: var(--surface); border: var(--bw) solid var(--border);
  border-radius: var(--radius); box-shadow: var(--shadow);
}

.sticker {
  display: inline-block; padding: 0 6px; line-height: 1.5; white-space: nowrap;
  font-size: 0.65rem; font-weight: 800; letter-spacing: 0.04em; text-transform: uppercase;
  color: #000000; background: var(--pink);
  border: var(--bw) solid var(--shadow-ink); border-radius: 4px;
  box-shadow: 2px 2px 0 0 var(--shadow-ink);
  transform: rotate(var(--tilt, -3deg));
}
.sticker.ok { background: var(--green); }
.sticker.wait { background: var(--yellow); }
/* CSS has no random, so the tilt cycles by list row. Change the row selector if rows are not li. */
li:nth-child(3n+2) .sticker { --tilt: 2deg; }
li:nth-child(3n) .sticker { --tilt: -1.5deg; }

.btn {
  display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; cursor: pointer;
  font: inherit; font-weight: 700; color: var(--ink); background: var(--surface);
  border: var(--bw) solid var(--border); border-radius: var(--radius);
  transition: transform 80ms, box-shadow 80ms;
}
.btn:not(:disabled):hover { transform: translate(-1px, -1px); box-shadow: var(--shadow); }
.btn:not(:disabled):active { transform: translate(3px, 3px); box-shadow: none; }
.btn:disabled { opacity: 0.55; cursor: default; }
.btn.primary { background: var(--accent); color: var(--accent-fg); }
.btn.send {
  background: linear-gradient(135deg, #6C5CE7 0%, #FF5277 100%); color: #FFFFFF;
  box-shadow: 3px 3px 0 0 var(--shadow-ink);
}

/* Segmented control and tabs: mark the chosen button with aria-pressed or aria-selected. */
.seg {
  display: inline-flex; overflow: hidden; background: var(--surface);
  border: var(--bw) solid var(--border); border-radius: var(--radius);
}
.seg button {
  font: inherit; font-weight: 800; padding: 4px 14px; cursor: pointer;
  border: 0; background: transparent; color: var(--ink);
}
.seg button + button { border-left: var(--bw) solid var(--border); }
.seg button:is([aria-pressed="true"], [aria-selected="true"]) { background: var(--select); color: var(--select-fg); }
/* The control clips its children, so the focus ring goes inside the button. */
.seg button:focus-visible { outline-offset: -4px; box-shadow: none; }
```
