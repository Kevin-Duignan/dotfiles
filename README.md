# 🗂️ .dotfiles

A modular, multi-environment dotfiles repository that keeps macOS, Windows WSL, Windows Git Bash, and Windows MSYS2 in sync from a single source of truth.

```
~/.dotfiles/
├── .bashrc                 # Bash shell config (Git Bash / WSL fallback)
├── .zshrc                  # Zsh shell config  (macOS / WSL / MSYS2)
│                           #   MSYS2: lightweight fast-path (no OMZ)
│                           #   Others: full Oh My Zsh
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
│   └── msys2.sh            # pacman, cygpath, cached tool inits, lazy nvm
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

### Two-path `.zshrc`

The `.zshrc` is shared across macOS, WSL, and MSYS2, but it contains **two startup paths**:

| Path | When | What loads |
|------|------|------------|
| **MSYS2 fast-path** | `uname -s` matches `MINGW*` or `MSYS*` | Cached `compinit`, P10k direct-load, 3 plugins sourced directly, cached fzf init, then `install.sh`. Oh My Zsh is **completely skipped**. |
| **Standard path** | Everything else (macOS, WSL, Linux) | Full Oh My Zsh with all plugins, themes, and `source <(fzf --zsh)`. |

The fast-path exists because MSYS2's POSIX emulation layer makes every subprocess fork and file-stat 10–50× slower than on native Unix. Skipping OMZ and caching tool init scripts eliminates the biggest bottlenecks.

```
┌──────────────────────────────────────────────────────┐
│  ~/.zshrc                                            │
│                                                      │
│  ┌─ P10k instant prompt ───────────────────────────┐ │
│  │  (all platforms)                                 │ │
│  └──────────────────────────────────────────────────┘ │
│  ┌─ History config ────────────────────────────────┐ │
│  │  MSYS2: 50k lines │ others: 10M lines           │ │
│  └──────────────────────────────────────────────────┘ │
│                                                      │
│  if MSYS2:                    else (macOS/WSL/Linux): │
│  ┌────────────────────┐      ┌──────────────────────┐│
│  │ Cached compinit    │      │ Full Oh My Zsh       ││
│  │ Vi-mode (bindkey)  │      │ 22 plugins           ││
│  │ Colored man pages  │      │ P10k via OMZ theme   ││
│  │ P10k direct-load   │      │ fzf / zoxide / eza   ││
│  │ 3 plugins (direct) │      └──────────┬───────────┘│
│  │ Cached fzf init    │                 │            │
│  │ install.sh ────────┤                 │            │
│  │ return (skip OMZ)  │                 │            │
│  └────────────────────┘                 │            │
│                                ┌────────▼──────────┐ │
│                                │  install.sh       │ │
│                                └───────────────────┘ │
└──────────────────────────────────────────────────────┘

         install.sh loads:
   ┌─────────────────────────────────────┐
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

