---
title: コーディング規約とセキュリティ
description: PowerShellのベストプラクティス、コーディング規約、セキュリティ対策
sidebar:
  order: 1
---

## コーディング規約

### 命名規則

| 要素 | 規則 | 例 |
|---|---|---|
| 関数 | `PascalCase` + `Verb-Noun` | `Get-UserInfo`, `Set-Config` |
| パラメータ | `PascalCase` | `$ComputerName`, `$FilePath` |
| 変数 | `camelCase` or `PascalCase` | `$result`, `$UserName` |
| 定数 | `UPPER_SNAKE_CASE` | `$MAX_RETRIES` |
| ブール変数 | 疑問形 | `$isEnabled`, `$hasPermission` |
| プライベート関数 | 承認済み動詞は不要だが推奨 | `Get-InternalData` |

### コード構造のベストプラクティス

```powershell
# ✅ 良い例: CmdletBinding + 検証属性 + Verbose
function Get-UserReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Department,

        [ValidateRange(1, 100)]
        [int]$TopN = 10
    )

    Write-Verbose "部署 '$Department' のレポートを生成中..."
    # ... 処理 ...
}

# ❌ 悪い例: 検証なし、Write-Host 多用
function getreport($dept) {
    Write-Host "Report for $dept"  # Write-Hostはパイプに流れない
    # ... 
}
```

### 主要ルール

1. **`Set-StrictMode -Version Latest`** をスクリプト先頭で宣言
2. **`$ErrorActionPreference = 'Stop'`** で厳格なエラー処理
3. **承認済み動詞**（`Get-Verb`）を使う
4. **`Write-Output`** でパイプに流す（`Write-Host` は表示専用）
5. **スプラッティング**で長いコマンドの可読性を向上
6. **比較で `$null` を左側**に置く（配列比較の罠を防ぐ）
7. **`-ErrorAction Stop`** + `try/catch` でエラーを確実に捕捉
8. **バッククォート改行を避ける**（パイプ `|` の後で自然に改行）

## セキュリティ

### SecureString と資格情報

```powershell
# SecureString の作成
$securePassword = Read-Host "パスワード" -AsSecureString
$securePassword = ConvertTo-SecureString "MyP@ssw0rd" -AsPlainText -Force

# PSCredential の作成
$cred = [PSCredential]::new("username", $securePassword)
# または
$cred = Get-Credential  # GUIプロンプト

# 資格情報の使用
Invoke-Command -ComputerName Server01 -Credential $cred -ScriptBlock { hostname }
```

### 実行ポリシーのベストプラクティス

```powershell
# 推奨設定
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# スクリプト署名（企業環境向け）
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath ./script.ps1 -Certificate $cert
```

### セキュリティチェックリスト

- [ ] パスワードをスクリプトにハードコードしない
- [ ] `SecureString` / `PSCredential` を使う
- [ ] 入力パラメータを検証する（`Validate*` 属性）
- [ ] `-WhatIf` / `-Confirm` で破壊的操作を保護
- [ ] ログに機密情報を出力しない

## ドキュメントコメント

```powershell
function Get-SystemHealth {
    <#
    .SYNOPSIS
        システムの健全性をチェックします。

    .DESCRIPTION
        CPU使用率、メモリ使用率、ディスク使用率を確認し、
        健全性レポートを返します。

    .PARAMETER ComputerName
        チェック対象のコンピュータ名。

    .PARAMETER Threshold
        警告を出すCPU使用率の閾値（パーセント）。

    .EXAMPLE
        Get-SystemHealth -ComputerName "Server01"
        Server01の健全性をチェックします。

    .EXAMPLE
        "Server01","Server02" | Get-SystemHealth -Threshold 80
        複数サーバーを閾値80%でチェックします。

    .OUTPUTS
        PSCustomObject

    .NOTES
        作成者: Your Name
        更新日: 2025-03-15
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ComputerName,
        [int]$Threshold = 90
    )
    process {
        # ... 実装 ...
    }
}

# ドキュメントコメントはGet-Helpで表示される
Get-Help Get-SystemHealth -Full
```

## エコシステム紹介（awesome-powershell主要ツール）

### 開発環境

| ツール | 説明 |
|---|---|
| **VS Code + PowerShell拡張** | 最も推奨されるIDE |
| **PSReadLine** | コマンドライン編集・予測・履歴管理 |
| **Oh-My-Posh** | プロンプトのカスタマイズ |
| **Terminal-Icons** | ファイル/フォルダのアイコン表示 |
| **posh-git** | Gitステータスのプロンプト表示 |
| **PSFzf** | ファジーファインダー統合 |
| **zoxide** | スマートなディレクトリジャンプ |

### コード品質

| ツール | 説明 |
|---|---|
| **Pester** | テストフレームワーク（BDDスタイル） |
| **PSScriptAnalyzer** | 静的コード解析・ベストプラクティスチェック |
| **Plaster** | プロジェクトテンプレート生成 |
| **Catesta** | CI/CD統合プロジェクトスキャフォールド |

### 生産性向上

| ツール | 説明 |
|---|---|
| **ImportExcel** | Excelインストール不要のExcel操作 |
| **PSScriptTools** | 便利なユーティリティ関数集 |
| **PSFramework** | モジュール開発の基盤フレームワーク |
| **dbatools** | SQL Serverの自動化ツール |

### 学習リソース

| リソース | URL |
|---|---|
| **Microsoft Learn** | https://learn.microsoft.com/en-us/powershell/ |
| **PSKoans** | Pesterを使った対話型学習 |
| **PowerShell Gallery** | https://www.powershellgallery.com/ |
| **PowerShell GitHub** | https://github.com/PowerShell/PowerShell |

## ハンズオン課題

```powershell
# 1. コーディング規約に従った関数を作成
function Get-DirectorySummary {
    <#
    .SYNOPSIS
        ディレクトリの概要を取得します。
    .PARAMETER Path
        対象ディレクトリのパス。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path
    )

    Write-Verbose "ディレクトリ分析中: $Path"
    $items = Get-ChildItem $Path -File -Recurse -ErrorAction SilentlyContinue
    $stats = $items | Measure-Object Length -Sum -Average

    [PSCustomObject]@{
        Path       = Resolve-Path $Path
        FileCount  = $stats.Count
        TotalSizeMB = [math]::Round($stats.Sum / 1MB, 2)
        AvgSizeKB  = [math]::Round($stats.Average / 1KB, 2)
        Extensions = ($items | Group-Object Extension | Sort-Object Count -Descending |
                      Select-Object -First 5 -ExpandProperty Name) -join ", "
    }
}

Get-DirectorySummary -Path ~ -Verbose
```


---

## 🌙 寝る前チートシート

> **第17章の要点を3分で復習**

| ベストプラクティス | ポイント |
|---|---|
| 命名規則 | `Verb-Noun` 形式、Approved Verbs を使う |
| エラー処理 | `try/catch` + `-ErrorAction Stop` |
| `-WhatIf` 対応 | 変更系関数には `SupportsShouldProcess` |
| 出力 | `Write-Output`（データ） vs `Write-Host`（表示のみ） |
| セキュリティ | `SecureString` / `Get-Credential` でパスワード管理 |
| モジュール化 | 再利用可能な関数はモジュールに |
| テスト | Pester でユニットテスト |

```powershell
# セキュリティ（暗記）
$cred = Get-Credential                     # 安全な認証情報入力
$pass = Read-Host -AsSecureString           # パスワードをマスク入力
$plain = ConvertFrom-SecureString $pass -AsPlainText  # 平文化（PS7+）

# Approved Verbs の確認
Get-Verb | Sort-Object Verb
```
