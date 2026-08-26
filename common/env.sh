#!/bin/sh
# ============================================
# Common Environment — Shared across all environments
# Sourced by: macOS (Zsh), WSL (Zsh/Bash), Git Bash, MSYS2 (Zsh)
# ============================================
# POSIX sh only — this file is sourced by bash as well as zsh.
# Loaded FIRST, before aliases and functions.
# ============================================

# ============================================
# Fast tool detection helper
# ============================================
# Zsh keeps a hash of every command on $PATH ($commands), so testing
# membership is a hash lookup with no fork. `command -v` in a POSIX
# shell is a builtin too, but slower. Defined here so every later
# file can rely on it.
if [ -n "$ZSH_VERSION" ]; then
    _has_cmd() { (( ${+commands[$1]} )); }
else
    _has_cmd() { command -v "$1" >/dev/null 2>&1; }
fi

# ============================================
# Cached tool initialisation — used by every platform
# ============================================
# Tools like zoxide, direnv and pyenv generate their shell
# integration by running a subprocess whose output you eval. Each
# of those forks costs 10-90ms on every single shell start.
#
# _dot_cache_eval runs the command ONCE, writes the output to a
# cache file, and sources that file on every later startup —
# regenerating only when the tool's binary is newer than the cache.
#
#   _dot_cache_eval <cache-name> <command> [args...]
#
# Defined here rather than in ~/.zshrc so macOS, WSL, MSYS2 and
# Git Bash all share one implementation, in both zsh and bash.
DOTFILES_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[ -d "$DOTFILES_CACHE" ] || command mkdir -p "$DOTFILES_CACHE" 2>/dev/null

if [ -n "$ZSH_VERSION" ]; then
    _dot_cache_eval() {
        local name=$1; shift
        local cache="$DOTFILES_CACHE/$name.zsh"
        local bin=${commands[$1]}
        if [[ ! -s $cache || ( -n $bin && $bin -nt $cache ) ]]; then
            "$@" >| "$cache" 2>/dev/null || return 1
            # Byte-compile so later startups skip the parser.
            [[ -s $cache ]] && zcompile -R -- "$cache" 2>/dev/null
        fi
        source "$cache"
    }
else
    _dot_cache_eval() {
        _dce_name="$1"; shift
        _dce_cache="$DOTFILES_CACHE/$_dce_name.sh"
        _dce_bin="$(command -v "$1" 2>/dev/null)"
        if [ ! -s "$_dce_cache" ] || \
           { [ -n "$_dce_bin" ] && [ "$_dce_bin" -nt "$_dce_cache" ]; }; then
            "$@" > "$_dce_cache" 2>/dev/null || {
                rm -f "$_dce_cache"
                unset _dce_name _dce_cache _dce_bin
                return 1
            }
        fi
        # shellcheck disable=SC1090
        . "$_dce_cache"
        unset _dce_name _dce_cache _dce_bin
    }
fi

# ============================================
# XDG base directories
# ============================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ============================================
# Locale
# ============================================
export LANG="${LANG:-en_AU.UTF-8}"
export LC_ALL="${LC_ALL:-en_AU.UTF-8}"

# ============================================
# Editor
# ============================================
# Remote sessions get plain vim — a GUI editor can't display there.
if [ -n "$SSH_CONNECTION" ]; then
    export EDITOR='vim'
    export VISUAL='vim'
else
    export EDITOR="${EDITOR:-vim}"
    export VISUAL="${VISUAL:-vim}"
fi

# ============================================
# Pager
# ============================================
# -R renders colour, -F exits if it fits on one screen,
# -X stops it clearing the screen on exit.
export LESS="${LESS:--RFX}"
export PAGER="${PAGER:-less}"

# Colourised man pages. This replaces the OMZ colored-man-pages
# plugin, which did nothing except set these seven variables.
export LESS_TERMCAP_mb="$(printf '\033[1;31m')"   # blink   → red
export LESS_TERMCAP_md="$(printf '\033[1;36m')"   # bold    → cyan
export LESS_TERMCAP_me="$(printf '\033[0m')"      # reset
export LESS_TERMCAP_so="$(printf '\033[01;33m')"  # standout→ yellow
export LESS_TERMCAP_se="$(printf '\033[0m')"      # reset
export LESS_TERMCAP_us="$(printf '\033[1;32m')"   # underline→ green
export LESS_TERMCAP_ue="$(printf '\033[0m')"      # reset

# ============================================
# PATH
# ============================================
# _path_prepend / _path_append add a directory, keeping PATH free
# of duplicates. Without deduping, PATH grows every time you
# re-source your rc file, and every command lookup gets slower.
#
# Crucially, _path_prepend MOVES a directory that is already
# present rather than leaving it where it is. If it merely skipped
# duplicates, an entry inherited from a parent shell would keep its
# old position — which is how Homebrew's node ended up shadowing
# the nvm default version.
if [ -n "$ZSH_VERSION" ]; then
    # zsh keeps $PATH and the $path array tied together. `typeset -U`
    # makes the array reject duplicates, keeping the FIRST
    # occurrence — so prepending a directory that already exists
    # later in PATH automatically removes the later copy.
    typeset -U path fpath
    _path_prepend() { [ -d "$1" ] && path=("$1" $path); return 0; }
    _path_append()  { [ -d "$1" ] && path=($path "$1"); return 0; }
else
    # POSIX/bash: rebuild PATH without the entry, then re-add it.
    # Uses only shell string handling — no forks.
    _path_remove() {
        _pr_out=""
        _pr_ifs="$IFS"
        IFS=:
        for _pr_e in $PATH; do
            [ -z "$_pr_e" ] && continue
            [ "$_pr_e" = "$1" ] && continue
            _pr_out="$_pr_out:$_pr_e"
        done
        IFS="$_pr_ifs"
        PATH="${_pr_out#:}"
        unset _pr_out _pr_e _pr_ifs
    }

    _path_prepend() {
        [ -d "$1" ] || return 0
        _path_remove "$1"
        PATH="$1:$PATH"
    }

    _path_append() {
        [ -d "$1" ] || return 0
        _path_remove "$1"
        PATH="$PATH:$1"
    }
fi

_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/bin"
_path_append  "$HOME/.cargo/bin"
export PATH

# ============================================
# Tool behaviour
# ============================================
# Stop Python writing .pyc files into your source trees.
export PYTHONDONTWRITEBYTECODE=1
# Unbuffered output — makes piped Python output appear immediately.
export PYTHONUNBUFFERED=1
# Don't let pip run outside a virtualenv by accident.
export PIP_REQUIRE_VIRTUALENV="${PIP_REQUIRE_VIRTUALENV:-false}"
# Keep Homebrew quiet and fast.
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
# Don't let Docker phone home on every command.
export DOCKER_SCAN_SUGGEST=false
# Node: bigger heap for build tooling.
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}"

# ============================================
# fzf
# ============================================
export FZF_DEFAULT_OPTS="--ansi --layout=reverse --border=rounded --height=60% \
--bind=ctrl-/:toggle-preview,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down"

if _has_cmd fd; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif _has_cmd rg; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --glob !.git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if _has_cmd bat; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
fi

# ============================================
# Jira (used by the jira helper functions)
# ============================================
export JIRA_URL='https://wspdigital.atlassian.net/'
export JIRA_NAME='kevin.duignan@wspdigital.com'
export JIRA_PREFIX='HVSD'
