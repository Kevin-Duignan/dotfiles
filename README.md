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

### 4 · Windows MSYS2 (Zsh)

**Install MSYS2** from [msys2.org](https://www.msys2.org/), or via winget:

```powershell
winget install MSYS2.MSYS2
```

**Open an MSYS2 UCRT64 or MINGW64 terminal.**

**Install Zsh and tools via pacman:**

```bash
pacman -Syu
pacman -S zsh git vim
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

git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
   "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use"
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
    "commandline": "C:/msys64/msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell zsh",
    "icon": "C:/msys64/msys2.ico",
    "startingDirectory": "~",
    "fontFace": "MesloLGS NF",
    "fontSize": 12,
    "cursorShape": "bar",
    "colorScheme": "One Half Dark"
}
```

> **Flags explained:**
> - `-defterm` — use Windows Terminal as the rendering terminal (not mintty)
> - `-here` — start in the current directory
> - `-no-start` — don't open a new window (stay inside Windows Terminal)
> - `-ucrt64` — use the UCRT64 environment (modern, recommended)
> - `-shell zsh` — launch Zsh directly

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

