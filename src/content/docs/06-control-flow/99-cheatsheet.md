---
title: "第6章 チートシート"
description: "制御構文 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## 条件分岐

| 構文 | 書き方 |
|---|---|
| if | `if ($x -gt 0) { } elseif ($x -eq 0) { } else { }` |
| switch | `switch ($val) { "A" { } "B" { } default { } }` |
| switch -Wildcard | パターンに `*` `?` が使える |
| switch -Regex | 正規表現パターンで分岐 |

## ループ

| ループ | 書き方 | 使い分け |
|---|---|---|
| `for` | `for ($i=0; $i -lt N; $i++)` | 回数指定 |
| `foreach` | `foreach ($x in $col)` | コレクション走査 |
| `ForEach-Object` | `\| ForEach-Object { }` | パイプライン内 |
| `while` | `while (条件) { }` | 条件が真の間 |
| `do-while` | `do { } while (条件)` | 最低1回実行 |
| `do-until` | `do { } until (条件)` | 条件が真になるまで |

## ループ制御

```powershell
break      # ループを抜ける
continue   # 次の反復へスキップ
return     # 関数から抜ける
```
