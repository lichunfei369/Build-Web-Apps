#!/usr/bin/env bash
# build-web-apps · ensure the agent-browser CLI + its browser engine are ready.
#
# Idempotent and safe to re-run — installs only what is missing. The diagnosis
# skills call this automatically on first browser use, so the plugin works on a
# fresh machine with ZERO manual setup. You can also run it yourself to
# pre-install:  bash scripts/ensure-agent-browser.sh
set -uo pipefail

# 1) The CLI ----------------------------------------------------------------
if command -v agent-browser >/dev/null 2>&1; then
  echo "build-web-apps: agent-browser present ($(agent-browser --version 2>/dev/null))."
else
  if ! command -v npm >/dev/null 2>&1; then
    echo "build-web-apps: ERROR Node.js/npm not found. Install Node >= 18 from https://nodejs.org, then re-run." >&2
    exit 1
  fi
  echo "build-web-apps: installing agent-browser globally (npm i -g agent-browser)…"
  if ! npm install -g agent-browser >/dev/null 2>&1; then
    echo "build-web-apps: ERROR 'npm i -g agent-browser' failed. Try 'sudo npm i -g agent-browser', or set a user-writable npm prefix, then re-run." >&2
    exit 1
  fi
  if ! command -v agent-browser >/dev/null 2>&1; then
    echo "build-web-apps: ERROR installed but 'agent-browser' is not on PATH. Add \"\$(npm prefix -g)/bin\" to your PATH." >&2
    exit 1
  fi
  echo "build-web-apps: agent-browser installed ($(agent-browser --version 2>/dev/null))."
fi

# 2) The browser engine -----------------------------------------------------
#    Chromium downloads on first launch (a few minutes, once). Warm it up now
#    so the first real task isn't slow or surprising.
if agent-browser open about:blank >/dev/null 2>&1; then
  agent-browser close >/dev/null 2>&1 || true
  echo "build-web-apps: agent-browser + browser engine ready. ✅"
else
  echo "build-web-apps: agent-browser installed; the browser engine will download on first real use." >&2
fi
