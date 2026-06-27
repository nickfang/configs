# atoll — palette reference

A teal-forward, low-contrast dark scheme built around the signature teal
`#318787`. Designed to be easy on the eyes: deep tinted-dark background, soft
text, dimmed-but-readable comments, and a brightened blue/red versus stock Vim.

## Backgrounds

| Role | Hex | Notes |
|------|-----|-------|
| Background | `#0f1716` | Main editor / tmux bg. Deep, with a slight teal tint, not pure black. |
| Darker fill | `#0a1110` | Inactive panes, deepest layer. |
| Cursorline / popups | `#16201f` | Current line, completion menu, folds. |
| Selection | `#264039` | Visual mode, copy-mode selection. |
| Subtle highlight | `#1b2826` | Color column, split borders. |

## Text

| Role | Hex | Notes |
|------|-----|-------|
| Default text | `#cbd8d5` | Soft teal-tinted off-white — bulk of your code. Not harsh white. |
| Operators / punctuation | `#8aa39e` | Calm, low-noise. |
| Line numbers / faint | `#5f7370` | Recedes into the background. |
| Comments | `#708b87` | Readable but dimmed so they don't distract. Brighter than Vim's navy. |

## Accents (teal is the star)

| Role | Hex | Used for |
|------|-----|----------|
| Teal · signature | `#318787` | Your base color. UI chrome: status bar, cursor, active pane borders. |
| Keyword | `#3f9e9e` | `if` `for` `def` `return` `import`. Lifted slightly from `#318787` so small text reads clearly. |
| Function | `#56c1b4` | Function names and calls — the brightest teal, easy to scan for. |
| Type | `#6cb6c4` | Types, classes, builtins. |
| Parameter · blue | `#7fb3d9` | Function params, special identifiers. The "fixed" bright blue. |
| String | `#9cc882` | Soft green — cool, classic, readable. |
| Number | `#e0a87e` | Numbers and constants. |
| Boolean · periwinkle | `#a0a6da` | `True`/`False`/`None`, macros, preprocessor. Soft blue-violet, no pink. |
| Error · red | `#e0867d` | Errors, removed diff lines. Lifted to a soft coral. |
| Warning | `#d8c27a` | Warnings, search highlight. |

## Hue spread

Teal dominates (keywords, functions, types, UI), with green (strings), blue
(params), orange (numbers), periwinkle (booleans), coral (errors), and yellow
(warnings) as supporting hues. All desaturated for low contrast.

## Tweaks

- **Keywords too bright?** Replace `#3f9e9e` with your exact `#318787` in
  `atoll.vim` — it will read a touch dimmer.
- **Comments too dim / too loud?** Nudge `#708b87` lighter (`#7e9995`) or
  darker (`#62807b`).
- **Background still too bright/dark?** It's `#0f1716`. Lighter step `#13201e`,
  darker step `#0a1110`.
- **Dislike italic comments?** Set the comment `gui=italic`/`cterm=italic` to
  `NONE` in `atoll.vim`.

## Files

- `atoll.vim` → `~/.vim/colors/atoll.vim` (then `colorscheme atoll`)
- `atoll.tmux.conf` → source it or paste into `~/.tmux.conf`
