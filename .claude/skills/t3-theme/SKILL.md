---
name: t3-theme
description: Make or change a T3 Code theme of the user's fork - the theme JSON (colours, shape, fonts, canvas pattern), the theme CSS with the app's data-attribute hooks, and icon packs that replace app icons. Use when the user asks to change how T3 Code looks, restyle a part of the app in their theme, or make icons for T3 Code. For the tick3d look itself, also use the neo-brutalism skill.
license: MIT
---

# T3 Code themes

A published theme is `.t3/userdata/themes/<id>.json` and an optional `<id>.css` in this repository. The file name is the theme id.

- On each machine, `~/.t3/userdata/themes` links to the dotfiles `main` checkout. A change to that checkout is live on that machine at once. Make theme changes on a branch, in a worktree of this repository, and merge them.
- The machine map shares published themes between machines (MM-408 in `apps/machine-map/SPEC.md` of the fork).
- The fork documents the theme fields in `docs/fork.md` and `docs/user/appearance.md`. If this skill and the fork disagree, the fork is correct. Fix this skill in the same change.

## Steps

1. Change the theme JSON, the CSS, or both. For the tick3d themes, change light and dark together.
2. For icons, change `icon_pack.py` in this folder. Then write the pack into the themes:
   `uv run .claude/skills/t3-theme/icon_pack.py --write .t3/userdata/themes/tick3d-light.json .t3/userdata/themes/tick3d-dark.json`
3. Check the limits below.
4. Preview the change. Render a contact sheet of the icons, or a mock of the styled part, with the theme CSS. In the app, open Settings > Appearance and pick the theme.
5. Commit on the branch and open a pull request.

## Limits

The server skips a theme file that breaks a limit, and the app then falls back to its stock look.

- 32 KB for each `.json` and each `.css` file. The machine map re-indents the JSON when it writes it, so keep some room.
- 192 KB for all theme files of a machine together, and at most 32 files.
- An icon is at most 4096 characters and must start with `<svg`.
- A CSS value field in the JSON (`shadow`, fonts, `canvasPatternColor`) is at most 128 characters, with no `;`, `{`, `}`, `<` or `>`.

## Theme JSON

| Field | Value |
| --- | --- |
| `name`, `appearance` | Display name; `light` or `dark`. |
| `canvas`, `accent` | Seed colours. The app derives the other roles from them. |
| `colors` | Colour roles, such as `sidebar`, `sidebarRowActive` or `border`. A role overrides its derived value. |
| `radius`, `borderWidth` | CSS lengths such as `0.25rem` or `2px`. |
| `shadow` | A hard box shadow for raised surfaces, such as `4px 4px 0 0 #000000`. |
| `fonts` | `sans`, `composer`, `code`, `terminal`. A font set in the client settings wins. |
| `canvasPattern`, `canvasPatternColor` | `none`, `dots`, `grid` or `noise`, and its colour. |
| `icons` | The icon pack: icon slot to SVG. See below. |

## CSS hooks

Theme CSS loads last, so it wins over the app at equal specificity. Use these hooks, not generated class names.

- **Root:** `:root[data-theme-id="<id>"]`, plus `data-theme-radius`, `data-theme-border-width`, `data-theme-shadow` and `data-canvas-pattern` when the theme sets them.
- **Sidebar threads:** `[data-testid="sidebar-row-card"]`, `[data-testid="sidebar-row-slim"]`, and `[data-sidebar-status="<label>"]` on the status label.
- **Thread card elements:** `[data-thread-card-element="<element>"]`, such as `terminal` or `pullRequest`.
- **Sidebar group tabs:**
  - The bar: `[data-sidebar-group-tabs]`. It clips its content, so give it padding for shadows and tilts.
  - Each tab: `[data-sidebar-group-tab="default|group"]`, with these states:
    - `[data-selected]`: the open tab.
    - `[data-status="<status>"]`: the most urgent status in the tab. The values are `approval`, `input`, `failed`, `limited`, `woke`, `done`, `working` and `waiting`.
    - `[data-attention]`: a thread in the tab waits for the user or failed.
    - `[data-drop-target]`: a dragged thread is over the tab.
    - `[data-dragging]`: the tab itself is being moved.
  - The overflow button: `[data-sidebar-group-more]`.
  - The new-group drop target during a drag: `[data-sidebar-group-new]`.
  - The thread count inside a tab: `.tabular-nums`.
- **Icons:** `[data-app-icon="<slot>"]` on every icon that a pack can replace.

The app measures each tab with the theme CSS applied. A theme can therefore change the padding, the borders and the gap of the tabs, and the bar still fits whole tabs.

## Icon packs

`icons` maps an icon slot to an SVG document. The app draws the SVG in place of the stock icon, at the size and colour of the stock icon.

- The app sanitizes each SVG. It removes `<script>`, `<style>`, `<foreignObject>`, `<image>`, `<a>`, `href` and `src`. Draw with shapes and paths only.
- Use `viewBox="0 0 24 24"` and `currentColor`, so the icon takes the text colour.
- Give parts a class, and colour them in the theme CSS: `[data-app-icon] .nbf { fill: #FFE14D; }`. A class in the SVG keeps one pack usable in light and dark mode.
- A slot that the pack does not have keeps the stock icon.

Slots:

- `group.<id>`: the icons a user can pick for a sidebar group, such as `group.dot`, `group.star` or `group.bolt`. The full list is `GROUP_ICONS` in `apps/web/src/components/AppIcon.tsx` of the fork.
- `status.working`, `status.waiting`, `status.approval`, `status.input`, `status.failed`, `status.limited`, `status.woke`, `status.done`: the thread status on group tabs and on sidebar rows.
- `groups.more`, `groups.new`, `groups.edit`: the buttons of the group tab bar.
- `sidebar.search`, `sidebar.filter`, `sidebar.add-project`, `sidebar.new-thread`: the sidebar header.

The tick3d pack (`icon_pack.py`) draws each icon as a flat body with a 2.25 ink outline, square caps, miter joins and a hard shadow offset by 1.6. Bodies have class `nbf` and shadows class `nbs`.
