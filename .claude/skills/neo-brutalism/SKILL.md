---
name: neo-brutalism
description: The user's UI standard, the "tick3d" neo-brutalism look. Ink borders, hard offset shadows, yellow selection, purple accent, heavy Bricolage Grotesque headings, tilted stickers, a dots canvas, light and dark mode, and standard components (tooltips, checkboxes, radios, switches, inputs, selects, menus, dialogs, overlay panels) that replace native browser UI. Use when you build or change a web page, mockup, dashboard or app UI for the user, including kitshn. Also use when the user asks for the tick3d or neo-brutalism style. Do not use in a project that has its own design system.
license: MIT
---

# Neo-brutalism (tick3d)

Flat colour, thick ink lines, hard shadows. The values come from the T3 Code tick3d themes in this
repository: `.t3/userdata/themes/tick3d-{light,dark}.{json,css}`. If this skill and a theme file
disagree, the theme file is correct. Fix this skill in the same change.

This skill is the standard for every web UI that the user owns and that has no design system of
its own: kitshn, tick3d, mockups, reports and one-off pages. Follow every rule and use the
standard components below. Do not invent a second version of a component.

Finished UIs in this style: the kitshn map at https://kit.yarden-zamir.com and the T3 machine map
mockup at https://t3-map-mockup.yarden-zamir.com (both behind Cloudflare Access).

## When not to use

- The project has its own design system, component library theme or brand. Use that.
- The T3 Code app gets this look from the tick3d theme files. To change the app, edit those files.

## Steps

1. Put the font import and the tokens at the top of the page style.
2. Add the starter block. Build the page from cards on the dots canvas.
3. Add the standard components that the page uses. In a component framework (React and so on), make
   each one a shared component with these styles, and use it everywhere.
4. Before you call the UI done, go through the checklist at the end of this skill.

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
- **Radius.** Use `var(--radius)`. Stickers and checkboxes use 4px. Only toggle switches and radio buttons are round.
- **No native browser UI.** Do not use the browser's own tooltips (`title`), checkboxes, radio buttons, switches, select lists, date pickers or colour pickers. They look foreign and differ per browser. Keep the native element for its meaning and keyboard support, set `appearance: none` and style it, or use the standard component below. A native control is fine only inside a form that the browser itself owns, such as a file chooser dialog.
- **Tooltips everywhere.** Every icon button, control, option, sticker and short label gets a tooltip that says what it is and what happens. Use one short sentence. Show it on hover after 300ms and at once on keyboard focus. Never put needed information only in a tooltip: touch screens have no hover.
- **Controls.** Checkboxes, radios and switches show the checked state with `--select`, have a hit area of at least 1.75rem, and press into their shadow like buttons.
- **Overlays.** Menus, tooltips, dialogs and overlay panels are cards: ink border, `--surface` and a hard shadow. Dialogs and overlay panels use `var(--shadow)`; menus and tooltips use 3px. A dialog dims the page with a flat `#0006` layer, without blur.
- **Selection.** Fill the selected item with `--select` and `--select-fg`: yellow in light mode, accent purple in dark mode. This covers tabs, segments, cells and rows.
- **Selected list row.** Make it a flat `--select` block with a `--shadow-ink` border, an 8px left edge and no shadow.
- **Accent.** Use `--accent` for focus rings, links and the main action.
- **Size.** Use a big default size: 18px on `html`, body text at 1rem. Size labels, stickers and code in rem or em, so they scale with the default. Do not set small pixel sizes.
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

## Differences from generic neo-brutalism

If you know the generic style, use the tick3d value where the two differ.

| Generic prompt | tick3d |
| --- | --- |
| Cream canvas `#FFFDF5` | Lilac canvas `#E4E7FF` with dots |
| Red accent `#FF6B6B`, yellow and violet colour blocks | Purple accent `#6C5CE7`, yellow `#FFE14D` for selection |
| Space Grotesk, weight 700 to 900, caps everywhere | Bricolage Grotesque 800 for headings, caps only on labels and stickers |
| 4px borders, sharp corners | 2px borders, 0.25rem radius |
| Shadows from 4px to 16px | 4px on cards, 3px on controls, 2px on stickers |
| Pure black text, no grays | `--muted` for secondary text |
| Marquees, spins, pulses, bounces | No continuous animations |
| Light mode only | Light and dark mode |
| No base size given | 18px base size, all other sizes in rem or em |

