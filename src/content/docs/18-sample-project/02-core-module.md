---
title: "コアモジュール解説"
description: "DevOpsCore.psm1 — class・enum・メトリクス収集"
sidebar:
  order: 2
---

`DevOpsCore.psm1` はこのプロジェクトの心臓部です。
**504行**の中に、PowerShellの中級〜上級機能が凝縮されています。

## Enum 定義

Enumは**定数の集合**を型安全に定義します。文字列で状態を管理するより、タイプミスを防げます。

```powershell
enum LogLevel   { Debug; Info; Warning; Error; Critical }
enum HealthStatus { Healthy; Degraded; Critical; Unknown }
enum MetricType { CPU; Memory; Disk; Process; Network; Uptime }
```

**使い方：**

```powershell
$status = [HealthStatus]::Healthy
$status -eq [HealthStatus]::Healthy   # → True

# switch文と組み合わせ
switch ($status) {
    'Healthy'  { Write-Host "正常" -ForegroundColor Green }
    'Critical' { Write-Host "危険" -ForegroundColor Red }
}
```

## Class 設計

### MetricSnapshot — 1回の計測を表すクラス

1回のメトリクス計測を**構造化データ**として保持します。

```powershell
class MetricSnapshot {
    [datetime]$Timestamp      # いつ計測したか
    [MetricType]$Type         # CPU? Memory? Disk?
    [string]$Name             # "Total", "Used" など
    [double]$Value            # 計測値
    [string]$Unit             # "%", "MB", "hours"
    [HealthStatus]$Status     # Healthy / Degraded / Critical

    # ToString() をオーバーライドして見やすく
    [string] ToString() {
        return "[{0:HH:mm:ss}] {1}/{2}: {3:N1} {4} ({5})" -f 
            $this.Timestamp, $this.Type, $this.Name, 
            $this.Value, $this.Unit, $this.Status
    }
}
```

:::tip[なぜPSCustomObjectではなくclassを使うのか]
- **型安全**: `$m.Type = "CPUUU"` のようなタイプミスがコンパイル時に検出される
- **メソッド**: `ToString()` や独自メソッドを定義できる
- **再利用**: 他のクラスでプロパティ型として使える（`[MetricSnapshot[]]$Metrics`）
:::

### SystemReport — 計測結果の集約

```powershell
class SystemReport {
    [string]$Hostname
    [datetime]$GeneratedAt
    [string]$OS
    [string]$PowerShellVersion
    [MetricSnapshot[]]$Metrics        # 全メトリクスの配列
    [PSCustomObject[]]$TopProcesses   # プロセス一覧
    [PSCustomObject[]]$DiskUsage      # ディスク使用量
    [HealthStatus]$OverallStatus      # 最も深刻な状態
    [string[]]$Alerts                 # アラートメッセージ
}
```

**ポイント**: `MetricSnapshot[]` のように**自作クラスの配列型**をプロパティに使えます。

### MetricHistory — 履歴管理クラス

```powershell
class MetricHistory {
    [List[MetricSnapshot]]$Snapshots = [List[MetricSnapshot]]::new()
    [int]$MaxEntries = 1000

    [void] Add([MetricSnapshot]$Snapshot) {
        $this.Snapshots.Add($Snapshot)
        # リングバッファ: 古いデータを自動削除
        if ($this.Snapshots.Count -gt $this.MaxEntries) {
            $this.Snapshots.RemoveAt(0)
        }
    }

    [PSCustomObject] GetStatistics([MetricType]$Type) {
        $filtered = $this.Snapshots | Where-Object { $_.Type -eq $Type }
        $stats = $filtered | Measure-Object -Property Value -Average -Maximum -Minimum
        return [PSCustomObject]@{
            Type = $Type; Average = $stats.Average; Max = $stats.Maximum; Min = $stats.Minimum
        }
    }
}
```

**注目**: `using namespace System.Collections.Generic` を使って `List[T]` をインポートし、
.NETのジェネリックコレクションを活用しています。

### Logger — ファイル＋コンソール出力

