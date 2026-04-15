#!/bin/bash
# ============================================
# Git Bash (Windows) — Lightweight / Fast Start
# ============================================
# This is the minimal config. Heavy tools (nvm, pyenv,
# fzf plugins) are intentionally omitted for speed.
# Use WSL or MSYS2 for a full-featured environment.
# ============================================

# ============================================
# Fixes (must be early)
# ============================================
export MSYS_NO_PATHCONV=1
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
export TERM=xterm-256color

# ============================================
# Windows User & Home
# ============================================
WIN_USER="${USERNAME:-$USER}"
export WIN_USER
export WIN_HOME="/c/Users/${WIN_USER}"

# ============================================
# Quick Navigation
# ============================================
alias cdwin='cd "$WIN_HOME"'
alias cddl='cd "$WIN_HOME/Downloads"'
alias cddesk='cd "$WIN_HOME/Desktop"'
alias cddocs='cd "$WIN_HOME/Documents"'

# ============================================
# Shell Config
# ============================================
alias rl='source ~/.bashrc'
alias shrc='${EDITOR:-vim} ~/.bashrc'

# ============================================
# Clipboard
# ============================================
alias clip='clip.exe'
alias pbcopy='clip.exe'
alias paste='powershell.exe -NoProfile -Command "Get-Clipboard"'
alias pbpaste='powershell.exe -NoProfile -Command "Get-Clipboard"'

# ============================================
# open (macOS-like)
# ============================================
open() { explorer.exe "${1:-.}"; }

# ============================================
# Minimal tool init (only the fast ones)
# ============================================

# zoxide — fast, no measurable startup cost
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# delta (beautiful git diffs) — configure as git pager
if command -v delta >/dev/null 2>&1; then
    export GIT_PAGER='delta'
fi

# uv — fast Python package manager completions
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi

# fzf keybindings (just the source, no plugin overhead)
[ -f "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"

# ============================================
# PATH
# ============================================
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
