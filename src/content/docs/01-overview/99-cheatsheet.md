---
title: "第1章 チートシート"
description: "PowerShellの世界 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## PowerShellとは

| 概念 | ポイント |
|---|---|
| 定義 | .NET上に構築された**オブジェクト指向**の自動化シェル |
| 3つの顔 | ①コマンドラインシェル ②スクリプト言語 ③構成管理 |
| Win PS vs PS7 | Win PS = .NET Framework / 5.1終了。PS7 = .NET Core / クロスプラットフォーム |
| 命名規則 | `Verb-Noun`（動詞-名詞） |
| パイプライン | テキストではなく**.NETオブジェクト**が流れる |
| コマンドの種類 | Cmdlet / Function / Alias / Application |

## 覚えるコマンド

```powershell
$PSVersionTable              # バージョン情報
$PSVersionTable.PSVersion    # バージョン
$PSVersionTable.PSEdition    # Core or Desktop
pwsh                         # PowerShell 7起動
```
