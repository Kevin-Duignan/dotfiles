#!/bin/sh
# ============================================
# Common Aliases — Shared across all environments
# Sourced by: macOS (Zsh), WSL (Zsh/Bash), Git Bash, MSYS2 (Zsh)
# ============================================

# ============================================
# Fast tool detection helper
# Uses Zsh's built-in $commands hash (instant, no fork)
# when available; falls back to command -v for POSIX shells.
# ============================================
if [ -n "$ZSH_VERSION" ]; then
    _has_cmd() { (( ${+commands[$1]} )); }
else
    _has_cmd() { command -v "$1" >/dev/null 2>&1; }
fi

# ============================================
# Safer File Operations (with faster replacements)
# ============================================
alias mkdir='mkdir -pv'

# cp → xcp (parallel, reflink-aware copy)
if _has_cmd xcp; then
    alias cp='xcp'
else
    alias cp='cp -i'
fi

# rm → rip (rm-improved: safer rm with graveyard)
if _has_cmd rip; then
    alias rm='rip'
else
    alias rm='rm -i'
fi

alias mv='mv -i'

# ============================================
# sed → sd (simpler syntax, faster)
# ============================================
if _has_cmd sd; then
    alias sed='sd'
fi

# ============================================
# du → dust (intuitive disk usage)
# ============================================
if _has_cmd dust; then
    alias du='dust'
fi

# ============================================
# top/ps → procs (better process viewer)
# ============================================
if _has_cmd procs; then
    alias ps='procs'
fi

# ============================================
# curl → xh (httpie-like, fast HTTP client)
# ============================================
if _has_cmd xh; then
    alias http='xh'
    alias https='xh --https'
fi

# ============================================
# diff → delta (beautiful diffs, also used as git pager)
# ============================================
if _has_cmd delta; then
    alias diff='delta'
fi

# ============================================
# MSYS2 / Git Bash: Windows-native tool wrappers
# ============================================
# Tools installed via winget (eza, bat, fd, etc.) are Windows
# binaries that don't understand MSYS2 Unix paths (/c/Users/…).
# Since MSYS_NO_PATHCONV=1 disables automatic conversion, we
# wrap these tools with a helper that converts path arguments
# via cygpath before invoking the real binary.
# ============================================
_dotfiles_is_msys=0
case "$(uname -s)" in
    MINGW*|MSYS*) _dotfiles_is_msys=1 ;;
esac

