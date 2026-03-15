---
title: "第3章 チートシート"
description: "コマンドレットとヘルプシステム — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## 探索の三大コマンド

| コマンド | 用途 | 覚え方 |
|---|---|---|
| `Get-Command *名詞*` | コマンドを**探す** | 「何が使える？」 |
| `Get-Help コマンド -Examples` | 使い方を**学ぶ** | 「どう使う？」 |
| `コマンド \| Get-Member` | 出力を**理解する** | 「何が入ってる？」 |

## 必須エイリアス

| エイリアス | 本名 | エイリアス | 本名 |
|---|---|---|---|
| `ls` | `Get-ChildItem` | `?` | `Where-Object` |
| `cd` | `Set-Location` | `%` | `ForEach-Object` |
| `cat` | `Get-Content` | `select` | `Select-Object` |
| `cp` | `Copy-Item` | `sort` | `Sort-Object` |
| `mv` | `Move-Item` | `ft` | `Format-Table` |
| `rm` | `Remove-Item` | `fl` | `Format-List` |
| `ps` | `Get-Process` | `measure` | `Measure-Object` |
| `kill` | `Stop-Process` | `echo` | `Write-Output` |

## 暗記テスト

```powershell
# これをエイリアスなしで書けますか？
ls ~ -File | ? Length -gt 1MB | sort Length -Desc | select -First 5 Name, Length
```
