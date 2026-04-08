"Enable syntax highlighting and filetype detection
syntax on
filetype plugin indent on

" Set mapleader
let mapleader=" "

" UI settings
set number
set mouse=a
set ruler
set showmatch
set relativenumber
set splitbelow
set splitright
set lazyredraw
set visualbell

" Yank settings
set clipboard^=unnamed,unnamedplus

" Indentation
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4

" Search behaviour
set incsearch
set ignorecase
set smartcase

" Clear search highlight when entering insert mode or cursor moved
autocmd InsertEnter * :nohlsearch
autocmd CursorMoved * :nohlsearch

" Backspace behaviour
set backspace=indent,start,eol

" Completion settings
set wildmenu
set wildmode=list:longest,full
set completeopt=menuone,noinsert,noselect

" Persistent undo and backup
set undofile
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

" Automatically reload files changed outside Vim
set autoread
autocmd BufEnter * checktime

" Plugin manager
call plug#begin('~/.vim/plugged')

" Linting and fixing
Plug 'dense-analysis/ale'

" Lazy loading
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

" Auto-completion
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'

" Status line
Plug 'itchyny/lightline.vim'

" Code commenting
Plug 'tpope/vim-commentary'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Enhance surrounding delimiters (quotes, brackets, etc.) - A classic must-have
Plug 'tpope/vim-surround'

" Seamless Git integration and commands within Vim
Plug 'tpope/vim-fugitive'

" Show git diff signs in the gutter (sign column)
Plug 'airblade/vim-gitgutter'

" Indentation guides for better visual structure
Plug 'nathanaelkane/vim-indent-guides'

" Auto-closes parentheses, brackets, and quotes
Plug 'jiangmiao/auto-pairs'

" Enhanced text object manipulations (e.g., around/inside quotes, blocks)
Plug 'tpope/vim-unimpaired'

" Super-charged motion for jumping quickly within a file
Plug 'easymotion/vim-easymotion'

" Always-on highlight for a unique character in every word on a line to help you use f, F and family.
Plug 'unblevable/quick-scope'

" Better syntax highlighting for a vast number of languages
Plug 'sheerun/vim-polyglot'

call plug#end()

" --- EasyMotion Custom Configuration ---
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

" Disable compatibility for vim-polygot to work
set nocompatible
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1

" --- ALE (Asynchronous Lint Engine) Configuration ---

" Enable linting automatically when opening a file, inserting text, or saving
let g:ale_lint_on_enter = 1
let g:ale_lint_on_text_changed = 1
let g:ale_lint_on_save = 1

" Show error and warning signs in the gutter (sign column)
" This gives you immediate visual feedback next to the line numbers
let g:ale_signs_error = '✗'
let g:ale_signs_warning = '!'

" Highlight the lines containing errors or warnings
let g:ale_set_highlights = 1
highlight link ALEErrorSign ErrorMsg
highlight link ALEWarningSign Todo

" Show current error/warning in the Vim status line (works well with lightline.vim)
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', 'OK']

" Allow ALE to fix the file automatically when you save it (optional, needs external fixers like eslint, black, etc.)
" You still need the specific fixers installed on your system for this to work
" let g:ale_fix_on_save = 1
" let g:ale_fixers = {
" \ '*': ['remove_trailing_whitespace'],
" \ 'python': ['black'],
" \ 'javascript': ['eslint'],
" \ }

" Integrate ALE diagnostics with the quickfix/location list (accessible via :Errors or :lopen)
let g:ale_open_list = 0 " Don't open the list automatically, use :Errors or :lopen manually

" --- Autocomplete Visual Enhancements ---
" Your existing asyncomplete.vim setup will work, but to make the completion menu more visually descriptive (show documentation in a preview window):
set completeopt=menuone,noinsert,preview

" This option ensures that the preview window for documentation closes automatically when you stop navigating the completion menu.
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" Lightline configuration
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

set laststatus=2

" NERDTree toggle
nnoremap <C-n> :NERDTreeToggle<CR>

" FZF file search
nnoremap <C-p> :Files<CR>

" Remap Esc
inoremap <C-[> <Esc>

" Select whole file with Ctrl-A
nnoremap <C-a> ggVG

" Reload vimrc without restarting
nnoremap <leader>sv :source $MYVIMRC<CR>

" Toggle search highlight
nnoremap <leader>h :set hlsearch!<CR>

" move vertically by visual line with j and k
nnoremap j gj
nnoremap k gk

