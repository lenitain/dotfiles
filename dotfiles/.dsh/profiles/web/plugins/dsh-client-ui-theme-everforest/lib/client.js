/**
 * Everforest Dark Medium — browser half.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * THE RULE THIS FILE FOLLOWS
 * ─────────────────────────────────────────────────────────────────────────────
 * The palette's own definitions govern; DeepSeek Harness's token names are only
 * the slots that have to be filled. So the direction of the mapping is:
 *
 *     official Everforest role  ──►  DSH token
 *
 * and never the reverse. Every value below is one of the official dark-medium
 * colours, chosen to match the *official documented usage* of that colour. Where
 * DSH has a surface with no Everforest counterpart, the nearest official surface
 * by contrast rank wins — nothing is invented, no colour is blended, and no
 * in-between hex is interpolated.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * WHY AN OVERRIDE LAYER, NOT A REGISTERED THEME
 * ─────────────────────────────────────────────────────────────────────────────
 * DSH's ui-theme owns exactly three built-in preferences (`light`, `dark`,
 * `system`); its Appearance row renders those three cubes and its durable
 * settings schema accepts only those three ids, so a third-party palette cannot
 * arrive as a registered preference — it would be silently dropped on reload.
 * The documented extension point is an alias-token override layer stacked over
 * the active theme (`ctx.theme.overrideTokens`).
 *
 * Such a layer composes over whichever built-in preference is active, so the
 * palette holds regardless of Appearance or the OS colour scheme. Every token is
 * therefore declared with the SAME value in both the `light` and `dark` slots:
 * the override contract requires both so a scheme switch can never leave a token
 * unset, and this theme deliberately ignores that switch — it locks the GUI to
 * the Everforest dark medium ramp.
 */

