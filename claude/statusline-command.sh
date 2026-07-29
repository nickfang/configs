#!/usr/bin/env bash
# Claude Code statusLine: shows current git branch + context remaining.

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
echo $cwd
dir=$(basename "$cwd")
echo $dir

model=$(echo "$input" | jq -r '.model.display_name // empty')

echo $model

branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

out=""
[ -n "$dir" ]       && out="$dir"
[ -n "$branch" ]    && out="${out:+$out | }$branch"
[ -n "$model" ]     && out="${out:+$out | }$model"
[ -n "$remaining" ] && out="${out:+$out | }$remaining% left"
printf "%s" "$out"
