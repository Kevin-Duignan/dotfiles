# ============================================
# Directory Navigation Aliases
# ============================================
# alias cd='z'

# ============================================
# File and Directory Aliases
# ============================================
alias mkdir='mkdir -pv'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================
# System Aliases
# ============================================
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias rl='source ~/.zshrc'
alias zshrc='vim ~/.zshrc'
alias zshals='vim $ZSH_CUSTOM/aliases.zsh'
alias vimrc='vim ~/.vimrc'

# ============================================
# MacVim Aliases
# ============================================
alias vim='mvim' # Use MacVim Always
alias mvim='mvim --remote-tab-silent'
alias gvimrc='vim ~/.gvimrc'

# ============================================
# Make Aliases (WSP Cookiecutter Make Commands)
# ============================================
alias mdp='make dev-prompt'
alias mdu='make dev-up'
alias mdb='make dev-build'
alias mdd='make dev-down'
alias mga='make generate-apis'

# Python virtual environment activate
alias so-venv='source .venv/bin/activate'

# Ipython alias
alias ipy='ipython'

alias ydload='yt-dlp -U & cd $HOME/Downloads && yt-dlp --concurrent-fragments 4 -q --no-check-certificates -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --write-auto-sub --sub-lang en'

alias ghpr='gh pr create -B $(git_main_branch) --fill-first -e --template=pull_request_template.md'