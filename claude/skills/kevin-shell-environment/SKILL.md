---
name: kevin-shell-environment
description: >
  Kevin's macOS shell environment — which CLI tools are installed and preferred
  (rg, fd, eza, bat, uv, delta, fzf, zoxide), which standard commands are aliased
  and which deliberately are not, how Python/Node versions resolve, and how the
  lazy AWS CodeArtifact token works. Use whenever running shell commands on
  Kevin's Mac, choosing between equivalent CLI tools, writing a script or one-liner
  for him to run, debugging "command not found" or unexpected command behaviour,
  installing Python or Node packages, or editing anything in his dotfiles repo.
---

# Kevin's shell environment (macOS)

Read this before running shell commands on Kevin's Mac. It tells you which tools
exist, which are preferred, and where the sharp edges are.

Run `devinfo` to get the live state as JSON — OS, git context, Python/Node
versions, which tools are installed, whether the CodeArtifact token is loaded.
Prefer that over probing with a series of `command -v` checks.

---

## The one thing most likely to bite you

**`cd` is aliased to `z` (zoxide) and `cat` to `bat -pp`.**

Aliases only apply to *interactive* shells. Any command you run through a tool
that uses a non-interactive shell is unaffected. But if you print a command for
Kevin to paste, or run something in an interactive shell, `cd` is zoxide's `z`,
which does frecency matching rather than plain directory changes.

To bypass any alias, prefix with `command`, or use the `noalias` helper:

```sh
noalias cat file.txt     # the real cat
command cd /some/path    # the real cd
\ls                      # backslash also bypasses an alias
```

`rawshell` opens a subshell with no aliases or functions at all — use it to check
whether a problem is caused by this config.

---

## Tool preferences

Reach for the modern tool. All of these are installed.

| Instead of | Use | Why |
|---|---|---|
| `grep -r` | `rg` | Faster, respects .gitignore, better defaults |
| `find -name` | `fd` | Simpler syntax, faster, respects .gitignore |
| `ls` | `eza` | Already aliased — `ls`, `ll`, `la`, `lt` |
| `cat` (to read) | `bat` | Already aliased to `bat -pp` |
| `sed` | `sd` | Simpler regex syntax — **but see the warning below** |
| `du` | `dust` | Available as `dus` |
| `ps` | `procs` | Available as `pss` |
| `diff` | `delta` | Also configured as the git pager |
| `pip install` | `uv pip install` | Dramatically faster |
| `python -m venv` | `uv venv` | Faster |
| `curl` | `xh` | If installed |

Also installed: `fzf`, `zoxide`, `jq`, `gh`, `docker`, `aws`, `op` (1Password),
`yazi`, `lazygit`, `hyperfine`, `thefuck`.

### `sed` and `grep` are NOT aliased — this is deliberate

An earlier version of this config aliased `sed` → `sd` and `grep` → `rg`. Both
were removed because those tools have **incompatible command-line interfaces**:

- `sd` has no `-i`, `-e`, `-n`, and no `s/foo/bar/` addressing syntax
- `rg` has no `-r`, treats `-e` differently, and skips gitignored files by default

So `sed` is GNU sed (via Homebrew coreutils) and `grep` is grep. Scripts and
pasted one-liners work as written. Use `sd` and `rg` under their own names when
you want them — that is the preferred choice interactively.

---

## Language runtimes

### Python

- `python3` → **Homebrew's Python 3.14.3** at `/opt/homebrew/bin/python3`
- pyenv is installed (3.10.16, 3.11.4, 3.13.1, 3.13.7) but its **shims are
  deliberately off PATH**, so it does not control `python3`. The `pyenv`
  command still works and lazy-loads on first use.
  To make pyenv authoritative, set `DOTFILES_PYENV_SHIMS=1` in `~/.zshrc.local`.
- Virtualenvs live at `.venv` in the project root. Activate with `va`, leave with `vd`.
- Prefer `uv` for anything package-related.

### Node

- `node` → **v20.19.6** from nvm, at `~/.nvm/versions/node/v20.19.6/bin`
- Homebrew also has node v25.8.1, but the nvm default is deliberately first on
  PATH. Do not "fix" this by reordering PATH.
- `nvm` itself is a lazy stub — the real nvm.sh loads on first call, which takes
  about 0.7s once per shell. That is expected.
- There is **no `.nvmrc` auto-switching**. Run `nvm use` explicitly.

---

## AWS CodeArtifact — the token is lazy

Kevin's org hosts private Python packages in AWS CodeArtifact. The auth token
used to be fetched on every shell start, which cost 1.2 seconds per shell. It is
now fetched **on demand** and cached for 11 hours.

The account/domain/profile values live in `local.sh` (gitignored). If
`$CODEARTIFACT_DOMAIN` is empty, CodeArtifact simply is not configured on this
machine and the wrappers below pass straight through to the real tool.

