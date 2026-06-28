set clipboard=

" 使用系统剪切板的专用快捷键
let mapleader = " "

" Space + y：复制到系统剪切板
nnoremap <leader>y "+y
vnoremap <leader>y "+y

" Space + Y：复制当前行到系统剪切板
nnoremap <leader>Y "+yy

" Space + p：从系统剪切板粘贴
nnoremap <leader>p "+p
vnoremap <leader>p "+p

" Space + P：从系统剪切板粘贴到光标前
nnoremap <leader>P "+P
vnoremap <leader>P "+P

let skip_defaults_vim=1
syntax on
set nu!
set autoindent
