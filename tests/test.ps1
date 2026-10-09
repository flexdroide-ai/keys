# Tests for keys.ps1. Run with: pwsh -NoProfile -File tests/test.ps1
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("keys-test-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
$env:KEYS_FILE = Join-Path $tmp 'shortcuts.txt'
# Built from a code point so this file stays ASCII (Windows PowerShell 5.1 reads BOM-less scripts as ANSI)
$cmdQ = "$([char]0x2318)Q"

. (Join-Path $root 'keys.ps1')

$script:pass = 0
$script:fail = 0
function Check([string]$Name, [scriptblock]$Code, [string]$Expect, [switch]$Empty) {
    $out = (& $Code 2>&1 | Out-String).Trim()
    $ok = if ($Empty) { $out -eq '' } else { $out -like "*$Expect*" }
    if ($ok) { $script:pass++ } else { $script:fail++; Write-Host "FAIL $Name`n  output: $out" }
}

try {
    Check 'help'             { keys -h }                       'usage:'
    Check 'version'          { keys --version }                'keys 0.'
    Check 'path'             { keys -p }                       $env:KEYS_FILE
    Check 'missing file'     { keys -l }                       'no shortcut file'
    Check 'unknown option'   { keys -z }                       'unknown option'
    Check 'add needs 3 args' { keys -a windows 'Win+L' }       'usage: keys -a'
    Check 'add creates file' { keys -a macos $cmdQ 'quit app' } -Empty
    Check 'add appends'      { keys -a windows 'Win+L' 'lock screen' } -Empty
    Check 'list all'         { keys -l }                       'lock screen'
    Check 'list filter'      { keys -l macos }                 'quit app'
    Check 'list no match'    { keys -l nothing-here }          -Empty

    $want = "macos      | $cmdQ               | quit app"
    $got = (keys -l macos | Out-String).Trim()
    if ($got -eq $want) { $script:pass++ } else { $script:fail++; Write-Host "FAIL add format`n  got:  $got`n  want: $want" }

    # File written by PowerShell must be UTF-8 without BOM, so the shell version reads the same bytes
    $bytes = [System.IO.File]::ReadAllBytes($env:KEYS_FILE)
    if (-not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB)) { $script:pass++ } else { $script:fail++; Write-Host 'FAIL file has a BOM' }

    # Example file reads cleanly
    $env:KEYS_FILE = Join-Path $root 'examples/shortcuts.txt'
    Check 'example file'     { keys -l 'Win+L' }               'lock screen'
}
finally {
    Remove-Item -Recurse -Force $tmp
}

Write-Host "pwsh: $script:pass passed, $script:fail failed"
if ($script:fail -gt 0) { exit 1 }
