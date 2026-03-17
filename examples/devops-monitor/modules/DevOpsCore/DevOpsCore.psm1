# ===========================================================================
# DevOpsCore.psm1 — コアモジュール
# 
# 使用機能: class / enum / CmdletBinding / ValidateSet / Pipeline /
#          Get-Process / Get-PSDrive / Regex / JSON / エラー処理
# ===========================================================================

using namespace System.Collections.Generic

# ── Enums ──────────────────────────────────────────────

enum LogLevel   { Debug; Info; Warning; Error; Critical }
enum HealthStatus { Healthy; Degraded; Critical; Unknown }
enum MetricType { CPU; Memory; Disk; Process; Network; Uptime }

# ── Classes ────────────────────────────────────────────

class AppConfig {
    [string]$AppName
    [string]$Version
    [hashtable]$Monitoring
    [hashtable]$Api
    [hashtable]$Report
    [hashtable]$Logging

    static [AppConfig] Load([string]$Path) {
        if (-not (Test-Path $Path)) {
            throw "設定ファイルが見つかりません: $Path"
        }
        $json = Get-Content $Path -Raw | ConvertFrom-Json
        $config = [AppConfig]::new()
        $config.AppName    = $json.AppName
        $config.Version    = $json.Version
        # PSCustomObject → Hashtable 変換
        $config.Monitoring = [AppConfig]::ToHashtable($json.Monitoring)
        $config.Api        = [AppConfig]::ToHashtable($json.Api)
        $config.Report     = [AppConfig]::ToHashtable($json.Report)
        $config.Logging    = [AppConfig]::ToHashtable($json.Logging)
        return $config
    }

    hidden static [hashtable] ToHashtable([PSCustomObject]$obj) {
        $ht = @{}
        foreach ($prop in $obj.PSObject.Properties) {
            if ($prop.Value -is [PSCustomObject]) {
                $ht[$prop.Name] = [AppConfig]::ToHashtable($prop.Value)
            } else {
                $ht[$prop.Name] = $prop.Value
            }
        }
        return $ht
    }
}

class MetricSnapshot {
    [datetime]$Timestamp
    [MetricType]$Type
    [string]$Name
    [double]$Value
    [string]$Unit
    [HealthStatus]$Status

    [string] ToString() {
        return "[{0:HH:mm:ss}] {1}/{2}: {3:N1} {4} ({5})" -f 
            $this.Timestamp, $this.Type, $this.Name, $this.Value, $this.Unit, $this.Status
    }
}

class SystemReport {
    [string]$Hostname
    [datetime]$GeneratedAt
    [string]$OS
    [string]$PowerShellVersion
    [MetricSnapshot[]]$Metrics
    [PSCustomObject[]]$TopProcesses
    [PSCustomObject[]]$DiskUsage
    [HealthStatus]$OverallStatus
    [string[]]$Alerts

    [string] GetSummary() {
        $alertCount = $this.Alerts.Count
        return "$($this.Hostname): $($this.OverallStatus) | メトリクス: $($this.Metrics.Count) | アラート: $alertCount"
    }
}

class MetricHistory {
    [List[MetricSnapshot]]$Snapshots = [List[MetricSnapshot]]::new()
    [int]$MaxEntries = 1000

    [void] Add([MetricSnapshot]$Snapshot) {
        $this.Snapshots.Add($Snapshot)
        if ($this.Snapshots.Count -gt $this.MaxEntries) {
            $this.Snapshots.RemoveAt(0)
        }
    }

    [MetricSnapshot[]] GetLast([int]$Count) {
        $start = [Math]::Max(0, $this.Snapshots.Count - $Count)
        return $this.Snapshots.GetRange($start, [Math]::Min($Count, $this.Snapshots.Count)).ToArray()
    }

    [PSCustomObject] GetStatistics([MetricType]$Type) {
        $filtered = $this.Snapshots | Where-Object { $_.Type -eq $Type }
        if (-not $filtered) { return $null }
        $stats = $filtered | Measure-Object -Property Value -Average -Maximum -Minimum
        return [PSCustomObject]@{
            Type    = $Type
            Samples = $stats.Count
            Average = [math]::Round($stats.Average, 2)
            Max     = [math]::Round($stats.Maximum, 2)
            Min     = [math]::Round($stats.Minimum, 2)
        }
    }
}

# ── Logger ─────────────────────────────────────────────

class Logger {
    [string]$LogFile
    [LogLevel]$MinLevel
    hidden [object]$Lock = [object]::new()

