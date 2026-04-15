# ============================================
# ~/.zshrc — Global Zsh Configuration
# ============================================
# This file is shared across macOS, WSL, and MSYS2.
# MSYS2 uses a lightweight fast-path that skips Oh My Zsh
# entirely (subprocess forks are 10-50x slower on Windows
# POSIX emulation). All other platforms use the full OMZ stack.
# ============================================

# ============================================
# Detect MSYS2 early (before any heavy work)
# ============================================
_DOTFILES_IS_MSYS2=0
case "$(uname -s)" in
    MINGW*|MSYS*) _DOTFILES_IS_MSYS2=1 ;;
esac

# ============================================
# Powerlevel10k Instant Prompt (all platforms)
# Must stay near the top — no console input below this.
# ============================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================
# History (shared — all platforms)
# ============================================
HISTFILE="$HOME/.zsh_history"
HIST_STAMPS="mm/dd/yyyy"
if (( _DOTFILES_IS_MSYS2 )); then
    # Smaller history = faster startup on NTFS
    HISTSIZE=50000
    SAVEHIST=50000
else
    HISTSIZE=10000000
    SAVEHIST=10000000
fi
setopt APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
SHELL_SESSION_HISTORY=0

# ##########################################################
# MSYS2 FAST PATH — skip Oh My Zsh, load features directly
# ##########################################################
if (( _DOTFILES_IS_MSYS2 )); then

    export ZSH="$HOME/.oh-my-zsh"
    _ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

    # --------------------------------------------------
    # Completions — cached compinit (once per day)
    # --------------------------------------------------
    autoload -Uz compinit
    _comp_dump="$HOME/.zcompdump"
    # Regenerate only if older than 24h (stat -c on MSYS2)
    if [[ -f "$_comp_dump" ]]; then
        # MSYS2 stat uses GNU coreutils format
        _dump_age=$(( $(date +%s) - $(stat -c %Y "$_comp_dump" 2>/dev/null || echo 0) ))
        if (( _dump_age > 86400 )); then
            compinit -d "$_comp_dump"
        else
            compinit -C -d "$_comp_dump"   # -C = skip security check, use cache
        fi
    else
        compinit -d "$_comp_dump"
    fi
    unset _comp_dump _dump_age

    # --------------------------------------------------
    # Vi-mode (replaces OMZ vi-mode plugin)
    # --------------------------------------------------
    bindkey -v
    export KEYTIMEOUT=1

    # --------------------------------------------------
    # Colored man pages (replaces OMZ colored-man-pages)
    # --------------------------------------------------
    export LESS_TERMCAP_mb=$'\e[1;31m'
    export LESS_TERMCAP_md=$'\e[1;36m'
    export LESS_TERMCAP_me=$'\e[0m'
    export LESS_TERMCAP_so=$'\e[01;33m'
    export LESS_TERMCAP_se=$'\e[0m'
    export LESS_TERMCAP_us=$'\e[1;32m'
    export LESS_TERMCAP_ue=$'\e[0m'

    # --------------------------------------------------
    # Powerlevel10k — load directly (no OMZ theme engine)
    # --------------------------------------------------
    _p10k_theme="$_ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme"
    [[ -f "$_p10k_theme" ]] && source "$_p10k_theme"
    unset _p10k_theme

    # --------------------------------------------------
    # Plugins — source directly (no OMZ plugin loader)
    # Only the three that matter most for interactive use.
    # --------------------------------------------------
    # zsh-autosuggestions
    _plug="$_ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    [[ -f "$_plug" ]] && source "$_plug"

    # zsh-syntax-highlighting (must be near last)
    _plug="$_ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    [[ -f "$_plug" ]] && source "$_plug"

    # you-should-use (alias reminders)
    _plug="$_ZSH_CUSTOM/plugins/you-should-use/you-should-use.plugin.zsh"
    [[ -f "$_plug" ]] && source "$_plug"

    unset _plug _ZSH_CUSTOM

    # --------------------------------------------------
    # P10k config
    # --------------------------------------------------
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    # --------------------------------------------------
    # FZF — cache the init script instead of forking
    # --------------------------------------------------
    _fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-init.zsh"
    if (( ${+commands[fzf]} )); then
        if [[ ! -f "$_fzf_cache" || "${commands[fzf]}" -nt "$_fzf_cache" ]]; then
            mkdir -p "${_fzf_cache:h}"
            fzf --zsh > "$_fzf_cache" 2>/dev/null
        fi
        [[ -f "$_fzf_cache" ]] && source "$_fzf_cache"
        export FZF_DEFAULT_OPTS="--ansi --layout=reverse --border=rounded --height=60%"
        (( ${+commands[fd]} )) && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    fi
    unset _fzf_cache

    # --------------------------------------------------
    # Dotfiles — common aliases, functions, OS config
    # --------------------------------------------------
    DOTFILES_DIR="$HOME/.dotfiles"
    [ -f "$DOTFILES_DIR/install.sh" ] && . "$DOTFILES_DIR/install.sh"

    unset _DOTFILES_IS_MSYS2
    return 0   # ← stop here, skip the OMZ section below
fi
unset _DOTFILES_IS_MSYS2

# ##########################################################
# STANDARD PATH — macOS / WSL / Linux (full Oh My Zsh)
# ##########################################################

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    # --- Active ---
    vi-mode
    you-should-use
    zsh-autosuggestions
    zsh-syntax-highlighting

    # --- Disabled (redundant with dotfiles or direct init below) ---
    # aliases          # → common/aliases.sh covers all aliases
    # brew             # → os/macos.sh sets up Homebrew FPATH directly
    # celery           # → niche; enable if actively using celery CLI
    # colored-man-pages # → appearance only
    # command-not-found # → slow (queries package DB on every miss)
    # copyfile         # → trivial one-liner, rarely used
    # copypath         # → trivial one-liner, rarely used
    # git              # → common/aliases.sh defines all git shortcuts
    # octozen          # → novelty / motivational quotes
    # pip              # → slow completion init, rarely needed interactively
    # python           # → just a few aliases
    # zoxide           # → eval "$(zoxide init zsh)" is called directly below
)

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Use bat for man
export MANPAGER="bat -plman"


# FZF Default Options
export FZF_DEFAULT_OPTS="--ansi --layout=reverse --border=rounded --height=60%"

# Improve Ctrl+t command to ignore hidden files/directories
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
DISABLE_FZF_KEY_BINDINGS="true"
source <(fzf --zsh)

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FPATH="~/.eza/completions/zsh:$FPATH"
export PATH="~/.local/bin/:$PATH"
eval "$(zoxide init zsh)"

# ============================================
# Dotfiles — Load common aliases, functions, and OS config
# ============================================
DOTFILES_DIR="$HOME/.dotfiles"
[ -f "$DOTFILES_DIR/install.sh" ] && . "$DOTFILES_DIR/install.sh"

