#!/usr/bin/env bash
#
# install.sh — wire the versioned shell config into your shell rc files.
#
# Idempotent: it appends a single `source` line to ~/.bashrc and/or ~/.zshrc
# only if that line isn't already present. The actual config stays in this
# repo (common.sh / bash.sh / zsh.sh) and is sourced live — nothing is copied.
#
# Usage:
#   ./install.sh            # set up whichever rc files exist (~/.bashrc, ~/.zshrc)
#
set -euo pipefail

# Directory this script lives in, resolved to an absolute path.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add a "source <file>" line to <rcfile> if it's not already there.
link_rc() {
    local rcfile="$1" target="$2"
    local line="[ -f \"$target\" ] && . \"$target\""
    # Match either ~/...  or /home/you/... form of the path when checking.
    local marker="shell/$(basename "$target")"

    if [ ! -e "$rcfile" ]; then
        echo "skip: $rcfile does not exist"
        return
    fi
    if grep -qF "$marker" "$rcfile"; then
        echo "ok:   $rcfile already sources $marker"
        return
    fi
    {
        echo ""
        echo "# personal shell config (versioned in $DIR)"
        echo "$line"
    } >> "$rcfile"
    echo "done: added source line to $rcfile"
}

link_rc "$HOME/.bashrc" "$DIR/bash.sh"
link_rc "$HOME/.zshrc"  "$DIR/zsh.sh"

echo "Open a new shell (or 'source' your rc file) to pick up the changes."
