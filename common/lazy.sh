#!/bin/sh
# ============================================
# Lazy Loaders — defer expensive tool initialisation
# ============================================
# Every tool in this file used to run at startup. Together they
# accounted for roughly 2 seconds of a 2.5s shell start:
#
#   aws codeartifact get-authorization-token   1200ms  (network call!)
#   nvm.sh                                      670ms
#   thefuck --alias                             130ms
#   pyenv init -                                 90ms
#
# The pattern below replaces each with a stub function. The stub
# deletes itself on first call, does the real (slow) initialisation
# once, then re-invokes itself so the call still works. You pay the
# cost only when you actually use the tool, and only once per shell.
# ============================================

# ============================================
# AWS CodeArtifact — fully lazy
# ============================================
# The old config ran a `codeartifact get-authorization-token` call
# on EVERY shell start — a blocking network round-trip to AWS. It
# cost 1.2 seconds per shell, left you with no token when offline,
# and re-fetched a token that stays valid for 12 hours.
#
# Now: nothing runs at startup. `ca-token` fetches on demand and
# caches for 11 hours; the pip/uv/twine/poetry wrappers below call
# it automatically, so your install commands behave exactly as
# before without you thinking about it.
#
# These are deliberately empty here — this repo is public. Set the
# real values in local.sh, which is gitignored and sourced last:
#
#   export CODEARTIFACT_PROFILE='your-aws-profile'
#   export CODEARTIFACT_DOMAIN='your-domain'
#   export CODEARTIFACT_OWNER='your-aws-account-id'
#
# With them unset, the wrappers below simply pass through to the
# real pip/uv/poetry and nothing tries to fetch a token.
CODEARTIFACT_PROFILE="${CODEARTIFACT_PROFILE:-}"
CODEARTIFACT_DOMAIN="${CODEARTIFACT_DOMAIN:-}"
CODEARTIFACT_OWNER="${CODEARTIFACT_OWNER:-}"
_CA_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/codeartifact-token"

# ca-token [--force]
#   Populate $CODEARTIFACT_AUTH_TOKEN, using the cache when fresh.
ca-token() {
    _ca_force=0
    [ "$1" = "--force" ] && _ca_force=1

    # Use the cached token if it exists and is under 11 hours old.
    # CodeArtifact tokens last 12h; 11 gives us an hour of headroom.
    if [ "$_ca_force" -eq 0 ] && [ -s "$_CA_CACHE" ]; then
        if [ -z "$(find "$_CA_CACHE" -mmin +660 2>/dev/null)" ]; then
            CODEARTIFACT_AUTH_TOKEN="$(cat "$_CA_CACHE")"
            export CODEARTIFACT_AUTH_TOKEN
            unset _ca_force
            return 0
        fi
    fi

    if ! _has_cmd aws; then
        echo "ca-token: aws CLI not installed." >&2
        unset _ca_force
        return 1
    fi

    # Not configured on this machine — say so clearly rather than
    # running an aws command with empty --domain/--domain-owner.
    if [ -z "$CODEARTIFACT_DOMAIN" ] || [ -z "$CODEARTIFACT_OWNER" ]; then
        cat >&2 <<'EOF'
ca-token: CodeArtifact is not configured on this machine.

Add to local.sh (gitignored, beside this repo):

    export CODEARTIFACT_PROFILE='your-aws-profile'
    export CODEARTIFACT_DOMAIN='your-domain'
    export CODEARTIFACT_OWNER='your-aws-account-id'
EOF
        unset _ca_force
        return 1
    fi

    echo "ca-token: fetching CodeArtifact token (valid 12h)..." >&2
    _ca_new="$(aws --profile "$CODEARTIFACT_PROFILE" codeartifact \
        get-authorization-token \
        --domain "$CODEARTIFACT_DOMAIN" \
        --domain-owner "$CODEARTIFACT_OWNER" \
        --query authorizationToken --output text 2>/dev/null)"

    if [ -z "$_ca_new" ] || [ "$_ca_new" = "None" ]; then
        echo "ca-token: failed. Check your AWS SSO login:" >&2
        echo "          aws sso login --profile $CODEARTIFACT_PROFILE" >&2
        unset _ca_force _ca_new
        return 1
    fi

    # Write with restrictive permissions — this is a credential.
    _ca_old_umask="$(umask)"
    umask 077
    printf '%s' "$_ca_new" > "$_CA_CACHE"
    umask "$_ca_old_umask"

    CODEARTIFACT_AUTH_TOKEN="$_ca_new"
    export CODEARTIFACT_AUTH_TOKEN
    unset _ca_force _ca_new _ca_old_umask
    return 0
}

# ca-refresh — force a new token regardless of cache age.
ca-refresh() { ca-token --force; }

# ca-clear — drop the cached token.
ca-clear() {
    rm -f "$_CA_CACHE"
    unset CODEARTIFACT_AUTH_TOKEN
    echo "ca-token: cache cleared."
}

# --------------------------------------------------
# Wrappers that need the token
# --------------------------------------------------
# These make the lazy token invisible in normal use: run `pip
# install`, `uv sync`, `poetry add` or `twine upload` and the token
# is fetched first if it isn't already loaded.
#
# Only the subcommands that actually talk to the index trigger a
# fetch, so `pip list` and `uv run` stay instant and work offline.
_ca_needs_token() {
    # Not configured? Then nothing ever needs a token, and the
    # wrappers below pass straight through to the real tool. This
    # keeps a fresh clone of this repo working with zero setup.
    [ -n "$CODEARTIFACT_DOMAIN" ] || return 1
    case "$1" in
        install|download|wheel|sync|add|lock|upload|publish|update) return 0 ;;
        *) return 1 ;;
    esac
}

