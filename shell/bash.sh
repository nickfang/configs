# shell/bash.sh — personal bash config. Source this from the stock ~/.bashrc:
#     [ -f ~/workspace/configs/shell/bash.sh ] && . ~/workspace/configs/shell/bash.sh
# It overrides the default prompt; the rest of ~/.bashrc stays stock.

# Shared, cross-shell helpers (git_branch_name, etc.)
[ -f ~/workspace/configs/shell/common.sh ] && . ~/workspace/configs/shell/common.sh

# Prompt:  user@host:dir - (branch)$   (branch in yellow when color is available)
case "$TERM" in
    xterm-color|*-256color) __color=yes ;;
    *)                      __color= ;;
esac

if [ "$__color" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(git_branch_name)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(git_branch_name)\$ '
fi
unset __color

# Keep the xterm/rxvt window title as user@host: dir
case "$TERM" in
    xterm*|rxvt*) PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1" ;;
esac
