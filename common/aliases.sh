#!/bin/sh
# ============================================
# Common Aliases — Shared across all environments
# Sourced by: macOS (Zsh), WSL (Zsh/Bash), Git Bash, MSYS2 (Zsh)
# ============================================

# ============================================
# Safer File Operations
# ============================================
alias mkdir='mkdir -pv'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================
# ls Aliases (use eza/exa if available, else fallback)
# ============================================
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -alh --icons --group-directories-first'
    alias la='eza -a --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
elif command -v exa >/dev/null 2>&1; then
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
# grep with Color
# ============================================
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ============================================
# System / Shell
# ============================================
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'

# ============================================
# Git Shortcuts
# ============================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gba='git branch -a'
alias gst='git stash'
alias gstp='git stash pop'
alias gf='git fetch --all --prune'

if command -v gh >/dev/null 2>&1; then
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
if command -v ipython >/dev/null 2>&1; then
    alias ipy='ipython'
fi

# ============================================
# uv — fast Python package manager (guarded)
# ============================================
if command -v uv >/dev/null 2>&1; then
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
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi

if command -v zoxide >/dev/null 2>&1; then
    alias cd='z'
fi

if command -v yt-dlp >/dev/null 2>&1; then
    alias ydload='yt-dlp -U && cd "$HOME/Downloads" && yt-dlp --concurrent-fragments 4 -q --no-check-certificates -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --write-auto-sub --sub-lang en'
fi

# ============================================
# Commit Helper (commitwell.sh)
# ============================================
alias commit='zsh "${DOTFILES_DIR:-$HOME/.dotfiles}/common/commitwell.sh"'

# ============================================
# Docker Shortcuts (guarded)
# ============================================
if command -v docker >/dev/null 2>&1; then
    alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias dpa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"'
    alias dcu='docker compose up -d'
    alias dcd='docker compose down'
    alias dcl='docker compose logs -f'
fi
