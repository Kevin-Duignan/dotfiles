" ============================================
" ~/.vimrc — Global Vim Configuration
" ============================================
" Shared across macOS, WSL, Git Bash, and MSYS2.
" On MSYS2/Git Bash a minimal plugin set is loaded
" (Vim's file I/O is slow on Windows POSIX emulation).
" All other platforms get the full plugin stack.
" ============================================

" --- Environment detection ---
" $MSYSTEM is set by MSYS2 and Git Bash (e.g. UCRT64, MINGW64, MSYS)
let s:is_windows_posix = !empty($MSYSTEM)

" ============================================
" Core Settings (all platforms)
" ============================================
syntax on
filetype plugin indent on
set nocompatible

let mapleader=" "

" UI
set number
set relativenumber
set mouse=a
set ruler
set showmatch
set splitbelow
set splitright
set lazyredraw
set visualbell
set laststatus=2

" Clipboard
set clipboard^=unnamed,unnamedplus

" Indentation
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4

" Search
set incsearch
set ignorecase
set smartcase

autocmd InsertEnter * :nohlsearch
autocmd CursorMoved * :nohlsearch

" Backspace
set backspace=indent,start,eol

" Completion
set wildmenu
set wildmode=list:longest,full
set completeopt=menuone,noinsert,noselect

" Persistent undo and backup
set undofile
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

" Auto-reload
set autoread
autocmd BufEnter * checktime

" ============================================
" Plugins
" ============================================
call plug#begin('~/.vim/plugged')

" --- Always loaded (lightweight, zero-config) ---
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

if !s:is_windows_posix
    " --- Full stack (macOS / WSL / Linux only) ---
    Plug 'dense-analysis/ale'
    Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
    Plug 'prabirshrestha/vim-lsp'
    Plug 'mattn/vim-lsp-settings'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'itchyny/lightline.vim'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'nathanaelkane/vim-indent-guides'
    Plug 'easymotion/vim-easymotion'
    Plug 'unblevable/quick-scope'
    Plug 'sheerun/vim-polyglot'
endif

call plug#end()

" ============================================
" Plugin Config — Full stack only
" ============================================
if !s:is_windows_posix

    " --- EasyMotion ---
    let g:EasyMotion_do_mapping = 0
    nmap <Leader>f <Plug>(easymotion-bd-f)
    nmap <Leader>t <Plug>(easymotion-bd-t)
    nmap / <Plug>(easymotion-bd-fn)
    nmap n <Plug>(easymotion-bd-n)
    nmap <Leader>w <Plug>(easymotion-bd-w)
    nmap <Leader>e <Plug>(easymotion-bd-e)
    let g:EasyMotion_smartcase = 1
    map <Leader>j <Plug>(easymotion-j)
    map <Leader>k <Plug>(easymotion-k)

    " --- vim-polyglot ---
    let g:vim_markdown_math = 1
    let g:vim_markdown_frontmatter = 1
    let g:vim_markdown_json_frontmatter = 1

    " --- ALE ---
    let g:ale_lint_on_enter = 1
    let g:ale_lint_on_text_changed = 1
    let g:ale_lint_on_save = 1
    let g:ale_signs_error = '✗'
    let g:ale_signs_warning = '!'
    let g:ale_set_highlights = 1
    highlight link ALEErrorSign ErrorMsg
    highlight link ALEWarningSign Todo
    let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', 'OK']
    let g:ale_open_list = 0

    " --- Autocomplete ---
    set completeopt=menuone,noinsert,preview
    autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

    " --- Lightline ---
    let g:lightline = {
          \ 'colorscheme': 'wombat',
          \ 'active': {
          \   'left': [ [ 'mode', 'paste' ],
          \             [ 'readonly', 'filename', 'modified', 'gitbranch' ] ],
          \   'right': [ [ 'lineinfo' ], [ 'percent' ], [ 'filetype' ] ]
          \ },
          \ 'component_function': {
          \   'gitbranch': 'FugitiveHead',
          \ }
          \ }

    " --- NERDTree ---
    nnoremap <C-n> :NERDTreeToggle<CR>

    " --- FZF ---
    nnoremap <C-p> :Files<CR>

endif

" ============================================
" Keymaps (all platforms)
" ============================================
inoremap <C-[> <Esc>
nnoremap <C-a> ggVG
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <leader>h :set hlsearch!<CR>
nnoremap j gj
nnoremap k gk

