#!/bin/zsh
# ============================================
# MSYS2 (Windows) Specific Configuration
# Shell: Zsh (Oh My Zsh)
# ============================================
# NOTE: Oh My Zsh, theme, and plugins are configured
# in ~/.zshrc — this file handles only MSYS2-specific
# environment, Windows interop, and tool setup.
# ============================================

# ============================================
# Shell Config Shortcuts
# ============================================
alias rl='source ~/.zshrc'
alias shrc='${EDITOR:-vim} ~/.zshrc'
alias vimrc='${EDITOR:-vim} ~/.vimrc'

# ============================================
# Windows Path Mapping
# ============================================
# MSYS2 mounts drives as /c/ /d/ etc. (same as Git Bash)
if [ -z "$WIN_USER" ]; then
    WIN_USER="${USERNAME:-$(cmd.exe //C "echo %USERNAME%" 2>/dev/null | tr -d '\r')}"
    export WIN_USER
fi

if [ -n "$WIN_USER" ]; then
    export WIN_HOME="/c/Users/${WIN_USER}"
    alias cdwin='cd "$WIN_HOME"'
    alias cddesk='cd "$WIN_HOME/Desktop"'
    alias cddl='cd "$WIN_HOME/Downloads"'
    alias cddocs='cd "$WIN_HOME/Documents"'
fi

# ============================================
# Clipboard
# ============================================
if command -v clip.exe >/dev/null 2>&1; then
    alias clip='clip.exe'
    alias pbcopy='clip.exe'
fi

if command -v powershell.exe >/dev/null 2>&1; then
    alias paste='powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d "\r"'
    alias pbpaste='powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d "\r"'
fi

# ============================================
# Windows Executable Helpers
# ============================================
# "open" — macOS-like command to open files/URLs
open() {
    if [ -z "$1" ]; then
        explorer.exe .
    else
        start "" "$@" 2>/dev/null || explorer.exe "$@"
    fi
}

if command -v notepad.exe >/dev/null 2>&1; then
    alias notepad='notepad.exe'
fi

# ============================================
# Path Conversion Helpers
# ============================================
# MSYS2 path (/c/Users/...) -> Windows path (C:\Users\...)
towinpath() {
    if [ -z "$1" ]; then
        echo "Usage: towinpath <path>"
        return 1
    fi
    cygpath -w "$1" 2>/dev/null || echo "$1" | sed -E 's|^/([a-zA-Z])/|\U\1:\\|; s|/|\\|g'
}

# Windows path (C:\Users\...) -> MSYS2 path (/c/Users/...)
tounixpath() {
    if [ -z "$1" ]; then
        echo "Usage: tounixpath <path>"
        return 1
    fi
    cygpath -u "$1" 2>/dev/null || echo "$1" | sed -E 's|^([a-zA-Z]):\\|/\L\1/|; s|\\|/|g'
}

# ============================================
# MSYS2 Fixes
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
# MSYS2 Package Manager (pacman) Shortcuts
# ============================================
if command -v pacman >/dev/null 2>&1; then
    alias pacs='pacman -Ss'       # Search packages
    alias paci='pacman -S'        # Install
    alias pacr='pacman -Rns'      # Remove + deps
    alias pacu='pacman -Syu'      # Full system update
    alias pacl='pacman -Qs'       # List installed
    alias pacinfo='pacman -Qi'    # Package info
fi

# ============================================
# bat as man pager
# ============================================
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="bat -plman"
fi

# ============================================
# Tool Initializations (guarded)
# ============================================

# fzf
if command -v fzf >/dev/null 2>&1; then
    if [ -f "$HOME/.fzf.zsh" ]; then
        source "$HOME/.fzf.zsh"
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    source "$NVM_DIR/bash_completion"
fi

# uv (fast Python package manager)
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

# pyenv
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# ============================================
# PATH additions
# ============================================
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Include MSYS2 toolchain paths
for msys_dir in "/mingw64/bin" "/usr/local/bin"; do
    case ":$PATH:" in
        *":${msys_dir}:"*) ;;
        *) [ -d "$msys_dir" ] && export PATH="${msys_dir}:${PATH}" ;;
    esac
done