    Logger([string]$LogFile, [LogLevel]$MinLevel) {
        $this.LogFile = $LogFile
        $this.MinLevel = $MinLevel
        $dir = Split-Path $LogFile -Parent
        if ($dir -and -not (Test-Path $dir)) {
            $null = New-Item -Path $dir -ItemType Directory -Force
        }
    }

    [void] Log([LogLevel]$Level, [string]$Message, [string]$Source = "System") {
        if ($Level -lt $this.MinLevel) { return }

        $entry = "[{0:yyyy-MM-dd HH:mm:ss}] [{1,-8}] [{2}] {3}" -f 
            (Get-Date), $Level, $Source, $Message

        # コンソール出力（色付き）
        $color = switch ($Level) {
            'Debug'    { 'DarkGray' }
            'Info'     { 'Cyan' }
            'Warning'  { 'Yellow' }
            'Error'    { 'Red' }
            'Critical' { 'Magenta' }
        }
        Write-Host $entry -ForegroundColor $color

        # ファイル出力
        try {
            $entry | Out-File -FilePath $this.LogFile -Append -Encoding utf8
        }
        catch {
            Write-Warning "ログ書き込み失敗: $_"
        }
    }

    [void] Info([string]$Message)     { $this.Log([LogLevel]::Info, $Message) }
    [void] Warning([string]$Message)  { $this.Log([LogLevel]::Warning, $Message) }
    [void] Error([string]$Message)    { $this.Log([LogLevel]::Error, $Message) }
    [void] Debug([string]$Message)    { $this.Log([LogLevel]::Debug, $Message) }
}

# ── Metric Collection Functions ────────────────────────

function Get-CpuUsage {
    <#
    .SYNOPSIS
        Linux環境のCPU使用率を取得（/proc/stat ベース）
    .OUTPUTS
        [double] CPU使用率（パーセント）
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param()

    try {
        # /proc/stat の最初の行から計算
        $stat1 = (Get-Content /proc/stat -TotalCount 1) -split '\s+'
        Start-Sleep -Milliseconds 500
        $stat2 = (Get-Content /proc/stat -TotalCount 1) -split '\s+'

        $idle1 = [long]$stat1[4]; $idle2 = [long]$stat2[4]
        $total1 = ($stat1[1..10] | ForEach-Object { [long]$_ } | Measure-Object -Sum).Sum
        $total2 = ($stat2[1..10] | ForEach-Object { [long]$_ } | Measure-Object -Sum).Sum

        $totalDiff = $total2 - $total1
        $idleDiff  = $idle2 - $idle1

        if ($totalDiff -eq 0) { return 0.0 }
        return [math]::Round((1 - ($idleDiff / $totalDiff)) * 100, 2)
    }
    catch {
        Write-Warning "CPU使用率の取得に失敗: $_"
        return -1
    }
}

function Get-MemoryUsage {
    <#
    .SYNOPSIS
        Linux環境のメモリ使用状況を取得（/proc/meminfo ベース）
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        $meminfo = @{}
        Get-Content /proc/meminfo | ForEach-Object {
            if ($_ -match '^(\w+):\s+(\d+)') {
                $meminfo[$Matches[1]] = [long]$Matches[2]
            }
        }

        $totalMB     = [math]::Round($meminfo['MemTotal'] / 1024, 0)
        $availableMB = [math]::Round($meminfo['MemAvailable'] / 1024, 0)
        $usedMB      = $totalMB - $availableMB
        $usedPercent = [math]::Round(($usedMB / $totalMB) * 100, 1)

        # Swap
        $swapTotalMB = [math]::Round($meminfo['SwapTotal'] / 1024, 0)
        $swapFreeMB  = [math]::Round($meminfo['SwapFree'] / 1024, 0)
        $swapUsedMB  = $swapTotalMB - $swapFreeMB

        [PSCustomObject]@{
            TotalMB      = $totalMB
            UsedMB       = $usedMB
            AvailableMB  = $availableMB
            UsedPercent  = $usedPercent
            SwapTotalMB  = $swapTotalMB
            SwapUsedMB   = $swapUsedMB
        }
    }
    catch {
        Write-Warning "メモリ情報の取得に失敗: $_"
        return $null
    }
}

function Get-DiskUsage {
    <#
    .SYNOPSIS
        ディスク使用状況をPSDriveから取得
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    Get-PSDrive -PSProvider FileSystem | 
        Where-Object { $_.Used -or $_.Free } |
        ForEach-Object {
            $totalGB = [math]::Round(($_.Used + $_.Free) / 1GB, 2)
            $usedGB  = [math]::Round($_.Used / 1GB, 2)
            $freeGB  = [math]::Round($_.Free / 1GB, 2)
            $pct     = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 1) } else { 0 }

            [PSCustomObject]@{
                Drive       = $_.Name
                Root        = $_.Root
                TotalGB     = $totalGB
                UsedGB      = $usedGB
                FreeGB      = $freeGB
                UsedPercent = $pct
            }
        }
}

