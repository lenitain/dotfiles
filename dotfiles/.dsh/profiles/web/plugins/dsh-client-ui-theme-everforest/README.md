# Everforest Dark Medium for the DSH Web GUI

The official [Everforest](https://github.com/sainnhe/everforest) **dark, medium
contrast** palette wired into the DeepSeek Harness browser surface.

## The rule

**The palette's definitions govern; DSH's token names are only the slots that
have to be filled.** The mapping runs `official Everforest role → DSH token`, and
never the reverse: every colour is one of the 24 official dark-medium colours,
chosen to match that colour's documented usage. Nothing is blended, no in-between
hex is interpolated, and where DSH has a surface with no Everforest counterpart
the nearest official surface by contrast rank wins.

**Palette use: 21 of the 24 official colours.** The palette carries all 24, but
three of them reach no token: `bg_purple` `#4a444e`, `purple` `#d699b6` and
`orange` `#e69875`. DSH has no slot whose meaning is one of theirs, and a colour
that means nothing is not spent to make the palette look complete.

## Shape of the override

DSH's `ui-theme` owns exactly three built-in preferences (`light`, `dark`,
`system`) and its durable settings schema accepts only those ids, so a third-party
palette cannot arrive as a registered theme. It arrives instead as an alias-token
override layer (`ctx.theme.overrideTokens`) stacked over whichever built-in theme
is active, so the palette holds regardless of Appearance or the OS colour scheme.

Every token is declared with the **same value in both the `light` and `dark`
slots**: the override contract requires both, so a scheme switch can never leave a
token unset. The Appearance cubes keep working as preference toggles; they no
longer change colour.

Three tiers, 174 tokens: 73 `--dsw-static-*`, 90 `--dsw-alias-*`, 11 `--shiki-*`.

## Mapping

### Surfaces — one official background step per elevation

| DSH token | Colour | Official usage that justifies it |
|---|---|---|
| `--dsw-alias-bg-base` | `bg0` `#2d353b` | Default Background |
| `--dsw-alias-bg-layer-1` | `bg_dim` `#232a2e` | Dimmed Background |
| `--dsw-alias-bg-layer-2` | `bg1` `#343f44` | Cursor Line / Status Line Background (active) |
| `--dsw-alias-bg-layer-3` | `bg2` `#3d484d` | Popup Menu Background, Floating Window Background |
| `--dsw-alias-bg-overlay` | `bg3` `#475258` | List Chars, Special Keys |
| `--dsw-alias-bg-module-platform` | `bg1` `#343f44` | neutral raised container |
| `--dsw-specific-sidebar-fill` | `bg1` `#343f44` | raised column beside the transcript |
| `--dsw-specific-menu`, `-tip`, `-selector` | `bg2` `#3d484d` | Popup Menu / Floating Window |
| `--dsw-specific-sidebar-nav-item-active` | `bg_visual` `#543a48` | Visual Selection |
| `--dsw-alias-markdown-code-block` | `bg_dim` `#232a2e` | dimmed block on the default background |

`bg-module-platform` is a neutral surface rather than a selection tint: DSH uses
it both for form editors and setup cards and as the background of a
foreground-paired warning, so it takes the raised-surface step.

### Borders

| DSH token | Colour | Official usage |
|---|---|---|
| `--dsw-alias-border-l1` | `bg3` `#475258` | surface-contrast hairline |
| `--dsw-alias-border-l2`, `-l2-darkmode-thin` | `bg4` `#4f585e` | Window Splits Separators |
| `--dsw-alias-border-l3` | `grey0` `#7a8478` | Foreground UI Elements |
| `--dsw-alias-border-l4` | `grey1` `#859289` | UI Borders |

The official rule is that drawn lines are `grey1`; the softer steps that separate
two adjacent Everforest surfaces are background contrast, not a line.

### Text

`label-primary(-bluish/-dimmed)` → `fg` · `label-secondary` → `grey2` ·
`label-tertiary`/`-dimmed` → `grey1` · `label-caption` → `grey0` ·
`label-primary-foreground`/`-inverted` → `bg0` (text inside a green fill is dark) ·
`link` → `blue`.

### State — one colour per severity, from the message semantics

| Severity | Colour | Official usage |
|---|---|---|
| success | `green` `#a7c080` | Hint Messages, Hint Signs |
| success secondary | `aqua` `#83c092` | Constants, Macros |
| success tertiary | `bg_green` `#425047` | Hint Highlights |
| error | `red` `#e67e80` | Error Messages, Error Signs |
| warning | `yellow` `#dbbc7f` | Warning Messages, Warning Signs |
| warning tertiary | `bg_yellow` `#4d4c43` | Warning Highlights |
| info / business | `blue` `#7fbbb3` | Info Messages, Info Signs |
| info tertiary | `bg_blue` `#3a515d` | Info Highlights |

### Scrims — Everforest dims darker, never lighter

`bg-mask-1/2/3/photo` are `bg_dim` at 50/20/60/88 % alpha; `bg-mask-drop` is
`bg0` at 70 %. The colour is always official; only the alpha is added.

### Syntax highlighting

| Shiki token | Colour | Official usage |
|---|---|---|
| `token-comment` | `grey1` | Comments |
| `token-keyword` | `red` | Conditional / Loop / Exception / Inclusion Keywords |
| `token-string`, `-string-expression`, `token-function` | `green` | Strings, Characters, Function Names |
| `token-constant` | `aqua` | Constants, Macros |
| `token-punctuation` | `grey1` | Punctuation Delimiters |
| `token-parameter` | `fg` | Function Parameters |
| `token-link` | `blue` | Identifiers |
| `foreground` | `fg` | Default Foreground |

### The static ramp

All 73 `--dsw-static-*` steps the design platform declares are retargeted in
official contrast order, so an isolated component keeps rendering in-palette
instead of falling back to DeepSeek's blues and greys: amber→yellow/orange,
blue & deepseek→blue, green→green, red→red, and the two neutral ramps→the
background and grey steps.

## Switching contrast

`lib/client.js` keeps the palette in one `P` object whose comment carries the
**hard** and **soft** background values from the palette document. Moving between
medium, hard and soft is a change to that object alone — the foreground colours
are identical across all three.

## Layout

| Path | Role |
|---|---|
| `lib/index.js` | Host half. Mountable no-op: it exists so the Loader row has a node-side entry, which is how the client module registry discovers `dsh.client` and the `./client` bundle. |
| `lib/client.js` | Browser half. The palette plus the three mapping tiers. |

## Install / uninstall

Live in the `web` profile:

- package: `~/.dsh/profiles/web/plugins/dsh-client-ui-theme-everforest/`
- link: `~/.dsh/profiles/web/node_modules/dsh-client-ui-theme-everforest`
- row: the `ui-theme-everforest` insert in `~/.dsh/profiles/web/cordis.patch.yml`

The link is a plain symlink; the Loader resolves the row's specifier through
ordinary node resolution, so a pnpm install is not required.

**A restart is required** for any change here to reach the browser: the boot graph
is composed once at startup and the client bundle is served from that composition.
Editing `lib/client.js` does not hot-reload.

**Removing the theme:** delete the `- insert:` block from `cordis.patch.yml` and
the symlink. Nothing else references it.
