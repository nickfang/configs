# Building the vim installer — a type-it-yourself tutorial

This walks you through creating the whole setup from scratch: splitting `.vimrc`,
writing `go.vim`, and building `install.sh` line by line. Type each piece
yourself and read the notes — the goal is that you understand *why* every line is
there, not just that it works.

By the end you'll have:

```
vim/
  .vimrc        # base editor config (no Go specifics)
  go.vim        # Go/vim-go config, loaded conditionally
  atoll.vim     # colorscheme (already exists)
  install.sh    # the idempotent symlink installer
  README.md     # user-facing docs
```

---

## Part 0 — The mental model

Three design choices drive everything. Understand these first.

**1. Symlink, not copy.** `~/.vimrc` will be a *symbolic link* pointing at the
repo's `.vimrc`. Editing either one edits the same bytes. This is why there's
nothing to "copy back" — the home file and the repo file are literally the same
file. A plain `cp` would give you two independent copies that drift apart.

**2. Conditional Go config.** The vim-go plugin is useless (and its binary
installer errors) on a machine without the Go toolchain. So the Go-specific lines
live in a separate `go.vim`, and `.vimrc` loads it *only if that file exists*. The
installer creates the `go.vim` link only when `go` is on PATH. Result: one
`.vimrc` that works everywhere.

**3. vim-plug has exactly one `plug#begin()`…`plug#end()` block.** Every `Plug`
command must run *between* those two calls. That constraint is the reason we
`source ~/.vim/go.vim` from *inside* the block rather than tacking it on the end —
`go.vim` contains a `Plug` line, and it has to execute in that window.

Keep these three in mind; each file below exists to serve one of them.

---

## Part 1 — Split `.vimrc` into base + Go

Right now `.vimrc` mixes base editor settings with vim-go settings. Separate them.

Open `.vimrc` and make it look like this — **base config only**:

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

What changed and why:

- **The vim-go `Plug` line and the `g:go_*` settings are gone** — they move to
  `go.vim` in Part 2.
- **`if filereadable(expand('~/.vim/go.vim'))`** — `expand()` turns `~` into your
  real home path; `filereadable()` returns true only if that file exists. This is
  the runtime half of the conditional. The install-time half is the installer
  choosing whether to create the link.
- **`source` sits inside `plug#begin`/`plug#end`** — per Part 0 point 3, so the
  `Plug` line in `go.vim` runs in the valid window.

> **Sidebar — `has('nvim') ? … : …`.** Vim's ternary. The bootstrap picks the
> right plugin directory for Neovim vs. Vim. You're on Vim, so `data_dir` is
> `~/.vim`. Left as-is for portability.

---

## Part 2 — Create `go.vim`

New file, `go.vim`. This is everything Go-specific, and nothing else:

```vim
" Go tooling. Sourced by .vimrc ONLY when `go` is installed (installer links
" this file into ~/.vim/go.vim). Safe to omit entirely on non-Go machines.
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
let g:go_fmt_command = "goimports"   " format AND fix imports on save
let g:go_fmt_autosave = 1            " run it automatically on :w
```

Notes:

- **`Plug 'fatih/vim-go'`** — the plugin. `fatih` (not `faith`); the author is
  Fatih Arslan. The `{ 'do': ':GoUpdateBinaries' }` hook runs after the plugin
  installs/updates and tries to fetch vim-go's helper binaries.
