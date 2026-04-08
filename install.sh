#!/bin/sh
# ============================================
# Dotfiles Entry Point — OS Detection & Sourcing
# ============================================
# This script is sourced from ~/.zshrc or ~/.bashrc.
# It detects the current environment and loads the
# appropriate common + OS-specific configuration.
#
# Usage: Add this to the END of your ~/.zshrc or ~/.bashrc:
#
#   DOTFILES_DIR="$HOME/.dotfiles"
#   [ -f "$DOTFILES_DIR/install.sh" ] && . "$DOTFILES_DIR/install.sh"
#
# ============================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# ============================================
# 1. Source Common Files (all environments)
#    Skips standalone scripts (commitwell.sh) that are
#    meant to be run directly, not sourced.
# ============================================
_dotfiles_skip="commitwell.sh"

for _common_file in "$DOTFILES_DIR"/common/*.sh; do
    [ -f "$_common_file" ] || continue
    _basename="${_common_file##*/}"
    case " $_dotfiles_skip " in
        *" $_basename "*) continue ;;
    esac
    . "$_common_file"
done
unset _common_file _basename _dotfiles_skip

# ============================================
# 2. Detect OS / Environment
# ============================================
_dotfiles_os=""

case "$(uname -s)" in
    Darwin)
        _dotfiles_os="macos"
        ;;
    Linux)
        if grep -qEi '(microsoft|wsl)' /proc/version 2>/dev/null; then
            _dotfiles_os="wsl"
        else
            _dotfiles_os="linux"
        fi
        ;;
    MINGW*|MSYS*)
        if command -v pacman >/dev/null 2>&1; then
            _dotfiles_os="msys2"
        else
            _dotfiles_os="gitbash"
        fi
        ;;
    CYGWIN*)
        _dotfiles_os="gitbash"
        ;;
    *)
        echo "[dotfiles] WARNING: Unknown OS '$(uname -s)' — only common config loaded."
        ;;
esac

# ============================================
# 3. Source OS-Specific File
# ============================================
if [ -n "$_dotfiles_os" ]; then
    _os_file="$DOTFILES_DIR/os/${_dotfiles_os}.sh"
    if [ -f "$_os_file" ]; then
        . "$_os_file"
    fi
    unset _os_file
fi

export DOTFILES_DIR
export DOTFILES_OS="$_dotfiles_os"
unset _dotfiles_os

# ============================================
# 4. Source local overrides (not tracked in git)
# ============================================
if [ -f "$DOTFILES_DIR/local.sh" ]; then
    . "$DOTFILES_DIR/local.sh"
fi
