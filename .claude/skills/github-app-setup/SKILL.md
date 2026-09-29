---
name: github-app-setup
description: Create a GitHub App for a project ("Sign in with GitHub", GitHub login, OAuth with GitHub, GitHub webhooks, a bot) through the GitHub App Manifest flow, and write the credentials to the project's local secrets or, for KitSHn deployments, to GitHub secrets. Use this instead of asking the user to register an app by hand and paste back the client ID, client secret, or private key.
license: MIT
---

# GitHub App setup (manifest flow)

The manifest flow creates a GitHub App from a JSON description. The user clicks one button on GitHub. The agent gets all credentials back from the API. The user never copies a value.

This skill gives the steps and a code skeleton. The GitHub docs are the source of truth for fields, permissions, and endpoints. Read the relevant page before each run, because GitHub changes these details.

## Sources

- [Registering a GitHub App from a manifest](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest): manifest fields, the form POST URLs for accounts and organizations, `state`, `redirect_url`, and the code expiry.
- [Create a GitHub App from a manifest](https://docs.github.com/en/rest/apps/apps#create-a-github-app-from-a-manifest): the conversion endpoint and its response fields.
- [Choosing permissions for a GitHub App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/choosing-permissions-for-a-github-app): permission names for `default_permissions`.
- [Generating a user access token](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app): the login flow, token expiry, refresh tokens, and device flow.
- The docs of the auth library that the project uses (for example Auth.js or better-auth): the callback path and the variable names.

## Things the docs do not make obvious

If a source now says something else, trust the source and update this skill.

- The flow creates GitHub Apps only, not OAuth Apps. A GitHub App supports "Sign in with GitHub".
- Some settings are not manifest fields (for example device flow, or user token expiry). Tell the user to change them in the app settings after creation.
- The app name must be unique across all of GitHub. If the name is taken, the user edits it on the GitHub form before the click.
- The conversion response is the only time that the API returns the private key and the client secret. If the write fails after the exchange, the user must delete the app and run the flow again. For this reason, the skeleton checks the target files before it opens the browser.
- For oauth2-proxy, request `emails: read`. The manifest uses the settings-form names, which differ from the REST `app-permissions` schema: there the same permission is `email_addresses`, and a manifest with that key fails with "Default permission records resource is not included in the list". Do not "correct" a manifest key from the REST schema. If it uses `--github-org` or `--github-team`, also request the org permission `members: read` and install the app on the org. If that is not possible, use an OAuth App, which has no creation API.
- A login-only app needs only the client ID and the client secret. The private key is for API calls as the app itself.
- No API deletes a GitHub App. To delete one, give the user `https://github.com/settings/apps/<slug>/advanced` (for an organization, see the app settings). Deletion also revokes the user sign-ins.
- A site with a service worker: the worker must not handle the sign-in routes (for oauth2-proxy, `/auth/*`) or a per-visitor "who am I" route. A worker that fetches the sign-in route again cannot follow the redirect to github.com, and Chrome shows `ERR_FAILED`. curl has no worker, so a curl check does not show this fault.
- Decide who may sign in. Both choices are valid, so ask the user. Choice 1: the proxy blocks all other people at sign-in (`--github-user`, `--github-org`). Choice 2: any GitHub user signs in, and the app checks a whitelist of logins. With choice 2, a stranger signs in and gets no rights, and you add a person with an app config change.
- An app without `"public": true` in the manifest is private. GitHub then answers 404 to every other person on the sign-in page, before the proxy or the whitelist can act. The default in this skill is `"public": true`. Make an app private only when the user asks for that. To change an existing app, use **Make public** on `https://github.com/settings/apps/<slug>/advanced`. That page asks for sudo mode, so the user confirms it first.

## Steps

1. Find how the project reads its GitHub credentials. Read the auth config for the exact variable names and the callback path. Do not guess them.
2. Find where local secrets go:
   - In the bare + worktree layout (a `.bare/` folder in the container directory), write to `<container>/_shared/`. See the `worktree-repo` skill.
   - Otherwise, write to the git-ignored env file of the project. Confirm with `git check-ignore <file>` before you write a secret.
3. Ask the user for the owner (personal account or organization) and for each environment that needs a callback URL.
4. Write the manifest from the manifest docs. Ask for the minimum permissions that the feature needs. Set `"public": true` unless the user asks for a private app. Leave `redirect_url` to the skeleton.
5. Fill in the `TODO` values of the skeleton. Check each URL and response field against the sources.
6. Run it with the Bash tool in the background, because it waits for the user. Tell the user to click **Create GitHub App** in the browser.
7. In the worktree layout, run `$DOTFILES/bin/git-shared-link <worktree>` to link the new files. Do not create the links by hand.
8. Verify the credentials without printing them:
   - Private key: sign a JWT ([Generating a JWT for a GitHub App](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app)) and call `GET /app`. Use `uv run --with 'pyjwt[crypto]'`.
   - Client ID and client secret: sign in once through the app, or through the web flow in the user access token docs on a registered callback URL.
9. Tell the user the app URL, the files that you wrote, and any manual settings. Never print a secret value in the chat.

## Deployments with KitSHn

If the repo has a `.kitshn.yaml`, the deployed app gets its values from GitHub secrets, not from files. Read these sources first:

- [KitSHn README](https://github.com/Yarden-zamir/kitshn/blob/main/README.md), sections "Public HTTP Services" and "Secrets And Config".
- [`specs/ci.md`](https://github.com/Yarden-zamir/kitshn/blob/main/specs/ci.md) for the `KITSHN_` prefix and the pull request lifecycle.
- The `kitshn-deploy-service` skill (`kitshn skill show`).
- A worked example of GitHub login on KitSHn: `kitshn.md` in the `Yarden-zamir/changeLorg` repo.

Steps that differ from the local flow:

1. Get the production host from the `Caddyfile.j2` of the repo. The callback URL is `https://<host>` plus the callback path of the auth library.
2. Create one app per environment. Do not add preview hosts (`pr.<N>.<domain>`) to the production app. Each pull request has a new host, and an app accepts only 10 callback URLs. Keep preview login off, or use a separate preview app, as `changeLorg` does.
3. Set `ENV_FILE` in the skeleton to a path in the scratchpad. The local files are only a step on the way to GitHub.
4. Send each value to a GitHub secret with the `KITSHN_` prefix, scoped to the environment. Pull request environments then never get production secrets. Send the value through stdin, so that it never shows in the output:

   ```sh
   uv run - <<'PY'
   import subprocess
   from pathlib import Path

   REPO = "OWNER/REPO"  # TODO
   ENVIRONMENT = "prod"  # TODO: the GitHub Environment from .kitshn.yaml
   ENV_FILE = Path("/scratchpad/path/.env.local")  # TODO: the ENV_FILE of the skeleton

   for line in ENV_FILE.read_text().splitlines():
       if not line:
           continue
       name, value = line.split("=", 1)
       subprocess.run(
           ["gh", "secret", "set", f"KITSHN_{name}", "--repo", REPO, "--env", ENVIRONMENT],
           input=value, text=True, check=True,
       )
   PY
   ```

5. Map each value in `compose.yml`, for example `GITHUB_CLIENT_ID: ${GITHUB_CLIENT_ID:?required}`. KitSHn passes params to Compose only for interpolation. A container does not get a param unless `compose.yml` maps it. Do not use a repo `.env`: KitSHn runs Compose with `--env-file`, and Compose then does not read `.env`.
6. The private key: KitSHn has no file params. A login-only app needs only the client ID and the client secret, so leave the key out of GitHub. If the app needs the key, send it base64-encoded (`base64 < github-app.private-key.pem`) as one secret, and decode it in the app. Compose interpolation changes a `$` in a value, and multi-line values are not tested in KitSHn.
7. After the next deploy, run `kitshn params list OWNER/REPO` to confirm the names. Do not use `--show`.
8. Delete the scratchpad files.

## Code skeleton

Run it with `uv run -` (see the `uv-python` skill). It uses only the standard library.

```sh
uv run - <<'PY'
import html
import http.server
import json
import secrets
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path

NEW_APP_URL = "https://github.com/settings/apps/new"  # TODO: organizations use another URL, see the manifest docs
CONVERSION_URL = "https://api.github.com/app-manifests/{code}/conversions"  # TODO: check the REST docs
ENV_FILE = Path("/abs/path/_shared/.env.local")  # TODO: from step 2
PEM_FILE = ENV_FILE.with_name("github-app.private-key.pem")  # own file: many .env loaders reject multi-line values
ENV_NAMES = {"client_id": "GITHUB_CLIENT_ID", "client_secret": "GITHUB_CLIENT_SECRET"}  # TODO: response field -> project variable
manifest: dict = {"public": True}  # TODO: the rest from step 4; public, so that other people can sign in

existing_env = ENV_FILE.read_text() if ENV_FILE.exists() else ""
clashes = [name for name in ENV_NAMES.values() if f"{name}=" in existing_env]
if clashes or PEM_FILE.exists():
    raise SystemExit(f"Already defined: {clashes or PEM_FILE}. Ask the user before you replace credentials.")

state = secrets.token_urlsafe(32)
code: str | None = None


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        global code
        url = urllib.parse.urlsplit(self.path)
        query = urllib.parse.parse_qs(url.query)
        if url.path == "/":
            body = f"""<form id="f" method="post" action="{NEW_APP_URL}?state={state}">
<input type="hidden" name="manifest" value="{html.escape(json.dumps(manifest))}"></form>
<script>document.getElementById("f").submit()</script>"""
        elif url.path == "/callback" and query.get("state") == [state] and "code" in query:
            code = query["code"][0]
            body = "Done. Close this tab and check the terminal."
        else:
            self.send_error(400)
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, format: str, *args: object) -> None:
        pass  # the default log prints the one-time code


server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
start_url = f"http://127.0.0.1:{server.server_address[1]}/"
manifest["redirect_url"] = start_url + "callback"
print(f"Open {start_url} if the browser does not open.", flush=True)
webbrowser.open(start_url)
while code is None:  # no timeout: if the user abandons the flow, stop the background task
    server.handle_request()

request = urllib.request.Request(
    CONVERSION_URL.format(code=urllib.parse.quote(code)),
    method="POST",
    headers={"Accept": "application/vnd.github+json"},
)
with urllib.request.urlopen(request) as response:
    app = json.load(response)

missing = [field for field in [*ENV_NAMES, "pem"] if app.get(field) is None]
if missing:  # stop before a partial write; the app exists, so the user must delete it and retry
    raise SystemExit(f"Response has no {missing}. Fields: {sorted(app)}")
prefix = "\n" if existing_env and not existing_env.endswith("\n") else ""
env_text = prefix + "".join(f"{name}={app[field]}\n" for field, name in ENV_NAMES.items())

PEM_FILE.touch(mode=0o600, exist_ok=False)
PEM_FILE.write_text(app["pem"])
ENV_FILE.touch(mode=0o600)  # mode applies only when the file is new
with ENV_FILE.open("a") as env:
    env.write(env_text)
print(f"Created {app['html_url']}. Wrote {ENV_FILE} and {PEM_FILE}.")
PY
```
