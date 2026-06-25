/* build-web-apps · accessibility injection (best-effort).
 *
 * Loads axe-core (from CDN if not already on the page), runs a WCAG 2.0/2.1
 * A+AA pass against the current document, stores the full result on
 * window.__AXE_RESULT__, and logs a compact summary to the console so
 * agent-browser (or Playwright) can read it back.
 *
 * Usage: inject via agent-browser's eval / init-script against the page under
 * test, then read window.__AXE_RESULT__ or the console summary. Re-run after
 * opening menus/modals to audit each significant UI state.
 *
 * If the app blocks the CDN (offline / strict CSP), bundle axe-core locally
 * and replace the src below, or fall back to @axe-core/playwright.
 */
(async () => {
  const AXE_CDN = 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js';
  async function ensureAxe() {
    if (window.axe) return window.axe;
    await new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = AXE_CDN;
      s.onload = resolve;
      s.onerror = () => reject(new Error('axe-core failed to load (offline or CSP). Bundle it locally.'));
      document.head.appendChild(s);
    });
    return window.axe;
  }
  try {
    const axe = await ensureAxe();
    const results = await axe.run(document, {
      resultTypes: ['violations'],
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'] },
    });
    window.__AXE_RESULT__ = results;
    const summary = results.violations.map((v) => ({
      id: v.id,
      impact: v.impact,
      count: v.nodes.length,
      help: v.help,
      targets: v.nodes.slice(0, 5).map((n) => n.target.join(' ')),
    }));
    console.log('[build-web-apps a11y] ' + summary.length + ' violation rule(s):');
    console.log(JSON.stringify(summary, null, 2));
    return summary;
  } catch (e) {
    const msg = (e && e.message) || String(e);
    console.error('[build-web-apps a11y] error: ' + msg);
    window.__AXE_RESULT__ = { error: msg };
    return { error: msg };
  }
})();
