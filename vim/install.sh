#!/usr/bin/env bash
#
# install.sh - link .vimrc using symlinks
#

set -euo pipefail

# Absolute path to the directory this script lives in.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$DIR/../lib/common.sh"

link "$DIR/.vimrc" "$HOME/.vimrc"
link "$DIR/atoll.vim" "$HOME/.vim/colors/atoll.vim"

# If Go exists
if command -v go >/dev/null 2>&1; then
   link "$DIR/go.vim" "$HOME/.vim/go.vim"

   marker="# configs/vim: \$GOPATH/bin on PATH"
   if [ -f "$HOME/.bashrc" ] && ! grep -qF "$marker" "$HOME/.bashrc"; then
      {
         echo ""
         echo "$marker"
         echo 'export PATH="$PATH:$(go env GOPATH)/bin"'
      } >> "$HOME/.bashrc"
      echo "done: added \$GOPATH/bin to PATH in ~/.bashrc"
   else
      echo "ok: ~/.bashrc PATH already set (or no ~/.bashrc)"
   fi
else
   echo "skip: go not found - Go config and PATH left out"
   if [ -L "$HOME/.vim/go.vim" ]; then
      rm "$HOME/.vim/go.vim"
      echo "done: removed stale ~/.vim/go.vim"
   fi
fi

# Install/refresh plugins.
#
# Check features, not just the binary: Debian's base install ships only
# vim-tiny, which is built without +eval and +syntax. The config needs both,
# and a tiny build fails every `syntax on` / `let` / `call plug#begin()` with
# E319 on first launch.
if ! command -v vim >/dev/null 2>&1; then
   echo "warn: vim not found - config linked, but install vim to use it"
   echo "      Debian/Ubuntu:  sudo apt install vim"
elif ! vim --version | grep -q '+eval'; then
   echo "warn: this vim lacks +eval/+syntax (vim-tiny?) - the config will error on startup"
   echo "      Debian/Ubuntu:  sudo apt install vim"
else
   if vim +PlugInstall +qall >/dev/null; then
      echo "done: plugins installed (:PlugInstall)"
   else
      echo "warn: headless :PlugInstall failed - run :PlugInstall inside vim"
   fi
fi

echo "All done.  Open vim to verify."
