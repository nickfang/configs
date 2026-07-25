" Copy this file to: ~/
syntax on
set number
set tabstop=3        " Set the width of a tab character to 3 columns
set shiftwidth=3     " Set the number of spaces used for (auto)indentation to 3
set expandtab        " Use spaces instead of tabs when pressing the <Tab> key
set softtabstop=3    " Set the number of columns to use for a <Tab> in insert mode
set laststatus=2
set statusline=%<%F%=%l/%L/,%c
set termguicolors    " required for the exact hex colors (truecolor)
set background=dark
colorscheme atoll    " copy atoll.vim palette file to ~/.vim/colors/

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
   silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
call plug#end()

let g:go_fmt_command = "goimports"
let g:go_fmr_autosave = 1
