---
name: web-debugger-agent
description: "Problem-driven deep-diagnosis entry point for React web apps. Use when something is broken, erroring, blank, slow, or behaving unexpectedly in a rendered web app — it starts/finds the dev server, drives the agent-browser CLI to reproduce, captures console/network/snapshot evidence, and routes to the right specialist (performance / memory / error / network / a11y / state). Distinct from frontend-testing-debugging, which is the post-change QA verifier."
---

# Web Debugger Agent

The **diagnosis dispatcher** for the Build Web Apps plugin. Use it when the user reports a *problem* ("it's broken / white screen / throws / slow / leaks / wrong state") rather than asking to verify a finished change. For post-edit QA verification, use `frontend-testing-debugging`.

## Browser backend (non-negotiable)

- The only browser is the **`agent-browser` CLI** (https://agent-browser.dev). It launches its own Chromium.
- **Never** use claude-in-chrome here — it would drive a second Chrome against the same dev server.
- Fallback is **Playwright** only when agent-browser is absent or lacks a needed capability.
- Exact flags vary by version; confirm with `agent-browser --help`.

## Workflow

### 1) Readiness
- `agent-browser --version`. If missing, tell the user once: `npm i -g agent-browser` (or `brew install agent-browser`), then `agent-browser install`. Don't hard-fail silently.

### 2) Find or start the dev server
- Read `package.json` scripts (`dev`, `start`). Detect the framework (Vite / Next / CRA / Remix).
- Check for an already-running port before starting a new one (`lsof -i :3000 -i :5173` etc.).
- Start it with the repo's package manager in the background and keep the host/port exact. Wait until it serves before opening.

### 3) Reproduce
- `agent-browser open <url>` (add `--enable react-devtools` if React-internal inspection is likely needed).
- Drive to the failing state with `agent-browser snapshot` (accessibility tree + `@e` refs) then `agent-browser click @e…` / form commands. Prefer refs over coordinates.
- `agent-browser screenshot <scratchpad>/repro.png`, then **Read the image** to confirm the symptom visually.

### 4) Capture the cheapest decisive evidence
- **Console**: capture errors/warnings (agent-browser debugging/CDP mode; if unavailable on this version, grab console via the Playwright fallback).
- **Network**: agent-browser network inspection for failed / slow requests.
- **DOM/state**: snapshot for blank-shell vs framework error overlay.

### 5) Triage — route to the specialist

| Symptom | Hand off to |
|---|---|
| Throws / white screen / stack trace / unhandled rejection | `web-error-forensics` |
| Janky / slow / re-renders too much / poor LCP·INP | `react-render-performance` |
| Memory grows / tab gets slow over time / detached nodes | `web-memory-leaks` |
| API slow / request fails / waterfall stalls | `web-network-inspector` |
| Keyboard/ARIA/contrast/focus problems | `web-a11y-audit` |
| Wrong/stale state, "why did it re-render" | `react-state-debugging` |

Load the specialist skill and follow its workflow; pass along the URL, repro steps, and evidence you already gathered so it doesn't restart from zero.

### 6) Verify the fix
- After a fix, hand to `frontend-testing-debugging` to run the QA validation loop on the same agent-browser session and produce the pass/fail report.

## Output

Lead with the **diagnosis** (what's wrong + root cause + evidence), then the **fix or the specialist you routed to**, then **verification status**. Keep raw logs out of the chat — cite the decisive lines only. Close the agent-browser session (`agent-browser close`) when done.
