#!/usr/bin/env bash
#
# install.sh - link the tmux config into $HOME and set up tpm
#
# Layout: ~/.tmux.conf (config) + ~/.tmux/plugins/ (tpm and its plugins).
# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf, so this is the path
# that actually wins. The theme lives beside the plugins at ~/.tmux/ and is
# pulled in by the `source-file` line in tmux.conf.
#

set -euo pipefail

# Absolute path to the directory this script lives in.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TPM_DIR="$HOME/.tmux/plugins/tpm"

. "$DIR/../lib/common.sh"

if ! command -v tmux >/dev/null 2>&1; then
   echo "warn: tmux not found - config will be linked but won't run until tmux is installed"
fi

link "$DIR/tmux.conf" "$HOME/.tmux.conf"
link "$DIR/atoll.tmux.conf" "$HOME/.tmux/atoll.tmux.conf"

# tpm - tmux.conf ends with `run '~/.tmux/plugins/tpm/tpm'`, so it must live there.
if [ -d "$TPM_DIR/.git" ]; then
   echo "ok:  tpm already installed at $TPM_DIR"
elif command -v git >/dev/null 2>&1; then
   git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" >/dev/null 2>&1
   echo "done: cloned tpm into $TPM_DIR"
else
   echo "skip: git not found - install tpm manually into $TPM_DIR"
fi

# Install the plugins declared in tmux.conf.
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
   if "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1; then
      echo "done: plugins installed"
   else
      echo "warn: headless plugin install failed - press <prefix> + I inside tmux"
   fi
fi

# Pick up the new config in any running server.
if command -v tmux >/dev/null 2>&1 && tmux has-session >/dev/null 2>&1; then
   tmux source-file "$HOME/.tmux.conf"
   echo "done: reloaded config in the running tmux server"
fi

echo "All done.  Prefix is ctrl + space."
