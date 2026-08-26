#!/bin/sh
# ============================================
# Common Functions — Shared across all environments
# Sourced by: macOS (Zsh), WSL (Zsh/Bash), Git Bash, MSYS2 (Zsh)
# ============================================
# Functions cost nothing at startup beyond parsing — no forks, no
# subprocesses. They only run when called.
# ============================================

# Earlier versions of this repo shipped `dotsync`, `dotsync-cp` and friends
# as aliases in common/aliases.sh. A live alias breaks the function
# definitions below, because the shell expands the alias while parsing
# `name() {` and reports "syntax error near unexpected token `('". That bites
# when an existing session re-sources this file after a pull, so drop any
# colliding alias before defining anything.
for _fn_stale in dotsync dotsync-cp dotsync_cp ports-kill ports_kill \
    dotfiles gbclean gswhv jira extract ua mkcd take serve backup up proj \
    vimi openi wfzf ffzf frg fbr fco fkill fzfdlog y batdiff; do
    unalias "$_fn_stale" 2>/dev/null
done
unset _fn_stale

if ! command -v _has_cmd >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
        _has_cmd() { (( ${+commands[$1]} )); }
    else
        _has_cmd() { command -v "$1" >/dev/null 2>&1; }
    fi
fi

# ============================================
# Git branch helpers
# ============================================
# These were previously provided by the Oh My Zsh `git` plugin.
# We no longer load it, but a dozen aliases in common/aliases.sh
# still call them (gcm, gpsup, grbm, gprom, ...), so they must be
# defined here or those aliases break.

# git_current_branch — the checked-out branch name.
git_current_branch() {
    _gcb_ref=$(git symbolic-ref --quiet HEAD 2>/dev/null)
    _gcb_status=$?
    if [ $_gcb_status -ne 0 ]; then
        # Detached HEAD: fall back to the short SHA.
        [ $_gcb_status -eq 128 ] && { unset _gcb_ref _gcb_status; return 1; }
        _gcb_ref=$(git rev-parse --short HEAD 2>/dev/null) || {
            unset _gcb_ref _gcb_status; return 1;
        }
    fi
    echo "${_gcb_ref#refs/heads/}"
    unset _gcb_ref _gcb_status
}

# git_main_branch — main, master, trunk, whichever this repo uses.
git_main_branch() {
    command git rev-parse --git-dir >/dev/null 2>&1 || return
    for _gmb in main trunk mainline default stable master; do
        if command git show-ref -q --verify "refs/heads/$_gmb" \
            || command git show-ref -q --verify "refs/remotes/origin/$_gmb"; then
            echo "$_gmb"; unset _gmb; return 0
        fi
    done
    unset _gmb
    echo master
}

# git_develop_branch — dev, develop, whichever this repo uses.
git_develop_branch() {
    command git rev-parse --git-dir >/dev/null 2>&1 || return
    for _gdb in dev devel develop development; do
        if command git show-ref -q --verify "refs/heads/$_gdb"; then
            echo "$_gdb"; unset _gdb; return 0
        fi
    done
    unset _gdb
    echo develop
}

