---
title: "使用技法の深掘り"
description: "このプロジェクトで活用したPowerShell技法の詳細解説"
sidebar:
  order: 5
---

このプロジェクトで使われている技法を、テーマ別に深掘りします。

## Linuxの /proc ファイルシステム

PowerShellの `Get-Content` で `/proc` 仮想ファイルシステムを直接読み取ることで、
外部コマンドに頼らずLinuxシステム情報を取得しています。

| ファイル | 内容 | 対応関数 |
|---|---|---|
| `/proc/stat` | CPU使用時間 | `Get-CpuUsage` |
| `/proc/meminfo` | メモリ情報 | `Get-MemoryUsage` |
| `/proc/uptime` | 起動時間 | `Get-SystemUptime` |
| `/proc/loadavg` | Load Average | `Get-LoadAverage` |
| `/sys/class/net/*/statistics/` | ネットワーク統計 | `Get-NetworkInfo` |

```powershell
# bashでの書き方
# cat /proc/meminfo | grep MemTotal | awk '{print $2}'

# PowerShellでの書き方 — オブジェクトで返る
$meminfo = @{}
Get-Content /proc/meminfo | ForEach-Object {
    if ($_ -match '^(\w+):\s+(\d+)') {
        $meminfo[$Matches[1]] = [long]$Matches[2]
    }
}
$meminfo['MemTotal']   # → 16129636（数値として扱える）
```

:::note[bashとの比較]
bashでは `awk`, `sed`, `grep` を組み合わせてテキスト処理しますが、
PowerShellでは正規表現でキャプチャした値を**ハッシュテーブル**に格納し、
型変換して数値演算ができます。
:::

## 設定管理パターン

### JSON → Hashtable 変換

`ConvertFrom-Json` は `PSCustomObject` を返しますが、
動的なキーアクセスには `Hashtable` の方が便利です：

```powershell
class AppConfig {
    # PSCustomObject → Hashtable の再帰変換
    hidden static [hashtable] ToHashtable([PSCustomObject]$obj) {
        $ht = @{}
        foreach ($prop in $obj.PSObject.Properties) {
            if ($prop.Value -is [PSCustomObject]) {
                # ネストされたオブジェクトも再帰的に変換
                $ht[$prop.Name] = [AppConfig]::ToHashtable($prop.Value)
            } else {
                $ht[$prop.Name] = $prop.Value
            }
        }
        return $ht
    }
}
```

**なぜ変換するのか**:

```powershell
# PSCustomObject — 静的なプロパティアクセスは可能
$config.Monitoring.Thresholds.CpuWarning   # ✅

# でも動的なキーアクセスはできない
$key = "CpuWarning"
$config.Monitoring.Thresholds.$key          # ❌ $null になることがある

# Hashtable — 動的キーアクセスが自然
$config.Monitoring.Thresholds[$key]         # ✅ 安全
```

## スプラッティング (@params)

パラメータが多い場合に、ハッシュテーブルにまとめて `@` で渡します：

```powershell
# ❌ 長い横スクロールが必要
Get-ChildItem -Path "/tmp" -Filter "*.txt" -Recurse -Force -ErrorAction SilentlyContinue

# ✅ スプラッティングで読みやすく
$params = @{
    Path        = "/tmp"
    Filter      = "*.txt"
    Recurse     = $true
    Force       = $true
    ErrorAction = 'SilentlyContinue'
}
Get-ChildItem @params    # @で展開（$ではない！）
```

:::caution[@パラメータ展開 vs $ハッシュテーブル]
- `Get-ChildItem @params` → パラメータとして**展開**される
- `Get-ChildItem $params` → **1つの引数**としてハッシュテーブルが渡される

`@` と `$` の違いは頻出の間違いポイントです。
:::

## パイプラインによるデータフロー

このプロジェクトの中核は「**オブジェクトがパイプラインを流れる**」設計です：

```powershell
# メトリクス収集 → フィルタ → ソート → 表示
$report.Metrics | 
    Where-Object { $_.Status -ne 'Healthy' } |   # 異常のみ
    Sort-Object { [int]$_.Status } -Descending |  # 深刻度順
    Format-Table Type, Name, Value, Unit, Status -AutoSize

# ヘルスチェック → HTMLレポート（パイプラインで直結）
Invoke-HealthCheck | New-DashboardHtml -OutputPath ./report.html
```

## エラー処理のパターン

### 段階的なエラー処理

```powershell
# グローバル設定（スクリプト冒頭）
$ErrorActionPreference = "Stop"  # 全ての非終了エラーを終了エラーに

# 個別関数 — 失敗しても続行させたい部分
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.CPU -gt 0 }

# API呼び出し — 個別にtry/catch
try {
    $repo = Invoke-RestMethod -Uri $url -TimeoutSec 10
}
catch {
    Write-Warning "API失敗: $_"
    $results['GitHub'] = $null  # フォールバック値を設定
}
```

### パターン: try/catchでフォールバック

```powershell
# /proc が読めない環境でも動くように
$uptime = try {
    $raw = (Get-Content /proc/uptime) -split '\s+'
    [TimeSpan]::FromSeconds([double]$raw[0])
}
catch {
    Write-Warning "Uptime取得失敗"
    $null
}
```

## 対話メニュー (TUI) パターン

```powershell
# do-while ループでメニュー繰り返し
do {
    Show-Menu                              # メニュー表示関数
    $choice = Read-Host "`n選択"           # ユーザー入力

    switch ($choice) {
        '1' { & ./tools/Invoke-SystemHealthCheck.ps1 }   # & で実行
        '2' {
            $path = Read-Host "ディレクトリ"
            $params = @{ Path = $path }                   # スプラッティング
            & ./tools/Get-ProjectStats.ps1 @params
        }
        'Q' { }
        default { Write-Host "❌ 無効" -ForegroundColor Red }
    }

    if ($choice -notin 'Q','q') {
        Read-Host "Enter で戻る"            # ポーズ
        Clear-Host
    }
} while ($choice -notin 'Q', 'q')
```

**ポイント**:
- `& パス` …スクリプトファイルを実行
- `@params` …スプラッティングでパラメータ渡し
- `Read-Host` …ユーザー入力待ち
- `Clear-Host` …画面クリア

## Format文字列 (-f 演算子)

数値や日付のフォーマットに `-f` 演算子を多用しています：

```powershell
"{0:N1}" -f 3.14159     # → "3.1"（小数1桁）
"{0:N0}" -f 1234567     # → "1,234,567"（桁区切り）
"{0,10:N2}" -f 42.5     # → "     42.50"（右寄せ10桁）
"{0,-10}" -f "hello"    # → "hello     "（左寄せ10桁）
"{0:yyyy-MM-dd}" -f (Get-Date)  # → "2025-03-17"

# 複数値
"[{0:HH:mm:ss}] {1}: {2:N1}%" -f (Get-Date), "CPU", 8.76
# → "[22:30:15] CPU: 8.8%"
```
