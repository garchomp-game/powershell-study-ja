---
title: "第2章 チートシート"
description: "環境構築と最初の一歩 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## キーバインド

| 操作 | キー |
|---|---|
| コマンド履歴 | `↑` `↓` |
| 単語移動 | `Ctrl+←` `Ctrl+→` |
| 行頭 / 行末 | `Home` / `End` |
| タブ補完 | `Tab` / `Shift+Tab` |
| 履歴検索 | `Ctrl+R` |
| 画面クリア | `Ctrl+L` |
| 処理中断 | `Ctrl+C` |

## 覚えるコマンド

```powershell
$PSVersionTable.PSVersion             # バージョン
$PROFILE                              # プロファイルパス
code $PROFILE                         # プロファイル編集
Get-PSReadLineKeyHandler              # キーバインド一覧
Set-PSReadLineOption -PredictionSource History  # 履歴予測ON
```
