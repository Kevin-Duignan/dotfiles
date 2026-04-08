# 🗂️ .dotfiles

A modular, multi-environment dotfiles repository that keeps macOS, Windows WSL, Windows Git Bash, and Windows MSYS2 in sync from a single source of truth.

```
~/.dotfiles/
├── .bashrc                 # Bash shell config (Git Bash / WSL fallback)
├── .zshrc                  # Zsh shell config  (macOS / WSL / MSYS2)
├── .vimrc                  # Vim editor config (all environments)
├── install.sh              # Entry point — detects OS, sources everything
├── common/
│   ├── aliases.sh          # Cross-platform aliases (ls, git, docker, uv…)
│   ├── functions.sh        # Cross-platform functions (extract, mkcd, yazi…)
│   └── commitwell.sh       # Interactive git commit wizard (standalone script)
├── os/
│   ├── macos.sh            # Homebrew, pbcopy, MacVim, macOS utilities
│   ├── wsl.sh              # Windows interop, clip.exe, wslpath helpers
│   ├── gitbash.sh          # Minimal / fast-start config for Git Bash
│   └── msys2.sh            # pacman shortcuts, cygpath, MSYS2 fixes
└── local.sh                # (create manually) Machine-specific overrides — git-ignored
```

---

## How It Works

1. Your shell RC file (`~/.zshrc` or `~/.bashrc`) sets up the shell itself (prompt, history, key bindings, Oh My Zsh + plugins).
2. At the very end it sources `~/.dotfiles/install.sh`.
3. `install.sh` auto-detects the OS and loads:
   - **`common/aliases.sh`** + **`common/functions.sh`** — shared across every environment.
   - **`os/<detected>.sh`** — environment-specific config (Homebrew on macOS, `clip.exe` on WSL, etc.).
   - **`local.sh`** (if it exists) — for secrets/tokens/machine-specific overrides that are never committed.

```
┌─────────────────────┐     ┌─────────────────────┐
│  ~/.zshrc            │     │  ~/.bashrc           │
│  (P10k, OMZ, hist)  │     │  (prompt, vi-mode)   │
└────────┬────────────┘     └────────┬────────────┘
         │  source                    │  source
         ▼                            ▼
   ┌─────────────────────────────────────┐
   │         install.sh                  │
   │  ┌───────────────────────────────┐  │
   │  │  common/aliases.sh            │  │
   │  │  common/functions.sh          │  │
   │  └───────────────────────────────┘  │
   │  ┌───────────────────────────────┐  │
   │  │  os/macos.sh   ← Darwin      │  │
   │  │  os/wsl.sh     ← Linux+WSL   │  │
   │  │  os/gitbash.sh ← MINGW (no   │  │
   │  │                   pacman)     │  │
   │  │  os/msys2.sh   ← MINGW+MSYS  │  │
   │  └───────────────────────────────┘  │
   │  ┌───────────────────────────────┐  │
   │  │  local.sh (if exists)         │  │
   │  └───────────────────────────────┘  │
   └─────────────────────────────────────┘
```

> **`commitwell.sh`** is a standalone Zsh script (not sourced). It is invoked via the `commit` alias.

---

## Prerequisites

The following tools are **expected** on every environment. All config files guard against missing tools with `command -v` checks, so nothing will break if a tool is absent — you just won't get that feature.

