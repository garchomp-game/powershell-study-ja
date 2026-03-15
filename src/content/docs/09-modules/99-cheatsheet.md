---
title: "第9章 チートシート"
description: "モジュールとパッケージ管理 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## モジュール管理

| 操作 | コマンド |
|---|---|
| 一覧 | `Get-Module -ListAvailable` |
| 読み込み | `Import-Module モジュール名` |
| Gallery検索 | `Find-Module -Name "*キーワード*"` |
| インストール | `Install-Module -Name M -Scope CurrentUser` |
| 更新 | `Update-Module -Name M` |
| 削除 | `Uninstall-Module -Name M` |
| モジュールパス | `$env:PSModulePath -split ':'` |

## 独自モジュール作成

```powershell
# マニフェスト生成
New-ModuleManifest -Path MyModule.psd1 -RootModule MyModule.psm1

# MyModule.psm1
function Get-Greeting { param($Name) "Hello, $Name!" }
Export-ModuleMember -Function Get-Greeting
```