The following tools are **expected** on every environment. All config files guard against missing tools with `_has_cmd` checks (which uses Zsh's instant `$commands[]` hash on Zsh, or `command -v` on Bash), so nothing will break if a tool is absent — you just won't get that feature.

| Tool | Purpose | macOS | WSL (Ubuntu) | Windows (winget) |
|------|---------|-------|--------------|------------------|
| **Git** | Version control | `brew install git` | `sudo apt install git` | Pre-installed (Git Bash) / `winget install Git.Git` |
| **[uv](https://docs.astral.sh/uv/)** | Fast Python package manager | `brew install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `winget install astral-sh.uv` |
| **[fzf](https://github.com/junegunn/fzf)** | Fuzzy finder | `brew install fzf` | `sudo apt install fzf` | `winget install junegunn.fzf` |
| **[fd](https://github.com/sharkdp/fd)** | Fast `find` (used by fzf) | `brew install fd` | `sudo apt install fd-find` | `winget install sharkdp.fd` |
| **[bat](https://github.com/sharkdp/bat)** | Cat with syntax highlighting | `brew install bat` | `sudo apt install bat` | `winget install sharkdp.bat` |
| **[eza](https://github.com/eza-community/eza)** | Modern `ls` replacement | `brew install eza` | [eza deb repo](#2--windows-wsl--ubuntu-zsh) | `winget install eza-community.eza` |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | Smarter `cd` | `brew install zoxide` | `curl -sSfL .../install.sh \| sh` | `winget install ajeetdsouza.zoxide` |
| **[yazi](https://github.com/sxyazi/yazi)** | Terminal file manager | `brew install yazi` | Binary download / cargo | `winget install sxyazi.yazi` |
| **[pre-commit](https://pre-commit.com/)** | Git hook framework (`commit`) | `brew install pre-commit` | `uv tool install pre-commit` | `uv tool install pre-commit` |

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

### 3 · Windows Git Bash (Bash — Portable / Zero Admin)

> Git Bash is the **fast-start, zero-install** environment designed for locked-down machines. Everything runs from a portable folder — **no admin rights, no installers, no package managers required**. Use WSL or MSYS2 when you need a full-featured setup.

#### 3a. Download Git for Windows Portable

1. Go to [git-scm.com/download/win](https://git-scm.com/download/win).
2. Under **Other Git for Windows downloads**, click **Portable ("thumbdrive edition")** → **64-bit Git for Windows Portable**.
3. Run the downloaded `.exe` — it's a self-extracting archive, **not** an installer. Extract it to a folder you control, e.g.:
   ```
   C:\Users\<you>\tools\PortableGit
   ```
4. Launch Git Bash via:
   ```
   C:\Users\<you>\tools\PortableGit\git-bash.exe
   ```

> **Tip:** Pin `git-bash.exe` to your taskbar or create a shortcut. You can also add the `bin/` folder to your Windows PATH via User Environment Variables (no admin) to get `git`, `bash`, `curl`, `vim`, etc. available in PowerShell and `cmd`.

#### 3b. Install uv (no admin)

From inside Git Bash:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

This installs to `~/.local/bin/` which is already on PATH via `os/gitbash.sh`.

#### 3c. (Optional) Portable tools

If you want `fzf` or `zoxide` on Git Bash, download their standalone binaries — no installer needed:

| Tool | Download | Where to put it |
|------|----------|-----------------|
| **fzf** | [github.com/junegunn/fzf/releases](https://github.com/junegunn/fzf/releases) → `fzf-*-windows_amd64.zip` | Extract `fzf.exe` into `~/bin/` or your PortableGit `usr/bin/` |
| **zoxide** | [github.com/ajeetdsouza/zoxide/releases](https://github.com/ajeetdsouza/zoxide/releases) → `zoxide-*-x86_64-pc-windows-msvc.zip` | Extract `zoxide.exe` into `~/bin/` |

Create `~/bin/` if it doesn't exist — it's already on `$PATH` via `os/gitbash.sh`:

```bash
mkdir -p ~/bin
# Then drop fzf.exe and/or zoxide.exe into ~/bin/
```

#### 3d. Clone the repo

```bash
git clone https://github.com/Kevin-Duignan/dotfiles.git ~/.dotfiles
```

#### 3e. Install vim-plug

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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

> **Keeping in sync:** After a `git pull` inside `~/.dotfiles`, re-run the copy commands above to pick up changes. Or create a small helper alias in your `local.sh`:
> ```bash
> alias dfsync='cp ~/.dotfiles/.bashrc ~/.bashrc && cp ~/.dotfiles/.vimrc ~/.vimrc && source ~/.bashrc'
> ```

#### 3h. Install Vim plugins

```bash
vim +PlugInstall +qall
```

#### 3i. Restart Git Bash

Close and reopen `git-bash.exe`. You should see your custom prompt and all shared aliases.

> **Note:** `.zshrc` is not used on Git Bash — it runs Bash only. All shared aliases and functions still load via `install.sh` → `common/*.sh` → `os/gitbash.sh`.

---

### 4 · Windows MSYS2 (Zsh — Lightweight, No Oh My Zsh)

> **Why MSYS2 over Git Bash?** MSYS2 gives you `pacman`, a real package manager, plus Zsh with autosuggestions, syntax highlighting, Powerlevel10k, fzf, zoxide — a full-featured dev shell on Windows. But MSYS2's POSIX emulation layer makes subprocess forks 10–50× slower than native Unix, so the `.zshrc` uses a **lightweight fast-path** that skips Oh My Zsh entirely while still providing the features that matter.

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
| Completions | Basic | **Zsh compinit** (cached, once per day) |
| Vi-mode | ✗ | **✓** (bindkey -v) |
| Colored man pages | ✗ | **✓** (LESS_TERMCAP) |
| nvm / node | ✗ | **✓** (lazy-loaded — zero startup cost) |

#### How the fast-path works

Instead of loading Oh My Zsh (which sources 15+ library files and runs `compinit` with security checks), the `.zshrc` MSYS2 fast-path:

1. **Caches `compinit`** — only regenerates `~/.zcompdump` once per day; all other startups use `-C` (skip security scan).
2. **Loads P10k directly** — sources the theme file without the OMZ theme engine.
3. **Sources 3 plugins directly** — `zsh-autosuggestions`, `zsh-syntax-highlighting`, `you-should-use` — no plugin loader overhead.
4. **Caches fzf init** — runs `fzf --zsh` once and caches the output to `~/.cache/fzf-init.zsh`; re-sources from cache on every startup.
5. **Caches tool init scripts** — `zoxide init zsh`, `uv generate-shell-completion zsh`, `pyenv init -` all get cached to `~/.cache/dotfiles/*.zsh` and only regenerated when the binary changes.
6. **Lazy-loads nvm** — `nvm.sh` is only sourced the first time you run `nvm`, `node`, `npm`, or `npx` (saves 1–2s).
7. **Uses `$commands[]`** — Zsh's built-in hash table for instant tool detection instead of `command -v` (which scans the entire `$PATH` on every call).

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
winget install astral-sh.uv
winget install eza-community.eza
winget install ajeetdsouza.zoxide
winget install sxyazi.yazi
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

> **Note:** Oh My Zsh itself is **not** installed on MSYS2. The `.zshrc` fast-path sources P10k and plugins directly from the `$ZSH_CUSTOM` directory structure. The `zsh-bat` plugin is also not needed — `bat` is used directly via the `cat` alias in `common/aliases.sh`.

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
rm -f ~/.zshrc ~/.vimrc

# Copy from dotfiles
cp ~/.dotfiles/.zshrc ~/.zshrc
cp ~/.dotfiles/.vimrc ~/.vimrc
```

> **Keeping in sync:** After a `git pull` inside `~/.dotfiles`, re-run the copy commands above to pick up changes. Or add a helper alias in your `local.sh`:
> ```bash
> alias dfsync='cp ~/.dotfiles/.zshrc ~/.zshrc && cp ~/.dotfiles/.vimrc ~/.vimrc && rm -rf ~/.cache/dotfiles ~/.cache/fzf-init.zsh && source ~/.zshrc'
> ```
> The `dfsync` alias also clears the cached tool init scripts so they get regenerated on the next shell startup.

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

To measure where time is spent during MSYS2 shell startup:

```bash
# Quick overall timing
time zsh -i -c exit

# Detailed function-level profiling — add to FIRST line of ~/.zshrc:
#   zmodload zsh/zprof
# Then add to LAST line:
#   zprof
# Restart shell to see the report. Remove both lines when done.
```

#### Clearing caches

If a tool was upgraded or something seems stale, clear the caches:

```bash
rm -rf ~/.cache/dotfiles ~/.cache/fzf-init.zsh ~/.zcompdump
source ~/.zshrc
```

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

**Verify:**

Open a new Warp tab — you should see the Powerlevel10k prompt and all aliases working.

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
gs                   # git status should work
uv --version         # uv should be found
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

