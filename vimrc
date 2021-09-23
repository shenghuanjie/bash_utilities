set backspace=indent,eol,start
set whichwrap+=<,>,[,]

" set colorscheme to 256 colors
 set t_Co=256

syntax enable
" set background=dark

let g:solarized_termcolors=256
" colorscheme solarized
" colorscheme default
" ** this is the default colorscheme and the one you seem to like **
" colorscheme elflord
colorscheme delek
set smartindent
set tabstop=4
set shiftwidth=4
set ai
set expandtab
set ruler
set number
set mouse=a

" for command mode
nnoremap <S-Tab> <<
" for insert mode
inoremap <S-Tab> <C-d>

autocmd BufRead,BufNewFile Snakefile set syntax=python
