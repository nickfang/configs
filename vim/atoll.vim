" ============================================================================
" atoll.vim  —  a teal-forward, low-contrast dark colorscheme for Vim
" ============================================================================
" Built around the signature teal #318787. Easy on the eyes: tinted-dark
" background, soft off-white text, dimmed-but-readable comments, brightened
" blue and red compared to stock Vim.
"
" INSTALL
"   1. Save this file to:   ~/.vim/colors/atoll.vim
"   2. Add to your ~/.vimrc:
"          set termguicolors      " required for the exact hex colors
"          set background=dark
"          colorscheme atoll
"
" Truecolor is required for the exact colors. Your tmux already enables it
" (xterm*:Tc). cterm fallbacks are provided for 256-color terminals.
"
" PALETTE
"   bg        #0f1716   background (deep teal-tinted dark)
"   bg_dim    #0a1110   darker fill / inactive
"   bg_alt    #16201f   cursorline / popups / folds
"   bg_sel    #264039   visual selection
"   bg_hl     #1b2826   subtle highlight / split borders
"   fg        #cbd8d5   default text
"   fg_dim    #8aa39e   operators / punctuation
"   fg_faint  #5f7370   line numbers / special keys
"   comment   #708b87   comments
"   teal_deep #318787   signature (UI: statusline, cursor, active borders)
"   teal      #3f9e9e   keywords / control flow
"   teal_brt  #56c1b4   functions
"   cyan      #6cb6c4   types / classes / builtins
"   blue      #7fb3d9   parameters / special identifiers
"   green     #9cc882   strings
"   orange    #e0a87e   numbers / constants
"   coral     #e0867d   errors / important
"   periwinkle #a0a6da  booleans / constants / macros
"   yellow    #d8c27a   warnings / search
" ============================================================================

set background=dark
highlight clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "atoll"

" ---- Editor UI ------------------------------------------------------------
hi Normal        guifg=#cbd8d5 guibg=#0f1716 ctermfg=252 ctermbg=233
hi NormalFloat   guifg=#cbd8d5 guibg=#16201f ctermfg=252 ctermbg=234
hi NonText       guifg=#313f3c guibg=NONE    ctermfg=238 ctermbg=NONE
hi EndOfBuffer   guifg=#1d2826 guibg=NONE    ctermfg=235 ctermbg=NONE
hi Conceal       guifg=#5f7370 guibg=NONE    ctermfg=59  ctermbg=NONE
hi Cursor        guifg=#0f1716 guibg=#56c1b4 ctermfg=233 ctermbg=80
hi lCursor       guifg=#0f1716 guibg=#56c1b4 ctermfg=233 ctermbg=80
hi CursorLine    guibg=#16201f cterm=NONE    ctermbg=234
hi CursorColumn  guibg=#16201f ctermbg=234
hi ColorColumn   guibg=#141d1b ctermbg=234
hi CursorLineNr  guifg=#7fb8b0 guibg=#16201f gui=bold ctermfg=80 ctermbg=234 cterm=bold
hi LineNr        guifg=#4f6a66 guibg=#0f1716 ctermfg=59  ctermbg=233
hi SignColumn    guifg=#54706b guibg=#0f1716 ctermfg=59  ctermbg=233
hi FoldColumn    guifg=#54706b guibg=#0f1716 ctermfg=59  ctermbg=233
hi Folded        guifg=#8aa39e guibg=#16201f ctermfg=109 ctermbg=234
hi VertSplit     guifg=#1b2826 guibg=#0f1716 ctermfg=235 ctermbg=233
hi WinSeparator  guifg=#1b2826 guibg=#0f1716 ctermfg=235 ctermbg=233
hi MatchParen    guifg=#56c1b4 guibg=#264039 gui=bold ctermfg=80 ctermbg=23 cterm=bold
hi SpecialKey    guifg=#54706b guibg=NONE    ctermfg=59  ctermbg=NONE
hi Whitespace    guifg=#25322f guibg=NONE    ctermfg=237 ctermbg=NONE

" ---- Popups / tabs / status ----------------------------------------------
hi Pmenu         guifg=#cbd8d5 guibg=#16201f ctermfg=252 ctermbg=234
hi PmenuSel      guifg=#0f1716 guibg=#318787 gui=bold ctermfg=233 ctermbg=30 cterm=bold
hi PmenuSbar     guibg=#1b2826 ctermbg=235
hi PmenuThumb    guibg=#54706b ctermbg=59
hi TabLine       guifg=#8aa39e guibg=#16201f ctermfg=109 ctermbg=234
hi TabLineFill   guibg=#0f1716 ctermbg=233
hi TabLineSel    guifg=#0f1716 guibg=#56c1b4 gui=bold ctermfg=233 ctermbg=80 cterm=bold
hi StatusLine    guifg=#0f1716 guibg=#318787 gui=bold ctermfg=233 ctermbg=30 cterm=bold
hi StatusLineNC  guifg=#8aa39e guibg=#16201f ctermfg=109 ctermbg=234

