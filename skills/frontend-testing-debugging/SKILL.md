---
name: frontend-testing-debugging
description: "Use when testing, debugging, or making targeted improvements to rendered frontend apps: local dev servers, UI regressions, interaction bugs, console errors, responsive layout, and visual QA. Drives the agent-browser CLI; falls back to Playwright with a recorded reason."
---

# Frontend Testing Debugging

> **Browser backend:** In this plugin the browser backend is the **`agent-browser` CLI** (https://agent-browser.dev) — a single Chromium it launches itself. Every "Browser" reference below means agent-browser. **Do not use claude-in-chrome here** (it would drive a second, conflicting Chrome instance). The Playwright fallback is unchanged.
>
> This is the **general QA / regression-verification** skill (run it to confirm a code change renders correctly). For *problem-driven* deep diagnosis use `web-debugger-agent`, which can call this skill to verify a fix.

## Invocation Contract

This skill should work from normal user prompts. Do not require the user to spell out browser routing, screenshots, report shape, or fallback policy.

Use this skill when the user asks to test, debug, QA, or make a targeted improvement to a rendered frontend surface (including phrasings like "use the web dev plugin", "frontend dev plugin", "Build Web Apps plugin", or "frontend testing/debugging skill").

Examples that should trigger this full workflow:

- `please make an improvement to the web dashboard transaction search area`
- `polish this dashboard and verify it in the browser`
- `debug this UI`
- `test this localhost app and fix the broken interaction`

From a brief prompt, infer the target surface from the repo, currently open app/browser URL, nearby files, or running dev server. If the target URL is unclear, inspect the repo scripts and running local ports before asking the user.

For any code change to a rendered frontend surface, do the validation loop by default:

1. Identify the target flow.
2. Choose the browser path below.
3. Make the smallest useful edit.
4. Validate the rendered behavior.
5. Reply with the QA final response report.

## Choose The Browser Path

First classify browser availability:

- **Available**: `agent-browser --version` succeeds. This is the default path (its Chromium is fetched automatically on first use).
- **Absent**: `agent-browser` is not on PATH. Auto-install it with `bash "$CLAUDE_PLUGIN_ROOT/scripts/ensure-agent-browser.sh"` (idempotent; downloads Chrome on first run). Only if that errors (no Node/npm, or npm permissions) fall back to regular Playwright and record `agent-browser not available`.
- **Invocation failed**: `agent-browser` is installed but `open`/`snapshot` fails (Chrome download blocked, sandbox, port). Treat this as a browser-path blocker, report the exact failure, and only then consider Playwright.

Do not launch claude-in-chrome, an external Chrome, or shell `open` first when agent-browser is available.

Only switch from a failed agent-browser invocation to Playwright if the user already allowed fallback or the task explicitly permits non-browser validation. In that case, report the exact agent-browser failure and the fallback decision.

## Target Flow

Before browser validation, define the target flow in one sentence:

`The flow under test is: [entry route] -> [user action or state] -> [expected rendered result].`

If the user asked for general smoke testing, use:

`The flow under test is: app loads -> first meaningful screen renders -> primary visible controls respond without runtime errors.`

## agent-browser Loop

Run browser checks through the `agent-browser` CLI (invoked via the shell). It keeps one persistent Chromium session: `open` starts it, later commands act on that session, `close` ends it. Keep using the same session unless you have a reason to restart it.

> Exact sub-command flags vary by version — confirm with `agent-browser --help` / `agent-browser <cmd> --help` rather than guessing. The names below are the documented core commands.

Required sequence:

1. Confirm readiness: `agent-browser --version` (and `agent-browser install` on first use).
2. Open the target: `agent-browser open <url>` (for React profiling work add `--enable react-devtools`).
3. Read structure: `agent-browser snapshot` returns the accessibility tree with stable refs (`@e1`, `@e2`, …) — ~200–400 tokens vs a full DOM dump. Select elements by ref.
4. Interact: `agent-browser click @e2`, form/typing commands for inputs (see `--help`). Prefer refs over pixel coordinates.
5. Capture proof: `agent-browser screenshot "${TMPDIR:-/tmp}/build-web-apps/<name>.png"` (reusable names like `before`/`after` — overwrite, don't accumulate), then **Read the image file** to inspect it visually.
6. After edits: re-`open` (or reload) the URL, then repeat the checks and the failing interaction.

For each UI-changing action, collect the cheapest proof that the next state is correct: fresh snapshot, visible text/state, URL change, focused control, toast, modal, screenshot, or console/network signal.

### Required Browser Checks

Run these checks before claiming the rendered app works:

1. **Page identity**: the snapshot / URL and title match the intended page.
2. **Not blank**: `agent-browser snapshot` contains meaningful app content, not an empty shell.
3. **No framework overlay**: the snapshot or screenshot does not show a Next.js, Vite, Webpack, or framework error overlay.
4. **Console health**: capture console output (agent-browser CDP/debugging mode; if a given version does not expose console, note it and use the Playwright branch to grab console). No relevant app errors, or each relevant error is explained.
5. **Network health**: agent-browser network inspection (`/network`) shows no failed / 4xx / 5xx requests for the flow.
6. **Screenshot evidence**: capture a screenshot to a file and Read it to support visual claims.
7. **Interaction proof**: at least one target-flow interaction is exercised and followed by a state check.

For visual work, add desktop plus one mobile-sized viewport when practical. For reference-driven work, keep a short mismatch ledger: reference evidence, rendered evidence, fix or intentional deviation.

> **Dialog safety:** native `alert`/`confirm`/`prompt` modals block automation. Avoid clicking elements that open them; if you must, warn the user first.

## Playwright Loop

Use this branch when agent-browser is not available, or when the user has allowed fallback after an agent-browser invocation failure (e.g. console capture is needed but the installed agent-browser version does not expose it).

Use this order:

1. Find scripts in `package.json`.
2. Start the app with the repo's package manager and keep the requested host exact.
3. Prefer the repo's e2e script if present.
4. Otherwise run `pnpm exec playwright test` or the package-manager equivalent when Playwright is configured.
5. If there is no project Playwright workflow, verify Playwright with `pnpm exec playwright --version`, then capture a screenshot with `pnpm exec playwright screenshot <url> /tmp/frontend-check.png`.
6. For deeper debugging, create a small temporary Playwright script outside committed source that opens the URL, captures console errors, screenshots, and runs the target interaction.
7. After edits, rerun the same command or script.

Do not install new browser dependencies unless the task requires it and the user has allowed dependency changes.

## Validation Checklist

- Keep the requested host exact.
- Verify controls update real UI state.
- Check the first viewport before scrolling, plus desktop and one mobile-sized viewport when practical.
- Look for clipping, overlap, unreadable text, wrapping, layout shift, missing assets, z-index issues, scroll traps, stale loading, and broken states.
- For reference-driven work, compare the rendered screenshot against the reference and keep a short mismatch ledger.
- A passing build is not enough when rendered validation was requested.

## QA Final Response Report

For any non-trivial rendered UI validation run, write the final response like a QA engineer verifying a code change. The response should make it easy for the user or PR reviewer to understand what changed, what was tested, what evidence proves it, and what remains untested.

Use this shape:

- **Summary**: one or two bullets explaining the user-visible change and whether QA passed.
- **Environment**: URL, viewport(s), browser availability classification (agent-browser / Playwright), and fallback reason if Playwright was used.
- **Changes Verified**: files or surfaces changed, plus the specific user-facing behavior expected.
- **Checks**: a pass/fail table for page identity, blank-page check, framework overlay check, console health, network health, screenshot evidence, and interaction proof.
- **Interaction Loop**: exact interaction path tested, including the control or workflow exercised and the observed state change.
- **Evidence**: describe the screenshot evidence in the QA sections, then place the actual screenshots together at the end of the response as consecutive images. Include as many screenshots as are useful to prove the relevant before, after, interaction, responsive, error, or fixed states.
- **Commands**: list the key `agent-browser` command sequence used, without dumping noisy logs.
- **Remaining Risk**: untested viewports, flows, browsers, data states, or known limitations.

If issues were found, lead with **Findings** before the summary. Each finding should include what the user sees, reproduction steps, screenshot/snapshot/console evidence, likely owner or file when known, and the fix made or remaining blocker.

Save screenshots under `${TMPDIR:-/tmp}/build-web-apps/` (outside the repo) and Read them so they can be referenced in chat. Reuse names to avoid pile-up; include multiple only when they verify distinct states or flows.

Do not interleave screenshots throughout the written report. Put a short **Screenshots** section at the very end, and make it a consecutive image gallery with one image per line. Add short labels only when they clarify the state, for example `Before`, `After`, `Filtered results`, `Empty state`, or `Mobile`.

Do not create separate HTML reports by default. Only create a standalone report file when the user explicitly asks for one, and write it outside the repo unless the user explicitly asks for committed artifacts.

Do not write reports, screenshots, traces, or temporary scripts into the repo unless the user explicitly asks for committed artifacts. After handoff, clean up temp screenshots: `bash "$CLAUDE_PLUGIN_ROOT/scripts/clean-shots.sh"` (or `rm -f "${TMPDIR:-/tmp}/build-web-apps/"*.png`).

## Related Skills

- Use `web-debugger-agent` for problem-driven deep diagnosis (it orchestrates this skill plus the performance / memory / error / network specialists).
- Use `frontend-app-builder` when the task is design creation, redesign, or fidelity to an accepted concept.
- Use `react-best-practices` after meaningful React/Next.js component edits.
- Do not generate images for ordinary debugging.

## Final Response

Use the QA final response report format above. Keep it concise, but include enough concrete evidence that a PR reviewer can trust the validation without rerunning it immediately.

If agent-browser was absent and Playwright was used, end by suggesting the user install agent-browser (`npm i -g agent-browser`) for a better frontend dev loop with accessibility snapshots, screenshots, network, and React/Web-Vitals inspection.
