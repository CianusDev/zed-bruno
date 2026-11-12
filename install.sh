#!/bin/sh
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
command -v bru >/dev/null || echo "⚠ bru absent : npm i -g @usebruno/cli"
mkdir -p "$HOME/.local/bin"
chmod +x "$DIR/bin/bruno-zed"
ln -sf "$DIR/bin/bruno-zed" "$HOME/.local/bin/bruno-zed"
echo "✓ bruno-zed -> $HOME/.local/bin/bruno-zed"
echo "Zed : ctrl-shift-p → 'zed: install dev extension' → $DIR"
