---
title: "第4章 チートシート"
description: "パイプラインとオブジェクト — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## パイプライン操作

| 操作 | コマンド | 覚え方 |
|---|---|---|
| フィルタ | `Where-Object { 条件 }` | 「どれ？」 |
| ソート | `Sort-Object プロパティ` | 「並べて」 |
| 選択 | `Select-Object -First N` | 「これだけ」 |
| 変換 | `ForEach-Object { 処理 }` | 「それぞれ」 |
| グループ | `Group-Object プロパティ` | 「分けて」 |
| 集計 | `Measure-Object -Sum` | 「数えて」 |
| 比較 | `Compare-Object $a $b` | 「違いは？」 |
| 分岐保存 | `Tee-Object -Variable v` | 「コピーして」 |

## 出力

| 操作 | コマンド |
|---|---|
| 表形式 | `Format-Table -AutoSize` |
| リスト | `Format-List *` |
| CSV保存 | `Export-Csv ./file.csv -NoTypeInformation` |
| JSON変換 | `ConvertTo-Json` |
| 破棄 | `$null = ...`（最速） |

## 定番パターン

```powershell
Get-Process | Where-Object CPU -gt 0 | Sort-Object CPU -Desc | Select-Object -First 5
```
