# configs
My configuration files.

## vim
```
cd vim && ./install.sh
```
Symlinks `.vimrc` + the `atoll` colorscheme into place (and vim-go config when
`go` is installed). See [vim/README.md](vim/README.md) for options, and
[vim/TUTORIAL.md](vim/TUTORIAL.md) to build the installer from scratch.

## tmux.conf
```
cp tmux/tmux.conf ~/.config/tmux/tmux.conf
tmux source ~/.config/tmux/tmux.conf
```
In tmux press <prefix> + I (ctrl + space then capital I)
