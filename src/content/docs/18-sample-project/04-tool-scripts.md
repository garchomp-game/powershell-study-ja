---
title: "ツールスクリプト解説"
description: "4つのツールスクリプトの設計と実装"
sidebar:
  order: 4
---

`tools/` ディレクトリには4つの実行可能スクリプトがあります。
それぞれが異なるPowerShell技法を活用しています。

## 1. Invoke-SystemHealthCheck.ps1

**目的**: 全システムメトリクスを一括収集 → コンソール表示 + HTMLレポート

### パラメータ設計

```powershell
[CmdletBinding()]
param(
    [ValidateSet("HTML", "JSON", "Console")]  # 選択肢を制限
    [string]$OutputFormat = "HTML"             # デフォルト値付き
)
```

`ValidateSet` によりユーザーは `HTML`, `JSON`, `Console` のいずれかしか指定できません。

### モジュール読み込みパターン

```powershell
# スクリプトの位置から相対パスでモジュールを探す
$scriptRoot = $PSScriptRoot
$moduleRoot = Join-Path (Split-Path $scriptRoot) "modules"

Import-Module (Join-Path $moduleRoot "DevOpsCore/DevOpsCore.psm1") -Force
Import-Module (Join-Path $moduleRoot "HtmlReporter/HtmlReporter.psm1") -Force
```

:::tip[$PSScriptRootとは]
実行中のスクリプトが置かれている**ディレクトリ**のパス。
これを使うことで、どこから実行しても正しいパスを解決できます。
:::

### 計算プロパティによるカスタム表示

```powershell
$report.Metrics | 
    Format-Table @{L='種別';E={$_.Type}},         # Label + Expression
                 @{L='名前';E={$_.Name}},
                 @{L='値';E={'{0:N2}' -f $_.Value};A='Right'},  # 右寄せ
                 @{L='単位';E={$_.Unit}},
                 @{L='状態';E={$_.Status}} -AutoSize
```

`@{L=;E=;A=}` は`Format-Table`の**計算プロパティ**で、表示名・値の加工・配置をカスタマイズできます。

---

## 2. Get-ProjectStats.ps1

**目的**: コードベースの言語別統計 + TODO検出 + 依存関係分析

### 除外パターン（正規表現）

```powershell
$excludeDirs = 'node_modules|\.git|vendor|__pycache__|\.venv|dist'

# ファイル収集時にフィルタ
$files = Get-ChildItem -Path $Path -Recurse -File |
    Where-Object { $_.FullName -notmatch $excludeDirs }
```

### Group-Object + Measure-Object パターン

言語別統計の集計は、PowerShellの**集約コマンド**のコンビネーションです：

```powershell
$langStats = $codeFiles | 
    ForEach-Object {
        [PSCustomObject]@{
            Language = $lang
            Lines = (Get-Content $_.FullName).Count
        }
    } | 
    Group-Object Language |                          # 言語でグループ化
    Select-Object @{L='言語';E={$_.Name}},
        @{L='ファイル';E={$_.Count}},
        @{L='行数';E={($_.Group | Measure-Object Lines -Sum).Sum}} |  # 合計
    Sort-Object 行数 -Descending
```

```mermaid
graph LR
    A["ファイル一覧"] -->|ForEach-Object| B["言語+行数<br/>オブジェクト"]
    B -->|Group-Object| C["言語別<br/>グループ"]
    C -->|Select-Object| D["計算プロパティ<br/>で集計"]
    D -->|Sort-Object| E["行数降順<br/>結果"]
    
    style A fill:#58a6ff,color:#0d1117
    style E fill:#3fb950,color:#0d1117
```

### Select-String によるTODO検出

```powershell
$markers = $codeFiles | ForEach-Object {
    Select-String -Path $_.FullName `
        -Pattern '\b(TODO|FIXME|HACK|XXX|BUG)\b' `
        -AllMatches
}

# 結果の集計
$markers | ForEach-Object { $_.Matches | ForEach-Object { $_.Value } } |
    Group-Object | 
    Select-Object Name, Count
```

`Select-String` はLinuxの`grep`に相当しますが、**オブジェクト**を返すため、
`$_.LineNumber`, `$_.Line`, `$_.Matches` など構造化されたデータにアクセスできます。

---

## 3. Watch-SystemMetrics.ps1

**目的**: 一定間隔でメトリクスを収集し、リアルタイムでコンソール表示

### パラメータバリデーション

```powershell
param(
    [ValidateRange(1, 60)]    # 1〜60の範囲のみ許可
    [int]$IntervalSeconds = 3,

    [ValidateRange(5, 600)]   # 5秒〜10分
    [int]$Duration = 30,

    [switch]$ExportCsv        # フラグパラメータ
)
```

### Write-Progress による進捗表示

```powershell
for ($i = 1; $i -le $iterations; $i++) {
    $pct = [math]::Round(($i / $iterations) * 100)
    Write-Progress -Activity "メトリクス収集中" `
        -Status "[$i/$iterations] 経過: $([math]::Round($elapsed.TotalSeconds))秒" `
        -PercentComplete $pct
}
Write-Progress -Activity "メトリクス収集中" -Completed  # 完了時に消す
```

### 色付きコンソール出力

```powershell
$cpuColor = if ($cpu -ge 90) { 'Red' } 
            elseif ($cpu -ge 70) { 'Yellow' } 
            else { 'Green' }

# -NoNewline で同じ行に出力、色を変えて続ける
Write-Host ("{0,8:N1}" -f $cpu) -NoNewline -ForegroundColor $cpuColor
```

### 統計サマリー（Measure-Object）

```powershell
$cpuStats = $history | Measure-Object -Property CPU -Average -Maximum -Minimum
# → $cpuStats.Average, $cpuStats.Maximum, $cpuStats.Minimum
```

---

## 4. Invoke-ApiDashboard.ps1

**目的**: REST APIを呼び出し、データを集約してレポート

### Invoke-RestMethod

JSONを自動的に**PSCustomObject**に変換して返します：

```powershell
# GitHub API — 結果は即座にオブジェクトとしてアクセス可能
$repo = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo" `
    -TimeoutSec $TimeoutSec

$repo.stargazers_count   # → 数値（文字列ではない！）
$repo.language           # → "C#"
$repo.license.name       # → "MIT License"
```

### Measure-Command による応答速度計測

```powershell
$timer = Measure-Command {
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -Method Head
}
Write-Host "$([math]::Round($timer.TotalMilliseconds)) ms"
```

`Measure-Command` はスクリプトブロック内の処理時間を計測する**ベンチマークツール**です。

### 複数URLの並列ベンチマーク

```powershell
$urls = @(
    @{ Name = "Google"; Url = "https://www.google.com" }
    @{ Name = "GitHub"; Url = "https://github.com" }
    @{ Name = "Cloudflare"; Url = "https://1.1.1.1" }
)

$benchResults = $urls | ForEach-Object {
    $entry = $_
    try {
        $timer = Measure-Command {
            Invoke-WebRequest -Uri $entry.Url -TimeoutSec 5 -Method Head
        }
        [PSCustomObject]@{
            サイト = $entry.Name
            応答ms = [math]::Round($timer.TotalMilliseconds)
        }
    }
    catch {
        [PSCustomObject]@{ サイト = $entry.Name; 応答ms = 99999 }
    }
}

# 平均応答時間
($benchResults | Where-Object 応答ms -lt 99999 | Measure-Object 応答ms -Average).Average
```
