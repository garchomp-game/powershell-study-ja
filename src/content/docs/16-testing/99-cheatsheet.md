---
title: "第16章 チートシート"
description: "テストとコード品質 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## Pester構文

| 構文 | 用途 |
|---|---|
| `Describe` | テストグループ |
| `Context` | サブグループ（条件別） |
| `It` | テストケース |
| `Should -Be` | 等値 |
| `Should -BeTrue` | 真 |
| `Should -Throw` | 例外 |
| `Mock` | 関数の差し替え |
| `BeforeEach` | 各テスト前 |
| `AfterEach` | 各テスト後 |

## 定型パターン

```powershell
Describe "Get-Greeting" {
    BeforeEach { $result = Get-Greeting "World" }
    It "挨拶文を返す" {
        $result | Should -Be "Hello, World!"
    }
    It "空文字でエラー" {
        { Get-Greeting "" } | Should -Throw
    }
}

# 実行
Invoke-Pester ./tests/ -Output Detailed

# 静的解析
Invoke-ScriptAnalyzer -Path ./script.ps1
```
