---
title: "第7章 チートシート"
description: "関数とスクリプト — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## 関数の構成要素

| 概念 | 書き方 |
|---|---|
| 基本関数 | `function Get-Greeting { param($Name) "Hello $Name" }` |
| 必須パラメータ | `[Parameter(Mandatory)]$Name` |
| 入力検証 | `[ValidateSet("A","B")]$Choice` |
| CmdletBinding | `[CmdletBinding()] param(...)` |
| パイプライン対応 | `process { $_ }` ブロック |

## スコープ

| スコープ | 変数 | 意味 |
|---|---|---|
| ローカル | `$local:var` | 現在のスコープのみ |
| スクリプト | `$script:var` | スクリプト全体 |
| グローバル | `$global:var` | セッション全体 |

## 定型パターン

```powershell
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name
    )
    begin   { <# 初期化 #> }
    process { <# $_を処理 #> }
    end     { <# 後処理 #> }
}
```