# List git emojis, if the cheatsheet is present.
if [ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/.gitmoji-list.txt" ]; then
    alias gmoji='cat "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/.gitmoji-list.txt"'
fi

# gswhv <ticket> — create/switch to an HVSD-prefixed branch.
gswhv() {
    if [ -z "$1" ]; then
        echo "Usage: gswhv <ticket-number>  →  HVSD-<ticket-number>"
        return 1
    fi
    # Accept "1234", "HVSD-1234" or "hvsd-1234" and normalise.
    _hv=$(echo "$1" | sed 's/^[Hh][Vv][Ss][Dd]-//')
    git switch -c "${JIRA_PREFIX:-HVSD}-$_hv" 2>/dev/null \
        || git switch "${JIRA_PREFIX:-HVSD}-$_hv"
    unset _hv
}

# gbclean — delete local branches whose remote is gone.
gbclean() {
    git fetch --prune
    git branch -vv | awk '/: gone]/{print $1}' | xargs -r git branch -D
}

# ============================================
# Jira — inlined from the OMZ jira plugin
# ============================================
# jira            → open the Jira dashboard
# jira 1234       → open HVSD-1234
# jira HVSD-1234  → open HVSD-1234
# jira .          → open the ticket named by the current branch
jira() {
    _jira_base="${JIRA_URL:-https://wspdigital.atlassian.net/}"
    _jira_base="${_jira_base%/}"

    if [ -z "$1" ]; then
        _jira_target="$_jira_base/jira/your-work"
    elif [ "$1" = "." ]; then
        # Pull the ticket key out of the current branch name.
        _jira_branch=$(git_current_branch 2>/dev/null)
        _jira_key=$(echo "$_jira_branch" | grep -oE '[A-Za-z]+-[0-9]+' | head -1)
        if [ -z "$_jira_key" ]; then
            echo "jira: no ticket key found in branch '$_jira_branch'" >&2
            unset _jira_base _jira_branch _jira_key
            return 1
        fi
        _jira_target="$_jira_base/browse/$(echo "$_jira_key" | tr '[:lower:]' '[:upper:]')"
    else
        case "$1" in
            *-*) _jira_key="$1" ;;
            *)   _jira_key="${JIRA_PREFIX:-HVSD}-$1" ;;
        esac
        _jira_target="$_jira_base/browse/$(echo "$_jira_key" | tr '[:lower:]' '[:upper:]')"
    fi

    echo "$_jira_target"
    _open_url "$_jira_target"
    unset _jira_base _jira_target _jira_key _jira_branch
}

# _open_url — cross-platform "open this in a browser".
_open_url() {
    if _has_cmd open; then open "$1"
    elif _has_cmd xdg-open; then xdg-open "$1"
    elif _has_cmd start; then start "$1"
    elif _has_cmd wslview; then wslview "$1"
    fi
}

# ============================================
# fzf-powered helpers
# ============================================

# vimi — pick a file with fzf and open it in $EDITOR.
vimi() {
    _has_cmd fzf || { echo "fzf is not installed."; return 1; }
    _vi_file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || head -200 {}')
    [ -n "$_vi_file" ] && "${EDITOR:-vim}" "$_vi_file"
    unset _vi_file
}

openi() {
    _has_cmd fzf || { echo "fzf is not installed."; return 1; }
    _op_file=$(fzf)
    [ -n "$_op_file" ] && _open_url "$_op_file"
    unset _op_file
}

# wfzf <cmd> — pick file(s) with fzf, pass them to <cmd>.
wfzf() {
    [ -z "$1" ] && { echo "Usage: wfzf <command>"; return 1; }
    _wf_sel=$(fzf --multi)
    [ -n "$_wf_sel" ] && echo "$_wf_sel" | tr '\n' '\0' | xargs -0 "$1"
    unset _wf_sel
}

# ffzf — fuzzy file finder with a preview pane.
ffzf() {
    if _has_cmd bat; then
        _ff_prev='bat --color=always --style=numbers --line-range=:200 {}'
    else
        _ff_prev='head -200 {}'
    fi
    if _has_cmd fd; then
        fd --type f --hidden --follow --exclude .git | fzf --multi --preview "$_ff_prev"
    elif _has_cmd rg; then
        rg --files --hidden --glob '!.git' | fzf --multi --preview "$_ff_prev"
    else
        find . -type f -not -path '*/.git/*' | fzf --multi --preview "$_ff_prev"
    fi
    unset _ff_prev
}

# frg — search file CONTENTS with ripgrep, pick a match, open it at that line.
frg() {
    _has_cmd rg || { echo "ripgrep is not installed."; return 1; }
    _has_cmd fzf || { echo "fzf is not installed."; return 1; }
    rg --color=always --line-number --no-heading --smart-case "${*:-}" \
        | fzf --ansi \
              --delimiter : \
              --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
              --preview-window 'up,60%,border-bottom,+{2}+3/3' \
              --bind 'enter:become($EDITOR {1} +{2})'
}

# fbr — fuzzy-pick a git branch and check it out.
fbr() {
    _fb=$(git branch --all | grep -v HEAD | sed 's/^[* ] //;s#remotes/origin/##' \
        | sort -u | fzf --preview 'git log --oneline --color=always -20 {}')
    [ -n "$_fb" ] && git switch "$_fb"
    unset _fb
}