```powershell
class Logger {
    [string]$LogFile
    [LogLevel]$MinLevel

    [void] Log([LogLevel]$Level, [string]$Message, [string]$Source = "System") {
        if ($Level -lt $this.MinLevel) { return }  # レベルフィルタ

        $entry = "[{0:yyyy-MM-dd HH:mm:ss}] [{1,-8}] [{2}] {3}" -f 
            (Get-Date), $Level, $Source, $Message

        # 色付きコンソール出力
        $color = switch ($Level) {
            'Debug'    { 'DarkGray' }
            'Info'     { 'Cyan' }
            'Warning'  { 'Yellow' }
            'Error'    { 'Red' }
            'Critical' { 'Magenta' }
        }
        Write-Host $entry -ForegroundColor $color

        # ファイルにも追記
        $entry | Out-File -FilePath $this.LogFile -Append -Encoding utf8
    }

    # ショートカットメソッド
    [void] Info([string]$Message)    { $this.Log([LogLevel]::Info, $Message) }
    [void] Warning([string]$Message) { $this.Log([LogLevel]::Warning, $Message) }
}
```

## メトリクス収集関数

### Get-CpuUsage — /proc/stat からCPU使用率を計算

Linuxの `/proc/stat` を2回読み取り、差分からCPU使用率を算出します。

```powershell
function Get-CpuUsage {
    [CmdletBinding()]
    [OutputType([double])]
    param()

    try {
        # 500ms間隔で2回読む → CPU使用時間の差分を計算
        $stat1 = (Get-Content /proc/stat -TotalCount 1) -split '\s+'
        Start-Sleep -Milliseconds 500
        $stat2 = (Get-Content /proc/stat -TotalCount 1) -split '\s+'

        $idle1 = [long]$stat1[4]; $idle2 = [long]$stat2[4]
        $total1 = ($stat1[1..10] | ForEach-Object { [long]$_ } | Measure-Object -Sum).Sum
        $total2 = ($stat2[1..10] | ForEach-Object { [long]$_ } | Measure-Object -Sum).Sum

        $totalDiff = $total2 - $total1
        $idleDiff  = $idle2 - $idle1

        return [math]::Round((1 - ($idleDiff / $totalDiff)) * 100, 2)
    }
    catch {
        Write-Warning "CPU使用率の取得に失敗: $_"
        return -1
    }
}
```

:::note[/proc/stat のフォーマット]
```
cpu  user nice system idle iowait irq softirq steal guest guest_nice
cpu  374292 428 101588 4839498 12272 52498 8840 0 0 0
```
4番目のフィールド（idle）の変化量から、CPU使用率を逆算しています。
:::

### Get-MemoryUsage — /proc/meminfo からメモリ情報

```powershell
function Get-MemoryUsage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $meminfo = @{}
    # 正規表現で key: value 形式を解析
    Get-Content /proc/meminfo | ForEach-Object {
        if ($_ -match '^(\w+):\s+(\d+)') {
            $meminfo[$Matches[1]] = [long]$Matches[2]
        }
    }

    $totalMB     = [math]::Round($meminfo['MemTotal'] / 1024, 0)
    $availableMB = [math]::Round($meminfo['MemAvailable'] / 1024, 0)
    $usedMB      = $totalMB - $availableMB
    $usedPercent = [math]::Round(($usedMB / $totalMB) * 100, 1)

    [PSCustomObject]@{
        TotalMB     = $totalMB
        UsedMB      = $usedMB
        AvailableMB = $availableMB
        UsedPercent = $usedPercent
    }
}
```

**テクニック**: `@{}` ハッシュテーブルに正規表現のキャプチャグループ `$Matches[1]`, `$Matches[2]` で動的にデータを格納しています。

### Get-DiskUsage — PSDrive プロバイダー活用

```powershell
function Get-DiskUsage {
    # Get-PSDrive → FileSystemプロバイダーのドライブのみ抽出
    Get-PSDrive -PSProvider FileSystem | 
        Where-Object { $_.Used -or $_.Free } |
        ForEach-Object {
            $totalGB = [math]::Round(($_.Used + $_.Free) / 1GB, 2)
            [PSCustomObject]@{
                Drive       = $_.Name
                Root        = $_.Root
                TotalGB     = $totalGB
                UsedGB      = [math]::Round($_.Used / 1GB, 2)
                FreeGB      = [math]::Round($_.Free / 1GB, 2)
                UsedPercent = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 1)
            }
        }
}
```

**ポイント**: Linuxの `df` コマンドではなく、PowerShellの**PSDriveプロバイダー**を使ってディスク情報を取得しています。プロバイダーはファイルシステムだけでなく、環境変数 (`Env:`) や変数 (`Variable:`) も同じインターフェースで扱えます。

## Export-ModuleMember

モジュールが外部に公開する関数を明示的に指定します：

```powershell
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
```

ここに含まれない関数（Loggerクラスのメソッドなど）はモジュール**内部でのみ**使用可能です。
これにより**カプセル化**が実現されています。
