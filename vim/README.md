# vim config

Personal Vim setup, versioned so it can be re-applied on any machine with one
command. The install **symlinks** these files into place (it never copies), so
editing `~/.vimrc` *is* editing the repo copy — no drift, nothing to "copy back".

## Layout

| file          | linked to                    | purpose                                   |
|---------------|------------------------------|-------------------------------------------|
| `.vimrc`      | `~/.vimrc`                    | base editor config + plugin bootstrap     |
| `atoll.vim`   | `~/.vim/colors/atoll.vim`    | the `atoll` colorscheme (required)        |
| `go.vim`      | `~/.vim/go.vim`             | vim-go config — linked **only if `go` is installed** |
| `install.sh`  | —                            | the installer                             |
| `notes.md`    | —                            | hotkey cheatsheet                         |

## Install

```bash
cd ~/workspace/configs/vim
./install.sh
```

The script is **idempotent** — run it as often as you like. It:

1. Symlinks `.vimrc` and `atoll.vim` into place. Any pre-existing *real* file is
   moved to `<file>.bak.<timestamp>` first; a symlink it already owns is left alone.
2. **If `go` is on your PATH:** symlinks `go.vim`, and appends `$GOPATH/bin` to
   `~/.bashrc` (behind a marker, so re-runs don't duplicate the line). If `go`
   is absent, Go config is skipped and any stale `~/.vim/go.vim` link is removed.
3. Installs plugins headlessly (`vim +PlugInstall +qall`), best-effort.

After it finishes, open a **new shell** so the PATH change takes effect.

## How the Go split works

`.vimrc` is machine-agnostic. At the bottom it does:

```vim
call plug#begin()
if filereadable(expand('~/.vim/go.vim'))
   source ~/.vim/go.vim      " Plug 'fatih/vim-go' + gofmt settings live here
endif
call plug#end()
```

So Go support is active **only when `~/.vim/go.vim` exists** — which the installer
creates only when `go` is installed. On a machine without Go, Vim loads cleanly
with no vim-go and no errors.

## Verify

Open a `.go` file, add a stray indent and a missing-but-available import, then
`:w`. It should reformat and fix imports on save (that's `goimports` +
`g:go_fmt_autosave`).

## Troubleshooting

**`:GoInstallBinaries` / vim-go fails with a `sum.golang.org … 500` error.**
vim-go's updater pins some tools to `@master`, whose fresh pseudo-versions can
500 against the checksum DB. Install the binaries yourself at a tagged release
instead:

```bash
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/gopls@latest
```

They land in `$GOPATH/bin` (`go env GOPATH`), which the installer already put on
your PATH.

**Format-on-save does nothing.** Confirm the tools are found:
`command -v goimports gopls`. If missing, `source ~/.bashrc` (or open a new
shell) and re-check. Inside Vim, `:GoInfo` and `:messages` report what's wrong.

**`Cannot find color scheme 'atoll'`.** `atoll.vim` didn't get linked into
`~/.vim/colors/`. Re-run `./install.sh`.
