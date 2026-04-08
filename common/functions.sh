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

# HVSD-specific branch creation function
gswhv() {
    if [ -z "$1" ]; then
        echo "Usage: gcohv <ticket-number>"
        return 1
    fi
    git checkout -b "HVSD-$1"
}

commit() {
    # 0. Pre-flight Check: Is this a Git Repo?
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "\033[0;31mError: This directory is not a Git repository.\033[0m"
        return 1
    fi

    # 1. Check if anything is actually staged
    if git diff --cached --quiet; then
        echo "\033[0;31mNo changes staged. Use 'git add' before committing.\033[0m"
        return 1
    fi

    # 2. Review Stage (Visual Audit)
    echo "\033[0;32m--- Reviewing Staged Changes ---\033[0m"
    if command -v bat >/dev/null 2>&1; then
        # bat for syntax-highlighted diffs if available
        git diff --cached --name-only --relative --diff-filter=d -z | xargs -0 bat
    else
        # Fallback to standard git diff (forcing color for a better experience)
        git diff --cached --color=always
    fi

    # 3. Hook Validation (Runs automatically after Review)
    echo "\033[0;34m--- Running Pre-commit Hooks (Linting/Formatting) ---\033[0m"
    if ! git commit --dry-run --short > /dev/null 2>&1; then
        echo "\033[0;31m❌ Hooks failed! Review errors below:\033[0m"
        # Run again without silence to show logs
        git commit --dry-run
        return 1
    fi
    echo "\033[0;32m✅ Hooks passed!\033[0m"

    # 4. Get current branch and extract ticket
    local branch potential_ticket_id
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
    potential_ticket_id=$(echo $branch | grep -oE '[A-Z]+-[0-9]+')

    # 5. Select scope
    local selection scope
    selection=$(printf "None\nJira Ticket ID: %s\nBranch Name: %s\nCustom..." "$potential_ticket_id" "$branch" | \
        fzf --height=15% --prompt="Select scope: " --layout=reverse)

    case "$selection" in
        "Custom...") vared -p "Enter custom scope: " scope; scope=$(echo "$scope" | tr '[:lower:]' '[:upper:]') ;;
        "None") scope="" ;;
        "Jira Ticket ID: "*) scope="$potential_ticket_id" ;;
        "Branch Name: "*) scope="$branch" ;;
        *) scope="$selection" ;;
    esac

    # 6. Choose components to include
    local mode
    mode=$(printf "None\nBoth (Type & Emoji)\nType Only\nEmoji Only" | \
        fzf --height=15% --prompt="Include components: " --layout=reverse)

    local type_val="" emoji_val=""
    local gitmoji_file="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/.gitmoji-list.txt"

    if [[ "$mode" != "None" && -f "$gitmoji_file" ]]; then
        local selected_line
        selected_line=$(fzf --prompt="Select Gitmoji/Type: " < "$gitmoji_file")

        if [ -n "$selected_line" ]; then
            emoji_val=$(echo "$selected_line" | awk '{print $1}')
            type_val=$(echo "$selected_line" | awk '{print $2}')
        fi
    fi

    [[ "$mode" == "Emoji Only" ]] && type_val=""
    [[ "$mode" == "Type Only" ]] && emoji_val=""
    [[ "$mode" == "None" ]] && { type_val=""; emoji_val=""; }

    # 7. Get Messages
    local header=""
    while [[ -z "$header" ]]; do
        vared -p "Commit message: " header
    done

    local description=""
    vared -p "Commit description (optional): " description

    # 8. Footer Functionality (New)
    local f_selection footer_content footer=""
    f_selection=$(printf "None\nBreaking Change\nCo-authored-by\nReference Link\nCustom..." | \
        fzf --height=15% --prompt="Select footer type: " --layout=reverse)

    case "$f_selection" in
        "Breaking Change")
            vared -p "Describe the breaking change: " footer_content
            footer="BREAKING CHANGE: $footer_content" ;;
        "Co-authored-by")
            vared -p "Enter author (Name <email>): " footer_content
            footer="Co-authored-by: $footer_content" ;;
        "Reference Link")
            vared -p "Enter URL: " footer_content
            footer="Refs: $footer_content" ;;
        "Custom...")
            vared -p "Enter custom footer: " footer ;;
        *) footer="" ;;
    esac

    # 9. Formatting Logic
    local first_line=""
    if [ -n "$type_val" ]; then
        first_line="$type_val"
        [ -n "$scope" ] && first_line+="($scope)"
        first_line+=": "
        [ -n "$emoji_val" ] && first_line+="$emoji_val "
    else
        [ -n "$scope" ] && first_line+="$scope "
        [ -n "$emoji_val" ] && first_line+="$emoji_val "
    fi

    first_line+="$header"
    first_line=$(echo "$first_line" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')

    # 10. Execute Commit
    local commit_args=(-m "$first_line")
    [[ -n "$description" ]] && commit_args+=(-m "$description")
    [[ -n "$footer" ]] && commit_args+=(-m "$footer")

    git commit "${commit_args[@]}"
}

# List git emojis
alias gmoji='cat $ZSH_CUSTOM/.gitmoji-list.txt'

# Interactive open commands using fzf
vimi() {
  vim "$(fzf)"
}

openi() {
  open "$(fzf)"
}

# 'With fzf' function to run fzf before the next command
wfzf() {
  local selected_file
  selected_file="$(fzf --multi)"
  if [[ -n "$selected_file" ]]; then
    "$1" "$selected_file"
  fi
}

ffzf() {
  fd --type f --hidden --follow --exclude .git | \
  fzf --multi --preview '~/.vim/plugged/fzf/bin/fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'
}

fzfdlog() {
  local service
  service=$(docker compose ps --services | fzf --prompt='Select service > ')
  [[ -n "$service" ]] && docker compose logs -n 100000 "$service" | \
    sed 's/^[^[]*\[//' | tac | \
    fzf --ansi --bind "ctrl-r:reload(docker compose logs -n 100000 $service | sed 's/^[^[]*\[//' | tac)"
}

_y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

y() {
  if [ "$1" != "" ]; then
    if [ -d "$1" ]; then
      _y "$1"
    else
      _y "$(zoxide query $1)"
    fi
  else
    _y
  fi
    return $?
}

batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}
