# configs

My configuration files.

---

## shell

Aliases and helpers for bash and zsh, sourced live from this repo.

```sh
cd shell && ./install.sh
```

`xc` — extended copy: puts a file's contents or piped input on the system clipboard.

---

## vim

`.vimrc` plus the atoll colorscheme, and vim-go config when `go` is installed.

```sh
cd vim && ./install.sh
```

See [vim/README.md](vim/README.md) for options.

---

## tmux

tmux config with the atoll theme.

```sh
cp tmux/tmux.conf ~/.config/tmux/tmux.conf
tmux source ~/.config/tmux/tmux.conf
```

In tmux press `<prefix> + I` (ctrl + space, then capital I).

---

## claude

Claude Code settings and a statusline showing directory, branch, model, and context remaining.

```sh
cp claude/settings.json ~/.claude/settings.json
cp claude/statusline-command.sh ~/.claude/statusline-command.sh
```

Keep the statusline at `~/.claude/statusline-command.sh` — that's the path `settings.json` invokes.

---

## git

Aliases for branch listing, pretty log graphs, and pruning stale branches.

```sh
cp git/.gitconfig ~/.gitconfig
```

Edit the `[user]` name and email first. `git alias` lists every alias.

---

## vscode

The atoll theme as VS Code settings overrides — teal-forward, low-contrast dark.

```
Command Palette → Preferences: Open User Settings (JSON)
Merge in vscode/atoll-vscode-settings.json
```