# Any of these may already be an alias — from the Oh My Zsh pip
# plugin, or simply from this file having been sourced once
# already. Defining a function over an existing alias is a parse
# error in zsh, so clear them first. See _dot_undef in common/env.sh.
_dot_undef pip pip3 uv twine poetry

pip() {
    if [ -z "$CODEARTIFACT_AUTH_TOKEN" ] && _ca_needs_token "$1"; then
        ca-token || true
    fi
    command pip "$@"
}

pip3() {
    if [ -z "$CODEARTIFACT_AUTH_TOKEN" ] && _ca_needs_token "$1"; then
        ca-token || true
    fi
    command pip3 "$@"
}

uv() {
    if [ -z "$CODEARTIFACT_AUTH_TOKEN" ] && _ca_needs_token "$1"; then
        ca-token || true
    fi
    command uv "$@"
}

twine() {
    if [ -z "$CODEARTIFACT_AUTH_TOKEN" ] && [ -n "$CODEARTIFACT_DOMAIN" ]; then
        ca-token || true
    fi
    command twine "$@"
}

poetry() {
    if [ -z "$CODEARTIFACT_AUTH_TOKEN" ] && _ca_needs_token "$1"; then
        ca-token || true
    fi
    command poetry "$@"
}

# ============================================
# nvm — PATH shim + lazy load
# ============================================
# Sourcing nvm.sh costs ~670ms because it is 4000 lines of shell
# that also probes the filesystem for installed versions.
#
# Instead: put the default Node version's bin directory straight on
# PATH, so `node`, `npm` and `npx` work instantly with zero setup.
# The `nvm` command itself is a stub that loads the real nvm.sh the
# first time you call it — which is only when you switch versions.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Guard must sit OUTSIDE the if below: zsh parses the whole block
# before running any of it, so a guard placed inside would run too
# late to help. See _dot_undef in common/env.sh.
_dot_undef nvm

if [ -d "$NVM_DIR/versions/node" ]; then
    # Resolve the default alias (e.g. "20.19.6") to a real directory.
    if [ -f "$NVM_DIR/alias/default" ]; then
        _nvm_default="$(cat "$NVM_DIR/alias/default" 2>/dev/null)"
        # The alias may be bare ("20.19.6") or prefixed ("v20.19.6").
        case "$_nvm_default" in
            v*) _nvm_ver="$_nvm_default" ;;
            *)  _nvm_ver="v$_nvm_default" ;;
        esac
        if [ -d "$NVM_DIR/versions/node/$_nvm_ver/bin" ]; then
            _path_prepend "$NVM_DIR/versions/node/$_nvm_ver/bin"
            export PATH
            export NVM_BIN="$NVM_DIR/versions/node/$_nvm_ver/bin"
            export NVM_INC="$NVM_DIR/versions/node/$_nvm_ver/include/node"
        fi
        unset _nvm_default _nvm_ver
    fi

    # Stub: replaced by the real nvm on first invocation.
    nvm() {
        unset -f nvm 2>/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi

# ============================================
# pyenv — lazy, and OFF the PATH by default
# ============================================
# `pyenv init -` costs ~90ms and, more importantly, prepends the
# shim directory to PATH — which changes which `python3` you get.
#
# This machine currently resolves python3 to Homebrew's, and pyenv
# is not on PATH at all. Enabling shims here would silently switch
# every `python3` invocation to the pyenv version (3.11.4 rather
# than Homebrew's 3.14.3), which would break existing virtualenvs
# and scripts. So shims stay OFF unless you ask for them.
#
# To make pyenv the authority on python versions, add to
# ~/.zshrc.local:
#
#     export DOTFILES_PYENV_SHIMS=1
#
# The `pyenv` command itself always works — it lazy-loads the full
# init on first use.
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
_dot_undef pyenv          # must be outside the if — see note above
if [ -d "$PYENV_ROOT" ]; then
    # The pyenv binary itself, without the shims.
    _path_append "$PYENV_ROOT/bin"
    export PATH

    if [ "${DOTFILES_PYENV_SHIMS:-0}" = "1" ]; then
        _path_prepend "$PYENV_ROOT/shims"
        export PATH
    fi

    pyenv() {
        unset -f pyenv 2>/dev/null
        eval "$(command pyenv init -)"
        pyenv "$@"
    }
fi

# ============================================
# thefuck — lazy alias
# ============================================
# `thefuck --alias` boots a Python interpreter, costing ~130ms on
# every shell. Since the command only matters after you've already
# mistyped something, defer it entirely.
_dot_undef fuck FUCK      # must be outside the if — see note above
if _has_cmd thefuck; then
    fuck() {
        unset -f fuck FUCK 2>/dev/null
        eval "$(command thefuck --alias fuck)"
        eval "$(command thefuck --alias FUCK)"
        fuck "$@"
    }
    FUCK() {
        unset -f fuck FUCK 2>/dev/null
        eval "$(command thefuck --alias fuck)"
        eval "$(command thefuck --alias FUCK)"
        FUCK "$@"
    }
fi

# ============================================
# Conda — lazy (if installed)
# ============================================
# Conda's init block is notoriously slow. Only pay for it on demand.
_dot_undef conda          # must be outside the if — see note above
if [ -d "$HOME/miniconda3" ] || [ -d "$HOME/anaconda3" ]; then
    conda() {
        unset -f conda 2>/dev/null
        _conda_base="$HOME/miniconda3"
        [ -d "$_conda_base" ] || _conda_base="$HOME/anaconda3"
        # shellcheck disable=SC1091
        . "$_conda_base/etc/profile.d/conda.sh"
        unset _conda_base
        conda "$@"
    }
fi