# fco — fuzzy-pick a commit and show it.
fco() {
    _fc=$(git log --oneline --decorate --color=always -200 \
        | fzf --ansi --preview 'git show --color=always {1}' | awk '{print $1}')
    [ -n "$_fc" ] && git show "$_fc"
    unset _fc
}

# fkill — fuzzy-pick a process and kill it.
fkill() {
    _fk=$(ps -ef | sed 1d | fzf --multi | awk '{print $2}')
    [ -n "$_fk" ] && echo "$_fk" | xargs kill -"${1:-15}"
    unset _fk
}

# fzfdlog — pick a docker compose service and tail its logs.
fzfdlog() {
    _has_cmd docker || { echo "Docker is not installed."; return 1; }
    _svc=$(docker compose ps --services | fzf --prompt='Select service > ')
    [ -n "$_svc" ] && docker compose logs -f --tail=200 "$_svc"
    unset _svc
}

# ============================================
# Yazi file manager — cd to wherever you quit
# ============================================
_y() {
    _y_tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$_y_tmp"
    if [ -s "$_y_tmp" ]; then
        _y_cwd="$(cat "$_y_tmp")"
        [ -n "$_y_cwd" ] && [ "$_y_cwd" != "$PWD" ] && builtin cd -- "$_y_cwd" || true
    fi
    rm -f -- "$_y_tmp"
    unset _y_tmp _y_cwd
}

y() {
    if [ -n "$1" ]; then
        if [ -d "$1" ]; then
            _y "$1"
        elif _has_cmd zoxide; then
            _y "$(zoxide query "$1")"
        else
            echo "zoxide not installed; pass a valid directory path."
            return 1
        fi
    else
        _y
    fi
}

# ============================================
# Diff helpers
# ============================================
batdiff() {
    if _has_cmd bat; then
        git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
    else
        git diff
    fi
}

# ============================================
# Archives
# ============================================
# extract <file> — unpack anything. Replaces the OMZ extract plugin.
extract() {
    if [ -z "$1" ]; then echo "Usage: extract <file>"; return 1; fi
    if [ ! -f "$1" ]; then echo "'$1' is not a valid file."; return 1; fi
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1"   ;;
        *.tar.gz|*.tgz)   tar xzf "$1"   ;;
        *.tar.xz|*.txz)   tar xJf "$1"   ;;
        *.tar.zst)        tar --zstd -xf "$1" ;;
        *.tar)            tar xf "$1"    ;;
        *.bz2)            bunzip2 "$1"   ;;
        *.gz)             gunzip "$1"    ;;
        *.xz)             unxz "$1"      ;;
        *.zst)            unzstd "$1"    ;;
        *.rar)            unrar x "$1"   ;;
        *.zip)            unzip "$1"     ;;
        *.Z)              uncompress "$1";;
        *.7z)             7z x "$1"      ;;
        *) echo "'$1' cannot be extracted via extract()" ;;
    esac
}

# ua <archive-name> <files...> — compress. Replaces universalarchive.
ua() {
    if [ -z "$2" ]; then echo "Usage: ua <archive.tar.gz> <files...>"; return 1; fi
    _ua_out="$1"; shift
    case "$_ua_out" in
        *.tar.gz|*.tgz)   tar czf "$_ua_out" "$@" ;;
        *.tar.bz2)        tar cjf "$_ua_out" "$@" ;;
        *.tar.xz)         tar cJf "$_ua_out" "$@" ;;
        *.tar.zst)        tar --zstd -cf "$_ua_out" "$@" ;;
        *.tar)            tar cf  "$_ua_out" "$@" ;;
        *.zip)            zip -r  "$_ua_out" "$@" ;;
        *.7z)             7z a    "$_ua_out" "$@" ;;
        *) echo "ua: unknown archive type '$_ua_out'"; return 1 ;;
    esac
    unset _ua_out
}

# ============================================
# Everyday utilities
# ============================================

# mkcd <dir> — create a directory and enter it.
mkcd() { mkdir -p "$1" && cd "$1" || return 1; }

# take <dir> — OMZ's mkcd, kept for muscle memory.
take() { mkcd "$@"; }