" ---- Search / selection / messages ---------------------------------------
hi WildMenu      guifg=#0f1716 guibg=#56c1b4 ctermfg=233 ctermbg=80
hi Visual        guibg=#264039 ctermbg=23
hi VisualNOS     guibg=#1b2826 ctermbg=235
hi Search        guifg=#0f1716 guibg=#d8c27a ctermfg=233 ctermbg=186
hi IncSearch     guifg=#0f1716 guibg=#e0a87e ctermfg=233 ctermbg=180
hi CurSearch     guifg=#0f1716 guibg=#e0a87e ctermfg=233 ctermbg=180
hi Title         guifg=#56c1b4 gui=bold ctermfg=80 cterm=bold
hi Directory     guifg=#7fb3d9 ctermfg=110
hi ModeMsg       guifg=#9cc882 ctermfg=150
hi MoreMsg       guifg=#56c1b4 ctermfg=80
hi Question      guifg=#9cc882 ctermfg=150
hi WarningMsg    guifg=#e0a87e ctermfg=180
hi ErrorMsg      guifg=#e0867d ctermfg=174
hi Error         guifg=#e0867d guibg=NONE ctermfg=174 ctermbg=NONE
hi Todo          guifg=#0f1716 guibg=#d8c27a gui=bold ctermfg=233 ctermbg=186 cterm=bold

" ---- Syntax ---------------------------------------------------------------
hi Comment       guifg=#708b87 gui=italic ctermfg=66 cterm=italic
hi Constant      guifg=#e0a87e ctermfg=180
hi String        guifg=#9cc882 ctermfg=150
hi Character     guifg=#9cc882 ctermfg=150
hi Number        guifg=#e0a87e ctermfg=180
hi Boolean       guifg=#a0a6da ctermfg=146
hi Float         guifg=#e0a87e ctermfg=180

hi Identifier    guifg=#cbd8d5 ctermfg=252
hi Function      guifg=#56c1b4 ctermfg=80

hi Statement     guifg=#3f9e9e gui=NONE ctermfg=73 cterm=NONE
hi Conditional   guifg=#3f9e9e ctermfg=73
hi Repeat        guifg=#3f9e9e ctermfg=73
hi Label         guifg=#3f9e9e ctermfg=73
hi Operator      guifg=#8aa39e ctermfg=109
hi Keyword       guifg=#3f9e9e ctermfg=73
hi Exception     guifg=#3f9e9e ctermfg=73

hi PreProc       guifg=#a0a6da ctermfg=146
hi Include       guifg=#3f9e9e ctermfg=73
hi Define        guifg=#a0a6da ctermfg=146
hi Macro         guifg=#a0a6da ctermfg=146
hi PreCondit     guifg=#a0a6da ctermfg=146

hi Type          guifg=#6cb6c4 ctermfg=73
hi StorageClass  guifg=#6cb6c4 ctermfg=73
hi Structure     guifg=#6cb6c4 ctermfg=73
hi Typedef       guifg=#6cb6c4 ctermfg=73

hi Special       guifg=#7fb3d9 ctermfg=110
hi SpecialChar   guifg=#e0a87e ctermfg=180
hi Tag           guifg=#3f9e9e ctermfg=73
hi Delimiter     guifg=#8aa39e ctermfg=109
hi SpecialComment guifg=#8aa39e gui=italic ctermfg=109 cterm=italic
hi Debug         guifg=#e0867d ctermfg=174
hi Underlined    guifg=#7fb3d9 gui=underline ctermfg=110 cterm=underline
hi Ignore        guifg=#54706b ctermfg=59

" ---- Diff -----------------------------------------------------------------
hi DiffAdd       guifg=NONE    guibg=#16291f ctermbg=22
hi DiffChange    guifg=NONE    guibg=#16252b ctermbg=23
hi DiffDelete    guifg=#e0867d guibg=#2b1a19 ctermfg=174 ctermbg=52
hi DiffText      guifg=NONE    guibg=#214336 gui=bold ctermbg=23 cterm=bold
hi diffAdded     guifg=#9cc882 ctermfg=150
hi diffRemoved   guifg=#e0867d ctermfg=174
hi diffChanged   guifg=#d8c27a ctermfg=186

" ---- Spell ----------------------------------------------------------------
hi SpellBad      guisp=#e0867d gui=undercurl cterm=undercurl
hi SpellCap      guisp=#d8c27a gui=undercurl cterm=undercurl
hi SpellRare     guisp=#a0a6da gui=undercurl cterm=undercurl
hi SpellLocal    guisp=#6cb6c4 gui=undercurl cterm=undercurl

" ---- Common plugin signs (git gutter, etc.) -------------------------------
hi GitGutterAdd          guifg=#9cc882 ctermfg=150
hi GitGutterChange       guifg=#d8c27a ctermfg=186
hi GitGutterDelete       guifg=#e0867d ctermfg=174
hi GitGutterChangeDelete guifg=#e0a87e ctermfg=180

" ---- Notes ----------------------------------------------------------------
" - Comments are italic by default. If your terminal/font renders italics
"   poorly, change the two `gui=italic`/`cterm=italic` lines to `gui=NONE`.
" - To make keywords use the exact base #318787 instead of the lifted
"   #3f9e9e, find/replace #3f9e9e -> #318787 (it will read slightly dimmer).
