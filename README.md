# 🗂️ .dotfiles

A modular, multi-environment dotfiles repository that keeps macOS, Windows WSL,
Windows Git Bash, and Windows MSYS2 in sync from a single source of truth.
Interactive Zsh starts in **~100ms**; the same config in a script or under an AI
agent starts in **~8ms**.

**Contents** — [Performance](#performance) · [How It Works](#how-it-works) ·
[Prerequisites](#prerequisites) · [Installation](#installation) ·
[Terminal Configuration](#terminal-configuration) ·
[Machine-Specific Overrides](#machine-specific-overrides) ·
[Alias Quick Reference](#alias-quick-reference) · [Vim](#vim) ·
[Key Bindings](#key-bindings-zsh) · [Troubleshooting](#troubleshooting) ·
[For AI Agents](#for-ai-agents) · [Updating](#updating)

```
~/.dotfiles/
├── .bashrc                 # Bash shell config (Git Bash / WSL fallback)
├── .zshrc                  # Zsh shell config  (macOS / WSL / Linux / MSYS2)
│                           #   Oh My Zsh's core is NOT loaded on any platform —
│                           #   plugins are sourced directly. See "Performance".
├── .p10k.zsh               # Powerlevel10k prompt config (all Zsh envs)
├── .vimrc                  # Vim editor config (all environments)
├── install.sh              # Entry point — detects OS, sources everything
│                           #   in a deliberate order (see comments in the file)
├── common/
│   ├── env.sh              # _has_cmd, PATH helpers, locale, XDG dirs, fzf
│   │                       #   config, the shared _dot_cache_eval helper
│   ├── aliases.sh          # Cross-platform aliases (ls, git, docker, uv…)
│   ├── functions.sh        # Cross-platform functions (extract, mkcd, yazi,
│   │                       #   fzf pickers, jira, dotsync…)
│   ├── lazy.sh             # Lazy loaders: AWS CodeArtifact, nvm, pyenv,
│   │                       #   thefuck, conda — nothing here forks at startup
│   ├── ai.sh               # Claude Code helpers, `devinfo`, 1Password-backed
│   │                       #   key loading, agent-safe execution helpers
│   └── commitwell.sh       # Interactive git commit wizard (standalone script)
├── os/
│   ├── macos.sh            # Homebrew (no fork), completion cache, MacVim,
│   │                       #   cached zoxide/fzf/direnv init, macOS utils
│   ├── wsl.sh              # Windows interop, clip.exe, wslpath helpers
│   ├── gitbash.sh          # Minimal / fast-start config for Git Bash
│   └── msys2.sh            # pacman, cygpath, cached tool inits, lazy nvm
├── tools/
│   └── dotfiles-doctor     # bench / profile / trace / completions / clean /
│                           #   check / link
├── claude/
│   └── skills/
│       └── kevin-shell-environment/   # Claude Code skill: teaches agents
│                           #   which tools you prefer and where the sharp
│                           #   edges are. Linked into ~/.claude/skills/.
├── local.sh.example        # Template for the file below
└── local.sh                # (create manually) Machine-specific overrides — git-ignored
```

---

## Performance

Interactive shell startup went from **~2.6 seconds to ~95-105ms** — a 25x
speedup — without dropping any tool, alias or function. Non-interactive shells
(scripts, CI, AI agents) come in at **~8ms**. The three rules that keep it
that way:

1. **Never fork a subprocess at startup.** Anything that used to run
   `eval "$(tool init)"` on every shell now runs once, caches the output to
   `~/.cache/zsh/`, and sources the cache. See `_dot_cache_eval` in
   `common/env.sh`.
2. **Never eagerly source a tool's init script if a lazy stub will do.**
   `common/lazy.sh` covers the worst offenders: the AWS CodeArtifact token
   fetch (was 1.2s of *network I/O* on every shell — now fetched on demand
   and cached for 11 hours), nvm (~0.7s), pyenv and thefuck.
3. **Aliases and functions are free.** Defining one costs microseconds, not
   milliseconds — it's the subprocess forks and eagerly-sourced init scripts
   that cost time. `common/aliases.sh` inlines every alias a heavy Oh My Zsh
   plugin used to provide, without loading the plugin.

AI coding agents (Claude Code, Cursor, Aider) are detected via `$CLAUDECODE`
and similar env vars and take an even faster path — no prompt, no syntax
highlighting, no autosuggestions, no audited `compinit`, since none of that is
agent-visible. Agents run every command through your login shell, so that
saving compounds hard across a session. Aliases, functions and `$PATH` are
identical either way.

Check and benchmark your own setup any time:

```bash
dotfiles-doctor check        # symlinks, syntax, tools, startup cost
dotfiles-doctor bench        # 10-run startup benchmark
dotfiles-doctor profile      # find what got slow (zprof)
dotfiles-doctor trace        # line-by-line timing, slowest 30 lines
dotfiles-doctor completions  # rebuild the tool completion cache
dotfiles-doctor clean        # clear every cache, then `exec zsh`
```

Or via the aliases: `dotdoctor`, `dotbench`.

---

## How It Works

1. Your shell RC file (`~/.zshrc` or `~/.bashrc`) sets up the shell itself — instant prompt, history, completions, key bindings.
2. Partway through, it sources `~/.dotfiles/install.sh`.
3. `install.sh` auto-detects the environment and loads, **in this order**:
   - **`common/env.sh`** — first, because it defines `_has_cmd`, `_path_prepend` and `_dot_cache_eval`, which everything below depends on.
   - **`common/aliases.sh`**, then **`common/functions.sh`** — so a function can override an alias of the same name.
   - **`common/ai.sh`** — Claude Code shortcuts, `devinfo`, 1Password key loading.
   - **`os/<detected>.sh`** — environment-specific config (Homebrew on macOS, `clip.exe` on WSL, `pacman` on MSYS2).
   - **`common/lazy.sh`** — *after* the OS file, so the nvm and pyenv PATH shims land in front of Homebrew rather than behind it.
   - **`local.sh`** (if it exists) — secrets, tokens and machine-specific overrides that are never committed.
4. Back in `~/.zshrc`, the line-editor plugins and Powerlevel10k load — after `install.sh`, so syntax highlighting can see every alias and function.

### Three startup paths

The `.zshrc` is shared across macOS, WSL, Linux and MSYS2. **Oh My Zsh's core
is never loaded on any of them** — the handful of plugins worth having are
sourced directly from `~/.oh-my-zsh/custom/plugins`, which skips OMZ's loader,
`compaudit` and 20+ library files.

What differs is *who* is running the shell:

| Path | When | What loads |
|------|------|------------|
| **Non-interactive** | `$-` has no `i` — scripts, `zsh -c`, scp/rsync, CI | `install.sh` only (env, aliases, functions, OS file, lazy stubs), then `return`. No prompt, completions or plugins. **~8ms.** |
| **AI agent** | `$CLAUDECODE`, `$AI_AGENT`, `$CURSOR_TRACE_ID`, `$AIDER_MODEL`, or `$TERM_PROGRAM == vscode-agent` | Everything except the human-facing layer: unaudited `compinit -C`, a plain `%~ %#` prompt, and no autosuggestions / syntax highlighting / you-should-use. |
| **Interactive** | Everything else | The full set: P10k instant prompt, audited `compinit` (once per 24h, byte-compiled), vi key bindings, `install.sh`, then the four plugins and Powerlevel10k. **~95-105ms.** |

Platform only changes two things: history size (50k on MSYS2, where NTFS makes
a large history file slow to load; 1M elsewhere) and which `os/*.sh` file gets
sourced.

```
┌──────────────────────────────────────────────────────────────┐
│  ~/.zshrc                                                    │
│                                                              │
│  §0  non-interactive?  ──►  install.sh, return  (~8ms)       │
│  §1  platform detect (via $OSTYPE — no fork)                 │
│  §2  P10k instant prompt                                     │
│  §3  cache helpers                                           │
│  §4  agent detect  ──►  sets DOTFILES_IS_AGENT               │
│  §5  history          (MSYS2: 50k │ others: 1M)              │
│  §6  shell options                                           │
│  §7  completions      (agent: -C │ human: audited, 24h TTL)  │
│  §8  key bindings     (vi by default; DOTFILES_VI_MODE=0)    │
│  §9  install.sh  ────────────────────────────┐               │
│  §10 plugins          (skipped for agents)   │               │
│  §11 prompt           (P10k │ agents: plain) │               │
│  §12 ~/.zshrc.local                          │               │
│  §13 syntax highlighting — MUST BE LAST      │               │
│  §14 Warp subshell hook — MUST BE VERY LAST  │               │
└──────────────────────────────────────────────┼───────────────┘
                                               │
         install.sh loads, in order:           │
   ┌───────────────────────────────────────────▼─────┐
   │  common/env.sh        ← _has_cmd, PATH, cache   │
   │  common/aliases.sh                              │
   │  common/functions.sh                            │
   │  common/ai.sh                                   │
   ├─────────────────────────────────────────────────┤
   │  os/macos.sh    ← Darwin                        │
   │  os/wsl.sh      ← Linux + $WSL_DISTRO_NAME      │
   │  os/gitbash.sh  ← MINGW/CYGWIN, no pacman       │
   │  os/msys2.sh    ← MINGW/MSYS with pacman        │
   ├─────────────────────────────────────────────────┤
   │  common/lazy.sh  ← LAST, so nvm/pyenv PATH wins │
   │  local.sh        ← if it exists                 │
   └─────────────────────────────────────────────────┘
```

> **Plugins loaded (interactive, non-agent only):** `you-should-use`,
> `zsh-autosuggestions`, Oh My Zsh's `aliases` plugin (gives you `als`, a
> grouped alias cheatsheet), and `zsh-syntax-highlighting` — which must load
> last, because it wraps every ZLE widget that exists at the moment it loads.

> **`commitwell.sh`** is a standalone Zsh script, not sourced. Invoke it with
> the `commitwell` alias.


---

## Prerequisites

The following tools are **expected** on every environment. All config files guard against missing tools with `_has_cmd` checks (which uses Zsh's instant `$commands[]` hash on Zsh, or `command -v` on Bash), so nothing will break if a tool is absent — you just won't get that feature.

| Tool | Purpose | macOS | WSL (Ubuntu) | Windows (winget) |
|------|---------|-------|--------------|------------------|
| **Git** | Version control | `brew install git` | `sudo apt install git` | Pre-installed (Git Bash) / `winget install Git.Git` |
| **[uv](https://docs.astral.sh/uv/)** | Fast Python package manager | `brew install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `winget install astral-sh.uv` |
| **[fzf](https://github.com/junegunn/fzf)** | Fuzzy finder | `brew install fzf` | `sudo apt install fzf` | `winget install junegunn.fzf` |
| **[fd](https://github.com/sharkdp/fd)** | Fast `find` (used by fzf) | `brew install fd` | `sudo apt install fd-find` | `winget install sharkdp.fd` |
| **[ripgrep](https://github.com/BurntSushi/ripgrep)** | Fast `grep` replacement | `brew install ripgrep` | `sudo apt install ripgrep` | `winget install BurntSushi.ripgrep` |
| **[bat](https://github.com/sharkdp/bat)** | Cat with syntax highlighting | `brew install bat` | `sudo apt install bat` | `winget install sharkdp.bat` |
| **[eza](https://github.com/eza-community/eza)** | Modern `ls` replacement | `brew install eza` | [eza deb repo](#2--windows-wsl--ubuntu-zsh) | `winget install eza-community.eza` |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | Smarter `cd` | `brew install zoxide` | `curl -sSfL .../install.sh \| sh` | `winget install ajeetdsouza.zoxide` |
| **[xcp](https://github.com/tarka/xcp)** | Fast, parallel `cp` | `brew install xcp` | `cargo install xcp` | `cargo install xcp` |
| **[sd](https://github.com/chmln/sd)** | Fast `sed` replacement | `brew install sd` | `cargo install sd` | `winget install chmln.sd` |
| **[dust](https://github.com/bootandy/dust)** | Intuitive `du` replacement | `brew install dust` | `cargo install du-dust` | `winget install bootandy.dust` |
| **[delta](https://github.com/dandavison/delta)** | Beautiful `diff` / git pager | `brew install git-delta` | `cargo install git-delta` | `winget install dandavison.delta` |
| **[rm-improved](https://github.com/nivekuil/rip)** | Safer, faster `rm` | `brew install rm-improved` | `cargo install rm-improved` | `cargo install rm-improved` |
| **[procs](https://github.com/dalance/procs)** | Better `ps` replacement | `brew install procs` | `cargo install procs` | `winget install dalance.procs` |
| **[xh](https://github.com/ducaale/xh)** | Fast HTTP client (`curl` alt) | `brew install xh` | `cargo install xh` | `winget install ducaale.xh` |
| **[yazi](https://github.com/sxyazi/yazi)** | Terminal file manager | `brew install yazi` | Binary download / cargo | `winget install sxyazi.yazi` |
| **[pre-commit](https://pre-commit.com/)** | Git hook framework | `brew install pre-commit` | `uv tool install pre-commit` | `uv tool install pre-commit` |
| **[gh](https://cli.github.com/)** | GitHub CLI (`ghpr`, `ghrun`…) | `brew install gh` | `sudo apt install gh` | `winget install GitHub.cli` |

Optional, but wired up if present:

| Tool | Purpose | macOS |
|------|---------|-------|
| **[MacVim](https://macvim.org/)** | GUI Vim; `vim` is aliased to it | `brew install macvim` |
| **[1Password CLI](https://developer.1password.com/docs/cli/)** | Backs `opkey` / `aikeys` / `opr` | `brew install --cask 1password-cli` |
| **[jq](https://jqlang.github.io/jq/)** | `devinfo --pretty`, `jqp` | `brew install jq` |
| **[direnv](https://direnv.net/)** | Per-directory env, cached init | `brew install direnv` |
| **[atuin](https://atuin.sh/)** | Better shell history, cached init | `brew install atuin` |
| **[lazygit](https://github.com/jesseduffield/lazygit)** / **[lazydocker](https://github.com/jesseduffield/lazydocker)** | `lg` / `ld` | `brew install lazygit lazydocker` |
| **[btop](https://github.com/aristocratos/btop)** | Aliased over `top` | `brew install btop` |
| **[tldr](https://tldr.sh/)** | Aliased to `?` | `brew install tldr` |
| **[hyperfine](https://github.com/sharkdp/hyperfine)** | `bench` | `brew install hyperfine` |

> **Windows note:** `winget` is pre-installed on Windows 10 (1709+) and Windows 11. It installs to system-wide paths and requires no admin for per-user packages. Git Bash is the exception — it uses a **portable download** that needs zero admin rights and zero package managers.

---

## Installation

### 1 · macOS (Zsh)

**Clone the repo:**

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

**Install Homebrew** (if not already present):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Install Oh My Zsh:**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

> Oh My Zsh is installed but **never loaded**. The `.zshrc` only uses it as a
> place to keep plugins (`~/.oh-my-zsh/custom/plugins/`) plus its `aliases`
> plugin, and sources those files directly. Its installer will offer to
> overwrite `~/.zshrc` — that's fine, the symlink step below replaces it.

**Install Powerlevel10k theme:**

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

**Install required custom OMZ plugins:**

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
```

> These three, plus Oh My Zsh's bundled `aliases` plugin, are the complete
> plugin set — `.zshrc` section 10 sources exactly those and nothing else.
> Note the destination directory is `you-should-use`, not `zsh-you-should-use`.

**Install CLI tools via Homebrew:**

```bash
brew install fzf fd ripgrep bat eza zoxide xcp sd dust git-delta rm-improved procs xh yazi uv gh vim macvim pre-commit
```

**Install vim-plug** (Vim plugin manager):

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

**Create required Vim directories:**

```bash
mkdir -p ~/.vim/{backup,swap,undo}
```

**Symlink the config files:**

```bash
~/.dotfiles/tools/dotfiles-doctor link
```

That backs up any existing `~/.zshrc`, `~/.p10k.zsh`, `~/.vimrc` and `~/.bashrc`
to `<name>.pre-dotfiles.<timestamp>`, symlinks the repo copies into `$HOME`, and
links `claude/skills/*` into `~/.claude/skills/` so the shell-environment skill
applies in every repo.

<details>
<summary>Or do it by hand</summary>

```bash
[ -f ~/.zshrc ]    && mv ~/.zshrc ~/.zshrc.bak
[ -f ~/.p10k.zsh ] && mv ~/.p10k.zsh ~/.p10k.zsh.bak
[ -f ~/.vimrc ]    && mv ~/.vimrc ~/.vimrc.bak

ln -sfn ~/.dotfiles/.zshrc    ~/.zshrc
ln -sfn ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
ln -sfn ~/.dotfiles/.vimrc    ~/.vimrc
```
</details>

**Install Vim plugins:**

```bash
vim +PlugInstall +qall
```

**Reload your shell:**

```bash
source ~/.zshrc
```

**Configure Powerlevel10k** (runs automatically on first launch, or manually):

```bash
p10k configure
```

---

### 2 · Windows WSL — Ubuntu (Zsh)

> Run all commands inside your WSL terminal.

**Clone the repo:**

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

**Install Zsh:**

```bash
sudo apt update && sudo apt install -y zsh
chsh -s "$(which zsh)"
```

**Install Oh My Zsh:**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

> Oh My Zsh is installed but **never loaded**. The `.zshrc` only uses it as a
> place to keep plugins (`~/.oh-my-zsh/custom/plugins/`) plus its `aliases`
> plugin, and sources those files directly. Its installer will offer to
> overwrite `~/.zshrc` — that's fine, the symlink step below replaces it.

**Install Powerlevel10k theme:**

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

**Install required custom OMZ plugins:**

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
```

> These three, plus Oh My Zsh's bundled `aliases` plugin, are the complete
> plugin set — `.zshrc` section 10 sources exactly those and nothing else.
> Note the destination directory is `you-should-use`, not `zsh-you-should-use`.

**Install CLI tools:**

```bash
sudo apt install -y fzf fd-find ripgrep bat vim

# fd is packaged as 'fdfind' on Ubuntu — create symlink
sudo ln -sf "$(which fdfind)" /usr/local/bin/fd

# bat is packaged as 'batcat' on Ubuntu — create symlink
sudo ln -sf "$(which batcat)" /usr/local/bin/bat
```

**Install tools not in apt** (via their official installers):

```bash
# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# eza
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo apt update && sudo apt install -y eza

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# yazi (via cargo, or download binary)
curl -LsSf https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip -o /tmp/yazi.zip \
  && unzip /tmp/yazi.zip -d /tmp/yazi && sudo mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/

# Fast replacements (via cargo — install Rust first if needed: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)
cargo install xcp sd du-dust git-delta rm-improved procs xh
```

**Install vim-plug:**

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

**Create required Vim directories:**

```bash
mkdir -p ~/.vim/{backup,swap,undo}
```

**Symlink the config files:**

```bash
~/.dotfiles/tools/dotfiles-doctor link
```

Same as on macOS: existing files are backed up to `<name>.pre-dotfiles.<timestamp>`
before being replaced by symlinks.

**Install Vim plugins:**

```bash
vim +PlugInstall +qall
```

**Restart your terminal** (or run `exec zsh`).

> **Tip:** Install a [Nerd Font](https://www.nerdfonts.com/) in Windows Terminal for Powerlevel10k icons to render correctly. `MesloLGS NF` is recommended.

---

### 3 · Windows Git Bash (Bash — Minimal, Fast-Start)

Git Bash is the **quickest, simplest way** to get a Unix-like shell on Windows. It is ideal for locked-down machines or when you want a portable, zero-admin setup. No extra plugins, no fancy tools—just Bash, Git, and your shared dotfiles.

#### 3a. Install Git Bash (choose one method)

**Option 1: Standard Installer**

1. Go to [git-scm.com/download/win](https://git-scm.com/download/win).
2. Download the regular **Git for Windows** installer and run it. This will install Git Bash to your system.
3. Launch Git Bash from the Start menu.

**Option 2: Portable (Thumbdrive Edition)**

1. On the same [download page](https://git-scm.com/download/win), under **Other Git for Windows downloads**, click **Portable ("thumbdrive edition")** → **64-bit Git for Windows Portable**.
2. Run the downloaded `.exe` (self-extracting archive, **not** an installer). Extract it to a folder you control, e.g.:
   ```
   C:\Users\<you>\tools\PortableGit
   ```
3. Launch Git Bash via:
   ```
   C:\Users\<you>\tools\PortableGit\git-bash.exe
   ```

> **Tip:** Pin `git-bash.exe` to your taskbar or create a shortcut. You can also add the `bin/` folder to your Windows PATH via User Environment Variables (no admin) to get `git`, `bash`, `curl`, `vim`, etc. available in PowerShell and `cmd`.

#### 3b. (Optional) Install uv (Python package manager)

If you want the `uv` Python package manager:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

This installs to `~/.local/bin/` which is already on PATH via `os/gitbash.sh`.

#### 3c. (Optional) Install zoxide (smarter `cd`)

Git Bash has no built-in package manager, so pick whichever fits your machine:

**Method 1 — winget (if available on your system):**

```bash
winget install ajeetdsouza.zoxide
```

**Method 2 — manual binary (portable Git Bash / no winget / locked-down machine):**

```bash
mkdir -p ~/.local/bin
curl -Lo /tmp/zoxide.zip "$(curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \
  | grep -o 'https://[^"]*x86_64-pc-windows-msvc\.zip')"
unzip -o /tmp/zoxide.zip -d ~/.local/bin
rm /tmp/zoxide.zip
```

`~/.local/bin` is already on `PATH` via `os/gitbash.sh`.

#### 3d. Clone the repo

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

#### 3e. (Optional) Install vim-plug (Vim plugin manager)

If you want to use Vim plugins, install vim-plug (optional):

**Method 1 — curl:**

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

**Method 2 — git clone (if curl is blocked by a corporate proxy):**

```bash
git clone --depth 1 https://github.com/junegunn/vim-plug.git /tmp/vim-plug
mkdir -p ~/.vim/autoload
cp /tmp/vim-plug/plug.vim ~/.vim/autoload/plug.vim
rm -rf /tmp/vim-plug
```

#### 3f. Create Vim directories

```bash
mkdir -p ~/.vim/{backup,swap,undo}
```

#### 3g. Copy the config files

Git Bash cannot create symlinks without admin rights, so **copy** the files instead:

```bash
cp ~/.dotfiles/.bashrc ~/.bashrc
cp ~/.dotfiles/.vimrc  ~/.vimrc
```

> **Keeping in sync:** once the dotfiles are loaded you get `dotsync-cp`, which
> pulls the repo, re-copies the tracked files into `$HOME` and restarts the
> shell. Use that instead of re-running the copy commands by hand. (`dotsync`
> is the symlinking version — don't use it here, Git Bash can't make symlinks
> without admin rights.)

#### 3h. (Optional) Install Vim plugins

If you installed vim-plug and want plugins:

```bash
vim +PlugInstall +qall
```

#### 3i. Restart Git Bash

Close and reopen `git-bash.exe`. You should see your custom prompt and all shared aliases.

> **Note:** `.zshrc` is not used on Git Bash — it runs Bash only. All shared aliases and functions still load via `install.sh` → `common/*.sh` → `os/gitbash.sh`.

---

### 4 · Windows MSYS2 (Zsh — Lightweight)

> **Why MSYS2 over Git Bash?** MSYS2 gives you `pacman`, a real package manager, plus Zsh with autosuggestions, syntax highlighting, Powerlevel10k, fzf and zoxide — a full-featured dev shell on Windows. MSYS2's POSIX emulation layer makes subprocess forks 10–50× slower than native Unix, which is exactly the cost this config is built to avoid, so it holds up here.

#### What you get (vs Git Bash)

| Feature | Git Bash | MSYS2 (Zsh) |
|---------|----------|-------------|
| Shell | Bash only | **Zsh** |
| Prompt | Basic | **Powerlevel10k** (instant prompt) |
| Autosuggestions | ✗ | **✓** (zsh-autosuggestions) |
| Syntax highlighting | ✗ | **✓** (zsh-syntax-highlighting) |
| Alias reminders | ✗ | **✓** (you-should-use) |
| Fuzzy finder | Manual binary | **fzf** with keybindings + cached init |
| Smart cd | Manual binary | **zoxide** with cached init |
| Package manager | ✗ | **pacman** |
| Completions | Basic | **Zsh compinit** (cached, audited once a day) |
| Vi-mode | ✗ | **✓** (`bindkey -v`, with cursor-shape feedback) |
| Colored man pages | ✗ | **✓** (`bat` as `MANPAGER`) |
| nvm / node | ✗ | **✓** (default version on PATH; `nvm` itself lazy) |

#### What makes it fast

MSYS2's POSIX emulation layer makes every subprocess fork and file-stat 10–50×
slower than on native Unix, so anything that shells out at startup hurts far
more here than on macOS. The same techniques the rest of this repo uses just
matter more:

1. **Oh My Zsh is never loaded** — on any platform, MSYS2 included. The four
   plugins are sourced directly, skipping OMZ's loader, `compaudit` and 20+
   library files.
2. **`compinit` is cached** — the full audited run happens once every 24 hours;
   every other startup uses `-C`, which skips the security scan. The dump is
   byte-compiled in the background.
3. **P10k loads directly** — sourced from `$ZSH_CUSTOM/themes/`, not through
   OMZ's theme engine.
4. **Tool init scripts are cached** — `zoxide init zsh`, `fzf --zsh` and
   `uv generate-shell-completion zsh` run once into `~/.cache/zsh/` and are
   re-sourced from there, regenerating only when the binary is newer.
5. **nvm is not sourced at all** — `common/lazy.sh` puts the default Node
   version's `bin` directly on `PATH`, so `node`/`npm`/`npx` are instant, and
   only the `nvm` command itself pays the ~700ms load on first use.
6. **`$commands[]` for tool detection** — Zsh's built-in hash table, rather than
   `command -v`, which scans the entire `$PATH` on every call.
7. **Smaller history** — 50k lines instead of 1M, because NTFS makes a large
   history file slow to load.

`os/msys2.sh` adds the MSYS2-only pieces on top: `MSYS_NO_PATHCONV` and
`MSYS2_ARG_CONV_EXCL` so arguments starting with `/` aren't mangled,
`GIT_DISCOVERY_ACROSS_FILESYSTEM` for git on NTFS, `pacman` aliases, and
`towinpath` / `tounixpath`.

> **Native Windows tools:** `eza`, `bat` and friends installed via `winget` are
> native Windows binaries — they don't understand `/c/Users/...` paths. On MSYS2
> the `ls`/`ll`/`la`/`lt`/`cat` wrappers route their arguments through `cygpath`
> first (`_win_wrap` in `common/aliases.sh`), so those commands take Unix paths
> like everywhere else.

#### Installation

**Install MSYS2** from [msys2.org](https://www.msys2.org/), or via winget:

```powershell
winget install MSYS2.MSYS2
```

**Open an MSYS2 UCRT64 or MINGW64 terminal.**

**Install Zsh and tools via pacman:**

```bash
pacman -Syu
pacman -S zsh git vim curl
```

**Install tools not in pacman** — run these in PowerShell (not inside MSYS2):

```powershell
winget install junegunn.fzf
winget install sharkdp.fd
winget install sharkdp.bat
winget install BurntSushi.ripgrep
winget install astral-sh.uv
winget install eza-community.eza
winget install ajeetdsouza.zoxide
winget install sxyazi.yazi
winget install chmln.sd
winget install bootandy.dust
winget install dandavison.delta
winget install dalance.procs
winget install ducaale.xh
# xcp and rm-improved: install via cargo (winget not available)
# cargo install xcp rm-improved
```

> `winget` installs to Windows-wide paths that are visible inside MSYS2. If a tool isn't found after install, restart your MSYS2 terminal.

**Set Zsh as your default shell** — launch MSYS2 with Zsh directly via the shell command:

```
C:/msys64/msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell zsh -use-full-path
```

> Use this as the command line in your Windows Terminal profile (see [Profile: MSYS2](#profile-msys2) below). The `-shell zsh` flag starts Zsh directly — no `.bashrc` hack needed. The `-use-full-path` flag inherits your Windows PATH so tools installed via `winget` are visible inside MSYS2.

**Set `HOME` to your real Windows home** — by default MSYS2 sets `HOME` to `/c/msys64/home/<username>/`, which is an isolated directory invisible to the rest of Windows. Override it so `~` points to your real Windows profile (`C:\Users\<username>`), sharing `.ssh/`, `.gitconfig`, `.dotfiles/`, etc. with VS Code, PowerShell, and Git GUI clients.

In your Windows Terminal profile, add an `environment` block (see [Profile: MSYS2](#profile-msys2) below):

```json
"environment": {
    "HOME": "%USERPROFILE%"
}
```

> Alternatively, you can set `HOME` system-wide via Windows environment variables (`System Properties → Environment Variables → User variables → New → HOME = %USERPROFILE%`), but the Windows Terminal profile approach keeps it scoped to MSYS2 only.

**Clone the repo:**

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

**Install Powerlevel10k theme** (loaded directly by `.zshrc`, not via OMZ):

```bash
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k"
```

**Install the 3 custom plugins** (sourced directly, not through OMZ):

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
  "$ZSH_CUSTOM/plugins/you-should-use"
```

> **Note:** Oh My Zsh itself is **not** installed on MSYS2 — only the directory
> layout it expects. `.zshrc` sources P10k and the plugins directly out of
> `$ZSH_CUSTOM`, so the OMZ installer is unnecessary here. The one thing you
> give up versus macOS/WSL is the `aliases` plugin's `als` cheatsheet, which
> ships with Oh My Zsh rather than as a standalone repo.

**Install vim-plug:**

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

**Create required Vim directories:**

```bash
mkdir -p ~/.vim/{backup,swap,undo}
```

**Copy the config files** — MSYS2 symlinks don't work reliably on NTFS, so copy the files instead:

```bash
# Remove any existing files/symlinks (handles dangling symlinks too)
rm -f ~/.zshrc ~/.p10k.zsh ~/.vimrc

# Copy from dotfiles
cp ~/.dotfiles/.zshrc    ~/.zshrc
cp ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
cp ~/.dotfiles/.vimrc    ~/.vimrc
```

> **Keeping in sync:** use `dotsync-cp` — it pulls the repo, re-copies the
> tracked files into `$HOME` and `exec zsh`s. If a tool was upgraded and its
> cached init looks stale, run `dotfiles-doctor clean` first to clear
> `~/.cache/zsh/`.

**Install Vim plugins:**

```bash
vim +PlugInstall +qall
```

**Restart your MSYS2 terminal.**

**Configure Powerlevel10k** (runs automatically on first launch, or manually):

```bash
p10k configure
```

#### Profiling startup time

Use `dotfiles-doctor` (works on every platform, not just MSYS2):

```bash
dotfiles-doctor bench      # 10-run timing, interactive and non-interactive
dotfiles-doctor profile    # function-level breakdown (zprof), top 25 by self time
dotfiles-doctor trace      # line-by-line timing of the slowest 30 lines
```

#### Clearing caches

If a tool was upgraded or something seems stale:

```bash
dotfiles-doctor clean      # clears ~/.cache/zsh, p10k instant-prompt cache,
                            # and stale .zwc byte-compiled files
exec zsh
```

---

## Post-Install: Verify

Open a new shell and check that everything loaded:

```bash
# Should print "macos", "wsl", "gitbash", "msys2" or "linux"
echo $DOTFILES_OS

# Test a shared alias
gst   # → git status

# Test uv
uv --version

# Test the commit wizard (requires staged changes)
commitwell

# Full health check: symlinks, syntax, tools, startup cost
dotdoctor
```

`devinfo` prints the whole environment as JSON — OS, git context, Python/Node
versions, which tools are installed, whether a CodeArtifact token is loaded.
`devinfo --pretty` pipes it through `jq`.

```bash
als          # grouped cheatsheet of every alias currently defined
als -g git   # just the git group
als docker   # search aliases matching a keyword
```

---

## Terminal Configuration

### macOS — Warp

[Warp](https://www.warp.dev/) is a GPU-accelerated terminal for macOS with built-in AI, block-based output, and modern editing.

**Install Warp:**

```bash
brew install --cask warp
```

**Or download directly** from [warp.dev/download](https://www.warp.dev/download).

**Configure Warp to use your dotfiles:**

1. Open Warp → **Settings** (⌘ + `,`) → **Features**.
2. Under **Session**, ensure **Shell** is set to the system default (`/bin/zsh`). Warp will automatically source `~/.zshrc` on launch.
3. Powerlevel10k's instant prompt works with Warp — no extra config needed.

**Recommended Warp settings:**

| Setting | Location | Value |
|---------|----------|-------|
| Font | Appearance → Text | `MesloLGS NF` (required for P10k icons) |
| Font size | Appearance → Text | `13` |
| Theme | Appearance → Theme | Your preference (e.g., Dracula, Tokyo Night) |
| Blurred background | Appearance → Window | Enable for translucency |
| Honor PS1 | Features → Session | **On** — allows Powerlevel10k to render |

> **Font install:** If you haven't already, install the MesloLGS NF font:
> ```bash
> brew install --cask font-meslo-lg-nerd-font
> ```

**Subshell integration ("Warpify"):**

Warp's block UI, its own input editor and its **vi mode** all depend on a
shell-integration handshake. Warp does that automatically for the shell it
launches itself, but a shell it did *not* launch — one behind `ssh`, inside
Docker or tmux, or a `zsh` you started by hand — has to announce itself.

`~/.zshrc` section 14 emits that announcement as the last thing it does:

```zsh
printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh" }}\x9c'
```

It is guarded on `TERM_PROGRAM == WarpTerminal`, on a real tty, and on not
being an AI-agent shell, so no other terminal ever sees the escape sequence.

**It must stay at the very end of the file.** The hook tells Warp the rc file
has finished; emitted any earlier it races the rest of startup, and
Powerlevel10k's instant prompt (section 2) swallows it outright.

Two related gotchas, both of which break the handshake silently:

- **Anything that writes to the terminal during startup.** A tool printing a
  warning to stderr on every shell start is enough. This is why
  `_ZO_DOCTOR=0` is set alongside the zoxide init in `os/macos.sh` — zoxide's
  "initialize me last" advice is a false positive given the load order here,
  but left enabled it wrote four lines on every single startup.
- **Vi mode belongs to Warp, not zsh.** When the handshake succeeds, Warp's
  own input editor handles keys and vi mode comes from
  `text_editing.vim_mode_enabled` in `~/.warp/settings.toml`. When it fails,
  Warp falls back to a plain PTY and zsh's own keymap takes over — so a
  broken handshake looks like "vi mode stopped working" even though
  `DOTFILES_VI_MODE` is untouched.

**Verify:**

Open a new Warp tab — you should see the Powerlevel10k prompt and all aliases working.

```bash
# Vi mode should report the vi keymap, not emacs:
bindkey -lL main        # → bindkey -A viins main
```

---

### Windows — Windows Terminal (WSL, MSYS2, Git Bash)

[Windows Terminal](https://aka.ms/terminal) is the modern terminal for Windows that supports tabs, profiles, GPU-rendering, and full Unicode/emoji. All three Windows environments (WSL, MSYS2, Git Bash) run inside it as separate profiles.

**Install Windows Terminal** (if not pre-installed):

```powershell
winget install Microsoft.WindowsTerminal
```

**Install a Nerd Font** (required for Powerlevel10k icons):

```powershell
winget install Nerdfont.MesloLG.NF
```

> After installing, you must select the font in Windows Terminal settings (see below).

#### Open Settings

Launch Windows Terminal → click the dropdown arrow (˅) next to the tabs → **Settings**, or press `Ctrl + ,`. This opens `settings.json` or the GUI editor.

#### Profile: WSL (Ubuntu)

WSL profiles are auto-detected. Find your Ubuntu profile and configure it:

**GUI method:** Settings → Profiles → Ubuntu → Appearance

| Setting | Value |
|---------|-------|
| Font face | `MesloLGS NF` |
| Font size | `12` |
| Color scheme | Your preference |
| Starting directory | `~` (or `\\wsl$\Ubuntu\home\<you>`) |
| Cursor shape | `Bar` or `Vintage` (for vi-mode visibility) |

**Or edit `settings.json` directly** — find the WSL profile and add/modify:

```json
{
    "name": "Ubuntu",
    "source": "Windows.Terminal.Wsl",
    "fontFace": "MesloLGS NF",
    "fontSize": 12,
    "startingDirectory": "~",
    "cursorShape": "bar",
    "colorScheme": "One Half Dark"
}
```

#### Profile: Git Bash (Portable)

Git Bash Portable is **not** auto-detected. You need to add it manually.

**In `settings.json`**, add a new entry inside the `"profiles" → "list"` array:

```json
{
    "name": "Git Bash",
    "commandline": "C:/Users/<you>/tools/PortableGit/bin/bash.exe --login -i",
    "icon": "C:/Users/<you>/tools/PortableGit/mingw64/share/git/git-for-windows.ico",
    "startingDirectory": "C:/Users/<you>",
    "fontFace": "MesloLGS NF",
    "fontSize": 12,
    "cursorShape": "bar",
    "colorScheme": "One Half Dark"
}
```

> **Important:** Replace `<you>` with your Windows username. Use **forward slashes** in the JSON paths. The `--login -i` flags ensure `.bashrc` is sourced.

> **Tip:** If you extracted PortableGit to a different location, adjust the paths accordingly.

#### Profile: MSYS2

MSYS2 is also **not** auto-detected. Add it manually to `settings.json`:

```json
{
    "name": "MSYS2 (Zsh)",
    "commandline": "C:/msys64/msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell zsh -use-full-path",
    "icon": "C:/msys64/msys2.ico",
    "startingDirectory": "%USERPROFILE%",
    "fontFace": "MesloLGS NF",
    "fontSize": 12,
    "cursorShape": "bar",
    "colorScheme": "One Half Dark",
    "environment": {
        "HOME": "%USERPROFILE%"
    }
}
```

> **Flags explained:**
> - `-defterm` — use Windows Terminal as the rendering terminal (not mintty)
> - `-here` — start in the current directory
> - `-no-start` — don't open a new window (stay inside Windows Terminal)
> - `-ucrt64` — use the UCRT64 environment (modern, recommended)
> - `-shell zsh` — launch Zsh directly
> - `-use-full-path` — allow visibility of tools installed via `winget`
>
> **`HOME` override:** Without `"environment": { "HOME": "%USERPROFILE%" }`, MSYS2 defaults `~` to `/c/msys64/home/<username>/` — an isolated directory invisible to the rest of Windows. The override makes `~` point to `/c/Users/<username>/` so `.dotfiles/`, `.ssh/`, `.gitconfig`, etc. are shared with VS Code, PowerShell, and Git GUI clients.

> If you installed MSYS2 via `winget`, the default path is `C:\msys64`. Adjust if different.

#### Global Settings (recommended)

In `settings.json` under `"profiles" → "defaults"`, set shared defaults so all profiles inherit them:

```json
{
    "profiles": {
        "defaults": {
            "fontFace": "MesloLGS NF",
            "fontSize": 12,
            "cursorShape": "bar",
            "padding": "8",
            "antialiasingMode": "cleartype",
            "useAcrylic": false,
            "scrollbarState": "hidden"
        },
        "list": [
            // ... your profiles
        ]
    }
}
```

#### Set Your Default Profile

Settings → Startup → **Default profile** → choose `Ubuntu` (WSL) or whichever you use most.

#### Useful Keybindings

Add these under `"actions"` in `settings.json` for quick profile switching:

```json
{ "command": { "action": "newTab", "profile": "Ubuntu" },       "keys": "ctrl+shift+1" },
{ "command": { "action": "newTab", "profile": "Git Bash" },     "keys": "ctrl+shift+2" },
{ "command": { "action": "newTab", "profile": "MSYS2 (Zsh)" },  "keys": "ctrl+shift+3" },
{ "command": { "action": "splitPane", "split": "horizontal" },  "keys": "alt+shift+-" },
{ "command": { "action": "splitPane", "split": "vertical" },    "keys": "alt+shift+=" }
```

#### Verify

Open each profile as a new tab and confirm:

```bash
echo $DOTFILES_OS   # Should print "wsl", "gitbash", or "msys2"
gst                  # git status should work
uv --version         # uv should be found
```

---

## Machine-Specific Overrides

**This repo is public.** Nothing org-specific, machine-specific or secret is
committed — no employer names, account IDs, internal URLs or email addresses.
All of it lives in `local.sh`, which is gitignored and sourced **last**, so
anything set there overrides the generic defaults in `common/`.

```bash
cp ~/.dotfiles/local.sh.example ~/.dotfiles/local.sh
$EDITOR ~/.dotfiles/local.sh          # or just: zshloc for ~/.zshrc.local
```

There are **two** override hooks, both optional and both gitignored:

| File | Sourced by | Use it for |
|------|-----------|------------|
| `~/.dotfiles/local.sh` | `install.sh`, last | Anything every shell needs: tokens, `$PATH`, org config. Works in Bash and Zsh. |
| `~/.zshrc.local` | `~/.zshrc` section 12 | Zsh-only, interactive-only settings — `bindkey`, `zstyle`, prompt tweaks. |

The config degrades gracefully when it's absent — a fresh clone works
immediately, it just won't have your Jira or private package index wired up:

| Unset value | Effect |
|---|---|
| `CODEARTIFACT_DOMAIN` / `_OWNER` / `_PROFILE` | `pip`/`uv`/`poetry`/`twine` pass straight through to the real tool; no token fetch, no network call |
| `JIRA_URL` / `JIRA_PREFIX` / `JIRA_NAME` | `jira` and `gswhv` print how to configure themselves instead of failing |
| `OP_ANTHROPIC_REF` / `OP_OPENAI_REF` | `aikeys` explains what to set |

```bash
# Example local.sh contents
export CODEARTIFACT_PROFILE='your-aws-profile'
export CODEARTIFACT_DOMAIN='your-domain'
export CODEARTIFACT_OWNER='your-aws-account-id'

export JIRA_URL='https://yourcompany.atlassian.net/'
export JIRA_PREFIX='PROJ'

export DOTFILES_PYENV_SHIMS=1   # make pyenv authoritative for python3
export DOTFILES_VI_MODE=0       # emacs key bindings (default is vi)
```

> **Secrets:** prefer `aikeys` / `opkey` (1Password-backed, loaded on demand)
> over exporting API keys here in plaintext. See `common/ai.sh`.

---

## Alias Quick Reference

Not exhaustive — run `als` for the live, grouped list of everything currently
defined, or `als -g git` / `als <keyword>` to narrow it. Everything below is
guarded by a `_has_cmd` check, so an alias only exists if its tool does.

### Files and navigation

| Alias | Command |
|-------|---------|
| `ls` / `ll` / `la` | `eza` — plain / long+all+git / all |
| `lt` / `lt3` / `ltg` | `eza --tree` at depth 2 / depth 3 / depth 2 respecting `.gitignore` |
| `lsd` / `lsm` / `lss` | directories only / newest first / largest first |
| `cat` | `bat -pp` (plain, no paging — byte-identical to `cat` for pipes) |
| `batp` / `bathelp` | the pretty paged `bat` / `bat` for `--help` output |
| `cd` / `cdi` | `zoxide`'s `z` / interactive picker `zi` |
| `..` / `...` / `....` / `.....` | up 1–4 directories |
| `-` | `cd -` |
| `d` | `dirs -v` — numbered directory stack |
| `up [n]` | go up n directories (default 1) |
| `mkcd <dir>` / `take <dir>` | `mkdir -p` + `cd` in one step |
| `mkdir` / `mv` / `cp` / `rm` / `ln` | the same tools, with `-pv` / `-i` |
| `xc` | `xcp` — fast parallel copy |
| `trash` | `rip` — recoverable delete |
| `dus` / `dfh` / `pss` | `dust` / `duf` / `procs` |
| `extract <file>` | Unpack any archive (tar, zip, 7z, rar, zst…) |
| `ua <archive> <files…>` | The reverse — compress by extension |
| `backup <file>` | Timestamped copy alongside the original |
| `y [dir]` | Yazi file manager, `cd`s to wherever you quit |

> `grep`, `sed`, `find`, `ps` and `du` are **deliberately not shadowed** — their
> replacements have incompatible interfaces and would break scripts. The fast
> versions live under their own names (`rg`, `sd`, `fd`, `pss`, `dus`).

### Search

| Alias | Command |
|-------|---------|
| `rga` / `rgi` | `rg --hidden --no-ignore` / `rg --ignore-case` |
| `rgf` / `rgl` / `rgc` | list files / files-with-matches / count |
| `hs` / `hsi` | search shell history (case-sensitive / insensitive) |
| `ffzf` | fuzzy file picker with a `bat` preview |
| `frg [pattern]` | ripgrep contents → pick a match → open it at that line |
| `fbr` / `fco` | fuzzy-pick a branch to switch to / a commit to show |
| `fkill` | fuzzy-pick a process and kill it |
| `vimi` / `openi` | fzf-pick a file, open in `$EDITOR` / open with the OS |
| `wfzf <cmd>` | fzf-pick file(s), pass them to `<cmd>` |
| `proj` | fzf-jump to a repo under `$PROJECTS_DIR` (default `~/Developer`) |

### Git

Inlined from the Oh My Zsh git plugin — the plugin itself is never loaded.

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gst` / `gss` / `gsb` | `git status` / `--short` / `--short --branch` |
| `ga` / `gaa` / `gau` / `gap` | `git add` / `--all` / `--update` / `--patch` |
| `gc` / `gca` | `git commit --verbose` / `--verbose --all` |
| `gcmsg "msg"` / `gcam "msg"` | `git commit -m` / `git commit -am` |
| `gc!` / `gca!` / `gcn` / `gcn!` | amend / amend all / no-edit / no-edit amend |
| `gcf` | `git commit --fixup` |
| `gco` / `gcb` | `git checkout` / `git checkout -b` |
| `gcm` / `gcd` | check out the **main** / **develop** branch |
| `gsw` / `gswc` / `gswm` / `gswd` | `git switch` / `--create` / to main / to develop |
| `gd` / `gds` / `gdw` / `gdst` | `git diff` / `--staged` / `--word-diff` / `--stat` |
| `gl` / `gpr` / `gpra` | `git pull` / `--rebase` / `--rebase --autostash` |
| `gprom` / `gproma` | pull-rebase from `origin/main` (`a` = autostash) |
| `gp` / `gpf` / `gpf!` | `git push` / `--force-with-lease` / `--force` |
| `gpsup` | `git push --set-upstream origin <current-branch>` |
| `gf` / `gfa` / `gfo` | `git fetch` / `--all --tags --prune` / `origin` |
| `glog` / `gloga` / `glo` | `git log --oneline --decorate --graph` (`a` = `--all`) |
| `glol` / `glola` | pretty graph log (`a` = `--all`) |
| `glg` / `glp` / `gld` | log `--stat` / `--patch` / since 1 day ago |
| `gm` / `gma` / `gmc` / `gms` | `git merge` / `--abort` / `--continue` / `--squash` |
| `grb` / `grba` / `grbc` / `grbi` | `git rebase` / `--abort` / `--continue` / `-i` |
| `grbm` / `grbom` / `grbd` | rebase onto main / `origin/main` / develop |
| `grh` / `grhh` / `grhs` | `git reset` / `--hard` / `--soft` |
| `grs` / `grst` / `grss` | `git restore` / `--staged` / `--source` |
| `gsta` / `gstp` / `gstl` / `gstd` | stash push / pop / list / drop |
| `gb` / `gba` / `gbd` / `gbD` | `git branch` / `-a` / `-d` / `-D` |
| `gbl` / `gsh` / `grf` | `git blame -w` / `git show` / `git reflog` |
| `gcp` / `gcpa` / `gcpc` | cherry-pick / `--abort` / `--continue` |
| `gwt` / `gwta` / `gwtl` / `gwtrm` | `git worktree` add / list / remove |
| `grt` | `cd` to the repo root |
| `gclean` / `gbclean` | interactive clean / delete branches whose remote is gone |
| `batdiff` | `bat --diff` over every changed file |
| `commitwell` | Interactive commit wizard (`common/commitwell.sh`) |

**GitHub CLI** (`gh` installed): `ghpr` / `ghprv` / `ghprl` / `ghprc` / `ghprs`
/ `ghprm` (PR create / view / list / checkout / status / merge), `ghrv`
(review), `ghis` / `ghisv` (issues), `ghrun` / `ghwatch` (Actions).

**Jira** (needs `JIRA_URL` / `JIRA_PREFIX` in `local.sh`): `jira` opens your
dashboard, `jira 1234` opens `<PREFIX>-1234`, `jira .` opens the ticket named by
the current branch. `gswhv 1234` creates or switches to the branch
`<PREFIX>-1234`.

### Python

| Alias | Command |
|-------|---------|
| `py` / `python` / `pyver` | `python3` / `python3` / `python3 --version` |
| `pyfind` / `pygrep` | `fd -e py` / `rg --type py` |
| `pyclean` | Delete every `__pycache__` and `.pyc` recursively |
| `va` / `vd` / `vc` | activate `.venv` / `deactivate` / create + activate |
| `uvs` / `uva` / `uvr` / `uvl` | `uv sync` / `add` / `remove` / `lock` |
| `uvpi` / `uvpu` / `uvv` | `uv pip install` / `install --upgrade` / `uv venv` |
| `uvrun` / `uvt` / `uvtx` | `uv run` / `uv run pytest` / `pytest -x` |
| `uvfmt` / `uvlint` | `uv run ruff format` / `ruff check --fix` |
| `rf` / `rc` | `ruff format` / `ruff check --fix` |
| `pt` / `ptx` / `ptv` / `ptl` / `ptk` | `pytest` / `-x` / `-v` / `--last-failed` / `-k` |
| `pipi` / `pipu` / `pipun` / `piplo` | pip install / upgrade / uninstall / list outdated |
| `serve [port]` | Static HTTP server in the current directory (default 8000) |

### Node, Docker, Make

| Alias | Command |
|-------|---------|
| `ni` / `nid` / `nig` / `nun` | `npm install` / `-D` / `-g` / `uninstall` |
| `nrb` / `nrd` / `nrs` / `nrt` / `nrl` | `npm run` build / dev / start / test / lint |
| `nls` / `nout` | `npm list --depth=0` / `npm outdated` |
| `pn` / `pni` / `pnd` | `pnpm` / `pnpm install` / `pnpm dev` |
| `dps` / `dpa` / `di` | formatted `docker ps` / `ps -a` / `images` |
| `dex` / `dlog` / `dstop` / `dprune` | exec -it / logs -f / stop all / full prune |
| `dc` / `dcu` / `dcub` / `dcd` / `dcdv` | `docker compose` / up -d / up -d --build / down / down -v |
| `dcl` / `dcp` / `dcr` / `dce` / `dcb` | logs -f / ps / restart / exec / build |
| `fzfdlog` | fzf-pick a compose service and tail its logs |
| `mdp` / `mdu` / `mdb` / `mdd` | `make dev-prompt` / `dev-up` / `dev-build` / `dev-down` |
| `mga` / `mt` / `ml` | `make generate-apis` / `test` / `lint` |

### Shell, config and dotfiles

| Alias | Command |
|-------|---------|
| `c` / `h` / `j` | `clear` / `history` / `jobs -l` |
| `path` | `$PATH`, one entry per line |
| `ports` / `ports-kill <port>` | list listeners / kill whatever holds a port |
| `myip` / `now` / `week` | public IP / timestamp / ISO week number |
| `reload` / `rl` | `exec zsh` — a clean restart, never a re-source |
| `zshrc` / `bashrc` / `vimrc` | Edit the shell / vim config |
| `zshenv` / `zshals` / `zshfunc` / `zshlazy` / `zshai` | Edit the matching `common/*.sh` |
| `zshloc` / `p10k-cfg` | Edit `~/.zshrc.local` / `.p10k.zsh` |
| `dotfiles` / `dotpull` | `cd` to the repo / `git pull` it |
| `dotdoctor` / `dotbench` | `dotfiles-doctor` / `dotfiles-doctor bench` |
| `dotsync` | Pull, re-symlink into `$HOME`, restart the shell |
| `dotsync-cp` | Same, but copies — for Git Bash and MSYS2 |
| `copypath` / `copyfile <f>` | Copy `$PWD` / a file's contents to the clipboard |
| `lg` / `ld` / `top` / `htp` | `lazygit` / `lazydocker` / `btop` / `htop` |
| `?` / `jqp` / `bench` | `tldr` / `jq -C . \| less -R` / `hyperfine` |

### AI helpers (`common/ai.sh`)

| Alias / Function | Description |
|-------------------|-------------|
| `cl` / `clc` / `clr` / `clp` | `claude` / `--continue` / `--resume` / `--print` |
| `clyolo` | `claude --dangerously-skip-permissions` |
| `clhere` | Start Claude with the **repo root** as the working directory |
| `cldiff` / `clfix` / `clask` / `clcommit` | Claude over the current diff / a failure / a question / a commit message |
| `devinfo [--pretty]` | The whole environment as JSON — OS, git, tool versions |
| `ctx` | Compact snapshot of cwd, branch, dirty files, recent commits |
| `opkey VAR op://…` / `aikeys` | Load a secret / your AI API keys from 1Password |
| `opr <cmd>` | `op run --` — inject secrets for one command only |
| `noalias <cmd>` | Run a command with aliases bypassed |
| `rawshell` | A subshell with no aliases or functions, for bisecting config |

### Lazy loaders (`common/lazy.sh`)

Nothing here costs anything at startup — each is a stub that replaces itself on
first use.

| Command | Description |
|---------|-------------|
| `ca-token` / `ca-refresh` / `ca-clear` | AWS CodeArtifact token — fetched on demand, cached 11h |
| `pip` / `pip3` / `uv` / `poetry` / `twine` | Wrappers that fetch a token first, only when one is needed |
| `nvm` | Lazy — but `node` / `npm` / `npx` are on `PATH` immediately |
| `pyenv` | Lazy, and **off `PATH`** unless `DOTFILES_PYENV_SHIMS=1` |
| `fuck` / `FUCK` | `thefuck`, lazy |
| `conda` | Lazy, if miniconda/anaconda is installed |

### macOS only

| Alias | Command |
|-------|---------|
| `vim` / `gvim` | **MacVim GUI**, reusing the existing window as a new tab |
| `vimt` | `command vim` — the blocking, in-terminal build |
| `gvimrc` | Edit `~/.gvimrc` in MacVim |
| `o` / `oo` / `finder` | `open` / `open .` / open the current dir in Finder |
| `ql <file>` | Quick Look a file from the terminal |
| `clip` / `paste` | `pbcopy` / `pbpaste` |
| `flushdns` | Flush the macOS DNS cache |
| `showfiles` / `hidefiles` | Toggle hidden files in Finder |
| `cleanup` | Remove every `.DS_Store` recursively |
| `emptytrash` | Empty the trash on all volumes, plus system logs |
| `afk` / `sleepnow` | Lock the screen / sleep immediately |
| `battery` / `caff` | `pmset -g batt` / `caffeinate -dimsu` until Ctrl-C |
| `awsw` / `awsl` / `awsp` | `aws sts get-caller-identity` / `aws sso login --profile` / print `$AWS_PROFILE` |
| `bup` | `brew update && brew upgrade && brew cleanup` |
| `bi` / `bun` / `br` | `brew install` / `uninstall` / `reinstall` |
| `bcin` / `bcup` / `bcl` | `brew install --cask` / `upgrade --cask` / `list --cask` |
| `bl` / `bo` / `binf` / `bs` | `brew list` / `outdated` / `info` / `search` |
| `bson` / `bsoff` / `bsl` | `brew services` start / stop / list |
| `bcn` / `ba` / `bdr` | `brew cleanup` / `autoremove` / `doctor` |

> **Why `vim` opens MacVim:** Homebrew's `macvim` formula installs a terminal
> build of `vim` at `/opt/homebrew/bin/vim` *as well as* the `.app`, so `vim`
> runs MacVim either way — the alias just picks the GUI. `$EDITOR`, `$VISUAL`
> and `$GIT_EDITOR` are pinned to the full path of the **terminal** binary,
> because git and `edit-command-line` need an editor that blocks, which
> `mvim --remote-silent-tab` does not.

### WSL only

| Alias / Function | Description |
|-------------------|-------------|
| `cdwin` / `cddl` / `cddesk` / `cddocs` | Navigate to Windows home / Downloads / Desktop / Documents |
| `clip` / `paste` (and `pbcopy` / `pbpaste`) | `clip.exe` / `powershell Get-Clipboard` |
| `open` / `explorer` | Open in Windows Explorer |
| `notepad` / `code` | The Windows-native binaries |
| `wopen [path]` | Open a path in Explorer, converting it via `wslpath` |
| `wpath <path>` | Convert between WSL ↔ Windows paths |

### Git Bash only (minimal)

| Alias | Description |
|-------|-------------|
| `cdwin` / `cddl` / `cddesk` / `cddocs` | Navigate to your Windows profile directories |
| `clip` / `paste` | `clip.exe` / `powershell Get-Clipboard` |
| `open [path]` | Open in Explorer |
| `rl` / `shrc` | `exec bash` / edit `~/.bashrc` |

> **`cd` / `z` (zoxide):** not bundled with Git Bash — no package manager ships
> it automatically. Install it manually (see [step 3c](#3c-optional-install-zoxide-smarter-cd))
> to get smart `cd` support.

### MSYS2 only

| Alias | Description |
|-------|-------------|
| `pacs` / `paci` / `pacr` / `pacu` | pacman search / install / remove / full update |
| `pacl` / `pacinfo` | List installed / package info |
| `towinpath` / `tounixpath` | Path conversion helpers |
| `open [path]` | Open in Explorer |

---

## Vim

`.vimrc` is shared across every environment and splits on `$MSYSTEM`, which
MSYS2 and Git Bash set. Both get the lightweight plugins; everything else gets
the full stack, because Vim's file I/O is slow under Windows POSIX emulation.

Leader is `<Space>`. Plugins load only if vim-plug is present, so the config
works fine with none installed.

| | Plugins |
|---|---|
| **Everywhere** | `vim-commentary`, `vim-surround`, `vim-unimpaired`, `auto-pairs`, `vim-fugitive`, `vim-gitgutter` |
| **macOS / WSL / Linux only** | `ale`, `nerdtree`, `vim-lsp` + `vim-lsp-settings`, `asyncomplete`, `lightline`, `fzf` + `fzf.vim`, `vim-indent-guides`, `vim-easymotion`, `quick-scope`, `vim-polyglot` |

Backup, swap and undo files go to `~/.vim/{backup,swap,undo}` — create those
directories or Vim will complain on every write.

```bash
vim +PlugInstall +qall     # install
vim +PlugUpdate  +qall     # update
```

---

## Key Bindings (Zsh)

Vi bindings are the default. Set `DOTFILES_VI_MODE=0` in `local.sh` for emacs
bindings.

| Key | Action |
|-----|--------|
| `Esc` | Command mode — `KEYTIMEOUT=1`, so it's instant, not sluggish |
| Cursor shape | Steady block in command mode, beam in insert mode |
| `ci"`, `da(`, `cs'"`, `ys` | Text objects and surround, on the command line |
| `vv` (command mode) | Edit the current line in `$EDITOR` |
| `Ctrl-X Ctrl-E` | The same thing, in either keymap |
| `Ctrl-A` / `Ctrl-E` | Start / end of line — kept in **both** keymaps |
| `Ctrl-R` / `Ctrl-S` | Incremental history search back / forward |
| `Ctrl-W` / `Ctrl-U` / `Ctrl-K` | Kill word back / line back / line forward |
| `↑` / `↓` | History search using what you've already typed |
| `Ctrl-←` / `Ctrl-→` | Move by word |
| `Ctrl-Space` | Accept the current autosuggestion |

`AUTO_CD` is on, so a bare directory name is a `cd`. History is shared live
across sessions, and a leading space keeps a command out of it.

---

## Troubleshooting

**A command behaves unexpectedly.** An alias may be shadowing it. `ls`, `cat`
and `cd` are the ones that shadow real tools.

```bash
which -a ls        # what's actually being run
noalias ls -la     # run the real binary once
\ls                # same, zsh shorthand
rawshell           # a subshell with no aliases or functions at all
```

**Startup got slow.**

```bash
dotfiles-doctor bench      # is it actually slow?
dotfiles-doctor profile    # zprof: slowest functions by self time
dotfiles-doctor trace      # slowest 30 lines
```

The usual cause is something new that forks at startup. Cache it with
`_dot_cache_eval`, or make it a lazy stub in `common/lazy.sh`.

**A tool's completions or init look stale.** Caches key off the binary's mtime,
so an upgrade should regenerate them by itself. To force it:

```bash
dotfiles-doctor completions   # just the completion cache
dotfiles-doctor clean         # everything, then: exec zsh
```

**`node` is the wrong version.** `common/lazy.sh` puts nvm's *default* alias on
`PATH` at startup. Run `nvm use <version>` to change it for the session, or
`nvm alias default <version>` to change it permanently.

**`python3` is the wrong version.** pyenv's shims are deliberately **off**
`PATH` — the default is whatever your package manager installed. Set
`DOTFILES_PYENV_SHIMS=1` in `local.sh` to make pyenv authoritative.

**"defining function based on alias" parse error.** Something is being sourced
twice into a shell that already has the alias. Zsh parses an entire `if`/`else`
block before running it, so this fires even on a branch that never executes.
Call `_dot_undef <name>` as its own statement before the block — see the note
in `common/env.sh`.

**Warp lost its block UI or vi mode.** Something wrote to the terminal during
startup and broke the handshake. See [macOS — Warp](#macos--warp) above.

---

## For AI Agents

`claude/skills/kevin-shell-environment/` is a Claude Code skill that teaches
agents which tools exist here, which commands are aliased and which deliberately
aren't, and where the sharp edges are. `dotfiles-doctor link` symlinks it into
`~/.claude/skills/`, so it applies in every repo rather than just this one.

Agents also get:

- **A faster shell.** `$CLAUDECODE` and friends set `DOTFILES_IS_AGENT=1`, which
  skips the prompt, autosuggestions, syntax highlighting and the audited
  `compinit`. Aliases, functions and `$PATH` are unchanged.
- **`devinfo`** — the whole environment as one JSON blob, instead of a dozen
  `command -v` probes.
- **`ctx`** — cwd, repo, branch, dirty file count, recent commits.
- **`noalias`** and **`rawshell`** — for when an alias is getting in the way.

---

## Updating

```bash
dotsync
```

Pulls the repo (`--rebase --autostash`), re-symlinks the tracked files into
`$HOME`, backing up anything that is a real file rather than one of our
symlinks, then `exec zsh`. Use `dotsync-cp` instead on Git Bash and MSYS2,
where symlinks don't work.

Because the files are symlinks, editing `~/.zshrc` edits the repo directly —
changes are never silently lost. `dotpull` pulls without re-linking or
restarting.

After upgrading a tool whose init is cached (`zoxide`, `fzf`, `direnv`,
`atuin`, `uv`), the cache regenerates automatically when the binary is newer.
To force it:

```bash
dotfiles-doctor clean && exec zsh
```

---

## Uninstalling

```bash
# Remove the symlinks
rm -f ~/.zshrc ~/.bashrc ~/.p10k.zsh ~/.vimrc

# Restore whatever was there before. `dotfiles-doctor link` and `dotsync`
# both back up to <name>.pre-dotfiles.<timestamp>; the manual install
# instructions above use <name>.bak.
ls -1 ~/.zshrc.pre-dotfiles.* ~/.zshrc.bak 2>/dev/null
mv ~/.zshrc.pre-dotfiles.<timestamp> ~/.zshrc

# Caches and the Claude Code skill link
rm -rf ~/.cache/zsh ~/.cache/codeartifact-token
rm -f  ~/.claude/skills/kevin-shell-environment

# Remove the repo
rm -rf ~/.dotfiles
```

