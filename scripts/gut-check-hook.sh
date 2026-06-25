#!/usr/bin/env bash
# build-web-apps · best-effort dev-server gut-check nudge.
#
# Wired as a PostToolUse(Bash) hook. Reads the tool payload (JSON) from stdin;
# if the Bash command that just ran looks like it started a web dev server,
# emits an additionalContext suggestion to run a quick agent-browser smoke
# check. It NEVER blocks and NEVER fails the tool — worst case it stays silent.
#
# Caveat: a foreground dev server blocks until it exits, so PostToolUse only
# fires usefully for backgrounded servers. This is intentionally lightweight.
set -uo pipefail
payload="$(cat 2>/dev/null || true)"

if printf '%s' "$payload" | grep -Eiq '(npm|pnpm|yarn|bun)([[:space:]]+run)?[[:space:]]+dev|next[[:space:]]+dev|vite([[:space:]]|"|'\''|$)|react-scripts[[:space:]]+start|astro[[:space:]]+dev|remix[[:space:]]+(vite:)?dev|ng[[:space:]]+serve|nuxt[[:space:]]+dev'; then
  msg="A web dev server appears to have started. Before continuing, consider a quick agent-browser gut-check: open the URL, confirm the page loads, has no console errors, and renders its key elements (web-debugger-agent / frontend-testing-debugging). Do NOT use claude-in-chrome in this plugin."
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$msg"
fi
exit 0
