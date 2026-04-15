#!/bin/sh
# ============================================
# WSL (Ubuntu) Specific Configuration
# Shell: Zsh (via Oh My Zsh) or Bash
# ============================================
# NOTE: Oh My Zsh, theme, and plugins are configured
# in ~/.zshrc — this file handles only WSL-specific
# environment, Windows interop, and tool setup.
# ============================================

# ============================================
# Shell Config Shortcuts
# ============================================
if [ -n "$ZSH_VERSION" ]; then
    alias rl='source ~/.zshrc'
    alias shrc='${EDITOR:-vim} ~/.zshrc'
else
    alias rl='source ~/.bashrc'
    alias shrc='${EDITOR:-vim} ~/.bashrc'
fi
alias vimrc='${EDITOR:-vim} ~/.vimrc'

# ============================================
# WSL <-> Windows Interop
# ============================================

# Detect Windows username (cached for performance)
if [ -z "$WIN_USER" ]; then
    if command -v cmd.exe >/dev/null 2>&1; then
        WIN_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        export WIN_USER
    fi
fi

# Windows home directory
if [ -n "$WIN_USER" ]; then
    export WIN_HOME="/mnt/c/Users/${WIN_USER}"
    alias cdwin='cd "$WIN_HOME"'
    alias cddesk='cd "$WIN_HOME/Desktop"'
    alias cddl='cd "$WIN_HOME/Downloads"'
    alias cddocs='cd "$WIN_HOME/Documents"'
fi

# ============================================
# Clipboard — map to Windows clip.exe / powershell
# ============================================
if command -v clip.exe >/dev/null 2>&1; then
    alias clip='clip.exe'
fi

# pbcopy/pbpaste equivalents for WSL
if command -v clip.exe >/dev/null 2>&1; then
    alias pbcopy='clip.exe'
fi

if command -v powershell.exe >/dev/null 2>&1; then
    alias pbpaste='powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d "\r"'
    alias paste='powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d "\r"'
fi

# ============================================
# Windows Executable Wrappers
# ============================================
# Run Windows executables seamlessly — .exe suffix helpers
if command -v explorer.exe >/dev/null 2>&1; then
    alias explorer='explorer.exe'
    alias open='explorer.exe'  # macOS-like `open` command
fi

if command -v notepad.exe >/dev/null 2>&1; then
    alias notepad='notepad.exe'
fi

if command -v code >/dev/null 2>&1; then
    : # VS Code already on PATH via WSL integration
elif command -v code.exe >/dev/null 2>&1; then
    alias code='code.exe'
fi

# ============================================
# Path Fixes for WSL
# ============================================
# Remove Windows paths from $PATH to speed up shell (optional, uncomment if needed)
# export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/mnt/c' | tr '\n' ':' | sed 's/:$//')

# Ensure common Linux tool paths are present
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Fix umask for proper file permissions in WSL
umask 022

# ============================================
# WSL-Specific Utilities
# ============================================

# Open current directory in Windows Explorer
wopen() {
    local target="${1:-.}"
    if [ -d "$target" ] || [ -f "$target" ]; then
        explorer.exe "$(wslpath -w "$target")" 2>/dev/null
    else
        echo "Path not found: $target"
        return 1
    fi
}

# Convert WSL path <-> Windows path
wpath() {
    if [ -z "$1" ]; then
        echo "Usage: wpath <path>"
        echo "Converts between WSL and Windows paths."
        return 1
    fi
    case "$1" in
        /mnt/*) wslpath -w "$1" ;;   # WSL -> Windows
        [A-Z]:\\*|[a-z]:\\*) wslpath -u "$1" ;;  # Windows -> WSL
        *) wslpath -w "$1" ;;        # Default: WSL -> Windows
    esac
}

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
    if [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.fzf.zsh" ]; then
        source "$HOME/.fzf.zsh"
    elif [ -n "$BASH_VERSION" ] && [ -f "$HOME/.fzf.bash" ]; then
        source "$HOME/.fzf.bash"
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    elif command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(zoxide init zsh)"
    elif [ -n "$BASH_VERSION" ]; then
        eval "$(zoxide init bash)"
    fi
fi

# delta (beautiful git diffs) — configure as git pager
if command -v delta >/dev/null 2>&1; then
    export GIT_PAGER='delta'
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
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(uv generate-shell-completion zsh)"
    elif [ -n "$BASH_VERSION" ]; then
        eval "$(uv generate-shell-completion bash)"
    fi
fi

# pyenv
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# ============================================
# WSL Display / GUI Support (WSLg or X11)
# ============================================
if [ -n "$WSL_DISTRO_NAME" ]; then
    # WSLg (Windows 11) sets DISPLAY automatically.
    # For older WSL2 + X server (VcXsrv, etc.), uncomment:
    # export DISPLAY="$(grep nameserver /etc/resolv.conf | awk '{print $2}'):0"
    # export LIBGL_ALWAYS_INDIRECT=1
    :
fi

