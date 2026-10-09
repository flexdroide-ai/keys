# keys

A simple, plain-text keyboard shortcut cheatsheet for your terminal.

All your shortcuts live in **one text file**, one per line. Type `keys`, start typing, and [fzf](https://github.com/junegunn/fzf) finds what you need. No app, no database, no lock-in: the file is yours, readable and diffable forever.

```
$ keys screenshot
macos      | ⇧⌘4              | screenshot: selected area to file
macos      | ⌃⇧⌘4             | screenshot: selected area to clipboard
windows    | Win+Shift+S      | screenshot: selected area to clipboard
```

Works on **macOS and Linux** (zsh, bash) and on **Windows** (PowerShell 5.1 and 7+).

This project started from a real need. After years on Windows and Linux, I moved to macOS and found myself constantly stuck on the simplest things: switching keyboard language, taking a screenshot of an area, opening my clipboard history. My fingers kept reaching for the old combinations, and the new ones just wouldn’t stick.

I didn’t want another page in a note app to dig through. So I built a simple yet useful solution: one text file with the shortcuts I actually use most, and a single command to find them in seconds. It grew with me during the migration, and it works the same way on macOS, Linux and Windows, so it’s just as handy for anyone switching in either direction.

## Why

- **Easy to maintain.** Adding a shortcut is one command or one line in an editor.
- **Covers everything.** OS shortcuts, app shortcuts, your tmux prefix, your custom remaps. Tools that read app menus can't see those.
- **Portable.** Plain UTF-8 text: keep it in git, sync it with your dotfiles, use the same file on every machine.

## File format

```
# comments start with #
app        | keys             | action
macos      | ⌃Space           | switch keyboard input source (previous)
windows    | Win+V            | clipboard history
```

- One shortcut per line, three fields separated by `|`.
- Keep the `app` field lowercase and consistent (`macos`, `windows`, `tmux`, `vscode`…) so searching by app works.
- Blank lines and `#` comments are ignored.
- Alignment is cosmetic: search works either way.

Default location: `~/.config/keys/shortcuts.txt`. Override it with the `KEYS_FILE` environment variable (handy if you keep it in a dotfiles repo).

## Install

### macOS / Linux (zsh or bash)

```sh
# 1. fzf (optional but recommended; without it keys prints a plain filtered list)
brew install fzf            # or your distro's package manager

# 2. get keys
git clone https://github.com/flexdroide-ai/keys.git ~/.local/share/keys

# 3. load it in your shell (~/.zshrc or ~/.bashrc)
echo 'source ~/.local/share/keys/keys.sh' >> ~/.zshrc

# 4. start from the examples
mkdir -p ~/.config/keys
cp ~/.local/share/keys/examples/shortcuts.txt ~/.config/keys/

source ~/.zshrc
```

### Windows (PowerShell, untested so far)

```powershell
# 1. fzf (optional but recommended)
winget install junegunn.fzf

# 2. get keys
git clone https://github.com/flexdroide-ai/keys.git $HOME\keys

# 3. load it in your profile
Add-Content $PROFILE '. "$HOME\keys\keys.ps1"'

# 4. start from the examples
New-Item -ItemType Directory -Force $HOME\.config\keys | Out-Null
Copy-Item $HOME\keys\examples\shortcuts.txt $HOME\.config\keys\

. $PROFILE
```

If your execution policy blocks the script, run `Unblock-File $HOME\keys\keys.ps1`, or allow local scripts with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

## Usage

| Command | What it does |
|---|---|
| `keys` | fuzzy search everything |
| `keys tmux` | fuzzy search, pre-filtered with "tmux" |
| `keys -l [text]` | print matching lines, no fzf (good for scripts and quick looks) |
| `keys -c [text]` | pick a line and copy it to the clipboard |
| `keys -a APP KEYS ACTION` | append a nicely aligned line |
| `keys -e` | open the file in `$VISUAL` / `$EDITOR` (Windows: `notepad` by default) |
| `keys -p` | print the file path |
| `keys -h` | help |

Search matches the whole line, so `keys -l windows` also finds a macOS action that mentions "windows". Add a word to narrow it down.

Adding a shortcut:

```sh
keys -a tmux "prefix d" "detach session"
```

Pass the three fields as separate arguments. Don't type the `|` yourself: unquoted, the shell treats it as a pipe.

Editors that need a "wait" flag work too:

```sh
export EDITOR="subl -w"     # or "code --wait"
```

## Tests

```sh
bash tests/test.sh                        # bash
KEYS_TEST_SHELL=zsh bash tests/test.sh    # zsh
pwsh -NoProfile -File tests/test.ps1      # PowerShell
```

CI runs them on Ubuntu, macOS and Windows, plus `shellcheck`.

## License

[MIT](LICENSE)