function Get-SystemUptime {
    <#
    .SYNOPSIS
        Linux環境のUptime（/proc/uptime ベース）
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        $raw = (Get-Content /proc/uptime) -split '\s+'
        $seconds = [double]$raw[0]
        $ts = [TimeSpan]::FromSeconds($seconds)

        [PSCustomObject]@{
            Days    = $ts.Days
            Hours   = $ts.Hours
            Minutes = $ts.Minutes
            TotalHours = [math]::Round($ts.TotalHours, 1)
            Display = "{0}d {1}h {2}m" -f $ts.Days, $ts.Hours, $ts.Minutes
        }
    }
    catch {
        Write-Warning "Uptime取得に失敗: $_"
        return $null
    }
}

function Get-TopProcesses {
    <#
    .SYNOPSIS
        CPU/メモリ使用量でプロセスを取得してリッチなオブジェクトで返す
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 100)]
        [int]$Count = 15,
        
        [ValidateSet("CPU", "Memory")]
        [string]$SortBy = "CPU"
    )

    $sortProp = switch ($SortBy) {
        "CPU"    { "CPU" }
        "Memory" { "WorkingSet64" }
    }

    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.CPU -gt 0 -or $_.WorkingSet64 -gt 0 } |
        Sort-Object $sortProp -Descending |
        Select-Object -First $Count |
        ForEach-Object {
            $startStr = "N/A"
            $runStr = "N/A"
            try { $startStr = $_.StartTime.ToString("HH:mm:ss") } catch { }
            try {
                $span = (Get-Date) - $_.StartTime
                $runStr = "{0:N1}h" -f $span.TotalHours
            } catch { }

            [PSCustomObject]@{
                PID        = $_.Id
                Name       = $_.ProcessName
                CPU_Sec    = [math]::Round($_.CPU, 2)
                MemoryMB   = [math]::Round($_.WorkingSet64 / 1MB, 1)
                Threads    = $_.Threads.Count
                StartTime  = $startStr
                RunningFor = $runStr
            }
        }
}

function Get-NetworkInfo {
    <#
    .SYNOPSIS
        ネットワークインターフェース情報を取得
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    try {
        $interfaces = Get-ChildItem /sys/class/net -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'lo' } |
            ForEach-Object {
                $name = $_.Name
                $state = (Get-Content "/sys/class/net/$name/operstate" -ErrorAction SilentlyContinue) ?? "unknown"
                $rxBytes = [long](Get-Content "/sys/class/net/$name/statistics/rx_bytes" -ErrorAction SilentlyContinue) 
                $txBytes = [long](Get-Content "/sys/class/net/$name/statistics/tx_bytes" -ErrorAction SilentlyContinue)

                [PSCustomObject]@{
                    Interface = $name
                    State     = $state
                    RxMB      = [math]::Round($rxBytes / 1MB, 2)
                    TxMB      = [math]::Round($txBytes / 1MB, 2)
                }
            }
        return $interfaces
    }
    catch {
        Write-Warning "ネットワーク情報の取得に失敗: $_"
        return @()
    }
}

function Get-LoadAverage {
    <#
    .SYNOPSIS
        Load Average を取得（/proc/loadavg）
    #>
    [CmdletBinding()]
    param()
    
    try {
        $parts = (Get-Content /proc/loadavg) -split '\s+'
        [PSCustomObject]@{
            OneMin     = [double]$parts[0]
            FiveMin    = [double]$parts[1]
            FifteenMin = [double]$parts[2]
            RunningProcs = ($parts[3] -split '/')[0]
            TotalProcs   = ($parts[3] -split '/')[1]
        }
    }
    catch { return $null }
}

