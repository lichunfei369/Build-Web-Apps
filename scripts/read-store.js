/* build-web-apps · client-state reader (best-effort).
 *
 * Dumps common React state containers (Redux, Zustand, TanStack/React Query)
 * to window.__STORE_DUMP__ and the console so agent-browser / Playwright can
 * read them. Snapshot before AND after the misbehaving action and diff.
 *
 * Many apps don't expose their store globally. When a section comes back as a
 * hint instead of data, expose it in dev (e.g. `window.store = store`,
 * `window.queryClient = queryClient`) or inspect Context via React DevTools
 * (open agent-browser with `--enable react-devtools`). Adjust the global names
 * below to match the app.
 */
(() => {
  const dump = {};

  // Redux (needs the store exposed on window in dev)
  try {
    if (window.store && typeof window.store.getState === 'function') {
      dump.redux = window.store.getState();
    } else if (window.__REDUX_DEVTOOLS_EXTENSION__) {
      dump.reduxHint =
        'Redux DevTools detected but store is not on window.store. Set window.store = store in dev to read state here, or use the DevTools panel.';
    }
  } catch (e) {
    dump.reduxError = (e && e.message) || String(e);
  }

  // Zustand (vanilla store must be exposed)
  try {
    const zs = window.__ZUSTAND_STORE__ || window.zustandStore;
    if (zs && typeof zs.getState === 'function') {
      dump.zustand = zs.getState();
    }
  } catch (e) {
    dump.zustandError = (e && e.message) || String(e);
  }

  // TanStack / React Query
  try {
    const qc = window.__REACT_QUERY_CLIENT__ || window.queryClient;
    if (qc && typeof qc.getQueryCache === 'function') {
      dump.reactQuery = qc.getQueryCache().getAll().map((q) => ({
        key: q.queryKey,
        status: q.state.status,
        fetchStatus: q.state.fetchStatus,
        isStale: typeof q.isStale === 'function' ? q.isStale() : undefined,
        dataUpdatedAt: q.state.dataUpdatedAt,
        errorUpdateCount: q.state.errorUpdateCount,
      }));
    }
  } catch (e) {
    dump.reactQueryError = (e && e.message) || String(e);
  }

  if (Object.keys(dump).length === 0) {
    dump.note =
      'No store found on window. Expose store / queryClient on window in dev, or inspect Context via React DevTools (--enable react-devtools).';
  }

  window.__STORE_DUMP__ = dump;
  try {
    console.log('[build-web-apps state]\n' + JSON.stringify(dump, null, 2));
  } catch (_) {
    console.log('[build-web-apps state] (contains non-serializable values)', dump);
  }
  return dump;
})();
