---
title: "第10章 チートシート"
description: "ファイル操作とデータ処理 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## ファイル操作

| 操作 | コマンド |
|---|---|
| 読み込み | `Get-Content ./file.txt` |
| 書き出し | `Set-Content ./file.txt -Value "text"` |
| 追記 | `Add-Content ./file.txt -Value "追加"` |
| 存在確認 | `Test-Path ./file.txt` |
| 作成 | `New-Item ./file.txt -ItemType File` |
| コピー | `Copy-Item ./a.txt ./b.txt` |
| 移動 | `Move-Item ./a.txt ./dir/` |
| 削除 | `Remove-Item ./file.txt` |

## データ形式

| 形式 | 読み込み | 書き出し |
|---|---|---|
| CSV | `Import-Csv ./data.csv` | `Export-Csv ./out.csv -NoTypeInformation` |
| JSON | `Get-Content f \| ConvertFrom-Json` | `$obj \| ConvertTo-Json \| Out-File f` |
| テキスト検索 | `Select-String -Pattern "regex" -Path f` | — |
