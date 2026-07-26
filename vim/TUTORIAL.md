# Building the vim installer — a type-it-yourself tutorial

This walks you through creating the whole vim setup from scratch: splitting
`.vimrc`, writing `go.vim`, building a shared `lib/install-common.sh`, and a thin
`vim/install.sh` on top of it. **Type each piece yourself** and read the notes —
the goal is that you understand *why* every line is there.

By the end you'll have:

```
configs/
  lib/
    install-common.sh   # shared install helpers (link / append_once / pick_rc)
  vim/
    .vimrc              # base editor config (no Go specifics)
    go.vim              # Go/vim-go config, loaded conditionally
    atoll.vim           # colorscheme (already exists)
    install.sh          # thin, standalone installer that sources the lib
    README.md           # user-facing docs
```

---

## Part 0 — The mental model

Five design choices drive everything. Understand these first; the code just
serves them.

**1. Symlink, not copy.** `~/.vimrc` will be a *symbolic link* to the repo's
`.vimrc`. Editing either edits the same bytes, so there's nothing to "copy back"
and no drift. (A `cp` gives you two files that quietly diverge — which is exactly
what bit you when a `mv ~/.vimrc` orphaned the home copy.)

**2. Conditional Go config.** vim-go is useless — and its binary installer
errors — on a machine without the Go toolchain. So the Go-specific lines live in
a separate `go.vim`, and `.vimrc` loads it *only if it exists*. The installer
creates that file (a symlink) only when `go` is on PATH. One `.vimrc`, works
everywhere.

**3. vim-plug has exactly one `plug#begin()`…`plug#end()` block.** Every `Plug`
command must run *between* those calls. That's why we `source ~/.vim/go.vim` from
*inside* the block — `go.vim` contains a `Plug` line that has to execute there.