## Starter

```css
* { box-sizing: border-box; }
html { font-size: 18px; }
body {
  margin: 0; font: 1rem/1.5 var(--sans); color: var(--ink);
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

## Standard components

Use these instead of native browser UI. In an app, make each one a shared component. On a one-off
page, paste the CSS block.

### Tooltip

A tooltip is a small card. In an app, render it in a portal and position it with the app's
positioning helper (for example Floating UI), so a parent's `overflow` cannot clip it. Link it with
`aria-describedby`. Show it on hover after 300ms and on focus at once. Hide it on Escape, on blur and
when the pointer leaves. On a one-off page, use `data-tip` with the CSS below.

```css
.tooltip, [data-tip]::after {
  max-width: 18rem; padding: 4px 8px; z-index: 50;
  font: 600 0.8rem/1.35 var(--sans); color: var(--ink); background: var(--surface);
  border: var(--bw) solid var(--border); border-radius: var(--radius);
  box-shadow: 3px 3px 0 0 var(--shadow-ink);
}
/* One-off pages only. In an app, use a positioned tooltip component. */
[data-tip] { position: relative; }
[data-tip]::after {
  content: attr(data-tip); position: absolute; left: 50%; bottom: calc(100% + 8px);
  width: max-content; transform: translateX(-50%);
  opacity: 0; pointer-events: none; transition: opacity 120ms;
}
[data-tip]:hover::after { opacity: 1; transition-delay: 300ms; }
[data-tip]:focus-visible::after { opacity: 1; transition-delay: 0ms; }
```

### Checkbox, radio and switch

Keep the native `<input>` for keyboard and screen readers, and remove its look. Wrap it in a
`<label>` with the text, so the whole row is the hit area.

```css
.check, .radio {
  appearance: none; margin: 0; flex: none; width: 1.15em; height: 1.15em; cursor: pointer;
  display: inline-grid; place-content: center; background: var(--surface);
  border: var(--bw) solid var(--border); box-shadow: 2px 2px 0 0 var(--shadow-ink);
  transition: transform 80ms, box-shadow 80ms;
}
.check { border-radius: 4px; }
.radio { border-radius: 50%; }
.check::after {
  content: ""; width: 0.6em; height: 0.32em; opacity: 0;
  border: solid var(--select-fg); border-width: 0 0 3px 3px; transform: rotate(-45deg) translate(1px, -1px);
}
.radio::after { content: ""; width: 0.5em; height: 0.5em; border-radius: 50%; background: var(--select-fg); opacity: 0; }
.check:checked, .radio:checked { background: var(--select); }
.check:checked::after, .radio:checked::after { opacity: 1; }
.check:active, .radio:active { transform: translate(2px, 2px); box-shadow: none; }
.check:disabled, .radio:disabled { opacity: 0.55; cursor: default; }

.switch {
  appearance: none; margin: 0; flex: none; position: relative; cursor: pointer;
  width: 2.4em; height: 1.35em; border-radius: 999px; background: var(--surface);
  border: var(--bw) solid var(--border); box-shadow: 2px 2px 0 0 var(--shadow-ink);
  transition: background 120ms, transform 80ms, box-shadow 80ms;
}
.switch::before {
  content: ""; position: absolute; top: 50%; left: 2px; width: 0.95em; height: 0.95em;
  border-radius: 50%; background: var(--ink); transform: translateY(-50%); transition: left 120ms;
}
.switch:checked { background: var(--select); }
.switch:checked::before { left: calc(100% - 0.95em - 2px); background: var(--select-fg); }
.switch:active { transform: translate(2px, 2px); box-shadow: none; }

