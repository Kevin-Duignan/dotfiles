#!/usr/bin/env zsh
# --- 0. Graceful Exit Handler ---
# This catches Ctrl+C and ensures you just exit to the prompt
trap "echo '\n\033[0;31mCommit cancelled.\033[0m'; exit 1" INT

# --- 1. Pre-flight Check: Is this a Git Repo? ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "\033[0;31mError: This directory is not a Git repository.\033[0m"
    exit 1
fi

# --- 2. Check if anything is actually staged ---
if git diff --cached --quiet; then
    echo "\033[0;31mNo changes staged. Use 'git add' before committing.\033[0m"
    exit 1
fi

# --- 2.5. Fail Fast: Run pre-commit on staged files ---
# This ensures we don't continue to review/format only to discover pre-commit fails later.
echo "\033[0;34m--- Running pre-commit on staged files ---\033[0m"
if ! command -v pre-commit >/dev/null 2>&1; then
    echo "\033[0;31mError: 'pre-commit' is not installed or not on PATH.\033[0m"
    echo "Install it (e.g., 'pip install pre-commit' or your package manager) and try again."
    trap - INT
    exit 1
fi

# Collect staged files (excluding deleted ones) and run pre-commit only on those.
# If nothing is captured, we still bail (though earlier guard would have caught that).
staged_files=("${(@f)$(git diff --cached --name-only --diff-filter=d)}")

if (( ${#staged_files[@]} > 0 )); then
    # Run pre-commit only against staged files; show diff on failure, keep colors
    if ! pre-commit run --show-diff-on-failure --color always --files "${staged_files[@]}"; then
        echo "\033[0;31m❌ pre-commit checks failed.\033[0m"
        echo "Fix the issues above, re-stage your changes, and re-run the script."
        trap - INT
        exit 1
    fi
else
    echo "\033[0;31mNo non-deleted staged files to check.\033[0m"
    trap - INT
    exit 1
fi
echo "\033[0;32m✅ pre-commit passed!\033[0m"

# --- 3. Review Stage ---
echo "\033[0;32m--- Reviewing Staged Changes (press 'q' to proceed) ---\033[0m"

# Allow overriding context lines; default to 0 (only changed lines)
CONTEXT_LINES="${CONTEXT_LINES:-0}"

if command -v bat >/dev/null 2>&1; then
  # Show only staged hunks, zero (or minimal) context, with nice diff highlighting in bat
  git diff --cached --relative --diff-filter=d \
           --color=always --unified="${CONTEXT_LINES}" \
    | bat -l diff --paging=always -p
else
  # Fallback: colorized diff with zero (or minimal) context in less
  git diff --cached --relative --diff-filter=d \
           --color=always --unified="${CONTEXT_LINES}" \
    | less -R
fi

# --- 4. Hook Validation (Automatic) ---
# Still useful in case you have other non–pre-commit hooks configured.
echo "\033[0;34m--- Running Pre-commit Hooks (Linting/Formatting) ---\033[0m"
if ! git commit --dry-run --short > /dev/null 2>&1; then
    echo "\033[0;31m❌ Hooks failed! Review errors below:\033[0m"
    git commit --dry-run
    trap - INT # Clean up trap before exiting
    exit 1
fi
echo "\033[0;32m✅ Hooks passed!\033[0m"

# --- 5. Extract Ticket ---
branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/devnull)
potential_ticket_id=$(echo "$branch" | grep -oiE '[A-Z]+-[0-9]+' | tr '[:lower:]' '[:upper:]' || echo "")

# --- 6. Select Scope ---
# Initialize variables first so vared doesn't complain
selection=""
scope=""
menu_list=""

[[ -n "$potential_ticket_id" ]] && menu_list="${potential_ticket_id} (Jira Ticket ID)\n"
menu_list="${menu_list}None\n${branch} (Branch)\nCustom..."

selection=$(printf "$menu_list" | fzf --height=15% --prompt="Select scope: " --layout=reverse)

case "$selection" in
    "Custom...") 
        vared -p "Enter custom scope: " scope
        scope=$(echo "$scope") 
        ;;
    "None"|"" ) 
        scope="" 
        ;;
    *"(Jira Ticket ID)") 
        scope="$potential_ticket_id" 
        ;;
    *"(Branch)") 
        scope="$branch" 
        ;;
    *) 
        scope="" 
        ;;
esac

# --- 7. Choose Components & Select Emoji/Type ---
mode=$(printf "None\nBoth (Type & Emoji)\nType Only\nEmoji Only" | fzf --height=15% --prompt="Include components: " --layout=reverse)
type_val="" emoji_val=""
gitmoji_file="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/.gitmoji-list.txt"

if [[ "$mode" != "None" && -f "$gitmoji_file" ]]; then
    selected_line=$(fzf --prompt="Select Gitmoji/Type: " < "$gitmoji_file")
    if [[ -n "$selected_line" ]]; then
        emoji_val=$(echo "$selected_line" | awk '{print $1}')
        type_val=$(echo "$selected_line" | awk '{print $2}')
    fi
fi
[[ "$mode" == "Emoji Only" ]] && type_val=""
[[ "$mode" == "Type Only"  ]] && emoji_val=""
[[ "$mode" == "None"       ]] && { type_val=""; emoji_val=""; }

# --- 8. Messages ---
header=""
while [[ -z "$header" ]]; do vared -p "Commit message: " header; done
description=""
vared -p "Description (optional): " description

# --- 9. Footer ---
f_selection=$(printf "None\nBreaking Change\nCo-authored-by\nReference Link\nCustom..." | fzf --height=15% --prompt="Select footer type: " --layout=reverse)
footer_content=""
footer=""
case "$f_selection" in
    "Breaking Change") vared -p "Describe the breaking change: " footer_content; footer="BREAKING CHANGE: $footer_content" ;;
    "Co-authored-by") vared -p "Enter author (Name <email>): " footer_content; footer="Co-authored-by: $footer_content" ;;
    "Reference Link") vared -p "Enter URL: " footer_content; footer="Refs: $footer_content" ;;
    "Custom...") vared -p "Enter custom footer: " footer ;;
    *) footer="" ;;
esac

# --- 10. Formatting & Execution ---
first_line=""
if [[ -n "$type_val" ]]; then
    first_line="$type_val"
    [[ -n "$scope" ]] && first_line+="($scope)"
    first_line+=": "
    [[ -n "$emoji_val" ]] && first_line+="$emoji_val "
else
    [[ -n "$scope" ]] && first_line+="$scope "
    [[ -n "$emoji_val" ]] && first_line+="$emoji_val "
fi
first_line+="$header"
first_line=$(echo "$first_line" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')

commit_args=(-m "$first_line")
[[ -n "$description" ]] && commit_args+=(-m "$description")
[[ -n "$footer"      ]] && commit_args+=(-m "$footer")

git commit "${commit_args[@]}"

# --- 11. Clean up ---
trap - INT
