---
title: "第14章 チートシート"
description: "クラスとオブジェクト指向 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## class vs PSCustomObject

| | class | PSCustomObject |
|---|---|---|
| メソッド | ✅ | ❌ |
| 型チェック | ✅ 厳密 | ❌ |
| 継承 | ✅ | ❌ |
| 手軽さ | △ | ◎ |

## 構文

```powershell
# PSCustomObject（手軽）
$obj = [PSCustomObject]@{ Name = "test"; Value = 42 }

# class（型安全）
class Person {
    [string]$Name
    [int]$Age
    Person([string]$n, [int]$a) {
        $this.Name = $n; $this.Age = $a
    }
    [string] ToString() {
        return "$($this.Name) ($($this.Age))"
    }
}
$p = [Person]::new("太郎", 25)

# Enum
enum Color { Red; Green; Blue }
[Color]::Red
```
