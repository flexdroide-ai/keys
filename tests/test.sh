#!/usr/bin/env bash
# Tests for keys.sh. Run under both shells:
#   bash tests/test.sh            (tests the function in bash)
#   KEYS_TEST_SHELL=zsh bash tests/test.sh   (tests the function in zsh)
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_SHELL="$(command -v "${KEYS_TEST_SHELL:-bash}")"
TMP="$(mktemp -d)"
# A UTF-8 locale is needed for character-based padding; C.UTF-8 on Linux, en_US.UTF-8 on macOS
if locale -a 2>/dev/null | grep -qix 'c.utf-\{0,1\}8'; then UTF8_LOCALE="C.UTF-8"; else UTF8_LOCALE="en_US.UTF-8"; fi
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

# run "<shell code>": sources keys.sh in the target shell with an isolated file and no fzf
run() {
  env -i HOME="$TMP" PATH="$TMP/bin:/usr/bin:/bin" LC_ALL="$UTF8_LOCALE" \
    KEYS_FILE="$TMP/shortcuts.txt" \
    "$TARGET_SHELL" -c ". '$ROOT/keys.sh'; $1" 2>&1
}

check() { # name, expected exit code, expected substring, shell code
  local out code
  out="$(run "$4")"; code=$?
  if [ "$code" -eq "$2" ] && [[ "$out" == *"$3"* ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL [%s] %s\n  exit=%s (want %s)\n  output: %s\n' "$TARGET_SHELL" "$1" "$code" "$2" "$out"
  fi
}

rm -f "$TMP/shortcuts.txt"
check "help"            0 "usage:"            "keys -h"
check "version"         0 "keys 0."           "keys --version"
check "path"            0 "$TMP/shortcuts.txt" "keys -p"
check "missing file"    1 "no shortcut file"  "keys -l"
check "unknown option"  2 "unknown option"    "keys -z"
check "add needs 3 args" 2 "usage: keys -a"   "keys -a macos '⌘Q'"
check "add creates file" 0 ""                 "keys -a macos '⌘Q' 'quit app'"
check "add appends"     0 ""                  "keys -a windows 'Win+L' 'lock screen'"
check "list all"        0 "lock screen"       "keys -l"
check "list filter"     0 "quit app"          "keys -l macos"
check "list case-insensitive" 0 "Win+L"       "keys -l WINDOWS"
check "list no match"   1 ""                  "keys -l nothing-here"
if ! PATH="/usr/bin:/bin" command -v fzf >/dev/null 2>&1; then
  check "fzf fallback"  0 "fzf not found"     "keys quit"
fi

# fzf stub: prints the query it received and the first input line
mkdir -p "$TMP/bin"
# shellcheck disable=SC2016
printf '#!/bin/sh\nfor a; do case "$a" in --query=*) echo "query=${a#--query=}";; esac; done\nhead -n 1\n' > "$TMP/bin/fzf"
chmod +x "$TMP/bin/fzf"
check "fzf gets query"  0 "query=quit app"    "keys quit app"
check "fzf gets lines"  0 "quit app"          "keys"
rm -rf "${TMP:?}/bin"

printf '# a comment\n\n' >> "$TMP/shortcuts.txt"
check "comments skipped" 1 ""                 "keys -l comment"

out="$(run "keys -l macos")"
want="macos      | ⌘Q               | quit app"
if [ "$out" = "$want" ]; then pass=$((pass + 1)); else
  fail=$((fail + 1)); printf 'FAIL [%s] add format\n  got:  %s\n  want: %s\n' "$TARGET_SHELL" "$out" "$want"; fi

# Every non-comment line in the example file must have exactly three non-empty fields.
bad="$(grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$ROOT/examples/shortcuts.txt" |
  awk -F'|' '{ for (i = 1; i <= NF; i++) gsub(/^ +| +$/, "", $i) }
             NF != 3 || $1 == "" || $2 == "" || $3 == "" { print NR": "$0 }')"
if [ -z "$bad" ]; then pass=$((pass + 1)); else
  fail=$((fail + 1)); printf 'FAIL example file format:\n%s\n' "$bad"; fi

printf '%s: %d passed, %d failed\n' "$TARGET_SHELL" "$pass" "$fail"
[ "$fail" -eq 0 ]
