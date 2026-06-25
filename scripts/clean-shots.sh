#!/usr/bin/env bash
# build-web-apps · clean up screenshots / temp images written by this plugin.
#
# Safe by design: only ever removes image files directly under
# "${TMPDIR:-/tmp}/build-web-apps" — it never touches your repo or anything else.
# Run it any time to reclaim space, or let each diagnosis skill call it on finish.
set -uo pipefail
dir="${TMPDIR:-/tmp}/build-web-apps"
if [ -d "$dir" ]; then
  n=$(find "$dir" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webm' \) 2>/dev/null | wc -l | tr -d ' ')
  find "$dir" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webm' \) -delete 2>/dev/null || true
  rmdir "$dir" 2>/dev/null || true
  echo "build-web-apps: removed ${n} screenshot(s) from ${dir}"
else
  echo "build-web-apps: nothing to clean (${dir} not present)"
fi
