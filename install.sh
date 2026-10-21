#!/bin/bash
# Installs (or updates) SnapUI. Run in Terminal:
#   curl -fsSL https://sprouthouse.github.io/snapui-updates/install.sh | bash
# Downloads the latest SnapUI, checks it's intact and signed, puts it in Applications
# (or ~/Applications without admin rights) and opens it. After this, SnapUI updates itself.
set -euo pipefail
URL="https://sprouthouse.github.io/snapui-updates"
DEST="${SNAPUI_DIR:-/Applications}"

major=$(sw_vers -productVersion | cut -d. -f1)
if [ "$major" -lt 15 ]; then
  echo "SnapUI needs macOS 15 or later (this Mac has $(sw_vers -productVersion))."; exit 1
fi

# The newest version listed in the update feed.
ZIP=$(curl -fsSL "$URL/appcast.xml" | grep -o 'url="[^"]*\.zip"' | head -1 | cut -d'"' -f2)
[ -n "$ZIP" ] || { echo "Couldn't read the update feed. Check your internet connection."; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo "Downloading SnapUI…"
curl -fsSL "$ZIP" -o "$TMP/SnapUI.zip"
ditto -x -k "$TMP/SnapUI.zip" "$TMP"
codesign --verify --deep --strict "$TMP/SnapUI.app" || { echo "The download looks damaged. Try again."; exit 1; }

# Applications needs an admin; otherwise the Applications folder in your home folder.
if [ ! -w "$DEST" ]; then DEST="$HOME/Applications"; mkdir -p "$DEST"; fi
osascript -e 'tell application id "com.sprouthouse.snap" to quit' >/dev/null 2>&1 || true
pkill -x SnapUI 2>/dev/null || true
rm -rf "$DEST/SnapUI.app"
ditto "$TMP/SnapUI.app" "$DEST/SnapUI.app"
echo "SnapUI is installed in $DEST. Opening it…"
[ -n "${SNAPUI_NO_OPEN:-}" ] || open "$DEST/SnapUI.app"
