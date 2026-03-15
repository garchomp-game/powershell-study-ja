---
title: PowerShell Gallery
description: PowerShell Galleryからモジュールをインストール・管理する
sidebar:
  order: 2
---

## PowerShell Gallery とは

[PowerShell Gallery](https://www.powershellgallery.com/) は、PowerShellモジュールの公式リポジトリです。コミュニティや企業が作成したモジュールをインストールできます。

## モジュールの検索とインストール

```powershell
# モジュールの検索
Find-Module -Name PSReadLine
Find-Module -Name *Pester*
Find-Module -Tag "Azure" | Select-Object -First 10

# モジュールのインストール
Install-Module -Name Pester -Scope CurrentUser
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# 更新
Update-Module -Name Pester

# アンインストール
Uninstall-Module -Name Pester

# インストール済みモジュールの確認
Get-InstalledModule
```

## 推奨モジュール（awesome-powershellより）

| モジュール | 説明 |
|---|---|
| **Pester** | BDDスタイルのテストフレームワーク |
| **PSScriptAnalyzer** | 静的コード解析ツール |
| **PSReadLine** | コマンドライン編集の強化 |
| **posh-git** | Git統合（プロンプトにステータス表示） |
| **Oh-My-Posh** | プロンプトのカスタマイズ |
| **Terminal-Icons** | ターミナルにファイル/フォルダアイコン表示 |
| **PSFzf** | fzf（ファジーファインダー）のPowerShellラッパー |
| **ImportExcel** | Excelファイルの読み書き（Excelインストール不要） |
| **Plaster** | テンプレートベースのプロジェクト生成 |
| **PSCX** | PowerShell Community Extensions |

```powershell
# 人気モジュールTOP10を確認
Find-Module | Sort-Object -Property DownloadCount -Descending | 
    Select-Object -First 10 Name, DownloadCount, Description
```

## PSResourceGet（PowerShellGet v3）

PowerShell 7.4+ では、次世代のモジュール管理ツール `Microsoft.PowerShell.PSResourceGet` が使えます。

```powershell
# PSResourceGet のコマンド
Get-Command -Module Microsoft.PowerShell.PSResourceGet

# 使用例
Find-PSResource -Name Pester
Install-PSResource -Name Pester -Scope CurrentUser
Get-InstalledPSResource
```

## ハンズオン課題

```powershell
# 1. PSScriptAnalyzer をインストールして試す
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
"Get-Process | % { $_.Name }" | Invoke-ScriptAnalyzer -ScriptDefinition

# 2. Gallery で興味のあるモジュールを検索
Find-Module -Tag "productivity" | Select-Object -First 5 Name, Description
```