| Tool | Purpose | Install |
|------|---------|---------|
| **Git** | Version control | Pre-installed on all targets |
| **[uv](https://docs.astral.sh/uv/)** | Fast Python package/project manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **[fzf](https://github.com/junegunn/fzf)** | Fuzzy finder | Brew / apt / pacman / winget |
| **[fd](https://github.com/sharkdp/fd)** | Fast `find` replacement (used by fzf) | Brew / apt / pacman / scoop |
| **[bat](https://github.com/sharkdp/bat)** | Cat with syntax highlighting | Brew / apt / pacman / scoop |
| **[eza](https://github.com/eza-community/eza)** | Modern `ls` replacement | Brew / apt / cargo |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | Smarter `cd` | Brew / apt / pacman / cargo |
| **[yazi](https://github.com/sxyazi/yazi)** | Terminal file manager | Brew / cargo |
| **[pre-commit](https://pre-commit.com/)** | Git hook framework (for `commit`) | `uv tool install pre-commit` |

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

git clone https://github.com/fdellwing/zsh-bat \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-bat"

git clone https://github.com/MichaelAqworter-Andi/zsh-you-should-use \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
```

**Install CLI tools via Homebrew:**

```bash
brew install fzf fd bat eza zoxide yazi uv gh vim macvim pre-commit
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
# Back up any existing files first
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
[ -f ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.bak

ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.vimrc ~/.vimrc
```

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

git clone https://github.com/fdellwing/zsh-bat \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-bat"

git clone https://github.com/MichaelAqworter-Andi/zsh-you-should-use \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
```

**Install CLI tools:**

```bash
sudo apt install -y fzf fd-find bat vim

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
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.bak
[ -f ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.bak

ln -sf ~/.dotfiles/.zshrc  ~/.zshrc
ln -sf ~/.dotfiles/.bashrc ~/.bashrc
ln -sf ~/.dotfiles/.vimrc  ~/.vimrc
```

**Install Vim plugins:**

```bash
vim +PlugInstall +qall
```

**Restart your terminal** (or run `exec zsh`).

> **Tip:** Install a [Nerd Font](https://www.nerdfonts.com/) in Windows Terminal for Powerlevel10k icons to render correctly. `MesloLGS NF` is recommended.

---

### 3 · Windows Git Bash (Bash — Lightweight)

> Git Bash is the **fast-start, minimal** environment. It skips heavy tools like nvm and pyenv on purpose. Use WSL or MSYS2 for a full setup.

**Clone the repo** (from Git Bash):

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

**Install uv** (open PowerShell or Git Bash):

```bash
# PowerShell
irm https://astral.sh/uv/install.ps1 | iex

# OR Git Bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Optionally install** fast tools via [Scoop](https://scoop.sh/) (in PowerShell):

```powershell
scoop install fzf fd zoxide
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

**Symlink (or copy) the config files:**

> Git Bash symlinks require running the terminal as Administrator, or use copies instead.

```bash
# Option A: Copy (simpler, no admin needed)
cp ~/.dotfiles/.bashrc ~/.bashrc
cp ~/.dotfiles/.vimrc  ~/.vimrc

# Option B: Symlink (requires admin Git Bash)
ln -sf ~/.dotfiles/.bashrc ~/.bashrc
ln -sf ~/.dotfiles/.vimrc  ~/.vimrc
```

**Install Vim plugins:**

```bash
vim +PlugInstall +qall
```

**Restart Git Bash.**

> **Note:** `.zshrc` is not used on Git Bash — it runs Bash only. All shared aliases/functions still load via `install.sh` → `common/*.sh` → `os/gitbash.sh`.

---

### 4 · Windows MSYS2 (Zsh)

**Install MSYS2** from [msys2.org](https://www.msys2.org/) if you haven't already.

**Open an MSYS2 UCRT64 or MINGW64 terminal.**

**Install Zsh and tools via pacman:**

```bash
pacman -Syu
pacman -S zsh git vim fzf fd bat
```

**Set Zsh as your default shell** — edit your MSYS2 shortcut or `/etc/nsswitch.conf`, or add to the top of `~/.bashrc`:

```bash
if [ -t 1 ]; then
  exec zsh
fi
```

**Clone the repo:**

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

**Install Oh My Zsh:**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

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

git clone https://github.com/fdellwing/zsh-bat \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-bat"

git clone https://github.com/MichaelAqworter-Andi/zsh-you-should-use \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
```

**Install additional tools:**

```bash
# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# eza (via cargo or download binary)
cargo install eza    # requires rust toolchain: pacman -S rust

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
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
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
[ -f ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.bak

ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.vimrc ~/.vimrc
```

**Install Vim plugins:**

```bash
vim +PlugInstall +qall
```

**Restart your MSYS2 terminal.**

---

## Post-Install: Verify

Open a new shell and check that everything loaded:

```bash
# Should print "macos", "wsl", "gitbash", or "msys2"
echo $DOTFILES_OS

# Test a shared alias
gs   # → git status

# Test uv
uv --version

# Test the commit wizard (requires staged changes)
commit
```

---

## Machine-Specific Overrides

Create `~/.dotfiles/local.sh` for anything that should **not** be committed — API tokens, work-specific PATHs, proxy settings, etc:

```bash
touch ~/.dotfiles/local.sh
```

```bash
# Example local.sh contents
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export HTTP_PROXY="http://proxy.corp.example.com:8080"
export PATH="$HOME/work-tools/bin:$PATH"
```

This file is sourced last (after OS-specific config) and should be added to `.gitignore`.

---

## Alias Quick Reference

### Shared (all environments)

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gcm "msg"` | `git commit -m "msg"` |
| `gp` / `gpl` | `git push` / `git pull` |
| `gl` | `git log --oneline --graph --decorate -20` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `commit` | Interactive commit wizard (`commitwell.sh`) |
| `ls` / `ll` / `la` / `lt` | `eza` (falls back to plain `ls`) |
| `cat` | `bat --paging=never` |
| `cd` | `zoxide` (`z`) |
| `uvs` / `uva` / `uvr` | `uv sync` / `uv add` / `uv remove` |
| `uvpi` / `uvpu` | `uv pip install` / `uv pip install --upgrade` |
| `uvrun` | `uv run` |
| `dcu` / `dcd` / `dcl` | `docker compose up -d` / `down` / `logs -f` |
| `extract <file>` | Auto-detect & extract any archive |
| `mkcd <dir>` | `mkdir -p` + `cd` in one step |
| `serve [port]` | Python HTTP server (default port 8000) |
| `y [dir]` | Yazi file manager with `cd`-on-exit |

### macOS Only

| Alias | Command |
|-------|---------|
| `bup` | `brew update && upgrade && cleanup` |
| `bin` / `bun` | `brew install` / `brew uninstall` |
| `clip` / `paste` | `pbcopy` / `pbpaste` |
| `flushdns` | Flush macOS DNS cache |
| `showfiles` / `hidefiles` | Toggle hidden files in Finder |
| `cleanup` | Remove all `.DS_Store` files recursively |
| `afk` | Lock the screen |

### WSL Only

| Alias / Function | Description |
|-------------------|-------------|
| `cdwin` / `cddl` / `cddesk` | Navigate to Windows home/Downloads/Desktop |
| `clip` / `paste` | `clip.exe` / `powershell Get-Clipboard` |
| `open <path>` | Open in Windows Explorer |
| `wopen [path]` | Open path in Explorer via `wslpath` |
| `wpath <path>` | Convert between WSL ↔ Windows paths |

### Git Bash Only (minimal)

| Alias | Description |
|-------|-------------|
| `cdwin` / `cddl` | Navigate to `C:\Users\Kevin-Duignan` paths |
| `clip` / `paste` | `clip.exe` / `powershell Get-Clipboard` |
| `open [path]` | Open in Explorer |

### MSYS2 Only

| Alias | Description |
|-------|-------------|
| `pacs` / `paci` / `pacr` / `pacu` | pacman search / install / remove / update |
| `towinpath` / `tounixpath` | Path conversion helpers |

---

## Updating

Pull the latest changes and reload:

```bash
cd ~/.dotfiles && git pull && source ~/.zshrc   # or: source ~/.bashrc
```

---

## Uninstalling

```bash
# Restore your backups
[ -f ~/.zshrc.bak ]  && mv ~/.zshrc.bak  ~/.zshrc
[ -f ~/.bashrc.bak ] && mv ~/.bashrc.bak ~/.bashrc
[ -f ~/.vimrc.bak ]  && mv ~/.vimrc.bak  ~/.vimrc

# Or just remove the symlinks
rm -f ~/.zshrc ~/.bashrc ~/.vimrc

# Remove the repo
rm -rf ~/.dotfiles
```

