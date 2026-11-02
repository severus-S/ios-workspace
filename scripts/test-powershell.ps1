<# Parse all PowerShell scripts and test safe failure paths without login/network mutation. #>
[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
foreach ($file in Get-ChildItem $PSScriptRoot -Filter '*.ps1') {
    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw "$($file.Name): $errors" }
    Write-Host "PARSE PASS $($file.Name)"
}
& pwsh -NoProfile -File "$PSScriptRoot/build-ios.ps1" *> $null
if ($LASTEXITCODE -eq 0) { throw 'Expected missing billing acknowledgement to stop dispatch.' }
Write-Host 'PASS build dispatch billing guard'
& pwsh -NoProfile -File "$PSScriptRoot/publish-ios.ps1" -Paths README.md -Message test *> $null
if ($LASTEXITCODE -eq 0) { throw 'Expected missing billing acknowledgement to stop push.' }
Write-Host 'PASS publish billing guard'
& pwsh -NoProfile -File "$PSScriptRoot/deploy-ios.ps1" -Ipa "$root/README.md" *> $null
if ($LASTEXITCODE -eq 0) { throw 'Expected non-IPA deployment to fail.' }
Write-Host 'PASS deploy rejects non-IPA'
. "$PSScriptRoot/common.ps1"
try {
    Invoke-Checked python @('-c', 'import sys;sys.exit(23)')
    throw 'Expected external process failure was not propagated.'
} catch {
    if ($_.Exception.Message -notmatch 'exit 23') { throw }
}
Write-Host 'PASS external process failure propagation'