**4. Standalone modules + a shared lib.** Each config (`vim/`, `shell/`, `tmux/`)
installs independently: update one, run just its installer. So `vim/install.sh`
must **not** depend on a *peer* module (e.g. it can't read `shell/`'s files —
that'd make "install vim" secretly require "install shell"). But the mechanical
plumbing — symlinking, editing rc files — is identical across modules, so it
lives in a repo-level **`lib/install-common.sh`** that each installer sources.
That's *shared infrastructure*, not a peer dependency: the repo (hence `lib/`) is
always checked out together, so running `vim/install.sh` alone still works.

**5. `--shell` selects the rc file.** vim-go needs `$GOPATH/bin` on your PATH.
That's a per-shell edit (`~/.bashrc` vs `~/.zshrc`), which maps to OS
(Linux→bash, Mac→zsh). Rather than guess, the installer takes `--shell bash|zsh`
(default: detect from `$SHELL`). This is the flag your future orchestrator will
pass to every module.

Keep these five in mind. Every file below exists to serve one of them.

---

## Part 1 — Split `.vimrc` into base + Go

Open `.vimrc` and reduce it to **base config only** — the vim-go plugin line and
the `g:go_*` settings move out to `go.vim` in Part 2:

```vim
" Symlinked to ~/.vimrc by install.sh (do not copy — edits are versioned).
syntax on
set number
set tabstop=3        " width of a literal tab
set shiftwidth=3     " spaces per indent level
set expandtab        " the Tab key inserts spaces
set softtabstop=3    " how many columns a Tab feels like in insert mode
set laststatus=2     " always show the status line
set statusline=%<%F%=%l/%L/,%c
set termguicolors    " needed for exact hex colors (truecolor terminals)
set background=dark
colorscheme atoll    " requires ~/.vim/colors/atoll.vim (installer links it)

" --- vim-plug bootstrap: fetch plug.vim on first run if it's missing ---
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
   silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
   autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" --- plugins ---
call plug#begin()
" Load Go tooling only when install.sh has linked go.vim (i.e. `go` is present).
if filereadable(expand('~/.vim/go.vim'))
   source ~/.vim/go.vim
endif
call plug#end()
```

What matters here:

- **`if filereadable(expand('~/.vim/go.vim'))`** — `expand()` turns `~` into your
  real home path; `filereadable()` is true only if that file exists. This is the
  *runtime* half of the conditional. The *install-time* half is the installer
  deciding whether to create the link.
- **`source` sits inside `plug#begin`/`plug#end`** — per mental-model point 3, so
  the `Plug` line in `go.vim` runs in the valid window.

> **Sidebar — `has('nvim') ? … : …`.** Vim's ternary. The bootstrap picks the
> right plugin directory for Neovim vs. Vim. On Vim, `data_dir` is `~/.vim`.

---

## Part 2 — Create `go.vim`

New file, `vim/go.vim`. Everything Go-specific, nothing else:

```vim
" Go tooling. Sourced by .vimrc ONLY when `go` is installed (installer links
" this file into ~/.vim/go.vim). Safe to omit entirely on non-Go machines.
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
let g:go_fmt_command = "goimports"   " format AND fix imports on save
let g:go_fmt_autosave = 1            " run it automatically on :w
```

Notes:

- **`Plug 'fatih/vim-go'`** — `fatih`, not `faith` (author is Fatih Arslan). The
  `{ 'do': ':GoUpdateBinaries' }` hook runs after install/update to fetch vim-go's
  helper binaries.
- **`g:go_fmt_command = "goimports"`** — `goimports` is `gofmt` plus automatic
  import management. Use `"gofmt"` if you'd rather it never touch imports.
- **`g:go_fmt_autosave = 1`** — the original file misspelled this
  `go_fmr_autosave`, which silently did nothing (Vim doesn't error on an unknown
  `g:` variable). This is the corrected name.

---

## Part 3 — Build the shared `lib/install-common.sh`

Create `configs/lib/install-common.sh`. This is the reusable plumbing every
module's installer will source — the symlink and rc-editing mechanics live here
once, so each `install.sh` just *declares* what to do.

Type it in three functions.

### 3.1 — The header

```bash
# lib/install-common.sh — shared helpers for the per-module install scripts.
#
# SOURCED, not executed:   . "$DIR/../lib/install-common.sh"
# Defines functions only. The executable installer owns `set -euo pipefail`;
# a sourced file shouldn't set shell options on the caller.
```

No shebang, no `set -euo pipefail` — this file is *sourced* into another script,
never run on its own. Setting shell options here would silently change the
behavior of whatever sources it.

### 3.2 — `link` (symlink with backup)

```bash
# link SRC DEST — symlink DEST -> SRC, backing up a pre-existing real file first.
link() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"

    # Already our symlink pointing at the same target? Nothing to do.
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        echo "ok:   $dest already links to repo"
        return
    fi

    # Something else is in the way (a real file, or a link elsewhere): back it up.
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local bak="$dest.bak.$(date +%s)"
        mv "$dest" "$bak"
        echo "bak:  moved $dest -> $bak"
    fi

    ln -s "$src" "$dest"
    echo "done: linked $dest -> $src"
}
```

Walk through it:

- **`[ -L "$dest" ]`** — recall `[` *is a command* (`test`); `-L` asks "is this a
  symlink?". Combined with the `readlink -f` comparison, this says "is `dest`
  already a link resolving to the same file as `src`?" If so, we're done — **this
  is what makes re-runs idempotent and stops backup spam.**
- **`[ -e "$dest" ] || [ -L "$dest" ]`** — `-e` is "exists (following symlinks)";
  we also check `-L` explicitly so a *broken* symlink (target gone, so `-e` is
  false) still gets cleaned up.
- **`mv "$dest" "$dest.bak.$(date +%s)"`** — the backup. `date +%s` is a Unix
  timestamp for a unique name. **The load-bearing safety step**: a naked
  `ln -sf` would delete a hand-edited `~/.vimrc` with no recovery.

### 3.3 — `append_once` (idempotent rc edit)

```bash
# append_once RC MARKER LINE — add LINE to RC once, keyed by MARKER.
append_once() {
    local rc="$1" marker="$2" line="$3"
    if [ ! -e "$rc" ]; then
        echo "skip: $rc does not exist"
        return
    fi
    if grep -qF "$marker" "$rc"; then
        echo "ok:   $rc already has marker"
        return
    fi
    {
        echo ""
        echo "$marker"
        echo "$line"
    } >> "$rc"
    echo "done: appended to $rc"
}
```

- **`grep -qF "$marker" "$rc"`** — `-q` quiet (exit status only), `-F` fixed
  string (so `$` in the marker isn't a regex). If the marker line is already
  present, do nothing → **idempotent**: running the installer ten times adds the
  line once. This is the same anti-duplicate trick `shell/install.sh` uses.
- **`{ …; } >> "$rc"`** — group the echoes and append their combined output in one
  redirect.

### 3.4 — `pick_rc` (the mac/linux selector)

```bash
# pick_rc [bash|zsh] — echo the rc path for a shell; default from $SHELL.
pick_rc() {
    local shell="${1:-$(basename "${SHELL:-bash}")}"
    case "$shell" in
        zsh) echo "$HOME/.zshrc" ;;
        *)   echo "$HOME/.bashrc" ;;
    esac
}
```

This is the *only* OS-aware piece, and it's tiny: map a shell name to its rc file,
defaulting to whatever `$SHELL` says. `${1:-...}` uses the argument if given, else
the default. Linux→bash→`~/.bashrc`, Mac→zsh→`~/.zshrc`.

> **Why a lib at all?** `link` and `append_once` are needed by *every* module
> (they all symlink dotfiles and some edit rc files). Putting them here means
> `vim/install.sh`, and later `shell/`/`tmux/`, share one implementation and one
> flag contract — which is what will let the future orchestrator stay a dumb
> dispatcher. Sourcing this lib is *shared infrastructure*, not a dependency on
> another feature module, so it doesn't violate the standalone rule.

---

## Part 4 — Build the thin `vim/install.sh`

Now the installer itself. Because the mechanics live in the lib, this file is
mostly *declarations*. Create `vim/install.sh`.

### 4.1 — Header, strict mode, source the lib

```bash
#!/usr/bin/env bash
#
# install.sh — install the vim config (symlinks + plugins). Standalone.
#
# Usage: ./install.sh [--shell bash|zsh] [--no-path]
#   --shell NAME   which rc gets $GOPATH/bin on PATH (default: detect from $SHELL)
#   --no-path      symlinks + plugins only; touch no rc file
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/../lib/install-common.sh"
```

- **`#!/usr/bin/env bash`** — shebang via `env` (note: `usr`, not `user` — that
  typo gives "cannot execute: required file not found").
- **`set -euo pipefail`** — `-e` exit on error, `-u` error on unset variable,
  `-o pipefail` a pipeline fails if any stage does. Lives *here*, in the
  executable, not in the sourced lib.
- **`DIR=…`** — the "where am I?" idiom: `BASH_SOURCE[0]` is this script,
  `dirname` strips to its directory, `cd … && pwd` makes it absolute. So the
  script works no matter where you invoke it from.
- **`. "$DIR/../lib/install-common.sh"`** — source the lib (`.` is `source`).
  `link`, `append_once`, `pick_rc` are now available.

### 4.2 — Parse arguments

```bash
shell_arg=""
no_path=0
while [ $# -gt 0 ]; do
    case "$1" in
        --shell)   shell_arg="$2"; shift 2 ;;
        --no-path) no_path=1;      shift ;;
        -h|--help) grep '^#' "$0" | cut -c3- ; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done
rc="$(pick_rc "$shell_arg")"
```

A standard arg loop. `shift 2` consumes both `--shell` and its value; `shift`
consumes a lone flag. `pick_rc "$shell_arg"` resolves to `~/.bashrc` or
`~/.zshrc` (empty `shell_arg` → detect from `$SHELL`).

### 4.3 — The declarations

```bash
# --- always-on config ---
link "$DIR/.vimrc"    "$HOME/.vimrc"
link "$DIR/atoll.vim" "$HOME/.vim/colors/atoll.vim"

# --- Go config, only when the toolchain is present ---
if command -v go >/dev/null 2>&1; then
    link "$DIR/go.vim" "$HOME/.vim/go.vim"
    if [ "$no_path" -eq 0 ]; then
        append_once "$rc" '# configs/vim: $GOPATH/bin on PATH' \
            'export PATH="$PATH:${GOPATH:-$HOME/go}/bin"'
    fi
else
    echo "skip: go not found — Go config left out"
    if [ -L "$HOME/.vim/go.vim" ]; then
        rm "$HOME/.vim/go.vim"
        echo "done: removed stale ~/.vim/go.vim"
    fi
fi
```

The whole installer's logic is now readable at a glance:

- **`command -v go >/dev/null 2>&1`** — "is `go` on PATH?" (`command -v` prints
  the path and exits 0 if found; output redirected away since we only want the
  exit code). This is the install-time half of the conditional split.
- **`append_once "$rc" '<marker>' '<export line>'`** — puts `$GOPATH/bin` on the
  chosen shell's PATH. Note the single quotes: the `$(go env GOPATH)`-free form
  `${GOPATH:-$HOME/go}` is written *literally* into the rc file so it re-resolves
  each shell start (and doesn't spawn `go` on every prompt).
- **`else` branch** removes a stale `~/.vim/go.vim` link, so `.vimrc`'s
  `filereadable()` guard correctly loads no Go config on a machine without Go.

### 4.4 — Install plugins, best-effort

```bash
# --- plugins (best-effort) ---
if command -v vim >/dev/null 2>&1; then
    if vim +PlugInstall +qall >/dev/null 2>&1; then
        echo "done: plugins installed (:PlugInstall)"
    else
        echo "warn: headless :PlugInstall failed — run :PlugInstall inside vim"
    fi
fi

echo "All set. Open a new shell, then launch vim to verify."
```

- **`vim +PlugInstall +qall`** — launch Vim, run `:PlugInstall`, then quit. The
  `+cmd` form runs Ex commands at startup.
- **Best-effort.** vim-go's `{ 'do': ':GoUpdateBinaries' }` hook can try to fetch
  helper binaries pinned to `@master`, which occasionally `500`s against
  `sum.golang.org`. That shouldn't fail the whole install, so we swallow it and
  print a `warn:`. (The README documents the `@latest` fix.)

Finally, make it executable:

```bash
chmod +x install.sh
```

> **Note — vim-go finds its tools even without the PATH edit.** vim-go appends
> `$GOPATH/bin` to `$PATH` *inside Vim* when it runs a tool (see its
> `autoload/go/path.vim` `CheckBinPath`). So format-on-save works even under
> `--no-path`. The rc edit is for using `goimports`/`gopls`/`dlv` from your
> *shell* and other programs — a broader, persistent need.

---

## Part 5 — Write the README

Document the finished setup for future-you: the file→link table, `./install.sh`
with `--shell`/`--no-path`, the Go-conditional behavior, and troubleshooting —
especially the `goimports@latest` fix for the `sum.golang.org 500`. A complete
`README.md` already sits in this directory; read it as the reference for what good
docs here look like.

---

## Part 6 — Run it and verify

```bash
cd ~/workspace/configs/vim
./install.sh                 # --shell defaults to your $SHELL (bash on Linux)
```

Expect a `bak:` line for the existing real `~/.vim/colors/atoll.vim`, and `done:`
links for `.vimrc`, `atoll.vim`, `go.vim`, plus the PATH line added to `~/.bashrc`.

Checks:

1. **Links are real:** `ls -l ~/.vimrc ~/.vim/colors/atoll.vim ~/.vim/go.vim` —
   each shows `-> …/configs/vim/…`.
2. **Idempotent:** run `./install.sh` again — every line `ok:`, no new `.bak`
   files, no duplicate PATH line (the marker guard).
3. **Shell targeting:** `./install.sh --shell zsh` → the PATH line lands in
   `~/.zshrc`. `./install.sh --no-path` → no rc file touched.
4. **PATH works:** `source ~/.bashrc && command -v goimports` → resolves under
   `$GOPATH/bin`.
5. **Format-on-save:** open a `.go` file, add a stray indent and a
   missing-but-used import, `:w` — it reformats and fixes imports. Proves `go.vim`
   loaded *and* the `go_fmt_autosave` typo is fixed.
6. **The conditional gates:** `mv ~/.vim/go.vim{,.off}`, reopen Vim — no Go
   config, no error (the `filereadable()` guard). Restore by re-running the
   installer.

---

## What you learned

- **Symlinks vs. copies**, and why a dotfiles repo prefers links (no drift, a
  stray `mv` can't orphan your config).
- **`[`/`test` and exit codes** — `-L`, `-e`, `-f`, and how `if`/`&&` branch on
  exit status, not on any printed value.
- **Idempotency patterns** — the `-L` + `readlink` "already correct?" check and
  the `grep -qF` marker guard for editing rc files without duplication.
- **Sourced lib vs. executable script** — why `set -euo pipefail` and the shebang
  live in `install.sh` but not in `lib/install-common.sh`, and how `.`/`source`
  pulls the helpers in.
- **Standalone modules + shared infrastructure** — the difference between
  depending on a *peer module* (bad: couples installs) and sourcing a repo-level
  *lib* (fine: shared plumbing), and why that keeps "update one config, run one
  installer" true.
- **Two-sided conditional config** — an install-time `command -v go` check paired
  with a runtime `filereadable()` guard, so one `.vimrc` adapts to any machine.
- **`--shell` / `pick_rc`** — mapping OS→shell→rc in one small function, the same
  flag every module and the future orchestrator will speak.
- **Vim scripting** — `+PlugInstall +qall`, `filereadable`/`expand`, and why
  `source` must sit inside vim-plug's single `begin`/`end` block.
