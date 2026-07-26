" Go tooling.  
" Sourced by .vimrc when 'go' is installed
" sourced from:  ~/.vim/go.vim
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
let g:go_fmt_command = "goimports" " format and fix imports on save
let g:go_fmt_autosave = 1 " run it automatically on :w
