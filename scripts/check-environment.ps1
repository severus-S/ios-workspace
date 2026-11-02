<# Read-only local checks. No credentials are printed. Run from any directory. #>
[CmdletBinding()] param()
. "$PSScriptRoot/common.ps1"
$report = [ordered]@{ checkedAt = (Get-Date -Format o); root = $script:Root; windows = $IsWindows }
foreach ($name in @('git','python','pwsh')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    $report[$name] = if ($cmd) { $cmd.Source } else { 'MISSING' }
}
try {
    $gh = Get-Gh
    $report['gh'] = $gh
    & $gh auth status *> $null
    $report['githubAuthenticated'] = ($LASTEXITCODE -eq 0)
} catch { $report['gh'] = 'MISSING'; $report['githubAuthenticated'] = $false }
foreach ($service in @('Bonjour Service','Apple Mobile Device Service')) {
    $s = Get-Service -Name $service -ErrorAction SilentlyContinue
    $report[$service] = if ($s) { [string]$s.Status } else { 'NOT DETECTED' }
}
$report['Sideloadly'] = 'Check installed apps/UI; portable/custom paths are not exhaustively detected'
$report | ConvertTo-Json
Write-Host 'Windows checks do not prove Xcode build, phone pairing, installation or renewal.'