# serve [port] — quick static HTTP server in the current directory.
serve() {
    _sv_port="${1:-8000}"
    if _has_cmd python3; then python3 -m http.server "$_sv_port"
    elif _has_cmd python; then python -m SimpleHTTPServer "$_sv_port"
    else echo "Python is not installed."; unset _sv_port; return 1
    fi
    unset _sv_port
}

# backup <file> — timestamped copy alongside the original.
backup() {
    [ -z "$1" ] && { echo "Usage: backup <file>"; return 1; }
    cp -r "$1" "$1.$(date +%Y%m%d-%H%M%S).bak" && echo "Backed up $1"
}

# up [n] — go up n directories (default 1).
up() {
    _up_n="${1:-1}"; _up_p=""
    while [ "$_up_n" -gt 0 ]; do _up_p="../$_up_p"; _up_n=$((_up_n - 1)); done
    cd "$_up_p" || return 1
    unset _up_n _up_p
}

# proj — jump to a project directory with fzf.
proj() {
    _has_cmd fzf || { echo "fzf is not installed."; return 1; }
    _pj_root="${PROJECTS_DIR:-$HOME/Developer}"
    _pj=$(find "$_pj_root" -maxdepth 2 -type d -name .git 2>/dev/null \
        | sed 's#/.git$##' | fzf --prompt='project > ')
    [ -n "$_pj" ] && cd "$_pj"
    unset _pj _pj_root
}

# ports-kill <port> — kill whatever is listening on a port.
ports_kill() {
    [ -z "$1" ] && { echo "Usage: ports-kill <port>"; return 1; }
    _pk=$(lsof -ti ":$1" 2>/dev/null)
    if [ -z "$_pk" ]; then echo "Nothing listening on port $1."; return 1; fi
    echo "$_pk" | xargs kill -9 && echo "Killed process(es) on port $1."
    unset _pk
}
alias ports-kill='ports_kill'

# ============================================
# Dotfiles sync
# ============================================
# Pulls the repo and re-links the tracked dotfiles into $HOME.
# Symlinking (rather than copying) means editing ~/.zshrc edits the
# repo directly, so changes are never silently lost.
dotsync() {
    _ds_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [ ! -d "$_ds_dir" ]; then
        echo "dotsync: $_ds_dir does not exist." >&2
        unset _ds_dir; return 1
    fi

    ( cd "$_ds_dir" && git pull --rebase --autostash ) || {
        echo "dotsync: git pull failed." >&2; unset _ds_dir; return 1;
    }

    # Back up anything that is a real file rather than our symlink,
    # so a first-time sync can never destroy existing config.
    for _ds_f in .zshrc .p10k.zsh .vimrc .bashrc; do
        [ -f "$_ds_dir/$_ds_f" ] || continue
        if [ -e "$HOME/$_ds_f" ] && [ ! -L "$HOME/$_ds_f" ]; then
            mv "$HOME/$_ds_f" "$HOME/$_ds_f.pre-dotfiles.$(date +%Y%m%d-%H%M%S)"
            echo "  backed up existing ~/$_ds_f"
        fi
        ln -sfn "$_ds_dir/$_ds_f" "$HOME/$_ds_f"
    done

    echo "Dotfiles synced (symlinked from $_ds_dir)."
    unset _ds_dir _ds_f

    if [ -n "$ZSH_VERSION" ]; then
        echo "Restarting shell..."
        exec zsh
    else
        # shellcheck disable=SC1090
        . "$HOME/.bashrc"
    fi
}

# dotsync-cp — same, but copies instead of symlinking. Use on
# machines where you want the repo and $HOME to stay independent.
dotsync_cp() {
    _ds_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    ( cd "$_ds_dir" && git pull --rebase --autostash ) || return 1
    for _ds_f in .zshrc .p10k.zsh .vimrc .bashrc; do
        [ -f "$_ds_dir/$_ds_f" ] && cp "$_ds_dir/$_ds_f" "$HOME/$_ds_f"
    done
    echo "Dotfiles synced (copied)."
    unset _ds_dir _ds_f
    [ -n "$ZSH_VERSION" ] && exec zsh
}
alias dotsync-cp='dotsync_cp'
