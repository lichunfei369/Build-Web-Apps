---
name: react-render-performance
description: "Diagnose React render performance — wasted re-renders, expensive components, fiber-tree hotspots, and Core Web Vitals (LCP, CLS, INP, TTFB, FCP) — using agent-browser's React DevTools and profiler. Use when a React app feels janky, slow to interact, slow to first paint, or re-renders too much."
---

# React Render Performance

Find *why* a React UI is slow and what to change. Browser backend is the **`agent-browser` CLI** only (Playwright fallback). Confirm flags with `agent-browser --help`.

## Workflow

### 1) Open with React profiling on
- `agent-browser open <url> --enable react-devtools`.
- React re-render recording and fiber inspection require a React **development or profiling** build. If the target is a minified production build, say so and ask to run the dev server instead.

### 2) Record re-renders
- Start re-render recording, exercise the slow interaction (`agent-browser click @e…` / type), stop recording.
- Read out: which components re-rendered, how many times, and why (props/state/context change). Look for:
  - components re-rendering with **unchanged props** (missing `memo`),
  - new inline objects/functions/arrays passed as props each render,
  - context providers whose value identity changes every render,
  - list items re-rendering because of unstable `key`s.

### 3) Measure Core Web Vitals
- Capture LCP, CLS, INP, TTFB, FCP from agent-browser's Web Vitals surface.
- Tie each regression to a cause: large LCP element / blocking resource (LCP), layout shift from late content or missing dimensions (CLS), long event-handler/render work (INP).

### 4) Confirm the hotspot
- Use the profiler to rank components by render cost. Screenshot the profile to `${TMPDIR:-/tmp}/build-web-apps/profile.png` (reusable name — overwrite) and Read it for the visual flame view.
- Distinguish "renders too often" (identity/memo problem) from "each render is expensive" (heavy compute in render → move to `useMemo`/worker/server).

## Recommendations

Map findings to concrete fixes and cite `react-best-practices` for the canonical patterns:
- `React.memo` + stable props (`useCallback`/`useMemo`) for unchanged-prop re-renders.
- Split or memoize context; move rarely-changing values out.
- Stable, content-derived `key`s for lists; virtualize long lists.
- Defer/lazy-load below-the-fold and heavy components; reserve space to avoid CLS.
- Move expensive pure computation out of render.

## Output

Report: **top offenders** (component → render count / cost → cause), **CWV table** (metric, value, target, cause), and a **prioritized fix list** (highest impact first) with the file/component to touch. Verify improvements by re-recording after the fix. When done, `agent-browser close` and clean up images: `bash "$CLAUDE_PLUGIN_ROOT/scripts/clean-shots.sh"` (or `rm -f "${TMPDIR:-/tmp}/build-web-apps/"*.png`).
