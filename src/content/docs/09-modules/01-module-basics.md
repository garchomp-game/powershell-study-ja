---
title: モジュールの基礎
description: PowerShellモジュールの概念・検索・インポート
sidebar:
  order: 1
---

## モジュールとは

モジュールは、関連するコマンドレット・関数・変数をパッケージ化した**再利用可能なコード単位**です。

```powershell
# ロード済みモジュールの確認
Get-Module

# 利用可能な全モジュール
Get-Module -ListAvailable

# 特定のモジュールの詳細
Get-Module -Name Microsoft.PowerShell.Utility -ListAvailable | Format-List

# モジュールのインポート
Import-Module -Name Microsoft.PowerShell.Management

# モジュールの削除（アンロード）
Remove-Module -Name MyModule
```

## モジュールの種類

| 種類 | 拡張子 | 説明 |
|---|---|---|
| **スクリプトモジュール** | `.psm1` | PowerShellスクリプトで構成 |
| **バイナリモジュール** | `.dll` | C#等で実装されたコンパイル済み |
| **マニフェストモジュール** | `.psd1` | メタデータを定義するマニフェスト |
| **動的モジュール** | — | `New-Module` でメモリ上に作成 |

## モジュールパス

```powershell
# モジュール検索パス
$env:PSModulePath -split [IO.Path]::PathSeparator

# 主要なモジュールパス
# ユーザー: ~/.local/share/powershell/Modules
# システム: /usr/local/share/powershell/Modules
# 組み込み: $PSHOME/Modules
```

## ハンズオン課題

```powershell
# 1. ロード済みモジュール数を確認
(Get-Module).Count

# 2. 特定モジュールのコマンド一覧
Get-Command -Module Microsoft.PowerShell.Utility | Measure-Object
Get-Command -Module Microsoft.PowerShell.Management | Select-Object -First 10 Name
```
