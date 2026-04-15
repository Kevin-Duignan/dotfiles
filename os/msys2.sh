#!/bin/zsh
# ============================================
# MSYS2 (Windows) Specific Configuration
# Shell: Zsh (lightweight — no Oh My Zsh)
# ============================================
# PERFORMANCE NOTES:
#   - Uses Zsh's built-in $commands[] hash for instant
#     tool detection (no PATH scanning / subprocess forks).
#   - All "eval $(tool init)" outputs are cached to disk
#     and only regenerated when the binary changes.
#   - nvm is lazy-loaded (only initializes on first use).
#   - fzf init is cached in .zshrc fast-path; NOT repeated here.
#   - zoxide init is cached in .zshrc fast-path; NOT repeated here.
# ============================================

# ============================================
# Shell Config Shortcuts
# ============================================
alias rl='source ~/.zshrc'
alias shrc='${EDITOR:-vim} ~/.zshrc'
alias vimrc='${EDITOR:-vim} ~/.vimrc'

# ============================================
# MSYS2 Fixes (must be early)
# ============================================
# Disable POSIX path conversion that mangles arguments starting with /
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# Fix slow git on NTFS
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Terminal colors
export TERM=xterm-256color

# Ensure proper locale (avoid mojibake)
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ============================================
# Windows Path Mapping
# ============================================
# MSYS2 mounts drives as /c/ /d/ etc. (same as Git Bash)
if [[ -z "$WIN_USER" ]]; then
    # Prefer the already-set env var (no subprocess)
    WIN_USER="${USERNAME:-${USER}}"
    export WIN_USER
fi

if [[ -n "$WIN_USER" ]]; then
    export WIN_HOME="/c/Users/${WIN_USER}"
    alias cdwin='cd "$WIN_HOME"'
    alias cddesk='cd "$WIN_HOME/Desktop"'
    alias cddl='cd "$WIN_HOME/Downloads"'
    alias cddocs='cd "$WIN_HOME/Documents"'
fi

# ============================================
# Clipboard
# ============================================
(( ${+commands[clip.exe]} )) && {
    alias clip='clip.exe'
    alias pbcopy='clip.exe'
}

(( ${+commands[powershell.exe]} )) && {
    alias paste='powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d "\r"'
    alias pbpaste='powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d "\r"'
}

# ============================================
# Windows Executable Helpers
# ============================================
# "open" — macOS-like command to open files/URLs
open() {
    if [[ -z "$1" ]]; then
        explorer.exe .
    else
        start "" "$@" 2>/dev/null || explorer.exe "$@"
    fi
}

(( ${+commands[notepad.exe]} )) && alias notepad='notepad.exe'

# ============================================
# Path Conversion Helpers
# ============================================
# MSYS2 path (/c/Users/...) -> Windows path (C:\Users\...)
towinpath() {
    if [[ -z "$1" ]]; then
        echo "Usage: towinpath <path>"
        return 1
    fi
    cygpath -w "$1" 2>/dev/null || echo "$1" | sed -E 's|^/([a-zA-Z])/|\U\1:\\|; s|/|\\|g'
}

# Windows path (C:\Users\...) -> MSYS2 path (/c/Users/...)
tounixpath() {
    if [[ -z "$1" ]]; then
        echo "Usage: tounixpath <path>"
        return 1
    fi
    cygpath -u "$1" 2>/dev/null || echo "$1" | sed -E 's|^([a-zA-Z]):\\|/\L\1/|; s|\\|/|g'
}

# ============================================
# MSYS2 Package Manager (pacman) Shortcuts
# ============================================
(( ${+commands[pacman]} )) && {
    alias pacs='pacman -Ss'       # Search packages
    alias paci='pacman -S'        # Install
    alias pacr='pacman -Rns'      # Remove + deps
    alias pacu='pacman -Syu'      # Full system update
    alias pacl='pacman -Qs'       # List installed
    alias pacinfo='pacman -Qi'    # Package info
}

# ============================================
# bat as man pager
# ============================================
(( ${+commands[bat]} )) && export MANPAGER="bat -plman"

# ============================================
# Helper: cached eval — run "tool <args>" once,
# cache the output, re-source from cache on startup.
# Cache is invalidated when the binary is newer than
# the cache file (i.e., after a tool upgrade).
# ============================================
_dotfiles_cached_eval() {
    local name="$1"; shift
    local cmd="$1"; shift
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
    local cache_file="$cache_dir/$name.zsh"
    local bin_path="${commands[$cmd]}"

    # Tool not installed — skip silently
    [[ -z "$bin_path" ]] && return 0

    if [[ ! -f "$cache_file" || "$bin_path" -nt "$cache_file" ]]; then
        mkdir -p "$cache_dir"
        "$cmd" "$@" > "$cache_file" 2>/dev/null
    fi
    source "$cache_file"
}

# ============================================
# Tool Initializations (cached or lazy-loaded)
# ============================================

# zoxide — cached init (also handled by .zshrc fast-path,
# but this covers the case where msys2.sh is sourced via
# install.sh after the fast-path already returned)
_dotfiles_cached_eval "zoxide" zoxide init zsh

# uv — cached shell completions
_dotfiles_cached_eval "uv-completion" uv generate-shell-completion zsh

# pyenv — cached init
if (( ${+commands[pyenv]} )); then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    _dotfiles_cached_eval "pyenv" pyenv init -
fi

# ============================================
# nvm — LAZY-LOADED (saves 1-2s on startup)
# nvm.sh is only sourced the first time you run
# nvm, node, npm, or npx.
# ============================================
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # Placeholder functions that lazy-load on first call
    _dotfiles_lazy_nvm() {
        unfunction nvm node npm npx 2>/dev/null
        source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    }
    nvm()  { _dotfiles_lazy_nvm; nvm "$@"; }
    node() { _dotfiles_lazy_nvm; node "$@"; }
    npm()  { _dotfiles_lazy_nvm; npm "$@"; }
    npx()  { _dotfiles_lazy_nvm; npx "$@"; }
fi

# ============================================
# PATH additions
# ============================================
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Include MSYS2 toolchain paths (no subprocess — just string check)
for msys_dir in "/mingw64/bin" "/usr/local/bin"; do
    case ":$PATH:" in
        *":${msys_dir}:"*) ;;
        *) [[ -d "$msys_dir" ]] && export PATH="${msys_dir}:${PATH}" ;;
    esac
done
unset msys_dir

