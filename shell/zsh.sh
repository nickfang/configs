# shell/zsh.sh — personal zsh config (macOS). Source this from ~/.zshrc:
#     [ -f ~/workspace/configs/shell/zsh.sh ] && . ~/workspace/configs/shell/zsh.sh

# Shared, cross-shell helpers (git_branch_name, etc.)
[ -f ~/workspace/configs/shell/common.sh ] && . ~/workspace/configs/shell/common.sh

# Enable command substitution in the prompt.
setopt prompt_subst

# Prompt:  <last 2 path components> - (branch) >
# No space before $(git_branch_name): the function supplies its own leading space.
prompt='%2/$(git_branch_name) > '
