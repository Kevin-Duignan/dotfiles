#!/bin/sh
# ============================================
# Common Functions — Shared across all environments
# Sourced by: macOS (Zsh), WSL (Zsh/Bash), Git Bash, MSYS2 (Zsh)
# ============================================

# ============================================
# Git Helpers
# ============================================

# List git emojis
if [ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/.gitmoji-list.txt" ]; then
    alias gmoji='cat "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/.gitmoji-list.txt"'
fi

# HVSD-specific branch creation function
gswhv() {
    if [ -z "$1" ]; then
        echo "Usage: gswhv <ticket-number>"
        return 1
    fi
    git checkout -b "HVSD-$1"
}

# ============================================
# File / Navigation Helpers
# ============================================

# Interactive file open with fzf
vimi() {
    if command -v fzf >/dev/null 2>&1; then
        vim "$(fzf)"
    else
        echo "fzf is not installed."
    fi
}

openi() {
    if command -v fzf >/dev/null 2>&1; then
        open "$(fzf)"
    else
        echo "fzf is not installed."
    fi
}

# 'With fzf' — run fzf then pass result to a command
wfzf() {
    local selected_file
    selected_file="$(fzf --multi)"
    if [ -n "$selected_file" ]; then
        "$1" "$selected_file"
    fi
}

# fzf with fd for fast file finding
ffzf() {
    if command -v fd >/dev/null 2>&1; then
        fd --type f --hidden --follow --exclude .git | \
            fzf --multi --preview 'head -100 {}' --bind 'focus:transform-header:file --brief {}'
    else
        find . -type f -not -path '*/.git/*' | \
            fzf --multi --preview 'head -100 {}'
    fi
}

# Docker compose log viewer with fzf
fzfdlog() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker is not installed."
        return 1
    fi
    local service
    service=$(docker compose ps --services | fzf --prompt='Select service > ')
    [ -n "$service" ] && docker compose logs -n 100000 "$service" | \
        sed 's/^[^[]*\[//' | tac | \
        fzf --ansi --bind "ctrl-r:reload(docker compose logs -n 100000 $service | sed 's/^[^[]*\[//' | tac)"
}

# ============================================
# Yazi file manager wrapper
# ============================================
_y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

y() {
    if [ -n "$1" ]; then
        if [ -d "$1" ]; then
            _y "$1"
        elif command -v zoxide >/dev/null 2>&1; then
            _y "$(zoxide query "$1")"
        else
            echo "zoxide not installed; pass a valid directory path."
            return 1
        fi
    else
        _y
    fi
    return $?
}

# ============================================
# Diff Helpers
# ============================================
batdiff() {
    if command -v bat >/dev/null 2>&1; then
        git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
    else
        git diff
    fi
}

# ============================================
# Utility: Extract any archive
# ============================================
extract() {
    if [ -z "$1" ]; then
        echo "Usage: extract <file>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "'$1' is not a valid file."
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1"   ;;
        *.tar.gz)  tar xzf "$1"   ;;
        *.tar.xz)  tar xJf "$1"   ;;
        *.bz2)     bunzip2 "$1"   ;;
        *.rar)     unrar x "$1"   ;;
        *.gz)      gunzip "$1"    ;;
        *.tar)     tar xf "$1"    ;;
        *.tbz2)    tar xjf "$1"   ;;
        *.tgz)     tar xzf "$1"   ;;
        *.zip)     unzip "$1"     ;;
        *.Z)       uncompress "$1";;
        *.7z)      7z x "$1"     ;;
        *)         echo "'$1' cannot be extracted via extract()" ;;
    esac
}

# ============================================
# Utility: Create dir and cd into it
# ============================================
mkcd() {
    mkdir -p "$1" && cd "$1" || return 1
}

# ============================================
# Utility: Quick HTTP server (Python)
# ============================================
serve() {
    local port="${1:-8000}"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port"
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port"
    else
        echo "Python is not installed."
        return 1
    fi
}
