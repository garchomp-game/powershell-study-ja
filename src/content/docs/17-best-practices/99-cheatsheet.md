---
title: "第17章 チートシート"
description: "ベストプラクティス — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## ベストプラクティス一覧

| 項目 | ポイント |
|---|---|
| 命名規則 | `Verb-Noun` + Approved Verbs |
| エラー処理 | `try/catch` + `-ErrorAction Stop` |
| 安全な操作 | `-WhatIf` / `SupportsShouldProcess` |
| 出力の使い分け | `Write-Output`=データ / `Write-Host`=表示のみ |
| パスワード | `SecureString` / `Get-Credential` |
| モジュール化 | 再利用関数はモジュールに |
| テスト | Pester でユニットテスト |

## セキュリティ

```powershell
$cred = Get-Credential                   # 認証情報入力
$pass = Read-Host -AsSecureString         # マスク入力
Get-Verb | Sort-Object Verb              # 承認済み動詞一覧
```
