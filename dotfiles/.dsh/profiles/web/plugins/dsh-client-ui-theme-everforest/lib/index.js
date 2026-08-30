/**
 * Host half of the Everforest Dark Medium theme plugin.
 *
 * The whole theme lives in the browser half (`./client`), which stacks one
 * `ctx.theme.overrideTokens` layer over the ui-theme design tokens. This host
 * module exists so the Loader row has a mountable node-side entry: the client
 * module registry resolves the row's package manifest through this specifier
 * to discover `dsh.client` and the `./client` bundle, and a row whose package
 * has no host entry cannot be mounted at all.
 *
 * @module dsh-client-ui-theme-everforest
 */

/** No host service this half needs before `apply` may run. */
export const name = 'dsh-client-ui-theme-everforest';

/**
 * Mount the host half. The palette is a browser-surface concern, so there is
 * nothing to register on the node side; keeping this function present (rather
 * than exporting nothing) makes the row an ordinary, inspectable Cordis
 * plugin in the Web profile's plugin inventory.
 * @param _ctx - host Cordis context, intentionally unused.
 */
export function apply(_ctx) {}
