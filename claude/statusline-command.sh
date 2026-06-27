#!/usr/bin/env bash
# Claude Code statusLine: shows current git branch + context remaining.

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

out=""
[ -n "$branch" ]    && out="$branch"
if [ -n "$remaining" ]; then
  [ -n "$out" ] && out="$out | "
  out="${out}${remaining}% left"
fi
printf "%s" "$out"