- **`g:go_fmt_command = "goimports"`** — `goimports` is `gofmt` plus automatic
  import management (adds what you use, removes what you don't). Set to `"gofmt"`
  if you'd rather it never touch imports.
- **`g:go_fmt_autosave = 1`** — the original file had this misspelled
  `go_fmr_autosave`, which silently did nothing (Vim doesn't error on unknown
  `g:` variables — same "typo = no-op" trap as undefined refs elsewhere). This is
  the corrected name.

---

## Part 3 — Build `install.sh` in stages

We'll assemble the installer piece by piece. Type each stage, read the notes, and
by the end you'll have the whole script. Create `install.sh` and start with the
header.

### Stage 3.1 — Header and strict mode

```bash
#!/usr/bin/env bash
#
# install.sh — link the versioned vim config into place.
#
# Symlinks (never copies) so edits stay under version control. Idempotent:
# re-running is safe and never stacks backups for links it already owns.
#
set -euo pipefail
```

- **`#!/usr/bin/env bash`** — the shebang. `env` finds `bash` on `PATH` rather
  than hardcoding `/bin/bash`. Matches the repo's other scripts.
- **`set -euo pipefail`** — the three-part safety belt:
  - `-e` — exit immediately if any command fails (non-zero exit).
  - `-u` — error on use of an *unset* variable (catches typos like `$destt`).
  - `-o pipefail` — a pipeline fails if *any* stage fails, not just the last one.

  Without these, a script barrels on after errors and can do real damage. With
  them, it stops at the first sign of trouble.

### Stage 3.2 — Find the repo directory

```bash
# Absolute path to the directory this script lives in (the repo's vim/ dir).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

This is the idiom for "where am I?" so the script works no matter where you run it
from. Read it inside-out:

- **`${BASH_SOURCE[0]}`** — the path to *this script* (more reliable than `$0`).
- **`dirname …`** — strips the filename, leaving the directory.
- **`cd … && pwd`** — `cd` there and print the *absolute* path. So even if you ran
  `./install.sh` or `../vim/install.sh`, `DIR` ends up fully-qualified.

`$(…)` is command substitution — it runs the command and substitutes its output.

### Stage 3.3 — The `link` helper (the heart of it)

This is where the "back up real files but not our own symlinks" logic lives.

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

- **`local src="$1" dest="$2"`** — name the two positional arguments. `local`
  keeps them scoped to the function.
- **`mkdir -p "$(dirname "$dest")"`** — ensure the parent dir exists (e.g.
  `~/.vim/colors/`). `-p` means "make parents, and don't error if it already
  exists".
- **`[ -L "$dest" ]`** — recall `[` *is a command* (`test`); `-L` asks "is this a
  symlink?". Combined with the `readlink -f` comparison, this says "is `dest`
  already a link resolving to the same file as `src`?" If so, we're done —
  **this is what makes re-runs idempotent and stops backup spam.**
- **`[ -e "$dest" ] || [ -L "$dest" ]`** — `-e` is "exists (following symlinks)";
  we also check `-L` explicitly so a *broken* symlink (whose target is gone, so
  `-e` is false) still gets cleaned up. If either is true, a real file/other link
  is in the way → move it aside.
- **`mv "$dest" "$dest.bak.$(date +%s)"`** — the backup. `date +%s` is a Unix
  timestamp, giving each backup a unique name. **This is the load-bearing safety
  step**: a naked `ln -sf` would delete your hand-edited `~/.vimrc` with no
  recovery.
- **`ln -s "$src" "$dest"`** — finally create the symlink.

> **Sidebar — why `[ -L ]` before `[ -e ]`?** The order of the two `if` blocks
> matters. We check "is it already *our* link?" first and bail early. Only if
> it's *not* already correct do we reach the backup-and-replace path. Flip them
> and you'd back up your own symlink on every run.

### Stage 3.4 — Link the always-on files

```bash
# Always-on config.
link "$DIR/.vimrc"    "$HOME/.vimrc"
link "$DIR/atoll.vim" "$HOME/.vim/colors/atoll.vim"
```

Two calls to the helper. `atoll.vim` currently exists in `~/.vim/colors/` as a
*real* file, so the first run will print a `bak:` line for it — expected.

### Stage 3.5 — Conditional Go setup

```bash
# Go config only when the toolchain is present.
if command -v go >/dev/null 2>&1; then
    link "$DIR/go.vim" "$HOME/.vim/go.vim"

    # Put $GOPATH/bin on PATH so vim-go finds goimports/gopls.
    marker="# configs/vim: \$GOPATH/bin on PATH"
    if [ -f "$HOME/.bashrc" ] && ! grep -qF "$marker" "$HOME/.bashrc"; then
        {
            echo ""
            echo "$marker"
            echo 'export PATH="$PATH:$(go env GOPATH)/bin"'
        } >> "$HOME/.bashrc"
        echo "done: added \$GOPATH/bin to PATH in ~/.bashrc"
    else
        echo "ok:   ~/.bashrc PATH already set (or no ~/.bashrc)"
    fi
else
    echo "skip: go not found — Go config and PATH left out"
    # Drop a stale link so the vimrc's filereadable() guard stays honest.
    if [ -L "$HOME/.vim/go.vim" ]; then
        rm "$HOME/.vim/go.vim"
        echo "done: removed stale ~/.vim/go.vim"
    fi
fi
```

The important ideas:

- **`command -v go >/dev/null 2>&1`** — "is `go` on PATH?" `command -v` prints the
  path if found and exits 0, else exits 1. We redirect its output to `/dev/null`
  (both stdout `>` and stderr `2>&1`) because we only care about the exit code,
  which is what `if` branches on. **This one check drives the whole conditional
  split** — it's the install-time decision that pairs with the `filereadable()`
  runtime check in `.vimrc`.
- **The `marker` + `grep -qF` guard** — idempotency for the PATH edit. `grep -qF`
  looks for the literal marker line (`-q` quiet, `-F` fixed-string so `$` isn't a
  regex). We append the export block *only if the marker isn't already there*, so
  running the installer ten times adds the line once. This mirrors how
  `shell/install.sh` avoids duplicate `source` lines.
- **`{ …; } >> file`** — group several `echo`s and append their combined output to
  `~/.bashrc` in one redirect.
- **Deferred evaluation** — we write the *literal* string
  `export PATH="$PATH:$(go env GOPATH)/bin"` (single-quoted, so `$(…)` is **not**
  expanded now). It gets evaluated fresh each time a new shell sources `.bashrc`.
  That's more robust than baking in today's absolute path.
- **The `else` branch** cleans up a stale `~/.vim/go.vim` link. Imagine you run
  this on a Go machine, then later on one without Go (or after uninstalling Go):
  removing the link makes `.vimrc`'s `filereadable()` check correctly return
  false, so no Go config loads.

### Stage 3.6 — Install plugins headlessly

```bash
# Install/refresh plugins without opening an interactive vim. Best-effort:
# vim-go's post-update hook can hit a transient sum.golang.org error.
if command -v vim >/dev/null 2>&1; then
    if vim +PlugInstall +qall >/dev/null 2>&1; then
        echo "done: plugins installed (:PlugInstall)"
    else
        echo "warn: headless :PlugInstall failed — run :PlugInstall inside vim"
    fi
fi

echo "All set. Open a new shell, then launch vim to verify."
```

- **`vim +PlugInstall +qall`** — launch Vim, run the `:PlugInstall` command, then
  `:qall` (quit all). The `+cmd` form runs Ex commands at startup — a normal way
  to script Vim non-interactively.
- **Best-effort by design.** vim-go's `{ 'do': ':GoUpdateBinaries' }` hook may try
  to fetch helper binaries pinned to `@master`, which can `500` against
  `sum.golang.org`. That failure shouldn't fail the whole install, so we catch it
  and print a `warn:` telling you to finish inside Vim (or use the `@latest` trick
  from the README). Your binaries are likely already installed anyway.

Now make it executable:

```bash
chmod +x install.sh
```

---

## Part 4 — Write the README

Create `README.md` documenting the finished setup for a future you (or anyone
else): the file→link table, `./install.sh`, the Go-conditional behavior, and the
troubleshooting entries — especially the `goimports@latest` fix for the
`sum.golang.org 500`. (A complete `README.md` is already in this directory; read
it as the reference for what good docs for this cover.)

---

## Part 5 — Run it and verify

```bash
cd ~/workspace/configs/vim
./install.sh
```

Expect: a `bak:` line for the existing real `~/.vim/colors/atoll.vim`, `done:`
links for `.vimrc`, `atoll.vim`, and `go.vim`, and the PATH line added to
`~/.bashrc`.

Checks:

1. **Links are real:** `ls -l ~/.vimrc ~/.vim/colors/atoll.vim ~/.vim/go.vim` —
   each should show `-> …/configs/vim/…`.
2. **Idempotent:** run `./install.sh` again — every line should now be `ok:`, and
   no new `.bak` files appear.
3. **PATH:** `source ~/.bashrc && command -v goimports` — resolves under
   `$GOPATH/bin`.
4. **Format-on-save:** open a `.go` file, add a stray indent and a
   missing-but-used import, `:w` — it reformats and fixes imports. This proves
   `go.vim` loaded *and* the `go_fmt_autosave` typo is fixed.
5. **The conditional actually gates:** `mv ~/.vim/go.vim{,.off}`, reopen Vim — no
   Go config, no error (the `filereadable()` guard did its job). Restore by
   re-running `./install.sh`.

---

## What you learned

- **Symlinks vs. copies**, and why a dotfiles repo prefers links (no drift, and a
  stray `mv` can't orphan your config).
- **`[`/`test` and exit codes** — `-L`, `-e`, `-f`, and how `if` branches on exit
  status, not on any printed value.
- **Idempotency patterns** — the `-L` + `readlink` "already correct?" check, and
  the `grep -qF` marker guard for editing rc files without duplicating lines.
- **`set -euo pipefail`** and the `BASH_SOURCE`/`dirname`/`pwd` "where am I" idiom.
- **Deferred evaluation** — writing a literal `$(…)` into `.bashrc` so it
  re-resolves per shell.
- **Two-sided conditional config** — an install-time `command -v go` check paired
  with a runtime `filereadable()` guard, so one `.vimrc` adapts to any machine.
- **Vim scripting** — `+PlugInstall +qall`, `filereadable`/`expand`, and why the
  `source` must sit inside vim-plug's single `begin`/`end` block.
