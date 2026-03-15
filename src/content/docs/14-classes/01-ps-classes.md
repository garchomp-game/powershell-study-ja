---
title: PowerShellクラス
description: PowerShellクラスの定義 — プロパティ、メソッド、コンストラクタ、継承、Enum
sidebar:
  order: 1
---

## クラスの定義

PowerShell 5.0以降で使えるクラス構文です。

```powershell
class Person {
    # プロパティ
    [string]$Name
    [int]$Age
    [string]$Email
    
    # デフォルトコンストラクタ
    Person() {
        $this.Name = "Unknown"
        $this.Age = 0
    }
    
    # パラメータ付きコンストラクタ
    Person([string]$name, [int]$age) {
        $this.Name = $name
        $this.Age = $age
    }
    
    # メソッド
    [string] Greet() {
        return "こんにちは、$($this.Name)です（$($this.Age)歳）"
    }
    
    # 静的メソッド
    static [Person] Create([string]$name, [int]$age) {
        return [Person]::new($name, $age)
    }
    
    # ToString の オーバーライド
    [string] ToString() {
        return "$($this.Name) (Age: $($this.Age))"
    }
}

# インスタンスの作成
$person1 = [Person]::new()
$person2 = [Person]::new("太郎", 25)
$person3 = [Person]::Create("花子", 30)

$person2.Greet()   # こんにちは、太郎です（25歳）
$person2.ToString() # 太郎 (Age: 25)
```

## 継承

```powershell
class Employee : Person {
    [string]$Department
    [decimal]$Salary
    
    Employee([string]$name, [int]$age, [string]$dept) : base($name, $age) {
        $this.Department = $dept
    }
    
    [string] GetInfo() {
        return "$($this.Name) - $($this.Department)"
    }
}

$emp = [Employee]::new("次郎", 28, "Engineering")
$emp.Greet()    # 親クラスのメソッドも使える
$emp.GetInfo()  # 次郎 - Engineering
```

## Enum 定義

```powershell
enum Priority {
    Low = 1
    Medium = 2
    High = 3
    Critical = 4
}

[Priority]$p = [Priority]::High
$p.value__  # 3

# Flags Enum
[Flags()] enum Permission {
    None = 0
    Read = 1
    Write = 2
    Execute = 4
    All = 7
}

$perm = [Permission]::Read -bor [Permission]::Write
$perm  # Read, Write
```

## 実践例: 設定管理クラス

```powershell
class AppConfig {
    [string]$AppName
    [int]$Port
    [string]$Environment
    hidden [datetime]$CreatedAt  # hidden プロパティ

    AppConfig([string]$name, [int]$port, [string]$env) {
        $this.AppName = $name
        $this.Port = $port
        $this.Environment = $env
        $this.CreatedAt = Get-Date
    }

    [hashtable] ToHashtable() {
        return @{
            AppName = $this.AppName
            Port = $this.Port
            Environment = $this.Environment
        }
    }

    [string] ToJson() {
        return $this.ToHashtable() | ConvertTo-Json
    }
}

$config = [AppConfig]::new("MyApp", 8080, "Production")
$config.ToJson()
```

## クラス vs PSCustomObject の使い分け

| 特徴 | PSCustomObject | class |
|---|---|---|
| メソッド定義 | ❌ 不可 | ✅ 可能 |
| コンストラクタ | ❌ 不可 | ✅ 可能 |
| 継承 | ❌ 不可 | ✅ 可能 |
| 型制約 | ❌ 弱い | ✅ 強い |
| 用途 | データ構造体・一時的なオブジェクト | ロジックを持つ再利用可能なモデル |

> **いつクラスを使うか:** 単にデータを構造化するだけなら `PSCustomObject` で十分です。メソッドや検証ロジック、継承が必要な場合にクラスを使いましょう。

## まとめ

| ポイント | 内容 |
|---|---|
| `class` | プロパティ・メソッド・コンストラクタを定義 |
| `[ClassName]::new()` | インスタンス作成 |
| `: base()` | 親クラスのコンストラクタ呼び出し（継承） |
| `hidden` | 外部から見えないプロパティ |
| `enum` / `[Flags()]` | 列挙型・フラグ列挙型の定義 |

## ハンズオン課題

```powershell
# タスク管理クラスを実装
class Task {
    [string]$Title
    [Priority]$Priority
    [bool]$IsCompleted
    [datetime]$DueDate

    Task([string]$title, [Priority]$priority, [datetime]$due) {
        $this.Title = $title; $this.Priority = $priority
        $this.DueDate = $due; $this.IsCompleted = $false
    }
    [void] Complete() { $this.IsCompleted = $true }
    [string] ToString() { 
        $status = $this.IsCompleted ? "✅" : "⬜"
        return "$status [$($this.Priority)] $($this.Title)"
    }
}

$tasks = @(
    [Task]::new("ドキュメント作成", [Priority]::High, (Get-Date).AddDays(3))
    [Task]::new("コードレビュー", [Priority]::Medium, (Get-Date).AddDays(1))
)
$tasks | ForEach-Object { $_.ToString() }
$tasks[0].Complete()
$tasks | ForEach-Object { $_.ToString() }
```


---

## 🌙 寝る前チートシート

> **第14章の要点を3分で復習**

| 概念 | 構文 |
|---|---|
| クラス定義 | `class MyClass { [string]$Name }` |
| コンストラクタ | `MyClass([string]$n) { $this.Name = $n }` |
| メソッド | `[string] GetInfo() { return $this.Name }` |
| 継承 | `class Child : Parent { }` |
| Enum | `enum Color { Red; Green; Blue }` |
| インスタンス化 | `$obj = [MyClass]::new("value")` |

| class vs PSCustomObject | class | PSCustomObject |
|---|---|---|
| メソッド | ✅ あり | ❌ なし |
| 型チェック | ✅ 厳密 | ❌ なし |
| 継承 | ✅ 可能 | ❌ 不可 |
| 手軽さ | △ | ◎ |

```powershell
# PSCustomObject（手軽にオブジェクト作成）
$obj = [PSCustomObject]@{ Name = "test"; Value = 42 }

# class（型安全な定義）
class Person {
    [string]$Name
    [int]$Age
    Person([string]$n, [int]$a) { $this.Name=$n; $this.Age=$a }
    [string] ToString() { return "$($this.Name) ($($this.Age))" }
}
```
