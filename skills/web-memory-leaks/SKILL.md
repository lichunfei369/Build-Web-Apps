---
name: web-memory-leaks
description: "Hunt browser memory leaks in web apps — growing heap across navigations, detached DOM nodes, un-removed event listeners, timers, and closures that retain state. Use when a tab gets slower/heavier over time, memory grows on repeated navigation, or a component's teardown doesn't release memory. Uses agent-browser profiler / CDP heap snapshots."
---

# Web Memory Leaks

Prove and locate memory leaks with a disciplined **baseline → exercise → compare** method. Browser backend is the **`agent-browser` CLI** (profiler / CDP). If the installed version can't take heap snapshots, fall back to driving Chrome via Playwright + CDP `HeapProfiler`. If agent-browser isn't installed, run `bash "$CLAUDE_PLUGIN_ROOT/scripts/ensure-agent-browser.sh"` first (auto-installs it). Confirm flags with `agent-browser --help`.

## Method (don't eyeball — diff)

### 1) Establish a baseline
- `agent-browser open <url>`. Navigate to the suspect screen and back to a neutral one to reach steady state.
- Force GC if the version exposes it, then take **snapshot A**.

### 2) Exercise the suspected flow N times
- Repeat the mount→unmount or navigate-in→navigate-out cycle several times (e.g. 5–10): open a modal and close it, route into a page and back, mount/unmount the component.
- This amplifies a per-cycle leak into an obvious slope.

### 3) Snapshot and compare
- Force GC, take **snapshot B**. Compare retained size A→B.
- A healthy flow returns near baseline. A leak shows **monotonic growth** proportional to cycle count.

### 4) Localize the retainer
Look for, in order of frequency:
- **Detached DOM nodes** still referenced by JS (removed from the tree but kept alive).
- **Event listeners / subscriptions** added on mount but not removed on unmount (missing cleanup in `useEffect` return, `addEventListener` without `removeEventListener`, store/socket subscriptions).
- **Timers/intervals** (`setInterval`) never cleared.
- **Closures** capturing large objects held by a long-lived ref, module-level cache, or context.
- **Growing collections**: arrays/Maps/Sets pushed to but never trimmed.

Read the snapshot's retainer path to name the holding reference and trace it back to a file/hook.

## Output

Report: **verdict** (leak confirmed? growth per cycle), **the retained objects + retainer path**, **the root-cause line** (which mount/subscription/timer lacks cleanup), and the **fix** (add the cleanup, clear the timer, remove the listener, bound the cache). Re-run the cycle test after the fix to show the slope flatten. Capture snapshots/screenshots to `${TMPDIR:-/tmp}/build-web-apps/` with reusable names (overwrite, don't accumulate) and Read them. When done, `agent-browser close` and clean up images: `bash "$CLAUDE_PLUGIN_ROOT/scripts/clean-shots.sh"` (or `rm -f "${TMPDIR:-/tmp}/build-web-apps/"*.png`).
