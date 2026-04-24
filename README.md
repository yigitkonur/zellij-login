# zmx-login

A zsh hook that prompts you for a [zmx](https://github.com/neurosnap/zmx) session on interactive SSH login, then attaches to an existing session or creates a new one rooted in a directory you pick with fzf.

- **Persistent**: sessions survive disconnect / Cmd-Q / network drops — that's zmx's job, this just wires it into login.
- **Safe for scripted SSH**: `scp`, `sftp`, `rsync`, `ssh host cmd`, git-over-ssh, VS Code / Cursor Remote, JetBrains Gateway all bypass the hook.
- **No dependencies beyond zmx + fzf + zsh**. macOS and Linux.

## Requirements

- zsh 5+ as the login shell
- [zmx](https://github.com/neurosnap/zmx) 0.5+ on PATH
- [fzf](https://github.com/junegunn/fzf) 0.48+ on PATH (for `--walker=dir`)

## Install

```sh
git clone https://github.com/USER/zmx-login.git
cd zmx-login
make install
```

Or directly:

```sh
sh install.sh
```

Installs the hook to `${XDG_DATA_HOME:-~/.local/share}/zmx-login/zmx-ssh-login.zsh` and appends a sourced block to `~/.zshrc` between `# zmx-login:hook {{{` and `# zmx-login:hook }}}` markers. Idempotent.

### Options

```
sh install.sh --no-wire         # install the file only, source it yourself
sh install.sh --prefix=/opt/…   # install under a custom prefix
```

## Uninstall

```sh
make uninstall
# or: sh uninstall.sh
```

Removes the hook file and strips the sourced block from `~/.zshrc`.

## Usage

SSH into the host. You'll see:

```
zmx session >
  [+ new session]
  main
  scratch
```

- Pick an existing session → attach. Your previous cwd and scrollback are preserved by zmx.
- Pick `[+ new session]` → type a name → pick a directory (fzf walker rooted in your project dirs) → `cd` there → attach.
- In the directory picker, `Ctrl-N` prompts for a subdir name and creates it under the highlighted path.
- Esc at any prompt falls through to a plain shell.

## Configuration

Set these in `~/.zshenv` or `~/.zshrc` *before* the sourced block:

| Variable | Effect |
| --- | --- |
| `ZMX_LOGIN_ROOTS` | Colon-separated list of directories for the picker. Default: whichever of `~/research ~/dev ~/code ~/projects ~/Developer ~/src ~/work` exist, fallback to `~`. |
| `ZMX_LOGIN_SKIP` | Set to `1` to bypass the hook for this session (`ZMX_LOGIN_SKIP=1 ssh host`). |

Example:

```sh
export ZMX_LOGIN_ROOTS="$HOME/repos:$HOME/work/clients"
```

## When the hook does *not* fire

The hook bails out silently if any of these are true — so scripted and IDE-driven SSH flows are untouched:

- shell is non-interactive (no `$- == *i*`)
- `SSH_TTY` is unset (scp/sftp/rsync/git-upload-pack/ssh-with-command all land here)
- already inside a zmx session (`ZMX_SESSION` set)
- `VSCODE_IPC_HOOK_CLI`, `CURSOR_SESSION_ID`, `TERM_PROGRAM=vscode`, or `TERMINAL_EMULATOR=JetBrains-JediTerm` is set
- `ZMX_LOGIN_SKIP=1`
- `zmx` or `fzf` not on `PATH` (prints a one-line warning)

## How it works

One file, `zmx-ssh-login.zsh`, sourced from `~/.zshrc`. Runs once per shell (guarded by `ZMX_LOGIN_HOOK_DONE`). No `exec` — if `zmx attach` fails you get a plain shell, not a logged-out SSH session. When the session detaches normally, you're dropped back to the outer shell; type `exit` to close SSH.

## License

MIT
