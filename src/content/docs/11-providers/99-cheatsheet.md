---
title: "第11章 チートシート"
description: "プロバイダーとドライブ — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## プロバイダー一覧

| プロバイダー | ドライブ | 対象 |
|---|---|---|
| FileSystem | `C:`, `/` | ファイル・フォルダ |
| Environment | `Env:` | 環境変数 |
| Variable | `Variable:` | PowerShell変数 |
| Function | `Function:` | 関数定義 |
| Alias | `Alias:` | エイリアス |
| Registry | `HKLM:` `HKCU:` | レジストリ ⚠️Win専用 |

## 覚えるコマンド

```powershell
Get-PSProvider               # プロバイダー一覧
Get-PSDrive                  # ドライブ一覧
Get-ChildItem Env:           # 環境変数一覧
Get-ChildItem Variable:      # 変数一覧
$env:PATH                    # 環境変数アクセス
New-PSDrive -Name docs -PSProvider FileSystem -Root ~/Documents
```
