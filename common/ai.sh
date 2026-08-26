#!/bin/sh
# ============================================
# AI / Agent Integration
# ============================================
# Makes this shell a good place for AI coding agents to work, and
# makes AI tooling convenient to reach from the shell.
#
# Four concerns:
#   1. Agent-friendly context   — feed the shell's state to a model
#   2. Machine-readable metadata — `devinfo` emits JSON
#   3. Secret hygiene            — keys come from 1Password, lazily
#   4. Agent-safe execution      — `noalias` for pasted commands
# ============================================

if ! command -v _has_cmd >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
        _has_cmd() { (( ${+commands[$1]} )); }
    else
        _has_cmd() { command -v "$1" >/dev/null 2>&1; }
    fi
fi

# ============================================
# 1. Claude Code shortcuts
# ============================================
if _has_cmd claude; then
    alias cl='claude'
    alias clc='claude --continue'            # resume the last conversation
    alias clr='claude --resume'              # pick a conversation to resume
    alias clp='claude --print'               # non-interactive, print and exit
    alias clyolo='claude --dangerously-skip-permissions'

    # clhere — start Claude with the repo root as the working dir,
    # so it sees the whole project rather than a subdirectory.
    clhere() {
        _cl_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
        ( cd "$_cl_root" && claude "$@" )
        unset _cl_root
    }

    # cldiff — ask Claude about the current uncommitted changes.
    # Pipes the diff in as context rather than making it hunt.
    cldiff() {
        _cld=$(git diff HEAD 2>/dev/null)
        if [ -z "$_cld" ]; then
            echo "cldiff: no uncommitted changes." >&2
            unset _cld; return 1
        fi
        printf '%s\n\n---\n%s\n' \
            "${*:-Review this diff. Flag bugs and anything that looks unintended.}" \
            "$_cld" | claude --print
        unset _cld
    }

    # clfix — pipe a failing command's output straight into Claude.
    #   clfix pytest -x
    #   clfix make build
    clfix() {
        [ -z "$1" ] && { echo "Usage: clfix <command...>"; return 1; }
        _clf_out=$("$@" 2>&1)
        _clf_rc=$?
        if [ $_clf_rc -eq 0 ]; then
            echo "$_clf_out"
            echo "clfix: command succeeded (exit 0), nothing to fix." >&2
            unset _clf_out _clf_rc; return 0
        fi
        printf 'This command failed with exit code %s:\n\n    %s\n\nOutput:\n\n%s\n\nDiagnose the cause and tell me the fix.\n' \
            "$_clf_rc" "$*" "$_clf_out" | claude --print
        unset _clf_out _clf_rc
    }

    # clask — one-shot question, no session. Reads stdin if piped.
    #   clask "how do I rebase onto main"
    #   cat error.log | clask "what went wrong here"
    clask() {
        if [ -t 0 ]; then
            printf '%s\n' "$*" | claude --print
        else
            printf '%s\n\n---\n%s\n' "${*:-Explain this.}" "$(cat)" | claude --print
        fi
    }

    # clcommit — draft a commit message from the staged diff.
    clcommit() {
        _clc_diff=$(git diff --staged 2>/dev/null)
        if [ -z "$_clc_diff" ]; then
            echo "clcommit: nothing staged." >&2
            unset _clc_diff; return 1
        fi
        printf 'Write a git commit message for this staged diff. Imperative mood, concise subject under 72 chars, body explaining why if it is not obvious. Output only the message.\n\n%s\n' \
            "$_clc_diff" | claude --print
        unset _clc_diff
    }
fi

# ============================================
# 2. devinfo — machine-readable environment metadata
# ============================================
# Prints the current toolchain state as JSON so you (or an agent)
# can query the environment in a single call instead of probing
# with a dozen `command -v` checks.
#
#   devinfo            → JSON to stdout
#   devinfo --pretty   → piped through jq if available
devinfo() {
    _di_pretty=0
    [ "$1" = "--pretty" ] && _di_pretty=1

    # Resolve versions only for tools that are actually installed.
    _di_ver() {
        if _has_cmd "$1"; then
            "$@" 2>/dev/null | head -1 | tr -d '"' | sed 's/[[:cntrl:]]//g'
        else
            printf 'null'
        fi
    }

    _di_git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    _di_git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    _di_git_dirty="false"
    if [ -n "$_di_git_root" ] && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        _di_git_dirty="true"
    fi

    _di_venv=""
    [ -n "$VIRTUAL_ENV" ] && _di_venv="$VIRTUAL_ENV"

    _di_out=$(cat <<EOF
{
  "os": "$(uname -s)",
  "arch": "$(uname -m)",
  "shell": "${SHELL##*/}",
  "dotfiles_os": "${DOTFILES_OS:-unknown}",
  "is_agent": $( [ "${DOTFILES_IS_AGENT:-0}" = "1" ] && echo true || echo false ),
  "cwd": "$PWD",
  "git": {
    "root": "$_di_git_root",
    "branch": "$_di_git_branch",
    "dirty": $_di_git_dirty
  },
  "python": {
    "version": "$(_di_ver python3 --version)",
    "virtualenv": "$_di_venv",
    "pyenv": "$(_has_cmd pyenv && command pyenv version-name 2>/dev/null || echo null)",
    "uv": "$(_di_ver uv --version)"
  },
  "node": {
    "version": "$(_di_ver node --version)",
    "npm": "$(_di_ver npm --version)",
    "nvm_default": "$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo null)"
  },
  "tools": {
    "rg": $(_has_cmd rg && echo true || echo false),
    "fd": $(_has_cmd fd && echo true || echo false),
    "bat": $(_has_cmd bat && echo true || echo false),
    "eza": $(_has_cmd eza && echo true || echo false),
    "fzf": $(_has_cmd fzf && echo true || echo false),
    "jq": $(_has_cmd jq && echo true || echo false),
    "sd": $(_has_cmd sd && echo true || echo false),
    "delta": $(_has_cmd delta && echo true || echo false),
    "gh": $(_has_cmd gh && echo true || echo false),
    "docker": $(_has_cmd docker && echo true || echo false),
    "aws": $(_has_cmd aws && echo true || echo false),
    "op": $(_has_cmd op && echo true || echo false)
  },
  "codeartifact_token_loaded": $( [ -n "$CODEARTIFACT_AUTH_TOKEN" ] && echo true || echo false )
}
EOF
)
    unset -f _di_ver 2>/dev/null

    if [ "$_di_pretty" = 1 ] && _has_cmd jq; then
        echo "$_di_out" | jq .
    else
        echo "$_di_out"
    fi
    unset _di_pretty _di_out _di_git_root _di_git_branch _di_git_dirty _di_venv
}

