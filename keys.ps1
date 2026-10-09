# keys: a tiny plain-text keyboard shortcut cheatsheet for your terminal.
# PowerShell version (Windows PowerShell 5.1 and PowerShell 7+).
# Dot-source it from your profile ($PROFILE):
#
#   . "$HOME\keys\keys.ps1"
#
# Shortcut file (one shortcut per line):  app | keys | action
# Location: $env:KEYS_FILE, default ~\.config\keys\shortcuts.txt

$script:KeysVersion = '0.1.0'

function Get-KeysFile {
    if ($env:KEYS_FILE) { return $env:KEYS_FILE }
    return (Join-Path (Join-Path (Join-Path $HOME '.config') 'keys') 'shortcuts.txt')
}

function Get-KeysLines([string]$File) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Error "keys: no shortcut file at $File (create it with keys -e or keys -a)"
        return
    }
    Get-Content -LiteralPath $File -Encoding UTF8 |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
}

function Select-KeysLine([string]$File, [string]$Query) {
    $lines = @(Get-KeysLines $File)
    if ($lines.Count -eq 0) { return }
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        # fzf needs UTF-8 on the pipe, or symbols like the Windows key glyphs get mangled
        $prevOut = $OutputEncoding
        $prevCon = [Console]::OutputEncoding
        try {
            $utf8 = New-Object System.Text.UTF8Encoding $false
            $global:OutputEncoding = $utf8
            [Console]::OutputEncoding = $utf8
            $lines | fzf --query="$Query" --no-sort
        }
        finally {
            $global:OutputEncoding = $prevOut
            [Console]::OutputEncoding = $prevCon
        }
    }
    else {
        Write-Warning 'keys: fzf not found, showing a plain list'
        $lines | Where-Object { $_ -like "*$Query*" }
    }
}

function Show-KeysHelp {
    @'
keys: plain-text keyboard shortcut cheatsheet

usage:
  keys [text]                    fuzzy search (fzf), optionally pre-filtered
  keys -l, --list [text]         print matching lines (no fzf)
  keys -c, --copy [text]         pick a line and copy it to the clipboard
  keys -a, --add APP KEYS ACTION append a formatted line
  keys -e, --edit                open the shortcut file in $env:EDITOR (default: notepad)
  keys -p, --path                print the shortcut file path
  keys -v, --version             print version
  keys -h, --help                show this help

file format (one per line, # for comments):
  app | keys | action

shortcut file: $env:KEYS_FILE, default ~\.config\keys\shortcuts.txt
'@
}

function keys {
    $file = Get-KeysFile
    $cmd = if ($args.Count -gt 0) { [string]$args[0] } else { '' }
    $rest = @(if ($args.Count -gt 1) { $args[1..($args.Count - 1)] })
    $query = ($rest -join ' ')

    switch -CaseSensitive ($cmd) {
        { $_ -in '-h', '--help' }    { Show-KeysHelp; return }
        { $_ -in '-v', '--version' } { "keys $script:KeysVersion"; return }
        { $_ -in '-p', '--path' }    { $file; return }
        { $_ -in '-e', '--edit' } {
            New-Item -ItemType Directory -Force -Path (Split-Path $file) | Out-Null
            if (-not (Test-Path -LiteralPath $file)) { New-Item -ItemType File -Path $file | Out-Null }
            $editor = if ($env:EDITOR) { $env:EDITOR } else { 'notepad' }
            # Invoke-Expression so that EDITOR values with flags (e.g. "code --wait") work
            Invoke-Expression "$editor `"$file`""
            return
        }
        { $_ -in '-a', '--add' } {
            if ($rest.Count -ne 3) {
                Write-Error 'usage: keys -a <app> <keys> <action>'
                return
            }
            New-Item -ItemType Directory -Force -Path (Split-Path $file) | Out-Null
            $line = '{0,-10} | {1,-16} | {2}' -f $rest[0], $rest[1], $rest[2]
            # UTF-8 without BOM, same bytes as the shell version
            [System.IO.File]::AppendAllText($file, $line + "`n", (New-Object System.Text.UTF8Encoding $false))
            return
        }
        { $_ -in '-l', '--list' } {
            Get-KeysLines $file | Where-Object { $_ -like "*$query*" }
            return
        }
        { $_ -in '-c', '--copy' } {
            $line = Select-KeysLine $file $query
            if ($line) { Set-Clipboard -Value $line; "copied: $line" }
            return
        }
        { $_ -like '-*' } {
            Write-Error "keys: unknown option $cmd (try keys -h)"
            return
        }
        default {
            Select-KeysLine $file ((@($cmd) + $rest) -join ' ').Trim()
            return
        }
    }
}