You usually do not need to think about it: `pip`, `pip3`, `uv`, `poetry` and
`twine` are wrapper functions that fetch the token automatically when the
subcommand needs the index (`install`, `sync`, `add`, `lock`, `upload`, ...).

When you do need it explicitly:

```sh
ca-token       # load into this shell (uses cache if fresh)
ca-refresh     # force a new token
ca-clear       # drop the cached token
```

If a package install fails with a 401/403 from CodeArtifact, the fix is almost
always an expired AWS SSO session. The profile name is `$CODEARTIFACT_PROFILE`
(set in `local.sh`, which is gitignored):

```sh
aws sso login --profile "$CODEARTIFACT_PROFILE"
ca-refresh
```

**Do not** add the token fetch back into any startup file.

---

## Git

Kevin uses OMZ-style git aliases, defined in `common/aliases.sh`. Common ones:
`gst`, `gaa`, `gc`, `gcb`, `gsw`, `gd`, `gds`, `gp`, `gpf` (force-with-lease),
`gl`, `gpr`, `glog`, `grb`, `gsta`.

Helper functions available: `git_main_branch`, `git_current_branch`,
`git_develop_branch`, `gbclean` (prune branches whose remote is gone),
`gswhv <ticket>` (create/switch to a `$JIRA_PREFIX-<n>` branch).

Jira config (`$JIRA_URL`, `$JIRA_PREFIX`) lives in `local.sh`, which is
gitignored — this repo is public, so no org-specific values are committed.
`jira .` opens the ticket named by the current branch; `jira 1234` opens
`$JIRA_PREFIX-1234`. Run `echo $JIRA_PREFIX` if you need the actual value.

`ctx` prints a compact snapshot of the current repo state (branch, base branch,
dirty file count, recent commits) — useful to orient yourself in one call.

---

## The dotfiles repo

Lives at `~/Developer/dotfiles`, symlinked to `~/.dotfiles`. Files in `$HOME`
(`.zshrc`, `.p10k.zsh`, `.vimrc`) are symlinks into the repo, so editing either
path edits the same file.

```
.zshrc              Orchestrator: load order, plugins, compinit, prompt
common/env.sh       Shared env: PATH helpers, locale, XDG, fzf config
common/aliases.sh   All aliases (~320)
common/functions.sh All functions
common/lazy.sh      Lazy loaders: CodeArtifact, nvm, pyenv, thefuck, conda
common/ai.sh        Claude helpers, devinfo, 1Password key loading
local.sh            Org/machine-specific values — GITIGNORED, not public
os/macos.sh         Homebrew, completion cache, macOS aliases
tools/dotfiles-doctor  bench / profile / trace / check / link / clean
```

`install.sh` sources these in a **deliberate order**. `lazy.sh` loads *after*
`os/macos.sh` so the nvm PATH shim wins over Homebrew. Do not reorder it.

### Performance rules when editing these files

Startup is ~115ms, down from ~2600ms. It stays fast because of three rules:

1. **Never fork a subprocess at startup.** No `eval "$(tool init)"`, no
   `$(command)` in a code path that runs on every shell. Use `_dot_cache_eval`,
   which runs the command once, caches the output, and sources the cache.
2. **Never eagerly source a tool's init script** if a lazy stub will do. See the
   pattern in `common/lazy.sh`.
3. **Aliases and functions are free** — they cost microseconds. Add as many as
   you like. It is subprocesses and file sourcing that cost time.

After changing anything, verify:

```sh
dotfiles-doctor check    # syntax, symlinks, tools, startup cost
dotfiles-doctor bench    # 10-run startup benchmark
dotfiles-doctor profile  # find what got slow
```

If startup regresses, `dotfiles-doctor profile` names the culprit function.

---

## Agent-aware shell

The shell detects AI agents via `$CLAUDECODE`, `$AI_AGENT`, `$CURSOR_TRACE_ID`
and friends, and sets `DOTFILES_IS_AGENT=1`. When set, it skips the Powerlevel10k
prompt, syntax highlighting, autosuggestions and completion generation — none of
which an agent reads. Aliases, functions and PATH are identical.

This is why a shell started by an agent looks plain. That is intended, not broken.

---

## Things that will look wrong but are not

- **`pip3` resolves to a function, not a binary.** That is the CodeArtifact
  wrapper. `command pip3` gets the real one.
- **`node` is v20 while Homebrew has v25.** Deliberate — nvm's default wins.
- **`python3` is Homebrew's, not pyenv's.** Deliberate — see above.
- **`rm` is `rm -i`, `cp` is `cp -i`, `mv` is `mv -i`.** Interactive safety.
  Use `command rm` in scripts, or `trash` (rm-improved, recoverable).
- **First shell after a tool upgrade is slower.** Completions regenerate in the
  background. It self-corrects on the next shell.
