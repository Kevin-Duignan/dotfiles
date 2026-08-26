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
    alias rl='exec zsh'   # full restart; re-sourcing can double-apply state
    alias shrc='${EDITOR:-vim} ~/.zshrc'
else
    alias rl='exec bash'  # full restart; re-sourcing can double-apply state
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
_dot_undef wopen wpath
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

# ============================================
# Tool initialisation — cached, no forks
# ============================================
# Every `eval "$(tool init)"` below used to fork a subprocess on
# each shell start. _dot_cache_eval (common/env.sh) runs each one
# once, caches the output, and sources the cache thereafter.
_dot_shell="bash"
[ -n "$ZSH_VERSION" ] && _dot_shell="zsh"

# zoxide (smart cd)
_has_cmd zoxide && _dot_cache_eval zoxide zoxide init "$_dot_shell"

# direnv (per-directory environments)
_has_cmd direnv && _dot_cache_eval direnv direnv hook "$_dot_shell"

# uv completions
_has_cmd uv && _dot_cache_eval uv uv generate-shell-completion "$_dot_shell"

unset _dot_shell

# delta (beautiful git diffs) — configure as git pager
_has_cmd delta && export GIT_PAGER='delta'

# NOTE: nvm and pyenv are NOT initialised here any more.
# common/lazy.sh handles both, lazily:
#   * nvm  — the default Node version's bin goes straight on PATH,
#            so node/npm/npx are instant; the `nvm` command itself
#            loads nvm.sh on first use (saves ~700ms per shell).
#   * pyenv — the `pyenv` command lazy-loads. Shims stay off PATH
#            unless you set DOTFILES_PYENV_SHIMS=1, so pyenv does
#            not silently change which python3 you get.
# common/lazy.sh is sourced AFTER this file precisely so its PATH
# entries take precedence over the system package manager's.

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