# ============================================
# 3. Secret hygiene — 1Password-backed, lazy
# ============================================
# API keys never live in this repo or in a plaintext rc file. They
# are pulled from 1Password on demand and exported into the current
# shell only. Nothing runs at startup, so there is no cost and no
# `op` authentication prompt when you open a terminal.
#
# Configure the item/field names in ~/.zshrc.local if yours differ:
#   OP_ANTHROPIC_REF="op://Private/Anthropic API/credential"
if _has_cmd op; then
    # opkey <VAR_NAME> <op://reference>
    #   Export a single secret into this shell.
    opkey() {
        if [ -z "$2" ]; then
            echo "Usage: opkey <VAR_NAME> <op://vault/item/field>" >&2
            return 1
        fi
        _ok_val=$(op read "$2" 2>/dev/null)
        if [ -z "$_ok_val" ]; then
            echo "opkey: could not read $2 (is 'op' signed in?)" >&2
            unset _ok_val; return 1
        fi
        export "$1=$_ok_val"
        echo "opkey: $1 loaded into this shell."
        unset _ok_val
    }

    # aikeys — load the AI provider keys you actually use.
    aikeys() {
        [ -n "$OP_ANTHROPIC_REF" ] && opkey ANTHROPIC_API_KEY "$OP_ANTHROPIC_REF"
        [ -n "$OP_OPENAI_REF" ]    && opkey OPENAI_API_KEY    "$OP_OPENAI_REF"
        if [ -z "$OP_ANTHROPIC_REF" ] && [ -z "$OP_OPENAI_REF" ]; then
            cat >&2 <<'EOF'
aikeys: no references configured. Add to ~/.zshrc.local:

    export OP_ANTHROPIC_REF="op://Private/Anthropic API/credential"
    export OP_OPENAI_REF="op://Private/OpenAI API/credential"

Then run `aikeys` in any shell that needs them.
EOF
            return 1
        fi
    }

    # opr — run a single command with secrets injected, never
    # leaving them in your environment afterwards.
    alias opr='op run --'
fi

# ============================================
# 4. Agent-safe execution
# ============================================
# Aliases do not apply to non-interactive shells, so scripts and
# most agent invocations are unaffected by them. The risk is when
# you PASTE a command into an interactive shell and an alias
# quietly rewrites it.
#
# common/aliases.sh already avoids shadowing tools with
# incompatible interfaces (sed, grep, cp stay themselves). These
# helpers cover the remaining cases.

# noalias <command...> — run a command with aliases bypassed.
#   noalias ls -la          → the real /bin/ls, not eza
#   noalias cat file        → the real cat, not bat
noalias() {
    [ -z "$1" ] && { echo "Usage: noalias <command...>"; return 1; }
    command "$@"
}

# Zsh: a leading backslash already bypasses an alias (\ls), and
# `command` bypasses functions. This is just a memorable name.

# rawshell — a subshell with no aliases or functions at all.
# Use when testing whether a problem is caused by this config.
rawshell() {
    if [ -n "$ZSH_VERSION" ]; then
        env -i HOME="$HOME" PATH="$PATH" TERM="$TERM" zsh -f
    else
        env -i HOME="$HOME" PATH="$PATH" TERM="$TERM" bash --noprofile --norc
    fi
}

# ============================================
# 5. Agent context helpers
# ============================================

# ctx — print a compact snapshot of the current working context.
# Useful to paste into a chat, or for an agent to run first.
ctx() {
    echo "=== context ==="
    echo "cwd:    $PWD"
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "repo:   $(git rev-parse --show-toplevel)"
        echo "branch: $(git_current_branch 2>/dev/null)"
        echo "base:   $(git_main_branch 2>/dev/null)"
        _ctx_changed=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        echo "dirty:  $_ctx_changed file(s)"
        unset _ctx_changed
        echo
        echo "--- recent commits ---"
        git log --oneline -5 2>/dev/null
        echo
        echo "--- changed files ---"
        git status --short 2>/dev/null | head -20
    else
        echo "repo:   (not a git repository)"
    fi
    [ -n "$VIRTUAL_ENV" ] && { echo; echo "venv:   $VIRTUAL_ENV"; }
}
