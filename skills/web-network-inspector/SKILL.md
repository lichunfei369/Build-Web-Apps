---
name: web-network-inspector
description: "Inspect a web app's network layer — slow requests, failed/4xx/5xx calls, request waterfall, payload sizes, API timing, caching, and request waterfalls that block first paint or interaction. Use when an API call is slow or failing, the page is network-bound, or you need to understand the request sequence behind a flow."
---

# Web Network Inspector

Understand and fix what a web app does over the network. Browser backend is the **`agent-browser` CLI** network inspection (`/network`); Playwright fallback otherwise. Confirm flags with `agent-browser --help`.

## Workflow

### 1) Record the flow's traffic
- `agent-browser open <url>`, then drive the target flow (initial load, or a specific action like search/submit) while network capture is on.
- Pull the request list with method, URL, status, type, size, and timing.

### 2) Read the waterfall
- Order by start time. Look for:
  - **Blocking chains**: request B can't start until A finishes (serial fetch that should be parallel / batched).
  - **Stalls**: long "queued"/"TTFB" gaps (server slow, connection limit, blocked by main thread).
  - **Render-blocking** requests delaying LCP/FCP.

### 3) Flag the offenders
- **Failed**: 4xx/5xx and CORS failures — capture the response body/headers for the cause.
- **Slow**: rank by total time; separate server time (TTFB) from transfer time (payload).
- **Wasteful**: oversized JSON/images, missing compression, no cache headers, duplicate identical requests, **N+1** (many small calls that should be one).
- **Auth/ordering**: requests firing before auth/token ready.

### 4) Tie back to UI symptom
Connect a network finding to what the user feels: "search is slow" → the `/search` call has 1.8s TTFB; "list flickers" → data refetched on every render (see `react-state-debugging` / React Query cache); "fails intermittently" → 401 race before token refresh.

## Output

Report: **waterfall summary**, a **table of offenders** (request, status, total / TTFB / size, problem), the **worst-impact item with its UI symptom**, and **fixes** (parallelize/batch, add cache headers, paginate, compress, fix the failing endpoint, gate on auth). Capture the network view to `${TMPDIR:-/tmp}/build-web-apps/network.png` (reusable name — overwrite) and Read it if a visual helps. When done, `agent-browser close` and clean up images: `bash "$CLAUDE_PLUGIN_ROOT/scripts/clean-shots.sh"` (or `rm -f "${TMPDIR:-/tmp}/build-web-apps/"*.png`).
