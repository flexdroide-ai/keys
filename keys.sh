# shellcheck shell=bash
#
# keys: a tiny plain-text keyboard shortcut cheatsheet for your terminal.
# Works in zsh and bash. Source it from your shell config:
#
#   source /path/to/keys/keys.sh
#
# Shortcut file (one shortcut per line):  app | keys | action
# Location: $KEYS_FILE, default ${XDG_CONFIG_HOME:-$HOME/.config}/keys/shortcuts.txt

KEYS_VERSION="0.1.0"

keys() {
  local file="${KEYS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/keys/shortcuts.txt}"
  local cmd="${1:-}"
  local line

  case "$cmd" in
    -h|--help)
      _keys_help
      ;;
    -v|--version)
      printf 'keys %s\n' "$KEYS_VERSION"
      ;;
    -p|--path)
      printf '%s\n' "$file"
      ;;
    -e|--edit)
      mkdir -p "$(dirname "$file")" || return 1
      # eval so that EDITOR values with flags (e.g. "subl -w", "code --wait") work in zsh too
      eval "${VISUAL:-${EDITOR:-vi}}" '"$file"'
      ;;
    -a|--add)
      shift
      if [ "$#" -ne 3 ]; then
        printf 'usage: keys -a <app> <keys> <action>\n' >&2
        return 2
      fi
      mkdir -p "$(dirname "$file")" || return 1
      printf '%s | %s | %s\n' "$(_keys_pad "$1" 10)" "$(_keys_pad "$2" 16)" "$3" >> "$file"
      ;;
    -l|--list)
      shift
      _keys_lines "$file" >/dev/null || return 1
      _keys_lines "$file" | grep -i -F -- "$*"
      ;;
    -c|--copy)
      shift
      line="$(_keys_pick "$file" "$*")" || return 1
      [ -n "$line" ] || return 1
      printf '%s' "$line" | _keys_clip || return 1
      printf 'copied: %s\n' "$line"
      ;;
    -*)
      printf 'keys: unknown option %s (try keys -h)\n' "$cmd" >&2
      return 2
      ;;
    *)
      _keys_pick "$file" "$*"
      ;;
  esac
}

# Print shortcut lines, skipping comments and blank lines.
_keys_lines() {
  if [ ! -f "$1" ]; then
    printf 'keys: no shortcut file at %s (create it with keys -e or keys -a)\n' "$1" >&2
    return 1
  fi
  grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$1"
}

# Pad to N characters (not bytes, so symbols like ⌘ align in bash too).
_keys_pad() {
  local s="$1"
  while [ "${#s}" -lt "$2" ]; do s="$s "; done
  printf '%s' "$s"
}

# Interactive pick with fzf; plain filtered list if fzf is missing.
_keys_pick() {
  _keys_lines "$1" >/dev/null || return 1
  if command -v fzf >/dev/null 2>&1; then
    _keys_lines "$1" | fzf --query="$2" --no-sort
  else
    printf 'keys: fzf not found, showing a plain list\n' >&2
    _keys_lines "$1" | grep -i -F -- "$2"
  fi
}

# Copy stdin to the system clipboard.
_keys_clip() {
  if command -v pbcopy >/dev/null 2>&1; then pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then wl-copy
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input
  elif command -v clip.exe >/dev/null 2>&1; then clip.exe
  else
    printf 'keys: no clipboard tool found (pbcopy, wl-copy, xclip, xsel)\n' >&2
    return 1
  fi
}

_keys_help() {
  cat <<'EOF'
keys: plain-text keyboard shortcut cheatsheet

usage:
  keys [text]                    fuzzy search (fzf), optionally pre-filtered
  keys -l, --list [text]         print matching lines (no fzf)
  keys -c, --copy [text]         pick a line and copy it to the clipboard
  keys -a, --add APP KEYS ACTION append a formatted line
  keys -e, --edit                open the shortcut file in $VISUAL / $EDITOR
  keys -p, --path                print the shortcut file path
  keys -v, --version             print version
  keys -h, --help                show this help

file format (one per line, # for comments):
  app | keys | action

shortcut file: $KEYS_FILE, default ~/.config/keys/shortcuts.txt
EOF
}
