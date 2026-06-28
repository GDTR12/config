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

" 显示相对行号，方便使用 5j / 3k 这种移动方式
set relativenumber

" 高亮当前光标所在行
set cursorline

" 高亮查找
set hlsearch
nnoremap <leader>h :nohlsearch<CR>

" 状态栏总是显示
set laststatus=2

" 如果搜索词中包含大写字母，则自动区分大小写
" 例如 /foo 匹配 foo/Foo/FOO，/Foo 只匹配 Foo
set smartcase

" 选中多行后，按 < 左缩进，缩进后保持选区
vnoremap < <gv
vnoremap > >gv

" Space + s + v：重新加载 ~/.vimrc
nnoremap <leader>sv ~/.vimrc<CR>

" 根据简单语法自动缩进
" 对 C/C++ 这种花括号语言比较有用
set smartindent

" 按 Tab 时插入空格，而不是真正的 Tab 字符
set expandtab

" 使用 >> 或 << 缩进时，每次缩进 2 个空格
set shiftwidth=2