.choice { display: inline-flex; align-items: center; gap: 0.5em; min-height: 1.75rem; cursor: pointer; }
```

### Text field and select

```css
.field, .select {
  font: inherit; color: var(--ink); background: var(--surface); padding: 4px 10px;
  border: var(--bw) solid var(--border); border-radius: var(--radius); min-height: 2rem;
}
.field::placeholder { color: var(--muted); opacity: 1; }
.field:focus-visible, .select:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.field[aria-invalid="true"] { border-color: var(--error); background: var(--error-surface); }
/* A native <select> only for short fixed lists. Long or rich lists use the menu below. */
.select {
  appearance: none; padding-right: 2em; cursor: pointer;
  background-image: linear-gradient(45deg, transparent 50%, var(--ink) 50%),
    linear-gradient(135deg, var(--ink) 50%, transparent 50%);
  background-position: calc(100% - 14px) 55%, calc(100% - 9px) 55%;
  background-size: 5px 5px; background-repeat: no-repeat;
}
```

Dates and colours: use presets plus a small custom popover (for example "Never, 1 day, 1 week,
Custom…", or a row of colour swatches from the tokens), never the native picker.

### Menu (context menu, dropdown, command list)

```css
.menu {
  min-width: 12rem; padding: 4px; display: grid; gap: 2px; z-index: 40;
  background: var(--surface); border: var(--bw) solid var(--border); border-radius: var(--radius);
  box-shadow: 3px 3px 0 0 var(--shadow-ink);
}
.menu-item {
  display: flex; align-items: center; gap: 8px; padding: 4px 8px; cursor: pointer;
  font: inherit; font-weight: 600; text-align: left; color: var(--ink);
  background: none; border: 0; border-radius: 4px;
}
.menu-item:is(:hover, :focus-visible, [data-highlighted]) { background: var(--select); color: var(--select-fg); outline: none; }
.menu-item[data-danger] { color: var(--error-fg); }
.menu-sep { height: var(--bw); margin: 2px 4px; background: var(--border); }
.menu-key { margin-left: auto; font-family: var(--mono); font-size: 0.75em; color: var(--muted); }
```

A context menu opens on right-click, on a "⋯" button and on a long press on touch. It holds the
same actions as the toolbar and the command palette, never actions that exist only there.

### Dialog and overlay panel

```css
.scrim { position: fixed; inset: 0; background: #0006; z-index: 60; }
.dialog {
  position: fixed; left: 50%; top: 50%; transform: translate(-50%, -50%); z-index: 61;
  width: min(32rem, calc(100vw - 2rem)); padding: 16px;
  background: var(--surface); border: var(--bw) solid var(--border); border-radius: var(--radius);
  box-shadow: var(--shadow);
}
/* An overlay panel floats over the main view (for example a map) instead of a fixed side bar. */
.overlay-panel {
  position: absolute; top: 12px; right: 12px; bottom: 12px; width: min(26rem, calc(100% - 24px));
  overflow: auto; padding: 12px; z-index: 30;
  background: var(--surface); border: var(--bw) solid var(--border); border-radius: var(--radius);
  box-shadow: var(--shadow);
}
```

An overlay panel has a header with its title, an "Enlarge" button that opens the full view of the
same content, and a close button. A dangerous action does not ask first. It runs at once and shows a
toast with "Undo". Its menu item uses `data-danger`. When an action cannot be undone, keep it a separate,
explicit action whose label names what goes (for example "Delete volume"). Do not add a confirm dialog
unless the user asks for one.

## Checklist before you call the UI done

- No `title` tooltips, and no native checkbox, radio, switch, colour or date picker is visible.
- Every icon button, control, option and sticker has a tooltip in the standard style.
- Light and dark mode both look right. Text meets WCAG AA contrast.
- Text is readable at the default zoom of a laptop: the 18px base, no small pixel sizes.
- Every action has a keyboard path, and focus is always visible.
- No continuous animation. Progress shows as text or a sticker colour.
