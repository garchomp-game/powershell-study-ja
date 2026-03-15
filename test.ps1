Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name g -Value git

function which ($command) {
  Get-Command $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Source
}

function mkcd($dir) {
  New-Item -ItemType Directory -Path $dir -Force
  Set-Location $dir
}

function prompt {
  $location = Get-Location
  "PS $location> "
}

Write-Host "PowerShell $($PSVersionTable.PSVersion) ready!" -ForegroundColor Cyan
