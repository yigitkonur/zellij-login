#!/bin/sh
# zmx-login uninstaller — POSIX sh.
set -eu

HOOK_NAME="zmx-ssh-login.zsh"
DEFAULT_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/zmx-login"
MARK_OPEN="# zmx-login:hook {{{"
MARK_CLOSE="# zmx-login:hook }}}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

prefix="$DEFAULT_PREFIX"

for arg in "$@"; do
  case "$arg" in
    --prefix=*)   prefix="${arg#--prefix=}" ;;
    -h|--help)
      cat <<EOF
Usage: sh uninstall.sh [--prefix=PATH]

  --prefix=PATH   remove hook installed under PATH (default: $DEFAULT_PREFIX)
EOF
      exit 0 ;;
    *) printf 'zmx-login: unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

info() { printf 'zmx-login: %s\n' "$*"; }

if [ -f "$prefix/$HOOK_NAME" ]; then
  rm -f -- "$prefix/$HOOK_NAME"
  info "removed $prefix/$HOOK_NAME"
fi
rmdir "$prefix" 2>/dev/null || true

if [ -f "$ZSHRC" ] && grep -Fq "$MARK_OPEN" "$ZSHRC"; then
  tmp="$(mktemp)"
  awk -v o="$MARK_OPEN" -v c="$MARK_CLOSE" '
    index($0, o) > 0 { inblock = 1; next }
    index($0, c) > 0 { inblock = 0; next }
    !inblock         { print }
  ' "$ZSHRC" > "$tmp"
  mv -- "$tmp" "$ZSHRC"
  info "stripped hook block from $ZSHRC"
fi

info "done."
