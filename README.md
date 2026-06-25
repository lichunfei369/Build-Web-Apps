# Build Web Apps — Claude Code plugin

Build, debug, and harden **React web apps** from one place. Adapted for Claude Code from OpenAI's Codex *Build Web Apps* plugin, then extended with a dedicated **diagnosis suite** driven by a single browser backend: the [`agent-browser`](https://agent-browser.dev) CLI.

> Sibling of [Build-iOS-Apps](https://github.com/lichunfei369/Build-iOS-Apps) — same packaging model, web edition.

## Why one browser backend

`agent-browser` launches **its own Chromium** and exposes everything an agent needs as compact, ref-addressed text (`@e1`, `@e2`, ~200–400 tokens vs thousands for a raw DOM dump): accessibility snapshots, clicks/forms, screenshots, network, React DevTools, profiler, and Core Web Vitals. We deliberately **do not** use claude-in-chrome here — running a second Chrome against the same dev server causes two conflicting sessions. Fallback for anything agent-browser can't do in a given version is **Playwright**.

## Components

### Diagnosis skills (new)
| Skill | Purpose |
|---|---|
| `web-debugger-agent` | Problem-driven deep-diagnosis **entry point**: discover/start dev server → open → reproduce → capture → triage to a specialist below → verify the fix |
| `react-render-performance` | Re-render recording, fiber tree, wasted renders, Core Web Vitals |
| `web-memory-leaks` | Heap snapshots, detached DOM, listener/closure leaks, growth diffing |
| `web-error-forensics` | Console / uncaught / rejection / network errors, **source-map stack reconstruction**, clustering & root cause |
| `web-network-inspector` | Slow/failed requests, waterfall, payloads, API timing |
| `web-a11y-audit` | Keyboard nav, ARIA, contrast, focus order (snapshot + injected `axe-core`) |
| `react-state-debugging` | Read Redux / Zustand / React Query state, trace re-render & stale-state causes |

### Build skills (migrated, reused not rewritten)
`frontend-app-builder` · `react-best-practices` · `shadcn-best-practices` · `stripe-best-practices` · `supabase-best-practices` · `frontend-testing-debugging` (browser routing rewritten to agent-browser).

### Entry command
`/webgo [build|debug|perf|memory|error|network|a11y|state] <free description>` — one Chinese-friendly dispatcher that routes a plain-language request to the right skill.

### Hook
`dev-server gut-check` (best-effort): when a dev server start is detected, suggest a quick agent-browser smoke check (loads, no console errors, key elements present).

## Prerequisite

```bash
npm i -g agent-browser      # or: brew install agent-browser
agent-browser install       # downloads Chrome on first use
agent-browser --version
```

`agent-browser` is a CLI, **not** an MCP server — so this plugin ships **no `.mcp.json`**. Skills invoke it through the shell. Exact sub-command flags vary by version; confirm with `agent-browser --help`.

## Install

```bash
claude plugin marketplace add lichunfei369/Build-Web-Apps
claude plugin install build-web-apps@build-web-apps-local
# restart / reload plugins to activate
```

## Browser-backend rule (enforced in every skill)

- **agent-browser** = the only interaction backend (navigate, snapshot, click, screenshot, network, React profiling, heap).
- **Playwright** = fallback when agent-browser is absent or a capability (e.g. console capture on some versions) is missing.
- **Screenshots** go to a path outside the repo; Read the image file to inspect it.

## Known risks (verify at runtime)

- **Console capture** and **deep heap diffing** depend on the installed agent-browser version's CDP/debugging surface — fall back to Playwright / raw CDP if missing.
- **a11y** and **state debugging** rely on injected scripts (`scripts/inject-axe.js`, `scripts/read-store.js`); treat as best-effort.

## License

MIT.
