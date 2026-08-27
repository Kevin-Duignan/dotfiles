#!/bin/sh
# ============================================
# Common Aliases — Shared across all environments
# Sourced by: macOS (Zsh), WSL (Zsh/Bash), Git Bash, MSYS2 (Zsh)
# ============================================
# Aliases are effectively free — each one is a hash-table insert
# costing about a microsecond. The whole file below adds under
# 0.5ms to startup, which is why we inline every useful alias from
# the Oh My Zsh plugins instead of loading the plugins themselves.
# A plugin costs 5-80ms because of completion registration, PATH
# probing and function definitions, not because of its aliases.
#
# ============================================
# A NOTE ON SHADOWING STANDARD COMMANDS
# ============================================
# Modern replacements (rg, sd, xcp, dust, procs) are excellent, but
# aliasing a POSIX command name to a tool with a DIFFERENT command
# line interface breaks any script, snippet or AI-generated one-liner
# you paste into an interactive shell.
#
# The rule used here:
#   * Safe to shadow    — same interface, nicer output (eza, bat).
#   * NEVER shadow      — different flags entirely (sd, rg, xcp).
#
# So `sed` is still sed and `grep` is still grep. `sd` and `rg` are
# right there under their own names, and they're what you should
# reach for interactively.
# ============================================

# _has_cmd is defined in common/env.sh, which loads first.
# Re-define defensively in case this file is sourced standalone.
if ! command -v _has_cmd >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
        _has_cmd() { (( ${+commands[$1]} )); }
    else
        _has_cmd() { command -v "$1" >/dev/null 2>&1; }
    fi
fi

# ============================================
# MSYS2 / Git Bash: Windows-native tool wrappers
# ============================================
# Tools installed via winget (eza, bat, fd) are Windows binaries
# that don't understand MSYS2 Unix paths (/c/Users/...). Since
# MSYS_NO_PATHCONV=1 disables automatic conversion, wrap them so
# path arguments get translated by cygpath first.
_dotfiles_is_msys=0
case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) _dotfiles_is_msys=1 ;;
esac