# _win_wrap <cmd> [args...]
# Converts any argument that looks like a Unix path (starts with /)
# to a Windows path, then calls the real binary.
if [ "$_dotfiles_is_msys" = 1 ] && _has_cmd cygpath; then
    _win_wrap() {
        local cmd="$1"; shift
        local args=()
        for arg in "$@"; do
            case "$arg" in
                /*) args+=("$(cygpath -w "$arg")") ;;
                *)  args+=("$arg") ;;
            esac
        done
        command "$cmd" "${args[@]}"
    }
fi

# ============================================
# ls Aliases (use eza/exa if available, else fallback)
# ============================================
# On MSYS/Git Bash, the default profile sets
#   alias ls='ls --show-control-chars'
# which causes "eza: Unknown argument --show-control-chars"
# when our alias/function is layered on top. Remove it first.
if [ "$_dotfiles_is_msys" = 1 ]; then
    unalias ls ll la lt 2>/dev/null
fi

if _has_cmd eza; then
    if [ "$_dotfiles_is_msys" = 1 ] && _has_cmd cygpath; then
        # Wrapper functions so eza receives Windows paths.
        # Use "function" keyword to prevent Bash from expanding
        # any pre-existing aliases during function definition.
        function ls  { _win_wrap eza --icons --group-directories-first "$@"; }
        function ll  { _win_wrap eza -alh --icons --group-directories-first "$@"; }
        function la  { _win_wrap eza -a --icons --group-directories-first "$@"; }
        function lt  { _win_wrap eza --tree --level=2 --icons "$@"; }
    else
        alias ls='eza --icons --group-directories-first'
        alias ll='eza -alh --icons --group-directories-first'
        alias la='eza -a --icons --group-directories-first'
        alias lt='eza --tree --level=2 --icons'
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
# grep / ripgrep
# ============================================
if _has_cmd rg; then
    alias grep='rg --color=auto'
    alias fgrep='rg --fixed-strings --color=auto'
    alias egrep='rg --color=auto'
    # Convenience: recursive grep (rg already recurses by default)
    alias rga='rg --hidden --no-ignore'
    alias rgi='rg --ignore-case'
else
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ============================================
# System / Shell
# ============================================
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias zshrc='vim ~/.zshrc'
alias zshloc='vim ~/.zshrc.local'
alias zshals='vim ${DOTFILES_DIR:-$HOME/.dotfiles}/common/aliases.sh'
alias zshfunc='vim ${DOTFILES_DIR:-$HOME/.dotfiles}/common/functions.sh'
alias bashrc='vim ~/.bashrc'
alias vimrc='vim ~/.vimrc'
alias p10k-cfg='vim ${DOTFILES_DIR:-$HOME/.dotfiles}/.p10k.zsh'
alias dotfiles='cd ${DOTFILES_DIR:-$HOME/.dotfiles} && git pull'
alias dotsync='(cd ${DOTFILES_DIR:-$HOME/.dotfiles} && git pull) && \
  ln -sf ${DOTFILES_DIR:-$HOME/.dotfiles}/.zshrc    ~/.zshrc && \
  ln -sf ${DOTFILES_DIR:-$HOME/.dotfiles}/.p10k.zsh ~/.p10k.zsh && \
  ln -sf ${DOTFILES_DIR:-$HOME/.dotfiles}/.vimrc    ~/.vimrc && \
  ln -sf ${DOTFILES_DIR:-$HOME/.dotfiles}/.bashrc   ~/.bashrc && \
  echo "✅ Dotfiles synced (symlinked)." && \
  if [ -n "$ZSH_VERSION" ]; then source ~/.zshrc; else source ~/.bashrc; fi'
alias dotsync-cp='(cd ${DOTFILES_DIR:-$HOME/.dotfiles} && git pull) && \
  cp ${DOTFILES_DIR:-$HOME/.dotfiles}/.zshrc    ~/.zshrc && \
  cp ${DOTFILES_DIR:-$HOME/.dotfiles}/.p10k.zsh ~/.p10k.zsh && \
  cp ${DOTFILES_DIR:-$HOME/.dotfiles}/.vimrc    ~/.vimrc && \
  cp ${DOTFILES_DIR:-$HOME/.dotfiles}/.bashrc   ~/.bashrc && \
  echo "✅ Dotfiles synced (copied)." && \
  if [ -n "$ZSH_VERSION" ]; then source ~/.zshrc; else source ~/.bashrc; fi'

# ============================================
# Git Aliases (most-used from OMZ git plugin)
# ============================================
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

alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias 'gc!'='git commit --verbose --amend'
alias gcam='git commit --all --message'
alias gcmsg='git commit --message'
alias gcn='git commit --verbose --no-edit'

alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'

alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'

alias gd='git diff'
alias gds='git diff --staged'
alias gdca='git diff --cached'
alias gdw='git diff --word-diff'

alias gf='git fetch'
alias gfa='git fetch --all --tags --prune'
alias gfo='git fetch origin'

alias gl='git pull'
alias gpr='git pull --rebase'
alias gpra='git pull --rebase --autostash'
alias gprom='git pull --rebase origin $(git_main_branch)'

alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpv='git push --verbose'
alias gpod='git push origin --delete'

alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glo='git log --oneline --decorate'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glg='git log --stat'

alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'

alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbs='git rebase --skip'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'

alias grh='git reset'
alias grhh='git reset --hard'
alias grhs='git reset --soft'

alias grs='git restore'
alias grst='git restore --staged'

alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'

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

# ============================================
# Homebrew Aliases (from OMZ brew plugin)
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
    alias bih='brew install --HEAD'
    alias bl='brew list'
    alias bo='brew outdated'
    alias br='brew reinstall'
    alias brewp='brew pin'
    alias brewsp='brew list --pinned'
    alias brh='brew reinstall --HEAD'
    alias bs='brew search'
    alias bsl='brew services list'
    alias bsoff='brew services stop'
    alias bson='brew services start'
    alias bsr='brew services run'
    alias bu='brew update'
    alias bubo='brew update && brew outdated'
    alias bubu='bubo && bup'
    alias bugbc='brew upgrade --greedy && brew cleanup'
    alias bup='brew upgrade'
    alias buz='brew uninstall --zap'
fi

# ============================================
# History Aliases (from OMZ history plugin)
# ============================================
if _has_cmd rg; then
    alias hs='history | rg'
    alias hsi='history | rg -i'
else
    alias hs='history | grep'
    alias hsi='history | grep -i'
fi

# ============================================
# Pip Aliases (from OMZ pip plugin)
# ============================================
if _has_cmd pip || _has_cmd pip3; then
    alias pipi='pip install'
    alias pipu='pip install --upgrade'
    alias pipun='pip uninstall'
    if _has_cmd rg; then
        alias pipgi='pip freeze | rg'
    else
        alias pipgi='pip freeze | grep'
    fi
    alias piplo='pip list -o'
    alias pipreq='pip freeze > requirements.txt'
    alias pipir='pip install -r requirements.txt'
fi

# ============================================
# Python Aliases (from OMZ python plugin)
# ============================================
if _has_cmd python3; then
    alias py='python3'
    alias pyfind='find . -name "*.py"'
    if _has_cmd rg; then
        alias pygrep='rg --type py'
    else
        alias pygrep='grep -nr --include="*.py"'
    fi
    alias pyserver='python3 -m http.server'
fi


if _has_cmd gh; then
    alias ghpr='gh pr create -B $(git_main_branch) --fill-first -e --template=pull_request_template.md'
fi

# ============================================
# Make Aliases (Cookiecutter Make Commands)
# ============================================
alias mdp='make dev-prompt'
alias mdu='make dev-up'
alias mdb='make dev-build'
alias mdd='make dev-down'
alias mga='make generate-apis'

# ============================================
# Python / Virtual Environments
# ============================================
alias so-venv='source .venv/bin/activate'
if _has_cmd ipython; then
    alias ipy='ipython'
fi

# ============================================
# uv — fast Python package manager (guarded)
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
    alias uvx='uvx'
    alias uvrun='uv run'
fi

# ============================================
# Misc Tools (guarded)
# ============================================
if _has_cmd bat; then
    if [ "$_dotfiles_is_msys" = 1 ] && _has_cmd cygpath; then
        function cat { _win_wrap bat --paging=never "$@"; }
    else
        alias cat='bat --paging=never'
    fi
fi

if _has_cmd zoxide; then
    alias cd='z'
fi

if _has_cmd yt-dlp; then
    alias ydload='yt-dlp -U && cd "$HOME/Downloads" && yt-dlp --concurrent-fragments 4 -q --no-check-certificates -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --write-auto-sub --sub-lang en'
fi

# ============================================
# Commit Helper (commitwell.sh)
# ============================================
alias commitwell='zsh "${DOTFILES_DIR:-$HOME/.dotfiles}/common/commitwell.sh"'

# ============================================
# Docker Shortcuts (guarded)
# ============================================
if _has_cmd docker; then
    alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias dpa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"'
    alias dcu='docker compose up -d'
    alias dcd='docker compose down'
    alias dcl='docker compose logs -f'
fi

unset _dotfiles_is_msys

