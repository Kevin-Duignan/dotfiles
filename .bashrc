# General
# =========

# Comment/Uncomment to use zsh as default
#if [ -t 1 ]; then
#  exec zsh
#fi

# Don't run twice
[[ $- != *i* ]] && return

# History like OMZ
shopt -s histappend
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Write history after every command
PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"

export HISTTIMEFORMAT='%F %T '

# Window size updates
shopt -s checkwinsize

# Load aliases (if present)
if [ -f ~/.bash_aliases ]; then
  source ~/.bash_aliases
fi

# =========
# Vi mode
# =========

set -o vi

export KEYTIMEOUT=1

bind -m vi-insert '"\C-l": clear-screen'
bind -m vi-command '"\C-l": clear-screen'
bind 'set show-mode-in-prompt on'

export KEYTIMEOUT=1

# =========
# Git (FAST, cached)
# =========

__GIT_BRANCH=""
__GIT_DIRTY=""
__GIT_LAST_DIR=""

__git_update_cache() {
  # Only recompute when directory changes
  [[ "$PWD" == "$__GIT_LAST_DIR" ]] && return
  __GIT_LAST_DIR="$PWD"

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    __GIT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null)"
    git diff --quiet 2>/dev/null || __GIT_DIRTY="*"
  else
    __GIT_BRANCH=""
    __GIT_DIRTY=""
  fi
}

# =========
# Colours
# =========

RESET='\[\e[0m\]'
BOLD='\[\e[1m\]'
DIM='\[\e[2m\]'

BLUE='\[\e[34m\]'
CYAN='\[\e[36m\]'
YELLOW='\[\e[33m\]'
RED='\[\e[31m\]'

# =========
# Prompt
# =========

PROMPT_COMMAND=prompt_command

prompt_command() {
  local EXIT="$?"

  __git_update_cache

  PS1=""

  # Path
  PS1+="${BOLD}${BLUE}\w${RESET}"

  # Git
  if [[ -n "$__GIT_BRANCH" ]]; then
    PS1+=" ${CYAN}(${__GIT_BRANCH}${YELLOW}${__GIT_DIRTY}${CYAN})${RESET}"
  fi

  # Exit status
  [[ "$EXIT" -ne 0 ]] && PS1+=" ${RED}✘${RESET}"

  # Newline + prompt char
  PS1+="\n${BOLD}❯ ${RESET}"
}

# =========
# Readline improvements
# =========

# Better tab completion
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"
bind "set menu-complete-display-prefix on"

# Ctrl+Backspace deletes word
bind '"\C-H": backward-kill-word'

# Faster history search
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ============================================
# Dotfiles — Load common aliases, functions, and OS config
# ============================================
DOTFILES_DIR="$HOME/.dotfiles"
[ -f "$DOTFILES_DIR/install.sh" ] && . "$DOTFILES_DIR/install.sh"

