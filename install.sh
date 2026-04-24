#!/bin/sh
# zmx-login installer — POSIX sh, macOS + Linux.
set -eu

HOOK_NAME="zmx-ssh-login.zsh"
DEFAULT_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/zmx-login"
MARK_OPEN="# zmx-login:hook {{{"
MARK_CLOSE="# zmx-login:hook }}}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

wire=1
prefix="$DEFAULT_PREFIX"

usage() {
  cat <<EOF
Usage: sh install.sh [--no-wire] [--prefix=PATH]

  --no-wire       install the hook but do not modify \$ZDOTDIR/.zshrc
  --prefix=PATH   install hook under PATH (default: $DEFAULT_PREFIX)
  -h, --help      show this help

Environment:
  ZMX_LOGIN_ROOTS   colon-separated list of directories for the dir picker
                    (default: \$HOME/{research,dev,code,projects,Developer,src,work})
  ZMX_LOGIN_SKIP    set to 1 to bypass the hook for a given session
EOF
}

for arg in "$@"; do
  case "$arg" in
    --no-wire)      wire=0 ;;
    --prefix=*)     prefix="${arg#--prefix=}" ;;
    -h|--help)      usage; exit 0 ;;
    *)              printf 'zmx-login: unknown argument: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

info() { printf 'zmx-login: %s\n' "$*"; }
warn() { printf 'zmx-login: %s\n' "$*" >&2; }
die()  { warn "$*"; exit 1; }

command -v zsh >/dev/null 2>&1 || die "zsh is required"
command -v zmx >/dev/null 2>&1 || warn "zmx not on PATH (install: https://github.com/neurosnap/zmx)"
command -v fzf >/dev/null 2>&1 || warn "fzf not on PATH (install via your package manager)"

# shellcheck disable=SC1007  # intentional: unset CDPATH for this cd only
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
src="$script_dir/$HOOK_NAME"
[ -f "$src" ] || die "cannot find $HOOK_NAME next to installer (looked in $script_dir)"

mkdir -p -- "$prefix"
cp -- "$src" "$prefix/$HOOK_NAME"
info "installed hook at $prefix/$HOOK_NAME"

if [ "$wire" -eq 0 ]; then
  info "skipped .zshrc wiring (--no-wire). Source the hook manually:"
  printf '    source %s/%s\n' "$prefix" "$HOOK_NAME"
  exit 0
fi

[ -f "$ZSHRC" ] || : > "$ZSHRC"
if grep -Fq "$MARK_OPEN" "$ZSHRC" 2>/dev/null; then
  info "$ZSHRC already sources the hook"
else
  # Ensure file ends with newline before appending.
  if [ -s "$ZSHRC" ] && [ "$(tail -c 1 "$ZSHRC" | wc -l | tr -d ' ')" = 0 ]; then
    printf '\n' >> "$ZSHRC"
  fi
  {
    printf '%s\n' "$MARK_OPEN"
    printf '[ -r "%s/%s" ] && source "%s/%s"\n' \
      "$prefix" "$HOOK_NAME" "$prefix" "$HOOK_NAME"
    printf '%s\n' "$MARK_CLOSE"
  } >> "$ZSHRC"
  info "wired hook into $ZSHRC"
fi

info "done. Open a new SSH session on this host to see the picker."
info "uninstall: run $script_dir/uninstall.sh"
