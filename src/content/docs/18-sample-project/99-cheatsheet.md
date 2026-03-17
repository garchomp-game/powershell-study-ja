---
title: "実践プロジェクト チートシート"
description: "DevOps Monitor Toolkit — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## プロジェクト構成パターン

| 要素 | 命名規則 | 例 |
|---|---|---|
| モジュール | `名前.psm1` | `DevOpsCore.psm1` |
| 設定 | `settings.json` | JSON → Hashtable変換 |
| ツール | `Verb-Noun.ps1` | `Invoke-SystemHealthCheck.ps1` |
| エントリーポイント | `Start-*.ps1` | `Start-DevOpsMonitor.ps1` |

## Linux /proc ファイルシステム

| ファイル | 内容 | 読み方 |
|---|---|---|
| `/proc/stat` | CPU時間 | 2回読み→差分計算 |
| `/proc/meminfo` | メモリ | 正規表現→Hashtable |
| `/proc/uptime` | 起動時間 | 秒数→TimeSpan変換 |
| `/proc/loadavg` | Load Average | split→数値配列 |

## class vs PSCustomObject 使い分け

```powershell
# 構造が決まっているデータ → class
class MetricSnapshot {
    [MetricType]$Type      # enum型で安全
    [double]$Value
    [string] ToString() { return "$($this.Type): $($this.Value)" }
}

# 一時的なデータ加工 → PSCustomObject
[PSCustomObject]@{ Name = "CPU"; Value = 8.76 }
```

## 頻出パターン

```powershell
# モジュール読み込み（相対パス）
Import-Module (Join-Path $PSScriptRoot "../modules/Core.psm1") -Force

# スプラッティング
$p = @{ Path="/tmp"; Recurse=$true }
Get-ChildItem @p

# 計算プロパティ
Format-Table @{L='サイズ';E={"{0:N1}MB" -f ($_.Length/1MB)};A='Right'}

# -f 演算子
"[{0:HH:mm:ss}] {1}: {2:N1}%" -f (Get-Date), "CPU", 8.76

# パイプラインでHTML生成
Invoke-HealthCheck | New-DashboardHtml

# 色付きコンソール
Write-Host "OK" -ForegroundColor Green -NoNewline
```

## 覚えるべきコマンド

| コマンド | 用途 |
|---|---|
| `Invoke-RestMethod` | REST API呼び出し（JSON自動パース） |
| `Invoke-WebRequest` | HTTP要求（ヘッダ・ステータス取得） |
| `Measure-Command { }` | 処理時間計測 |
| `Write-Progress` | プログレスバー表示 |
| `Export-ModuleMember` | モジュール公開関数の指定 |
| `$PSScriptRoot` | 実行中スクリプトのディレクトリ |
| `Select-String` | ファイル内テキスト検索（=grep） |
