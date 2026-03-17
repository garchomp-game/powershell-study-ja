<#
.SYNOPSIS
    リアルタイムシステム監視 — メトリクスの定期収集 + 統計分析
.DESCRIPTION
    指定間隔でCPU/メモリ/Load Averageを収集し、
    リアルタイムコンソール表示 + 収集完了後に統計レポートを出力する
    
    使用機能: ForEach-Object -Parallel / Write-Progress / 
             MetricHistory class / タイマー / ANSI色制御
.EXAMPLE
    ./Watch-SystemMetrics.ps1 -IntervalSeconds 3 -Duration 30
    ./Watch-SystemMetrics.ps1 -IntervalSeconds 1 -Duration 10 -Verbose
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 60)]
    [int]$IntervalSeconds = 3,

    [ValidateRange(5, 600)]
    [int]$Duration = 30,

    [switch]$ExportCsv
)

$ErrorActionPreference = "Stop"
$moduleRoot = Join-Path (Split-Path $PSScriptRoot) "modules"
Import-Module (Join-Path $moduleRoot "DevOpsCore/DevOpsCore.psm1") -Force

# ── 初期化 ──
$iterations = [math]::Ceiling($Duration / $IntervalSeconds)
$history = @()
$startTime = Get-Date

Write-Host "`n📡 System Metrics Monitor" -ForegroundColor Cyan
Write-Host ("─" * 60) -ForegroundColor DarkGray
Write-Host "間隔: ${IntervalSeconds}秒 | 期間: ${Duration}秒 | 計測回数: $iterations" -ForegroundColor Gray
Write-Host "停止: Ctrl+C`n" -ForegroundColor DarkGray

# ── ヘッダー ──
$header = "{0,-10} {1,8} {2,8} {3,10} {4,10} {5,8} {6,8} {7,8}" -f 
    "時刻", "CPU%", "MEM%", "MEM(MB)", "空きMB", "Load1m", "Load5m", "Load15m"
Write-Host $header -ForegroundColor DarkGray
Write-Host ("-" * 80) -ForegroundColor DarkGray

# ── メトリクス収集ループ ──
for ($i = 1; $i -le $iterations; $i++) {
    # Write-Progress でプログレスバー表示
    $pct = [math]::Round(($i / $iterations) * 100)
    $elapsed = (Get-Date) - $startTime
    Write-Progress -Activity "メトリクス収集中" `
        -Status "[$i/$iterations] 経過: $([math]::Round($elapsed.TotalSeconds))秒" `
        -PercentComplete $pct

    # CPU計測（Get-CpuUsage は内部で500ms待つ）
    $cpu = Get-CpuUsage

    # メモリ
    $mem = Get-MemoryUsage

    # Load Average
    $load = Get-LoadAverage

    # 結果をオブジェクトに
    $snapshot = [PSCustomObject]@{
        Timestamp   = Get-Date
        TimeStr     = (Get-Date).ToString("HH:mm:ss")
        CPU         = $cpu
        MemPercent  = if ($mem) { $mem.UsedPercent } else { 0 }
        MemUsedMB   = if ($mem) { $mem.UsedMB } else { 0 }
        MemFreeMB   = if ($mem) { $mem.AvailableMB } else { 0 }
        Load1       = if ($load) { $load.OneMin } else { 0 }
        Load5       = if ($load) { $load.FiveMin } else { 0 }
        Load15      = if ($load) { $load.FifteenMin } else { 0 }
    }
    $history += $snapshot

    # ── 色付きコンソール出力 ──
    $cpuColor = if ($cpu -ge 90) { 'Red' } elseif ($cpu -ge 70) { 'Yellow' } else { 'Green' }
    $memColor = if ($snapshot.MemPercent -ge 95) { 'Red' } elseif ($snapshot.MemPercent -ge 80) { 'Yellow' } else { 'Green' }

    $line = "{0,-10}" -f $snapshot.TimeStr
    Write-Host $line -NoNewline
    Write-Host ("{0,8:N1}" -f $cpu) -NoNewline -ForegroundColor $cpuColor
    Write-Host ("{0,8:N1}" -f $snapshot.MemPercent) -NoNewline -ForegroundColor $memColor
    Write-Host ("{0,10:N0}" -f $snapshot.MemUsedMB) -NoNewline -ForegroundColor Gray
    Write-Host ("{0,10:N0}" -f $snapshot.MemFreeMB) -NoNewline -ForegroundColor Gray
    Write-Host ("{0,8:N2}" -f $snapshot.Load1) -NoNewline -ForegroundColor $(if ($snapshot.Load1 -gt 6) {'Red'} elseif ($snapshot.Load1 -gt 3) {'Yellow'} else {'Cyan'})
    Write-Host ("{0,8:N2}" -f $snapshot.Load5) -NoNewline -ForegroundColor Gray
    Write-Host ("{0,8:N2}" -f $snapshot.Load15) -ForegroundColor Gray

    # 次の計測まで待機（CPU計測分の0.5秒を引く）
    $waitMs = [math]::Max(0, ($IntervalSeconds * 1000) - 500)
    if ($i -lt $iterations) {
        Start-Sleep -Milliseconds $waitMs
    }
}

Write-Progress -Activity "メトリクス収集中" -Completed

# ── 統計レポート ──
Write-Host "`n" + ("─" * 60) -ForegroundColor DarkGray
Write-Host "📊 統計サマリー ($($history.Count)回の計測)" -ForegroundColor Cyan

$cpuStats = $history | Measure-Object -Property CPU -Average -Maximum -Minimum
$memStats = $history | Measure-Object -Property MemPercent -Average -Maximum -Minimum
$loadStats = $history | Measure-Object -Property Load1 -Average -Maximum -Minimum

$statsTable = @(
    [PSCustomObject]@{ メトリクス = "CPU (%)"; 平均 = "{0:N1}" -f $cpuStats.Average; 最小 = "{0:N1}" -f $cpuStats.Minimum; 最大 = "{0:N1}" -f $cpuStats.Maximum }
    [PSCustomObject]@{ メトリクス = "Memory (%)"; 平均 = "{0:N1}" -f $memStats.Average; 最小 = "{0:N1}" -f $memStats.Minimum; 最大 = "{0:N1}" -f $memStats.Maximum }
    [PSCustomObject]@{ メトリクス = "Load Avg (1m)"; 平均 = "{0:N2}" -f $loadStats.Average; 最小 = "{0:N2}" -f $loadStats.Minimum; 最大 = "{0:N2}" -f $loadStats.Maximum }
)

$statsTable | Format-Table -AutoSize

# ── CSV出力 ──
if ($ExportCsv) {
    $csvDir = "/tmp/devops-reports"
    $null = New-Item -Path $csvDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    $csvPath = Join-Path $csvDir "metrics-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $history | Select-Object TimeStr, CPU, MemPercent, MemUsedMB, MemFreeMB, Load1, Load5, Load15 |
        Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8
    Write-Host "📄 CSV出力: $csvPath" -ForegroundColor Cyan
}

Write-Host "`n🏁 監視完了!`n" -ForegroundColor Green