window.__ModuleLoader__.load({
	id: 'dsh-client-ui-theme-everforest',
	factory: (require) => {
		var module = { exports: {} }
		var exports = module.exports
		Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' })

		/**
		 * The plugin id doubles as the override-layer source, so re-applying
		 * replaces this layer wholesale instead of stacking a second copy.
		 */
		const THEME_ID = 'everforest-dark-medium'

		/**
		 * THE official palette — dark variant, medium contrast. Every entry is
		 * named and documented in Everforest's own table; the comment beside each
		 * one is that table's "Usages" column, and it is what every mapping
		 * decision below is justified by. Nothing else may be added here.
		 *
		 * Swapping `medium` for `hard` or `soft` is a change to this object alone:
		 * hard  → bg_dim #1E2326, bg0 #272E33, bg1 #2E383C, bg2 #374145,
		 *         bg3 #414B50, bg4 #495156, bg5 #4F5B58,
		 *         bg_visual #4C3743, bg_red #493B40, bg_yellow #45443C,
		 *         bg_green #3C4841, bg_blue #384B55, bg_purple #463F48
		 * soft  → bg_dim #293136, bg0 #333C43, bg1 #3A464C, bg2 #434F55,
		 *         bg3 #4D5960, bg4 #555F66, bg5 #5D6B66,
		 *         bg_visual #5C3F4F, bg_red #59464C, bg_yellow #55544A,
		 *         bg_green #48584E, bg_blue #3F5865, bg_purple #4E4953
		 * (foreground colours are identical across all three contrast settings.)
		 */
		const P = {
			// ── background colours ────────────────────────────────────────────────
			/** Dimmed Background. The darkest official surface. */
			bg_dim: '#232a2e',
			/** Default Background, Line Numbers Background, Signs Background, Status Line Background (inactive), Tab Line Label (active). */
			bg0: '#2d353b',
			/** Cursor Line Background, Color Columns, Closed Folds Background, Status Line Background (active), Tab Line Background. */
			bg1: '#343f44',
			/** Popup Menu Background, Floating Window Background, Window Toolbar Background. */
			bg2: '#3d484d',
			/** List Chars, Special Keys, Tab Line Label Background (inactive). */
			bg3: '#475258',
			/** Window Splits Separators, Whitespaces, Breaks. */
			bg4: '#4f585e',
			/** Not currently used by Everforest itself. */
			bg5: '#56635f',
			/** Visual Selection. */
			bg_visual: '#543a48',
			/** Diff Deleted Line Background, Error Highlights. */
			bg_red: '#514045',
			/** Warning Highlights. */
			bg_yellow: '#4d4c43',
			/** Diff Added Line Background, Hint Highlights. */
			bg_green: '#425047',
			/** Diff Changed Line Background, Info Highlights. */
			bg_blue: '#3a515d',
			/** (no documented usage) */
			bg_purple: '#4a444e',

			// ── foreground colours ────────────────────────────────────────────────
			/** Default Foreground, Signs. */
			fg: '#d3c6aa',
			/** Conditional/Loop/Exception/Inclusion/Uncategorised Keywords, Diff Deleted Signs, Error Messages, Error Signs. */
			red: '#e67e80',
			/** Operator Keywords, Operators, Labels, Storage Classes, Composite Types, Enumerated Types, Tags, Title, Debugging Statements. */
			orange: '#e69875',
			/** Types, Special Characters, Warning Messages, Warning Signs. */
			yellow: '#dbbc7f',
			/** Function Names, Method Names, Strings, Characters, Hint Messages, Hint Signs, Search Highlights. */
			green: '#a7c080',
			/** Constants, Macros. */
			aqua: '#83c092',
			/** Identifiers, Uncategorised Special Symbols, Diff Changed Text Background, Info Messages, Info Signs. */
			blue: '#7fbbb3',
			/** Booleans, Numbers, Preprocessors. */
			purple: '#d699b6',
			/** Line Numbers, Fold Columns, Concealed Text, Foreground UI Elements. */
			grey0: '#7a8478',
			/** Comments, Punctuation Delimiters, Closed Folds, Ignored/Disabled, UI Borders, Status Line Text. */
			grey1: '#859289',
			/** Cursor Line Number, Tab Line Label (inactive). */
			grey2: '#9da9a0',
			/** Menu Selection Background, Tab Line Label Background (active), Status Line Mode Indicator. */
			statusline1: '#a7c080',
			/** Status Line Mode Indicator. */
			statusline2: '#d3c6aa',
			/** Status Line Mode Indicator. */
			statusline3: '#e67e80'
		}

		/**
		 * Screen scrims. DSH needs translucent versions of colours Everforest
		 * applies opaque; the colour is always an official one, only the alpha is
		 * added, and the dimming scrims dim toward `bg_dim` rather than toward
		 * white — an Everforest surface dims by going darker, never lighter.
		 */
		const scrim = (hex, alpha) => {
			const value = Number.parseInt(hex.slice(1), 16)
			const r = (value >> 16) & 255
			const g = (value >> 8) & 255
			const b = value & 255
			return `rgba(${String(r)}, ${String(g)}, ${String(b)}, ${String(alpha)})`
		}

		/**
		 * The static ramp. DSH's design platform declares these as raw steps that
		 * component sheets may read directly, so they are retargeted onto the
		 * palette as well — an isolated component then keeps rendering in-palette
		 * instead of falling back to DeepSeek's blues and greys.
		 *
		 * The `neutral-bluish-*` family is DSH's *surface* ramp (its steps are
		 * consumed as backgrounds, borders, and both light and dark text). It is
		 * filled in official contrast order from `bg_dim` upward, then hands over
		 * to the greys exactly where DSH hands over from surfaces to text.
		 */
		const STATIC_TOKENS = {
			// neutral-bluish — the surface ramp, darkest official step first.
			'--dsw-static-neutral-bluish-00': P.bg_dim,
			'--dsw-static-neutral-bluish-50': P.fg,
			'--dsw-static-neutral-bluish-60': P.bg1,
			'--dsw-static-neutral-bluish-75': P.bg1,
			'--dsw-static-neutral-bluish-100': P.bg1,
			'--dsw-static-neutral-bluish-150': P.bg2,
			'--dsw-static-neutral-bluish-200': P.bg2,
			'--dsw-static-neutral-bluish-300': P.grey2,
			'--dsw-static-neutral-bluish-400': P.grey0,
			'--dsw-static-neutral-bluish-500': P.grey0,
			'--dsw-static-neutral-bluish-600': P.grey1,
			'--dsw-static-neutral-bluish-700': P.bg4,
			'--dsw-static-neutral-bluish-750': P.bg3,
			'--dsw-static-neutral-bluish-800': P.bg2,
			'--dsw-static-neutral-bluish-850': P.bg2,
			'--dsw-static-neutral-bluish-875': P.bg_dim,
			'--dsw-static-neutral-bluish-900': P.bg0,
			'--dsw-static-neutral-bluish-950': P.bg_dim,
			'--dsw-static-neutral-bluish-1000': P.bg_dim,

			// neutral — the secondary/sunken ramp DSH uses under floating chrome.
			'--dsw-static-neutral-00': P.bg0,
			'--dsw-static-neutral-50': P.bg1,
			'--dsw-static-neutral-100': P.bg2,
			'--dsw-static-neutral-150': P.bg2,
			'--dsw-static-neutral-200': P.bg3,
			'--dsw-static-neutral-250': P.bg4,
			'--dsw-static-neutral-300': P.bg5,
			'--dsw-static-neutral-400': P.grey2,
			'--dsw-static-neutral-500': P.grey1,
			'--dsw-static-neutral-550': P.grey0,
			'--dsw-static-neutral-600': P.bg4,
			'--dsw-static-neutral-700': P.bg4,
			'--dsw-static-neutral-800': P.bg2,
			'--dsw-static-neutral-850': P.bg_dim,
			'--dsw-static-neutral-900': P.bg_dim,
			'--dsw-static-neutral-1000': P.bg_dim,

			// deepseek — DSH's brand ramp. Official "Identifiers / Info Messages"
			// blue, with the info-highlight step for its tinted low end.
			'--dsw-static-deepseek-50': P.bg_dim,
			'--dsw-static-deepseek-100': P.bg_blue,
			'--dsw-static-deepseek-200': P.bg_blue,
			'--dsw-static-deepseek-300': P.blue,
			'--dsw-static-deepseek-400': P.blue,
			'--dsw-static-deepseek-450': P.blue,
			'--dsw-static-deepseek-500': P.blue,
			'--dsw-static-deepseek-600': P.blue,
			'--dsw-static-deepseek-700-delete': P.blue,
			'--dsw-static-deepseek-800': P.bg_blue,
			'--dsw-static-deepseek-900': P.bg_dim,

			// blue — the plain cool accent.
			'--dsw-static-blue-50': P.bg_dim,
			'--dsw-static-blue-50p': P.bg_dim,
			'--dsw-static-blue-75': P.bg_blue,
			'--dsw-static-blue-100': P.bg_blue,
			'--dsw-static-blue-300': P.blue,
			'--dsw-static-blue-400': P.blue,
			'--dsw-static-blue-450': P.blue,
			'--dsw-static-blue-500': P.blue,
			'--dsw-static-blue-600': P.blue,
			'--dsw-static-blue-800': P.bg_blue,
			'--dsw-static-blue-900': P.bg_dim,
			'--dsw-static-blue-950': P.bg_dim,

			// green — "Hint Messages, Hint Signs".
			'--dsw-static-green-100': P.bg_green,
			'--dsw-static-green-400': P.green,
			'--dsw-static-green-500': P.green,
			'--dsw-static-green-900': P.bg_dim,

			// red — "Error Messages, Error Signs" and "Error Highlights".
			'--dsw-static-red-50': P.bg_red,
			'--dsw-static-red-100': P.bg_red,
			'--dsw-static-red-400': P.red,
			'--dsw-static-red-500': P.red,
			'--dsw-static-red-600': P.red,
			'--dsw-static-red-900': P.bg_dim,

			// amber — "Warning Messages, Warning Signs" and "Warning Highlights".
			'--dsw-static-amber-100': P.bg_yellow,
			'--dsw-static-amber-400': P.yellow,
			'--dsw-static-amber-500': P.yellow,
			'--dsw-static-amber-600': P.yellow,
			'--dsw-static-amber-900': P.bg_dim
		}

		/**
		 * The semantic layer. Each entry follows DSH's own slot meaning, filled
		 * with whichever official colour is documented for that kind of surface.
		 * The governing official rules, applied throughout:
		 *
		 *   bg0  default background            bg1  cursor line / active status line
		 *   bg2  popup menu, floating window   bg3  list chars, special keys
		 *   bg4  separators, whitespace        bg_dim dimmed background
		 *   grey0 foreground UI elements       grey1 UI BORDERS, comments, disabled
		 *   grey2 cursor line number, inactive tab label
		 *   green hints, strings, functions    aqua constants, macros
		 *   blue  identifiers, info            yellow types, warnings, special chars
		 *   red   errors, keywords             orange operators, labels, titles
		 *   purple booleans, numbers, preproc  statusline1 menu-selection background
		 */
		const ALIAS_TOKENS = {
			// ── surfaces: one official background step per elevation ──────────────
			'--dsw-alias-bg-base': P.bg0,
			'--dsw-alias-bg-layer-1': P.bg_dim,
			'--dsw-alias-bg-layer-2': P.bg1,
			'--dsw-alias-bg-layer-3': P.bg2,
			// A NEUTRAL container step, not a selection tint: DSH uses it for form
			// editors, setup cards, and selectors, and pairs it with other semantic
			// colours as foreground (`warning { background: <this>; color: warn-label }`),
			// so it must stay a surface. The official raised-surface step is bg1.
			'--dsw-alias-bg-module-platform': P.bg1,
			'--dsw-alias-bg-overlay': P.bg3,
			'--dsw-alias-bg-multi-select': P.bg2,
			'--dsw-alias-bg-skeleton': scrim(P.grey1, 0.16),

			// ── scrims: dim toward the dimmed background, never toward white ──────
			'--dsw-alias-bg-mask-1': scrim(P.bg_dim, 0.5),
			'--dsw-alias-bg-mask-2': scrim(P.bg_dim, 0.2),
			'--dsw-alias-bg-mask-3': scrim(P.bg_dim, 0.6),
			'--dsw-alias-bg-mask-drop': scrim(P.bg0, 0.7),
			'--dsw-alias-bg-mask-photo': scrim(P.bg_dim, 0.88),

			// ── borders: the official rule is grey1 = "UI Borders"; the softer
			// steps that separate adjacent Everforest surfaces are background
			// contrast, not a drawn line.
			'--dsw-alias-border-l1': P.bg3,
			'--dsw-alias-border-l2': P.bg4,
			'--dsw-alias-border-l2-darkmode-thin': P.bg3,
			'--dsw-alias-border-l3': P.grey0,
			'--dsw-alias-border-l4': P.grey1,
			'--dsw-alias-border-inverted': scrim(P.grey1, 0.35),
			'--dsw-alias-border-inverted2': scrim(P.grey1, 0.5),

			// ── labels ───────────────────────────────────────────────────────────
			'--dsw-alias-label-primary': P.fg,
			'--dsw-alias-label-primary-bluish': P.fg,
			'--dsw-alias-label-primary-dimmed': P.fg,
			'--dsw-alias-label-primary-foreground': P.bg0,
			'--dsw-alias-label-primary-inverted': P.bg0,
			'--dsw-alias-label-secondary': P.grey2,
			'--dsw-alias-label-tertiary': P.grey1,
			'--dsw-alias-label-caption': P.grey0,
			'--dsw-alias-label-dimmed': P.grey1,
			// "Identifiers, Uncategorised Special Symbols."
			'--dsw-alias-link': P.blue,

			// ── brand: green is the official main-interaction colour ─────────────
			'--dsw-alias-brand-primary': P.statusline1,
			'--dsw-alias-brand-primary-invert': P.bg0,
			'--dsw-alias-brand-primary-new-colorprimary-new-color': P.statusline1,
			'--dsw-alias-brand-text': P.statusline1,

			// ── interactive states ───────────────────────────────────────────────
			'--dsw-alias-interactive-bg-hover': scrim(P.fg, 0.08),
			'--dsw-alias-interactive-bg-active': scrim(P.fg, 0.14),
			'--dsw-alias-interactive-bg-hover-accent': scrim(P.statusline1, 0.18),
			// "Error Highlights" is a red-tinted background.
			'--dsw-alias-interactive-bg-hover-danger': scrim(P.red, 0.18),
			'--dsw-alias-interactive-bg-hover-solid': P.bg2,

			// ── buttons ──────────────────────────────────────────────────────────
			'--dsw-alias-button-primary-fill': P.statusline1,
			'--dsw-alias-button-primary-hover': P.green,
			// "Hint Highlights."
			'--dsw-alias-button-primary-dimmed': P.bg_green,
			'--dsw-alias-button-contrast-fill': P.fg,
			'--dsw-alias-button-elevated-fill': P.bg1,
			'--dsw-alias-button-floating-fill': P.bg1,
			'--dsw-alias-button-floating-hover': P.bg2,
			'--dsw-alias-button-ghost-active-fill': P.bg2,
			'--dsw-alias-button-ghost-active-hover': P.bg3,
			'--dsw-alias-button-ghost-active-border': P.grey1,
			'--dsw-alias-button-info-fill': P.blue,
			'--dsw-alias-button-info-hover': P.aqua,
			'--dsw-alias-button-tool-bar-fill': scrim(P.grey0, 0.5),
			'--dsw-alias-button-tool-bar-fill-invisible': scrim(P.bg_dim, 0.36),
			'--dsw-alias-button-tool-bar-hover': scrim(P.grey1, 0.6),

			// ── markdown ─────────────────────────────────────────────────────────
			'--dsw-alias-markdown-code-block': P.bg_dim,
			'--dsw-alias-markdown-code-block-banner': P.bg1,
			'--dsw-alias-markdown-inline-code': P.bg2,
			'--dsw-alias-markdown-code-segment-selected': P.bg3,
			'--dsw-alias-markdown-code-segment-unselected': P.bg_dim,
			'--dsw-alias-markdown-citation': P.bg1,
			'--dsw-alias-markdown-placeholder': P.bg2,
			'--dsw-alias-markdown-tag': P.bg1,

			// ── state: official message semantics, one colour per severity ────────
			// "Hint Messages, Hint Signs" is green; "Constants, Macros" is aqua.
			'--dsw-alias-state-success-primary': P.green,
			'--dsw-alias-state-success-secondary': P.aqua,
			'--dsw-alias-state-success-tertiary': P.bg_green,
			// "Error Messages, Error Signs" is red; "Error Highlights" is bg_red.
			'--dsw-alias-state-error-primary': P.red,
			'--dsw-alias-state-error-secondary': P.red,
			// "Warning Messages, Warning Signs" is yellow; "Warning Highlights"
			// is bg_yellow.
			'--dsw-alias-state-warn-primary': P.yellow,
			'--dsw-alias-state-warn-secondary': P.yellow,
			'--dsw-alias-state-warn-tertiary': P.bg_yellow,
			'--dsw-alias-state-warn-label': P.yellow,
			// "Info Messages, Info Signs" is blue; "Info Highlights" is bg_blue.
			'--dsw-alias-state-business-primary': P.blue,
			'--dsw-alias-state-business-tertiary': P.bg_blue,

			// ── floating surfaces: official "Popup Menu / Floating Window" = bg2 ──
			'--dsw-alias-toast-bg': P.bg2,
			'--dsw-alias-tooltip-bg': P.bg2,

			// ── scrollbars: "Foreground UI Elements" and its comment-grey pair ────
			'--dsw-alias-scrollbar-bg-l1': P.grey0,
			'--dsw-alias-scrollbar-bg-l2': P.grey0,
			'--dsw-alias-scrollbar-hover-l1': P.grey1,
			'--dsw-alias-scrollbar-hover-l2': P.grey1,

			// ── feature surfaces ─────────────────────────────────────────────────
			// The sidebar is a raised column beside the transcript, so it takes the
			// official raised-surface step; the transcript keeps the default bg0.
			'--dsw-specific-sidebar-fill': P.bg1,
			'--dsw-specific-sidebar-nav-item-hover': P.bg2,
			// "Visual Selection."
			'--dsw-specific-sidebar-nav-item-active': P.bg_visual,
			'--dsw-specific-sidebar-nav-item-active-accent': P.bg3,
			'--dsw-specific-bubble': P.bg1,
			'--dsw-specific-bubble-highlight': P.bg2,
			'--dsw-specific-input-major': P.bg1,
			'--dsw-specific-login-input': P.bg_dim,
			'--dsw-specific-menu': P.bg2,
			'--dsw-specific-selector': P.bg2,
			'--dsw-specific-tip': P.bg2
		}

		/**
		 * Syntax highlighting, mapped one token group at a time onto the official
		 * highlight groups. This tier is the palette's home ground: here DSH's
		 * names already mean what Everforest's names mean.
		 */
		const SHIKI_TOKENS = {
			'--shiki-foreground': P.fg,
			'--shiki-background': P.bg_dim,
			// "Constants, Macros."
			'--shiki-token-constant': P.aqua,
			// "Strings, Characters."
			'--shiki-token-string': P.green,
			'--shiki-token-string-expression': P.green,
			// "Comments."
			'--shiki-token-comment': P.grey1,
			// "Conditional Keywords, Loop Keywords, Exception Keywords, Inclusion
			// Keywords, Uncategorised Keywords."
			'--shiki-token-keyword': P.red,
			// "Function Parameters."
			'--shiki-token-parameter': P.fg,
			// "Function Names, Method Names."
			'--shiki-token-function': P.green,
			// "Operators, Punctuation Delimiters."
			'--shiki-token-punctuation': P.grey1,
			// "Identifiers."
			'--shiki-token-link': P.blue
		}

		/**
		 * Fold every tier into the `{ light, dark }` pair shape the override
		 * contract requires. `light` and `dark` carry the same value on purpose:
		 * this palette is scheme-invariant, so Appearance and the OS preference
		 * both leave it untouched.
		 * @returns the override-layer dictionary.
		 */
		function everforestTokens() {
			const pairs = {}
			for (const tier of [STATIC_TOKENS, ALIAS_TOKENS, SHIKI_TOKENS]) {
				for (const [name, value] of Object.entries(tier)) pairs[name] = { light: value, dark: value }
			}
			return pairs
		}

		/**
		 * Stack the Everforest layer over whatever theme is active, then keep it
		 * stacked. `overrideTokens` composes over the ACTIVE theme and is keyed by
		 * source, so re-applying after a theme switch replaces this layer instead
		 * of duplicating it — one listener covers preference changes, registry
		 * changes, and the OS scheme flipping while the preference is `system`.
		 * @param ctx - client root context.
		 */
		function apply(ctx) {
			const tokens = everforestTokens()
			ctx.effect(() => {
				const dispose = ctx.theme.overrideTokens(THEME_ID, tokens)
				const onChange = () => ctx.theme.overrideTokens(THEME_ID, tokens)
				ctx.on('theme/change', onChange)
				return () => {
					ctx.off('theme/change', onChange)
					dispose()
				}
			}, 'everforest-dark-medium: token override layer')
		}

		exports.apply = apply
		exports.inject = ['theme']
		exports.EVERFOREST_DARK_MEDIUM_ID = THEME_ID
		exports.EVERFOREST_PALETTE = P
		return module.exports
	}
})
