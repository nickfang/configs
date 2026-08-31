# shell/common.sh — shell-agnostic config, sourced by both bash and zsh.
# Keep everything here POSIX-ish so it works in both shells.

# Scripts versioned in this repo (xc, ...).
PATH="$HOME/workspace/configs/shell/bin:$PATH"

alias lsa='ls -lah'
alias hl='rg --passthru'
alias slowcat='pv -l -L 10 -q'

# Print " - (branch)" if inside a git repo, nothing otherwise (used in the prompt).
git_branch_name() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [ -n "$branch" ] && echo " - ($branch)"
}
export PROMPT_DIRTRIM=2
