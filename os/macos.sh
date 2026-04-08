#!/bin/zsh
# ============================================
# macOS-Specific Configuration
# Shell: Zsh (default on macOS)
# ============================================
# NOTE: Oh My Zsh, Powerlevel10k, plugins, and history
# are configured in ~/.zshrc — this file handles only
# macOS-specific environment, tools, and aliases.
# ============================================

# ============================================
# Homebrew Environment
# ============================================
if [ -f /opt/homebrew/bin/brew ]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v brew >/dev/null 2>&1; then
    # Homebrew completions for Zsh
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

    alias bup='brew update && brew upgrade && brew cleanup'
    alias bout='brew outdated'
    alias bin='brew install'
    alias bun='brew uninstall'
    alias bls='brew list'
    alias bsr='brew search'
    alias binf='brew info'
    alias bdr='brew doctor'
fi

# ============================================
# macOS Clipboard Aliases (consistency w/ Windows envs)
# ============================================
alias clip='pbcopy'
alias paste='pbpaste'

# ============================================
# MacVim Aliases
# ============================================
if command -v mvim >/dev/null 2>&1; then
    alias vim='mvim'
    alias mvim='mvim --remote-tab-silent'
    alias gvimrc='mvim ~/.gvimrc'
fi

# ============================================
# Shell Config Shortcuts (Zsh on macOS)
# ============================================
alias rl='source ~/.zshrc'
alias zshrc='${EDITOR:-vim} ~/.zshrc'
alias vimrc='${EDITOR:-vim} ~/.vimrc'

# ============================================
# macOS-Specific Utilities
# ============================================
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias afk='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
alias cleanup='find . -type f -name "*.DS_Store" -ls -delete'
alias emptytrash='sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl'

# ============================================
# bat as man pager
# ============================================
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="bat -plman"
fi

# ============================================
# eza completions
# ============================================
if [ -d "$HOME/.eza/completions/zsh" ]; then
    export FPATH="$HOME/.eza/completions/zsh:$FPATH"
fi

# ============================================
# 1Password CLI completions (guarded)
# ============================================
if command -v op >/dev/null 2>&1; then
    eval "$(op completion zsh)"; compdef _op op
fi

# ============================================
# Tool Initializations (guarded)
# ============================================

# fzf keybindings & completion
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_OPTS="--ansi --layout=reverse --border=rounded --height=60%"
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    fi
    # Use fzf's native Zsh integration (0.48+)
    DISABLE_FZF_KEY_BINDINGS="true"
    source <(fzf --zsh) 2>/dev/null
    [ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
fi

# zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    source "$NVM_DIR/bash_completion"
fi

# uv (fast Python package manager)
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

# pyenv
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# ============================================
# PATH additions (macOS-specific)
# ============================================
export PATH="$HOME/.local/bin:$PATH"

# GNU coreutils (if installed via brew)
if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null)"
    if [ -d "$_brew_prefix/opt/coreutils/libexec/gnubin" ]; then
        export PATH="$_brew_prefix/opt/coreutils/libexec/gnubin:$PATH"
    fi
    unset _brew_prefix
fi

