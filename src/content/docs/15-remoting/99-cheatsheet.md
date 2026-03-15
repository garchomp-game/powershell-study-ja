---
title: "第15章 チートシート"
description: "リモート管理とジョブ — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## リモート実行

| 操作 | コマンド |
|---|---|
| リモート実行 | `Invoke-Command -ComputerName SV -ScriptBlock { }` |
| SSH経由 | `Invoke-Command -HostName SV -ScriptBlock { }` |
| セッション作成 | `$s = New-PSSession -ComputerName SV` |
| 変数の渡し方 | `$using:変数名` |

## ジョブ

| 操作 | コマンド |
|---|---|
| 開始 | `Start-Job -ScriptBlock { }` |
| 一覧 | `Get-Job` |
| 結果取得 | `Receive-Job -Id N` |
| 待機 | `Wait-Job -Id N` |
| 削除 | `Remove-Job -Id N` |

## 並列処理（PowerShell 7+）

```powershell
1..10 | ForEach-Object -Parallel {
    "処理: $_"
} -ThrottleLimit 5
```
