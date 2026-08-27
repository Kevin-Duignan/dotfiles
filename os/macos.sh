#!/bin/sh
# ============================================
# macOS-Specific Configuration
# ============================================
# Oh My Zsh is NOT used. Prompt, plugins, history and completions
# are configured in ~/.zshrc. This file handles macOS-specific
# environment, tool init and aliases only.
#
# Performance rule: nothing here may fork a subprocess at startup.
# Anything that needs a tool's output is cached — see the
# completion cache section below.
# ============================================

# ============================================
# Homebrew — set up without forking
# ============================================
# `eval "$(brew shellenv)"` costs a fork plus Ruby startup on every
# shell. Its output is static for a given install prefix, so we
# just set the variables directly.
if [ -x /opt/homebrew/bin/brew ]; then
    HOMEBREW_PREFIX="/opt/homebrew"          # Apple Silicon
elif [ -x /usr/local/bin/brew ]; then
    HOMEBREW_PREFIX="/usr/local"             # Intel
fi

if [ -n "$HOMEBREW_PREFIX" ]; then
    export HOMEBREW_PREFIX
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"

    _path_prepend "$HOMEBREW_PREFIX/bin"
    _path_prepend "$HOMEBREW_PREFIX/sbin"
    export PATH

    export MANPATH="$HOMEBREW_PREFIX/share/man:${MANPATH-}"
    export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH-}"

    # Homebrew's zsh completions. Adding to FPATH is free; compinit
    # in ~/.zshrc picks them up.
    if [ -n "$ZSH_VERSION" ] && [ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]; then
        fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
    fi

    # GNU coreutils, if installed — gives GNU ls/date/sed semantics
    # instead of the BSD ones, which matters for portable scripts.
    if [ -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" ]; then
        _path_prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
        export PATH
        export MANPATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman:$MANPATH"
    fi
fi

# ============================================
# Completion cache
# ============================================
# Tools like gh, op, docker and uv generate their zsh completions
# by running a subprocess. Doing that at startup costs 50-200ms
# combined. Instead we generate each one ONCE into a cache
# directory that is already on FPATH, and only regenerate when the
# tool's binary is newer than the cached file.
#
# Rebuild manually at any time with:  dotfiles-doctor completions
if [ -n "$ZSH_VERSION" ] && [ "${DOTFILES_IS_AGENT:-0}" != "1" ]; then
    _dot_compdir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
    [ -d "$_dot_compdir" ] || command mkdir -p "$_dot_compdir"

    # _dot_gen_comp <tool> <outfile-name> <command...>
    #
    #   Fast path (the normal case): the cache file exists and the
    #   tool's binary is no newer than it — do nothing at all. No
    #   fork, no subprocess, roughly zero cost.
    #
    #   Slow path (first run, or after a tool upgrade): generate in
    #   the BACKGROUND with &! so startup never waits. The new
    #   completion becomes available in the next shell.
    #
    #   A .failed marker is written when generation produces
    #   nothing. Without it, a tool whose completion command errors
    #   would be retried on every single startup, forever.
    _dot_gen_comp() {
        _gc_tool="$1"; _gc_out="$_dot_compdir/$2"; shift 2
        _has_cmd "$_gc_tool" || { unset _gc_tool _gc_out; return 0; }

        _gc_bin="${commands[$_gc_tool]}"

        # Up to date — nothing to do.
        if [ -s "$_gc_out" ] && [ ! "$_gc_bin" -nt "$_gc_out" ]; then
            unset _gc_tool _gc_out _gc_bin; return 0
        fi
        # Previously failed for this exact binary — don't retry.
        if [ -f "$_gc_out.failed" ] && [ ! "$_gc_bin" -nt "$_gc_out.failed" ]; then
            unset _gc_tool _gc_out _gc_bin; return 0
        fi

        # Generate out of band; this shell carries on immediately.
        #
        # Written as `&` followed by `disown` rather than zsh's `&!`
        # shorthand. This file is #!/bin/sh and bash PARSES all of
        # it even though the block only RUNS under zsh — and `&!` is
        # a syntax error in bash, which would kill the entire file.
        {
            if "$@" > "$_gc_out.tmp" 2>/dev/null && [ -s "$_gc_out.tmp" ]; then
                mv -f "$_gc_out.tmp" "$_gc_out"
                rm -f "$_gc_out.failed"
            else
                rm -f "$_gc_out.tmp"
                : > "$_gc_out.failed"
            fi
        } &
        # Detach so the job does not get SIGHUP'd when the shell exits.
        disown 2>/dev/null || true

        unset _gc_tool _gc_out _gc_bin
    }

    _dot_gen_comp gh      _gh      gh completion -s zsh
    _dot_gen_comp op      _op      op completion zsh
    _dot_gen_comp uv      _uv      uv generate-shell-completion zsh
    _dot_gen_comp uvx     _uvx     uvx --generate-shell-completion zsh
    _dot_gen_comp docker  _docker  docker completion zsh
    _dot_gen_comp kubectl _kubectl kubectl completion zsh
    _dot_gen_comp rustup  _rustup  rustup completions zsh
    _dot_gen_comp poetry  _poetry  poetry completions zsh

    unset -f _dot_gen_comp 2>/dev/null
    unset _dot_compdir
fi

# eza ships its own completions.
if [ -n "$ZSH_VERSION" ] && [ -d "$HOME/.eza/completions/zsh" ]; then
    fpath=("$HOME/.eza/completions/zsh" $fpath)
fi

# ============================================
# Tool initialisation — cached, no forks
# ============================================
# _dot_cache_eval is defined in ~/.zshrc. It runs the command once,
# writes the output to a cache file, byte-compiles it, and sources
# that file on every later startup.
if [ -n "$ZSH_VERSION" ] && command -v _dot_cache_eval >/dev/null 2>&1; then

    # zoxide — smart cd. Was 20ms as an eval, ~1ms cached.
    #
    # _ZO_DOCTOR=0 suppresses zoxide's "initialize me last" warning.
    # That warning is a false positive here: zoxide is initialised
    # from os/macos.sh (~/.zshrc section 9) and the line-editor
    # plugins deliberately load after it in section 13, which is the
    # order zsh-syntax-highlighting requires. Left enabled, zoxide
    # writes four lines to stderr on EVERY shell startup, which is
    # stray output that terminal shell-integration handshakes (Warp
    # among them) can choke on.
    export _ZO_DOCTOR=0
    _has_cmd zoxide && _dot_cache_eval zoxide zoxide init zsh

    # fzf — key bindings and completion. Was 80ms via the OMZ
    # plugin (which searched the filesystem for fzf), ~1ms cached.
    #
    # Guarded on a real terminal: fzf's key bindings call `setopt
    # zle`, which fails noisily in a shell with no tty (`zsh -i -c`,
    # or an interactive shell with stdin redirected). Key bindings
    # are useless there anyway.
    if _has_cmd fzf && [ -t 0 ]; then
        _dot_cache_eval fzf fzf --zsh
    fi

    # direnv — per-directory environments, if installed.
    _has_cmd direnv && _dot_cache_eval direnv direnv hook zsh

    # atuin — better shell history, if installed.
    _has_cmd atuin && _dot_cache_eval atuin atuin init zsh --disable-up-arrow
fi

# ============================================
# Pagers / diff
# ============================================
if _has_cmd bat; then
    export MANPAGER="bat -plman"
    export BAT_THEME="${BAT_THEME:-ansi}"
fi

# delta as the git pager, when installed.
if _has_cmd delta; then
    export GIT_PAGER='delta'
fi

# ============================================
# macOS clipboard — names consistent with the Windows envs
# ============================================
alias clip='pbcopy'
alias paste='pbpaste'

# ============================================
# MacVim
# ============================================
# `vim` opens the MacVim GUI, reusing the existing window as a new
# tab. This is the long-standing behaviour here and it is what the
# muscle memory expects.
#
# Note that /opt/homebrew/bin/vim is ALSO MacVim — Homebrew's
# macvim formula installs a terminal build of vim alongside the
# .app. So without this alias `vim` still runs MacVim, just the
# console version, which is why "vim stopped opening MacVim" looks
# like the GUI vanished rather than the binary changing.
#
# $EDITOR is deliberately pinned to the terminal binary below.
# Aliases are not consulted when git, fc or edit-command-line spawn
# $EDITOR, but pinning the full path makes that explicit and
# guarantees those callers get an editor that BLOCKS — which
# -p --remote-silent does not.
if _has_cmd mvim; then
    mvim() {
        command mvim --remote-silent-tab "$@"
    }
    alias vim='mvim'
    alias gvim='mvim'
    alias gvimrc='mvim ~/.gvimrc'

    # Blocking, in-terminal vim for anything that waits on $EDITOR.
    alias vimt='command vim'
    export EDITOR="${commands[vim]:-vim}"
    export VISUAL="$EDITOR"
    export GIT_EDITOR="$EDITOR"

    # Custom tools use the GUI function to open files in tabs
    export GUI_EDITOR="mvim"
fi

# ============================================
# Shell config shortcuts
# ============================================
alias rl='exec zsh'                # full restart, avoids double-sourcing

# ============================================
# macOS utilities
# ============================================
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias afk='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
alias cleanup='find . -type f -name "*.DS_Store" -ls -delete'
alias emptytrash='sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl'
alias o='open'
alias oo='open .'
alias finder='open -a Finder .'
alias sleepnow='pmset sleepnow'
alias battery='pmset -g batt'
alias caff='caffeinate -dimsu'     # keep the Mac awake until Ctrl-C

# Quick Look a file from the terminal.
ql() { qlmanage -p "$@" >/dev/null 2>&1; }

# ============================================
# AWS
# ============================================
# The CodeArtifact token is handled lazily in common/lazy.sh.
_path_append "$HOME/.aws"
export PATH

if _has_cmd aws; then
    alias awsw='aws sts get-caller-identity'
    alias awsl='aws sso login --profile'
    alias awsp='echo "${AWS_PROFILE:-<unset>}"'
fi

# ============================================
# Project directories
# ============================================
export PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Developer}"
_path_append "$HOME/Developer/commitwell"
export PATH
