---
name: web-error-forensics
description: "Capture and analyze web app errors — uncaught exceptions, unhandled promise rejections, console errors/warnings, framework error overlays, and failed network calls — then reconstruct minified stack traces with source maps, cluster related errors, and find root cause. Use when an app throws, white-screens, or floods the console, or when you have a cryptic minified production stack to decode."
---

# Web Error Forensics

Turn raw errors into a **root cause**. Browser backend is the **`agent-browser` CLI**; if its version can't stream console, capture console/errors via the Playwright fallback. If agent-browser isn't installed, run `bash "$CLAUDE_PLUGIN_ROOT/scripts/ensure-agent-browser.sh"` first (auto-installs it). Confirm flags with `agent-browser --help`.

## Workflow

### 1) Capture everything the page emits
- `agent-browser open <url>`, drive to the failing state.
- Collect: uncaught exceptions, unhandled promise rejections, `console.error`/`warn`, framework error overlays (Next/Vite/Webpack), and failed/4xx/5xx network responses (these often *cause* the JS error).
- Screenshot the overlay/broken UI to `${TMPDIR:-/tmp}/build-web-apps/error.png` (reusable name — overwrite) and Read it.

### 2) Reconstruct minified stacks with source maps
A production stack like `at t (main.4f2a.js:1:88421)` is useless until mapped.
- Locate source maps: `dist/**/*.map`, `.next/**/*.map`, or the `//# sourceMappingURL=` comment. If maps aren't emitted, note that and recommend enabling them for the build under test.
- Map each minified frame (file:line:col) back to original file/function/line. Prefer a local tool (e.g. `npx source-map` / the project's `source-map` dep) over guessing.
- Present the **reconstructed stack** with real file paths.

### 3) Cluster, don't list
- Group errors by normalized signature (message template + top original frame), not by raw string. Count occurrences and note first/last trigger.
- Separate **one root error** from its **downstream cascade** (e.g. a failed fetch → undefined data → render throw). Fix the root, not each symptom.

### 4) Root cause
For the top cluster, state: the original throwing line, the value/condition that caused it (null/undefined, bad shape, race, missing guard), the **trigger** (which action/request), and the **fix** (guard, await, null-check, error boundary, fix the upstream request).

## Output

Report per top cluster: **signature + count**, **reconstructed stack (real files)**, **trigger**, **root cause**, **fix**, and whether an **error boundary / rejection handler** is missing. Keep noisy raw logs out of chat — cite the decisive frames only. When done, `agent-browser close` and clean up images: `bash "$CLAUDE_PLUGIN_ROOT/scripts/clean-shots.sh"` (or `rm -f "${TMPDIR:-/tmp}/build-web-apps/"*.png`).