if [ "$_dotfiles_is_msys" = 1 ] && _has_cmd cygpath; then
    _win_wrap() {
        _ww_cmd="$1"; shift
        set -- "$@"
        _ww_args=""
        for _ww_arg in "$@"; do
            case "$_ww_arg" in
                /*) _ww_args="$_ww_args $(cygpath -w "$_ww_arg")" ;;
                *)  _ww_args="$_ww_args $_ww_arg" ;;
            esac
        done
        # shellcheck disable=SC2086
        command "$_ww_cmd" $_ww_args
        unset _ww_cmd _ww_arg _ww_args
    }
fi

# ============================================
# Safer file operations
# ============================================
alias mkdir='mkdir -pv'
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'
alias ln='ln -i'

# Faster/safer alternatives kept under their OWN names, so they
# never surprise a script that expected the POSIX tool.
_has_cmd xcp  && alias xc='xcp'
_has_cmd rip  && alias trash='rip'          # rm-improved: recoverable delete
_has_cmd dust && alias dus='dust'
_has_cmd duf  && alias dfh='duf'
_has_cmd procs && alias pss='procs'

# ============================================
# ls — eza (drop-in compatible, safe to shadow)
# ============================================
# Cleared unconditionally, for two separate reasons:
#   * The MSYS profile pre-sets `alias ls='ls --show-control-chars'`,
#     which eza rejects.
#   * The block below defines ls/ll/la/lt as FUNCTIONS on one
#     branch. zsh parses the whole if/else before running it, so a
#     pre-existing `ls` alias makes that a parse error even on the
#     branch that never executes. See _dot_undef in common/env.sh.
_dot_undef ls ll la lt

if _has_cmd eza; then
    if [ "$_dotfiles_is_msys" = 1 ] && _has_cmd cygpath; then
        ls()  { _win_wrap eza --icons --group-directories-first "$@"; }
        ll()  { _win_wrap eza -alh --icons --group-directories-first --git "$@"; }
        la()  { _win_wrap eza -a --icons --group-directories-first "$@"; }
        lt()  { _win_wrap eza --tree --level=2 --icons "$@"; }
    else
        alias ls='eza --icons --group-directories-first'
        alias ll='eza -alh --icons --group-directories-first --git'
        alias la='eza -a --icons --group-directories-first'
        alias lt='eza --tree --level=2 --icons'
        alias lt3='eza --tree --level=3 --icons'
        alias ltg='eza --tree --level=2 --icons --git-ignore'
        alias lsd='eza -D --icons'              # directories only
        alias lsm='eza -lh --icons --sort=modified --reverse'
        alias lss='eza -lh --icons --sort=size --reverse'
    fi
elif _has_cmd exa; then
    alias ls='exa --icons --group-directories-first'
    alias ll='exa -alh --icons --group-directories-first'
    alias la='exa -a --icons --group-directories-first'
    alias lt='exa --tree --level=2 --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alh --color=auto'
    alias la='ls -A --color=auto'
    alias lt='ls -lhR --color=auto'
fi

# ============================================
# grep — NOT shadowed (see the note at the top)
# ============================================
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

if _has_cmd rg; then
    # ripgrep under its own name, with useful presets.
    alias rga='rg --hidden --no-ignore'      # search everything
    alias rgi='rg --ignore-case'
    alias rgf='rg --files'
    alias rgl='rg --files-with-matches'
    alias rgc='rg --count'
fi

# ============================================
# cat — bat in plain mode (safe: same output shape)
# ============================================
# -pp = --plain --plain: no line numbers, no grid, no paging.
# Output is byte-identical to cat for piping purposes.
_dot_undef cat        # defined as a function on the MSYS branch below
if _has_cmd bat; then
    if [ "$_dotfiles_is_msys" = 1 ] && _has_cmd cygpath; then
        cat() { _win_wrap bat -pp "$@"; }
    else
        alias cat='bat -pp'
    fi
    alias batp='bat'                          # the pretty, paged version
    alias bathelp='bat --plain --language=help'
fi

# ============================================
# Directory navigation
# ============================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias d='dirs -v'                             # numbered directory stack

# zoxide: frecency-based cd. `z` learns where you go.
if _has_cmd zoxide; then
    alias cd='z'
    alias cdi='zi'                            # interactive picker
fi

# ============================================
# System / shell
# ============================================
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'
alias reload='exec zsh'                       # full clean restart

# History search (from the OMZ history plugin)
if _has_cmd rg; then
    alias hs='history | rg'
    alias hsi='history | rg -i'
else
    alias hs='history | grep'
    alias hsi='history | grep -i'
fi

# ============================================
# Config file shortcuts
# ============================================
alias zshrc='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ~/.zshrc'
alias zshloc='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ~/.zshrc.local'
alias zshenv='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ${DOTFILES_DIR:-$HOME/.dotfiles}/common/env.sh'
alias zshals='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ${DOTFILES_DIR:-$HOME/.dotfiles}/common/aliases.sh'
alias zshfunc='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ${DOTFILES_DIR:-$HOME/.dotfiles}/common/functions.sh'
alias zshlazy='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ${DOTFILES_DIR:-$HOME/.dotfiles}/common/lazy.sh'
alias zshai='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ${DOTFILES_DIR:-$HOME/.dotfiles}/common/ai.sh'
alias bashrc='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ~/.bashrc'
alias vimrc='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ~/.vimrc'
alias p10k-cfg='${GUI_EDITOR:-${EDITOR:-${commands[vim]:-vim}}} ${DOTFILES_DIR:-$HOME/.dotfiles}/.p10k.zsh'

# ============================================
# Dotfiles management
# ============================================
alias dotfiles='cd ${DOTFILES_DIR:-$HOME/.dotfiles}'
alias dotpull='(cd ${DOTFILES_DIR:-$HOME/.dotfiles} && git pull)'
alias dotdoctor='${DOTFILES_DIR:-$HOME/.dotfiles}/tools/dotfiles-doctor'
alias dotbench='${DOTFILES_DIR:-$HOME/.dotfiles}/tools/dotfiles-doctor bench'

# ============================================
# Git — inlined from the OMZ git plugin
# ============================================
# These rely on git_main_branch() and git_current_branch(), which
# are defined in common/functions.sh (the OMZ git plugin used to
# provide them; we no longer load it).
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gau='git add --update'
alias gap='git add --patch'

alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbr='git branch --remote'
alias gbm='git branch --move'

alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias 'gc!'='git commit --verbose --amend'
alias 'gca!'='git commit --verbose --all --amend'
alias gcam='git commit --all --message'
alias gcmsg='git commit --message'
alias gcn='git commit --verbose --no-edit'
alias 'gcn!'='git commit --verbose --no-edit --amend'
alias gcf='git commit --fixup'

alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'
alias gcd='git checkout $(git_develop_branch)'

alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'

alias gd='git diff'
alias gds='git diff --staged'
alias gdca='git diff --cached'
alias gdw='git diff --word-diff'
alias gdst='git diff --stat'
alias gdt='git diff-tree --no-commit-id --name-only -r'

alias gf='git fetch'
alias gfa='git fetch --all --tags --prune'
alias gfo='git fetch origin'

alias gl='git pull'
alias gpr='git pull --rebase'
alias gpra='git pull --rebase --autostash'
alias gprom='git pull --rebase origin $(git_main_branch)'
alias gproma='git pull --rebase --autostash origin $(git_main_branch)'

alias gp='git push'
alias gpf='git push --force-with-lease'
alias 'gpf!'='git push --force'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpv='git push --verbose'
alias gpod='git push origin --delete'
alias gpt='git push --tags'

alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glo='git log --oneline --decorate'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glg='git log --stat'
alias glp='git log --patch'
alias gld='git log --oneline --decorate --graph --since="1 day ago"'

alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'
alias gmom='git merge origin/$(git_main_branch)'

alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbs='git rebase --skip'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbd='git rebase $(git_develop_branch)'

alias grh='git reset'
alias grhh='git reset --hard'
alias grhs='git reset --soft'
alias groh='git reset origin/$(git_current_branch) --hard'

alias grs='git restore'
alias grst='git restore --staged'
alias grss='git restore --source'

alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grset='git remote set-url'

alias grm='git rm'
alias grmc='git rm --cached'

alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gstd='git stash drop'
alias gstc='git stash clear'
alias gsts='git stash show --patch'
alias gstall='git stash --all'

alias gsh='git show'
alias gbl='git blame -w'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias gcount='git shortlog --summary --numbered'
alias gclean='git clean --interactive -d'
alias gcl='git clone --recurse-submodules'
alias gta='git tag --annotate'
alias gtv='git tag | sort -V'
alias grf='git reflog'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtl='git worktree list'
alias gwtrm='git worktree remove'
alias gbs='git bisect'
alias gsu='git submodule update --init --recursive'

# ============================================
# GitHub CLI — inlined from the OMZ gh plugin
# ============================================
if _has_cmd gh; then
    alias ghpr='gh pr create -B $(git_main_branch) --fill-first -e'
    alias ghprv='gh pr view --web'
    alias ghprl='gh pr list'
    alias ghprc='gh pr checkout'
    alias ghprs='gh pr status'
    alias ghprm='gh pr merge --squash --delete-branch'
    alias ghrv='gh repo view --web'
    alias ghis='gh issue list'
    alias ghisv='gh issue view --web'
    alias ghrun='gh run list --limit 10'
    alias ghwatch='gh run watch'
fi

# ============================================
# Homebrew — inlined from the OMZ brew plugin
# ============================================
if _has_cmd brew; then
    alias ba='brew autoremove'
    alias bcfg='brew config'
    alias bci='brew info --cask'
    alias bcin='brew install --cask'
    alias bcl='brew list --cask'
    alias bcn='brew cleanup'
    alias bco='brew outdated --cask'
    alias bcrin='brew reinstall --cask'
    alias bcubc='brew upgrade --cask && brew cleanup'
    alias bcubo='brew update && brew outdated --cask'
    alias bcup='brew upgrade --cask'
    alias bdr='brew doctor'
    alias bfu='brew upgrade --formula'
    alias bi='brew install'
    alias bin='brew install'
    alias bih='brew install --HEAD'
    alias binf='brew info'
    alias bl='brew list'
    alias bls='brew list'
    alias bo='brew outdated'
    alias bout='brew outdated'
    alias br='brew reinstall'
    alias brewp='brew pin'
    alias brewsp='brew list --pinned'
    alias brh='brew reinstall --HEAD'
    alias bs='brew search'
    alias bsr='brew services run'
    alias bsl='brew services list'
    alias bsoff='brew services stop'
    alias bson='brew services start'
    alias bu='brew update'
    alias bun='brew uninstall'
    alias bubo='brew update && brew outdated'
    alias bubu='brew update && brew outdated && brew upgrade'
    alias bugbc='brew upgrade --greedy && brew cleanup'
    alias bup='brew update && brew upgrade && brew cleanup'
    alias buz='brew uninstall --zap'
fi

# ============================================
# Python — inlined from the OMZ python plugin
# ============================================
if _has_cmd python3; then
    alias py='python3'
    alias python='python3'
    alias pyfind='fd -e py'
    alias pyserver='python3 -m http.server'
    alias pyclean='fd -H -t d "__pycache__" -x rm -rf; fd -H -e pyc -x rm -f'
    alias pyver='python3 --version'
    if _has_cmd rg; then
        alias pygrep='rg --type py'
    else
        alias pygrep='grep -nr --include="*.py"'
    fi
fi

# ============================================
# pip — inlined from the OMZ pip plugin
# ============================================
if _has_cmd pip || _has_cmd pip3; then
    alias pipi='pip install'
    alias pipu='pip install --upgrade'
    alias pipun='pip uninstall'
    alias piplo='pip list -o'
    alias pipreq='pip freeze > requirements.txt'
    alias pipir='pip install -r requirements.txt'
    if _has_cmd rg; then
        alias pipgi='pip freeze | rg'
    else
        alias pipgi='pip freeze | grep'
    fi
fi

# ============================================
# Virtual environments
# ============================================
alias so-venv='source .venv/bin/activate'
alias va='source .venv/bin/activate'
alias vd='deactivate'
alias vc='python3 -m venv .venv && source .venv/bin/activate'
_has_cmd ipython && alias ipy='ipython'

# ============================================
# uv — fast Python package manager
# ============================================
if _has_cmd uv; then
    alias uvs='uv sync'
    alias uva='uv add'
    alias uvr='uv remove'
    alias uvl='uv lock'
    alias uvp='uv pip'
    alias uvpi='uv pip install'
    alias uvpu='uv pip install --upgrade'
    alias uvv='uv venv'
    alias uvrun='uv run'
    alias uvt='uv run pytest'
    alias uvtx='uv run pytest -x'          # stop on first failure
    alias uvfmt='uv run ruff format'
    alias uvlint='uv run ruff check --fix'
fi

# ============================================
# Ruff / testing
# ============================================
_has_cmd ruff && { alias rf='ruff format'; alias rc='ruff check --fix'; }
_has_cmd pytest && {
    alias pt='pytest'
    alias ptx='pytest -x'
    alias ptv='pytest -v'
    alias ptl='pytest --last-failed'
    alias ptk='pytest -k'
}

# ============================================
# npm / node — inlined from the OMZ npm plugin
# ============================================
if _has_cmd npm; then
    alias ni='npm install'
    alias nid='npm install --save-dev'
    alias nig='npm install --global'
    alias nun='npm uninstall'
    alias nrb='npm run build'
    alias nrd='npm run dev'
    alias nrs='npm run start'
    alias nrt='npm run test'
    alias nrl='npm run lint'
    alias nls='npm list --depth=0'
    alias nout='npm outdated'
fi
_has_cmd pnpm && { alias pn='pnpm'; alias pni='pnpm install'; alias pnd='pnpm dev'; }
_has_cmd yarn && { alias yi='yarn install'; alias yd='yarn dev'; }

# ============================================
# Docker — inlined from the OMZ docker-compose plugin
# ============================================
if _has_cmd docker; then
    alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias dpa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'
    alias dprune='docker system prune -af --volumes'
    alias dstop='docker stop $(docker ps -q)'

    alias dc='docker compose'
    alias dcu='docker compose up -d'
    alias dcub='docker compose up -d --build'
    alias dcd='docker compose down'
    alias dcdv='docker compose down -v'
    alias dcl='docker compose logs -f'
    alias dcp='docker compose ps'
    alias dcr='docker compose restart'
    alias dce='docker compose exec'
    alias dcb='docker compose build'
fi

# ============================================
# Make — cookiecutter project commands
# ============================================
alias mdp='make dev-prompt'
alias mdu='make dev-up'
alias mdb='make dev-build'
alias mdd='make dev-down'
alias mga='make generate-apis'
alias mt='make test'
alias ml='make lint'

# ============================================
# Clipboard — consistent names across platforms
# ============================================
# macOS gets pbcopy/pbpaste in os/macos.sh; these cover Linux/WSL.
if [ "$_dotfiles_is_msys" = 1 ]; then
    alias clip='clip.exe'
    alias paste='powershell.exe -command Get-Clipboard'
elif _has_cmd xclip; then
    alias clip='xclip -selection clipboard'
    alias paste='xclip -selection clipboard -o'
elif _has_cmd wl-copy; then
    alias clip='wl-copy'
    alias paste='wl-paste'
fi

# copypath / copyfile — inlined from the OMZ plugins of the same name
alias copypath='pwd | tr -d "\n" | clip'
alias copyfile='clip <'

# ============================================
# Misc tools
# ============================================
_has_cmd delta   && alias dd='delta'
_has_cmd lazygit && alias lg='lazygit'
_has_cmd lazydocker && alias ld='lazydocker'
_has_cmd btop    && alias top='btop'
_has_cmd htop    && alias htp='htop'
_has_cmd tldr    && alias '?'='tldr'
_has_cmd jq      && alias jqp='jq -C . | less -R'
_has_cmd hyperfine && alias bench='hyperfine'

if _has_cmd yt-dlp; then
    alias ydload='yt-dlp -U && cd "$HOME/Downloads" && yt-dlp --concurrent-fragments 4 -q --no-check-certificates -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --write-auto-sub --sub-lang en'
fi

# ============================================
# Commit helper
# ============================================
alias commitwell='zsh "${DOTFILES_DIR:-$HOME/.dotfiles}/common/commitwell.sh"'

unset _dotfiles_is_msys
