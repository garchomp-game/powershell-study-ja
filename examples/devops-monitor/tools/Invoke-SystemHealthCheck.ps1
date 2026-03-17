<#
.SYNOPSIS
    システムヘルスチェック — 全メトリクス一括収集 + HTMLレポート
.DESCRIPTION
    CPU/メモリ/ディスク/プロセス/ネットワークを収集し、
    コンソールサマリー + HTMLダッシュボードを生成する
.EXAMPLE
    ./Invoke-SystemHealthCheck.ps1
    ./Invoke-SystemHealthCheck.ps1 -OutputFormat JSON -Verbose
#>
[CmdletBinding()]
param(
    [ValidateSet("HTML", "JSON", "Console")]
    [string]$OutputFormat = "HTML"
)

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot
$moduleRoot = Join-Path (Split-Path $scriptRoot) "modules"

# ── モジュールロード ──
Import-Module (Join-Path $moduleRoot "DevOpsCore/DevOpsCore.psm1") -Force
Import-Module (Join-Path $moduleRoot "HtmlReporter/HtmlReporter.psm1") -Force

Write-Host "`n🏥 System Health Check" -ForegroundColor Cyan
Write-Host ("─" * 50) -ForegroundColor DarkGray
Write-Host "ホスト: $(hostname) | 時刻: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# ── ヘルスチェック実行 ──
$report = Invoke-HealthCheck -Verbose:$VerbosePreference

# ── コンソール出力 ──
Write-Host "`n📊 概要" -ForegroundColor Yellow
Write-Host "  ステータス: $($report.OverallStatus)" -ForegroundColor $(
    switch ($report.OverallStatus.ToString()) {
        'Healthy'  { 'Green' }
        'Degraded' { 'Yellow' }
        'Critical' { 'Red' }
        default    { 'Gray' }
    }
)

# メトリクスサマリー
Write-Host "`n📈 メトリクス:" -ForegroundColor Yellow
$report.Metrics | 
    Format-Table @{L='種別';E={$_.Type}},
                 @{L='名前';E={$_.Name}},
                 @{L='値';E={'{0:N2}' -f $_.Value};A='Right'},
                 @{L='単位';E={$_.Unit}},
                 @{L='状態';E={$_.Status}} -AutoSize

# トッププロセス
Write-Host "⚡ プロセス Top 10 (CPU順):" -ForegroundColor Yellow
$report.TopProcesses | Select-Object -First 10 |
    Format-Table PID, Name, 
                 @{L='CPU(s)';E={$_.CPU_Sec};A='Right'},
                 @{L='Mem(MB)';E={$_.MemoryMB};A='Right'},
                 Threads -AutoSize

# ディスク
Write-Host "💾 ディスク:" -ForegroundColor Yellow
$report.DiskUsage | Format-Table Root,
    @{L='合計(GB)';E={$_.TotalGB};A='Right'},
    @{L='使用(GB)';E={$_.UsedGB};A='Right'},
    @{L='空き(GB)';E={$_.FreeGB};A='Right'},
    @{L='使用率';E={"$($_.UsedPercent)%"};A='Right'} -AutoSize

# アラート
if ($report.Alerts.Count -gt 0) {
    Write-Host "🚨 アラート:" -ForegroundColor Red
    $report.Alerts | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
} else {
    Write-Host "✅ アラートなし — 全て正常範囲内です" -ForegroundColor Green
}

# ── 出力形式別処理 ──
switch ($OutputFormat) {
    "HTML" {
        $htmlPath = $report | New-DashboardHtml
        Write-Host "`n📄 HTMLダッシュボード生成: $htmlPath" -ForegroundColor Cyan
        Write-Host "   ブラウザで開く: xdg-open $htmlPath" -ForegroundColor Gray
    }
    "JSON" {
        $jsonDir = "/tmp/devops-reports"
        $null = New-Item -Path $jsonDir -ItemType Directory -Force -ErrorAction SilentlyContinue
        $jsonPath = Join-Path $jsonDir "health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $report | ConvertTo-Json -Depth 5 | Out-File $jsonPath -Encoding utf8
        Write-Host "`n📄 JSON出力: $jsonPath" -ForegroundColor Cyan
    }
    "Console" {
        Write-Host "`n（コンソール出力のみ）" -ForegroundColor Gray
    }
}

Write-Host "`n🏁 完了!`n" -ForegroundColor Green