function Invoke-HealthCheck {
    <#
    .SYNOPSIS
        全メトリクスを収集してリッチなレポートを生成
    .DESCRIPTION
        CPU/メモリ/ディスク/プロセス/ネットワーク/Uptimeを一括収集し、
        閾値と照合してアラートを付与したSystemReportオブジェクトを返す
    #>
    [CmdletBinding()]
    [OutputType([SystemReport])]
    param(
        [Parameter()]
        [hashtable]$Thresholds = @{
            CpuWarning     = 70;  CpuCritical     = 90
            MemoryWarning  = 80;  MemoryCritical   = 95
            DiskWarning    = 85;  DiskCritical     = 95
        }
    )

    $report = [SystemReport]::new()
    $report.Hostname = (hostname)
    $report.GeneratedAt = Get-Date
    $report.OS = $PSVersionTable.OS
    $report.PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    $report.Alerts = @()

    $metrics = [List[MetricSnapshot]]::new()

    # CPU
    Write-Verbose "CPU計測中..."
    $cpu = Get-CpuUsage
    $cpuStatus = if ($cpu -ge $Thresholds.CpuCritical) { [HealthStatus]::Critical }
                 elseif ($cpu -ge $Thresholds.CpuWarning) { [HealthStatus]::Degraded }
                 else { [HealthStatus]::Healthy }
    $m = [MetricSnapshot]::new()
    $m.Timestamp = Get-Date; $m.Type = [MetricType]::CPU; $m.Name = "Total"
    $m.Value = $cpu; $m.Unit = "%"; $m.Status = $cpuStatus
    $metrics.Add($m)
    if ($cpuStatus -ne [HealthStatus]::Healthy) {
        $report.Alerts += "⚠️ CPU使用率が高い: ${cpu}%"
    }

    # Memory
    Write-Verbose "メモリ計測中..."
    $mem = Get-MemoryUsage
    if ($mem) {
        $memStatus = if ($mem.UsedPercent -ge $Thresholds.MemoryCritical) { [HealthStatus]::Critical }
                     elseif ($mem.UsedPercent -ge $Thresholds.MemoryWarning) { [HealthStatus]::Degraded }
                     else { [HealthStatus]::Healthy }
        $m = [MetricSnapshot]::new()
        $m.Timestamp = Get-Date; $m.Type = [MetricType]::Memory; $m.Name = "Used"
        $m.Value = $mem.UsedPercent; $m.Unit = "%"; $m.Status = $memStatus
        $metrics.Add($m)

        $m2 = [MetricSnapshot]::new()
        $m2.Timestamp = Get-Date; $m2.Type = [MetricType]::Memory; $m2.Name = "UsedMB"
        $m2.Value = $mem.UsedMB; $m2.Unit = "MB"; $m2.Status = $memStatus
        $metrics.Add($m2)

        if ($memStatus -ne [HealthStatus]::Healthy) {
            $report.Alerts += "⚠️ メモリ使用率が高い: $($mem.UsedPercent)% ($($mem.UsedMB)/$($mem.TotalMB) MB)"
        }
    }

    # Disk
    Write-Verbose "ディスク計測中..."
    $report.DiskUsage = Get-DiskUsage
    foreach ($disk in $report.DiskUsage) {
        $diskStatus = if ($disk.UsedPercent -ge $Thresholds.DiskCritical) { [HealthStatus]::Critical }
                      elseif ($disk.UsedPercent -ge $Thresholds.DiskWarning) { [HealthStatus]::Degraded }
                      else { [HealthStatus]::Healthy }
        $m = [MetricSnapshot]::new()
        $m.Timestamp = Get-Date; $m.Type = [MetricType]::Disk; $m.Name = $disk.Root
        $m.Value = $disk.UsedPercent; $m.Unit = "%"; $m.Status = $diskStatus
        $metrics.Add($m)

        if ($diskStatus -ne [HealthStatus]::Healthy) {
            $report.Alerts += "⚠️ ディスク $($disk.Root) の使用率: $($disk.UsedPercent)%"
        }
    }

    # Uptime
    $uptime = Get-SystemUptime
    if ($uptime) {
        $m = [MetricSnapshot]::new()
        $m.Timestamp = Get-Date; $m.Type = [MetricType]::Uptime; $m.Name = "System"
        $m.Value = $uptime.TotalHours; $m.Unit = "hours"; $m.Status = [HealthStatus]::Healthy
        $metrics.Add($m)
    }

    # Processes
    $report.TopProcesses = Get-TopProcesses -Count 15 -SortBy CPU
    $report.Metrics = $metrics.ToArray()

    # Overall status
    $worstStatus = $metrics | 
        Sort-Object { [int]$_.Status } -Descending |
        Select-Object -First 1 -ExpandProperty Status
    $report.OverallStatus = $worstStatus ?? [HealthStatus]::Unknown

    return $report
}

# ── Export ─────────────────────────────────────────────

Export-ModuleMember -Function @(
    'Get-CpuUsage'
    'Get-MemoryUsage'
    'Get-DiskUsage'
    'Get-SystemUptime'
    'Get-TopProcesses'
    'Get-NetworkInfo'
    'Get-LoadAverage'
    'Invoke-HealthCheck'
)
