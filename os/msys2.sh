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
alias rl='exec zsh'   # full restart; re-sourcing can double-apply state
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
_dot_undef open towinpath tounixpath
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
# delta (beautiful git diffs) — configure as git pager
# ============================================
(( ${+commands[delta]} )) && export GIT_PAGER='delta'

# ============================================
# Tool initialisation — cached, no forks
# ============================================
# This file used to define its own _dotfiles_cached_eval and its
# own lazy-nvm stubs. Both now live in shared code, so every
# platform behaves identically:
#
#   _dot_cache_eval  → common/env.sh
#   nvm / pyenv lazy → common/lazy.sh
#
# common/lazy.sh is sourced AFTER this file so its PATH entries win
# over the system package manager's.

# zoxide — cached init
(( ${+commands[zoxide]} )) && _dot_cache_eval zoxide zoxide init zsh

# uv — cached shell completions
(( ${+commands[uv]} )) && _dot_cache_eval uv uv generate-shell-completion zsh

# NOTE: nvm and pyenv are handled by common/lazy.sh.
# The old lazy stubs here also shadowed node/npm/npx, which meant
# the FIRST node call in every shell paid the full ~700ms nvm load.
# lazy.sh instead puts the default Node version's bin directly on
# PATH, so node/npm/npx are instant and only `nvm` itself is lazy.

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

