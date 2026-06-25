#!/usr/bin/env bash
# build-web-apps · SessionStart check (fast, no install).
#
# If agent-browser (the plugin's browser backend) isn't installed yet, nudge
# once that it will be auto-installed on first browser use — or can be
# pre-installed now. Never installs or downloads anything here; SessionStart
# must stay instant.
set -uo pipefail
if ! command -v agent-browser >/dev/null 2>&1; then
  msg="build-web-apps: agent-browser (this plugin's browser backend) isn't installed yet. It will be installed automatically the first time a browser skill runs. To pre-install now, run: \$CLAUDE_PLUGIN_ROOT/scripts/ensure-agent-browser.sh"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg"
fi
exit 0
