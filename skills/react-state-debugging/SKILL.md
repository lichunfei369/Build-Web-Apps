---
name: react-state-debugging
description: "Debug client state in React apps — Redux, Zustand, React Query / TanStack Query, Jotai, Recoil, and Context — to explain wrong, stale, or out-of-sync UI and trace why a component re-rendered or didn't update. Use when state is wrong/stale, a mutation doesn't reflect in the UI, or cache/server-state is out of sync. Reads the store via an injected script."
---

# React State Debugging

Explain *why the UI shows the state it shows*. Browser backend is the **`agent-browser` CLI**; read store state by injecting `scripts/read-store.js` (via agent-browser init-script / eval). This is **best-effort** — it depends on the app exposing a store and on eval being available; otherwise fall back to Playwright eval or temporary in-app logging. Confirm flags with `agent-browser --help`.

## Workflow

### 1) Identify the state stack
- Inspect `package.json` and imports: Redux Toolkit, Zustand, TanStack Query, Jotai, Recoil, or plain Context? Each is read differently.

### 2) Read the live store
- `agent-browser open <url>`, inject `read-store.js` to dump the relevant slice:
  - **Redux**: read the store via the DevTools hook (`window.__REDUX_DEVTOOLS_EXTENSION__`) or an exposed `store.getState()`.
  - **Zustand**: read the vanilla store's `getState()` if exposed.
  - **React Query**: read the `QueryClient` cache — query keys, `status`, `dataUpdatedAt`, `isStale`, `fetchStatus`.
  - **Context**: inspect provider value via React DevTools (`--enable react-devtools`).
- Snapshot the value **before and after** the action that misbehaves.

### 3) Classify the bug
- **Stale render**: state changed but component didn't re-render → wrong selector identity, missing dependency, mutation of state in place (Redux/Immer rule broken), or `memo` swallowing an update.
- **Wrong value**: reducer/setter logic, derived selector bug, or two sources of truth disagreeing.
- **Server/client desync (React Query)**: stale cache not invalidated after mutation, wrong query key, `staleTime`/`gcTime` misconfig, or missing `invalidateQueries`.
- **Over-render**: subscribing to too-broad a slice → pair with `react-render-performance`.

### 4) Prove it
- Show the before/after store dump next to the rendered UI. Tie the discrepancy to the exact selector / reducer / query key / effect dependency.

## Output

Report: **the state at the failing moment** (slice dump), **the classification**, **the root cause** (selector / reducer / cache key / dependency), and the **fix** (correct the selector, immutably update, invalidate the query, fix deps). Cross-link `react-render-performance` if the symptom is excessive re-rendering. Close the session when done.
