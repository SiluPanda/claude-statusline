#!/bin/bash
set -e

SCRIPT_URL="https://raw.githubusercontent.com/SiluPanda/claude-statusline/main/statusline.sh"
CLAUDE_DIR="$HOME/.claude"
SCRIPT_PATH="$CLAUDE_DIR/statusline.sh"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  echo "  macOS:        brew install jq"
  echo "  Debian/Ubuntu: sudo apt install jq"
  exit 1
fi

# Create ~/.claude if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Download the statusline script
echo "Downloading statusline.sh to $SCRIPT_PATH..."
curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Update settings.json
if [ -f "$SETTINGS_PATH" ]; then
  # Merge statusline config into existing settings
  tmp=$(mktemp)
  jq '. + {"statusline": {"command": "~/.claude/statusline.sh"}}' "$SETTINGS_PATH" > "$tmp" && mv "$tmp" "$SETTINGS_PATH"
  echo "Updated $SETTINGS_PATH with statusline config."
else
  echo '{"statusline": {"command": "~/.claude/statusline.sh"}}' | jq . > "$SETTINGS_PATH"
  echo "Created $SETTINGS_PATH with statusline config."
fi

echo "Done! Restart Claude Code to see the statusline."
