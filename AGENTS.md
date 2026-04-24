# AGENTS.md — zmx-login

Instructions for AI agents (Claude Code, Codex, Cursor, etc.) working in this repo. Read before editing.

## What this is

A 500-line zsh hook project. On interactive SSH login, the hook sources from `.zshrc`, prompts the user for a `zmx` session via `fzf`, and either attaches to an existing one or creates a new one after picking a directory with an `fzf --walker=dir` picker. POSIX-sh installer and uninstaller wire it into `.zshrc` via a marker-delimited block.

## Non-goals

- **Bash / fish compat for the hook.** zsh features are load-bearing: `${(@f)…}`, `(s.:.)`, `local -a`, `[[ -o interactive ]]`. Rewriting for portability is a regression.
- **Rewrite in Go / Rust / Python.** Adding a compile toolchain to install a shell fragment defeats the point.
- **Feature growth.** The hook does one thing: pick + attach. Configuration is env-var only (`ZMX_LOGIN_ROOTS`, `ZMX_LOGIN_SKIP`). Don't add CLI flags to the hook, YAML config, or session templates.
- **New dependencies.** Allowed: `zsh`, `zmx`, `fzf`, coreutils, `awk`. Not allowed: `gum`, `broot`, `yazi`, `jq`, anything else.

## Hard constraints

- **Hook** (`zmx-ssh-login.zsh`): zsh-only. Must pass `zsh -n`.
- **Installer / uninstaller / test** (`install.sh`, `uninstall.sh`, `test/roundtrip.sh`): POSIX `sh`. Must pass `sh -n` and `shellcheck --shell=sh`.
- **Behavior invariants** (verified by `test/roundtrip.sh`; breaking any of these is a regression):
  - Idempotent install — re-running produces exactly one marker block, never duplicates.
  - Byte-for-byte `.zshrc` restore on uninstall.
  - Silent bailout on non-interactive shells, IDE remote shells, already-in-zmx, missing deps.
- **No changes to** `~/.ssh/*`, `/etc/ssh/sshd_config`, SSH `ForceCommand`, or `~/.ssh/rc`. The hook's only integration point is `.zshrc`.
- **Hot path discipline.** The hook runs on every interactive SSH login. Any work added before the short-circuit guards (interactive / `SSH_TTY` / `ZMX_SESSION` / IDE exclusions / skip flag) is a hot-path regression. Guards must be parameter expansions only — no subshells, no external commands — until we've confirmed the user wants the hook to fire.

## Before committing

```
make check
```

Runs `zsh -n`, `sh -n`, `shellcheck --shell=sh`, and the sandbox round-trip test. CI runs the identical stack on every push. If local fails, don't push.

## Testing locally

Never exercise `install.sh` against your real `.zshrc`. Use the sandbox pattern from `test/roundtrip.sh`:

```sh
tmp=$(mktemp -d)
ZDOTDIR=$tmp XDG_DATA_HOME=$tmp/.local/share sh install.sh
# inspect / exercise
ZDOTDIR=$tmp XDG_DATA_HOME=$tmp/.local/share sh uninstall.sh
rm -rf $tmp
```

## Commit messages

Conventional Commits with a short, descriptive scope — `feat(hook): …`, `fix(installer): …`, `refactor(test): …`, `docs(readme): …`. Subject under 50 chars, imperative. No `WIP`, no `misc`, no `updates`. One commit, one purpose.

## File map

| Path | What |
| --- | --- |
| `zmx-ssh-login.zsh` | The hook. 77 lines. |
| `install.sh` | POSIX-sh installer. Handles both local-clone and curl-pipe install. |
| `uninstall.sh` | POSIX-sh uninstaller. Strips the marker block with awk. |
| `test/roundtrip.sh` | Sandbox install/idempotency/uninstall test. |
| `Makefile` | `install` / `uninstall` / `check` / `test`. |
| `.github/workflows/check.yml` | CI runs `make check`-equivalent on every push. |
| `README.md` | User-facing docs. Casual tone on purpose (dropped-session-friendly). |
| `AGENTS.md` | This file. |
| `CLAUDE.md` | Points at `AGENTS.md`. |
| `LICENSE` | MIT. |

## Style notes

- README tone is deliberately casual / lowercase — don't "professionalize" it without asking; the style is a product decision.
- Comments in code: only non-obvious WHY. No narration, no history. If a comment explains what the code does, delete it.
- Error messages from shell scripts: prefix with `zmx-login:`. Stderr for warnings and errors, stdout for progress.

## If you break the test

The round-trip test is the contract. If a change makes it fail, either fix the change or adjust the test — but don't commit with it failing, and don't commit with a test weakened to hide the regression. If the test is wrong, say so in the commit message and explain why.
