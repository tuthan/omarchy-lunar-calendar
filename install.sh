#!/usr/bin/env bash
set -e

PLUGIN_ID="omarchy-lunar-calendar"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
REPO_URL="git@github.com:tuthan/omarchy-lunar-calendar.git"

echo "=================================================="
echo " 🌕 Omarchy Lunar Calendar Plugin Setup / Installer "
echo "=================================================="

# Copy files if running outside plugin folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$SCRIPT_DIR" != "$PLUGIN_DIR" ]; then
    echo "🔗 Registering the GitHub plugin source..."
    omarchy plugin add "$REPO_URL" --enable --yes 2>/dev/null || true
    echo "📦 Copying plugin files to $PLUGIN_DIR..."
    mkdir -p "$PLUGIN_DIR"
    cp -r "$SCRIPT_DIR"/* "$PLUGIN_DIR/"
fi

echo "📎 Source repository: $REPO_URL"

# Enable plugin in Omarchy
echo "🔌 Enabling plugin '$PLUGIN_ID'..."
omarchy plugin enable "$PLUGIN_ID" 2>/dev/null || true

# Ask user interactively for bar placement
echo ""
echo "📍 Where would you like to place the Lunar Calendar widget on your top bar?"
echo "   [1] Center section — After Clock (Recommended)"
echo "   [2] Right section — Before Tray"
echo "   [3] Right section — End of bar"
echo "   [4] Skip bar placement (Panel access only)"
echo ""
read -p "Enter choice [1-4] (default: 1): " CHOICE

case "$CHOICE" in
    2)
        echo "📍 Placing widget in Right section (before tray)..."
        omarchy bar put "$PLUGIN_ID" --before omarchy.tray 2>/dev/null || echo "⚠️  Could not update the bar while the shell is stopped."
        ;;
    3)
        echo "📍 Placing widget at end of Right section..."
        omarchy bar put "$PLUGIN_ID" --section right 2>/dev/null || echo "⚠️  Could not update the bar while the shell is stopped."
        ;;
    4)
        echo "⏩ Skipping bar widget placement."
        ;;
    *)
        echo "📍 Placing widget in Center section (after clock)..."
        omarchy bar put "$PLUGIN_ID" --after omarchy.clock 2>/dev/null || echo "⚠️  Could not update the bar while the shell is stopped."
        ;;
esac

echo "🔄 Restarting Omarchy shell..."
omarchy restart shell 2>&1 || true

echo ""
echo "✨ Installation complete! Lunar Calendar plugin is ready."
