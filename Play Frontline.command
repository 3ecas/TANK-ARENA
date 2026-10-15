#!/usr/bin/env bash
# Double-click this file in Finder: it builds Frontline (first time / after updates) and opens the game window.
cd "$(dirname "$0")"

if ./scripts/build_app.sh; then
    open "dist/Frontline.app"
    echo ""
    echo "Frontline is starting. You can close this Terminal window."
else
    echo ""
    echo "Build failed - see the messages above."
    read -r -p "Press Enter to close..."
fi
