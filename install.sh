#!/bin/sh
# ============================================
# Dotfiles Entry Point — OS Detection & Sourcing
# ============================================
# Sourced from ~/.zshrc or ~/.bashrc. Detects the environment and
# loads the appropriate common + OS-specific configuration.
#
# Usage — add to the END of your ~/.bashrc (zsh users: ~/.zshrc
# already does this in section 9):
#
#   DOTFILES_DIR="$HOME/.dotfiles"
#   [ -f "$DOTFILES_DIR/install.sh" ] && . "$DOTFILES_DIR/install.sh"
#
# ============================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# ============================================
# 1. Source common files — EXPLICIT ORDER
# ============================================
# Order matters and a glob does not guarantee it:
#   env.sh       must be first — defines _has_cmd and _path_prepend,
#                which everything below depends on.
#   aliases.sh   before functions.sh, so a function can override an
#                alias of the same name if it needs to.
#   ai.sh        may reference helpers from all of the above.
#
# lazy.sh is NOT loaded here — see step 3. It sets up the nvm and
# pyenv PATH shims, which must be prepended AFTER the OS file adds
# Homebrew, or `node` resolves to Homebrew's version instead of
# your nvm default.
#
# commitwell.sh is deliberately excluded: it is a standalone script
# meant to be executed, not sourced.
for _dot_file in env.sh aliases.sh functions.sh ai.sh; do
    if [ -f "$DOTFILES_DIR/common/$_dot_file" ]; then
        . "$DOTFILES_DIR/common/$_dot_file"
    fi
done
unset _dot_file

# ============================================
# 2. Detect OS / environment
# ============================================
# Prefer zsh's built-in $OSTYPE over `uname -s` — it avoids a fork.
_dotfiles_os=""

if [ -n "$ZSH_VERSION" ]; then
    case "$OSTYPE" in
        darwin*)       _dotfiles_os="macos" ;;
        msys*|cygwin*) _dotfiles_os="msys2" ;;
        linux*)
            if [ -n "$WSL_DISTRO_NAME" ] || [ -n "$WSLENV" ]; then
                _dotfiles_os="wsl"
            else
                _dotfiles_os="linux"
            fi
            ;;
    esac
fi

# Fall back to uname for bash, or if $OSTYPE gave us nothing.
if [ -z "$_dotfiles_os" ]; then
    case "$(uname -s)" in
        Darwin) _dotfiles_os="macos" ;;
        Linux)
            if [ -n "$WSL_DISTRO_NAME" ] \
               || grep -qEi '(microsoft|wsl)' /proc/version 2>/dev/null; then
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
        CYGWIN*) _dotfiles_os="gitbash" ;;
        *)
            echo "[dotfiles] Unknown OS '$(uname -s)' — only common config loaded." >&2
            ;;
    esac
fi

# ============================================
# 3. Source the OS-specific file
# ============================================
if [ -n "$_dotfiles_os" ]; then
    if [ -f "$DOTFILES_DIR/os/${_dotfiles_os}.sh" ]; then
        . "$DOTFILES_DIR/os/${_dotfiles_os}.sh"
    fi
fi

export DOTFILES_DIR
export DOTFILES_OS="$_dotfiles_os"
unset _dotfiles_os

# ============================================
# 3b. Lazy loaders — LAST, so their PATH wins
# ============================================
# Version managers must take precedence over the system package
# manager. Homebrew installs its own node and python; nvm and pyenv
# are what actually decide which version you want. Loading this
# after os/*.sh guarantees the nvm/pyenv shims sit in front of
# /opt/homebrew/bin on PATH.
if [ -f "$DOTFILES_DIR/common/lazy.sh" ]; then
    . "$DOTFILES_DIR/common/lazy.sh"
fi

# ============================================
# 4. Local overrides (not tracked in git)
# ============================================
# Two hooks, both optional:
#   $DOTFILES_DIR/local.sh — machine-specific config kept beside
#                            the repo but gitignored
#   ~/.zshrc.local         — sourced later, from ~/.zshrc itself
if [ -f "$DOTFILES_DIR/local.sh" ]; then
    . "$DOTFILES_DIR/local.sh"
fi
