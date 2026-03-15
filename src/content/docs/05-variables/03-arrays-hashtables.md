---
title: 配列とハッシュテーブル
description: PowerShellのコレクション型を使いこなす
sidebar:
  order: 3
---

## 配列（Array）

### 配列の作成

```powershell
# 配列リテラル（カンマ区切り）
$colors = "red", "green", "blue"

# @() 演算子（明示的な配列作成）
$nums = @(1, 2, 3, 4, 5)

# 空の配列
$empty = @()

# 単一要素の配列（@() で囲まないとスカラーになる）
$single = @("only one")

# 範囲演算子
$range = 1..10          # 1〜10の配列
$alpha = [char]'a'..[char]'z'  # a〜zのASCIIコード配列
```

### 配列の操作

```powershell
$arr = @("a", "b", "c", "d", "e")

# インデックスアクセス（0始まり）
$arr[0]         # "a"（先頭）
$arr[-1]        # "e"（末尾）
$arr[1..3]      # "b", "c", "d"（スライス）
$arr[-2..-1]    # "d", "e"（末尾2つ）

# 要素数
$arr.Count      # 5
$arr.Length      # 5（同じ）

# 要素の追加（※新しい配列が作られる）
$arr += "f"     # @("a","b","c","d","e","f")

# 要素の検索
$arr -contains "c"     # True
"c" -in $arr           # True
$arr.IndexOf("c")      # 2

# 配列のフィルタリング
$nums = 1..20
$nums -gt 15           # 16, 17, 18, 19, 20
$nums -like "*5"       # 5, 15（ワイルドカード）

# 配列の結合
$a = 1, 2, 3
$b = 4, 5, 6
$combined = $a + $b    # 1, 2, 3, 4, 5, 6
```

### ArrayList（可変長リスト）

固定配列（`@()`）は要素追加のたびに新しい配列が作成されるため、**大量の要素を追加する場合はArrayList**を使います。

```powershell
# ArrayList の作成
$list = [System.Collections.ArrayList]::new()

# 要素の追加（戻り値はインデックス）
[void]$list.Add("item1")
[void]$list.Add("item2")
[void]$list.Add("item3")

# 要素の削除
$list.Remove("item2")
$list.RemoveAt(0)

# Generic List（型安全・推奨）
$typedList = [System.Collections.Generic.List[string]]::new()
$typedList.Add("hello")
$typedList.Add("world")
$typedList.Contains("hello")  # True
```

## ハッシュテーブル（Hashtable）

キーと値のペアでデータを管理するデータ構造です。

### 作成と基本操作

```powershell
# ハッシュテーブルの作成
$user = @{
    Name  = "太郎"
    Age   = 25
    Email = "taro@example.com"
}

# 値のアクセス
$user["Name"]       # "太郎"（インデクサ構文）
$user.Name          # "太郎"（ドット記法）

# 値の変更
$user["Age"] = 26
$user.Age = 26

# キー・値の一覧
$user.Keys          # Name, Age, Email
$user.Values        # 太郎, 25, taro@example.com

# 要素の追加
$user["City"] = "東京"
$user.Add("Country", "Japan")

# 要素の削除
$user.Remove("City")

# 要素の存在確認
$user.ContainsKey("Name")     # True
$user.ContainsValue("太郎")   # True

# 要素数
$user.Count
```

### 順序付きハッシュテーブル

通常のハッシュテーブルは順序が保証されません。挿入順序を保持するには `[ordered]` を使います。

```powershell
# 順序付きハッシュテーブル
$ordered = [ordered]@{
    First  = 1
    Second = 2
    Third  = 3
}
$ordered.Keys  # First, Second, Third（挿入順）

# 通常のハッシュテーブル
$unordered = @{
    First  = 1
    Second = 2
    Third  = 3
}
$unordered.Keys  # 順序は保証されない
```

### ハッシュテーブルの反復

```powershell
$config = @{
    Server = "localhost"
    Port   = 8080
    Debug  = $true
}

# GetEnumerator() で反復
$config.GetEnumerator() | ForEach-Object {
    "$($_.Key) = $($_.Value)"
}

# キーで反復
foreach ($key in $config.Keys) {
    "$key = $($config[$key])"
}
```

## PSCustomObject

`[PSCustomObject]` は、プロパティ付きのカスタムオブジェクトを簡単に作成できます。ハッシュテーブルとの最大の違いは、**プロパティの順序が保持される**ことです。

```powershell
# PSCustomObject の作成
$person = [PSCustomObject]@{
    Name  = "花子"
    Age   = 30
    City  = "大阪"
}

# プロパティアクセス
$person.Name    # "花子"

# Format-Table で綺麗に表示される
$person | Format-Table

# 複数オブジェクトの配列
$people = @(
    [PSCustomObject]@{ Name = "太郎"; Age = 25 }
    [PSCustomObject]@{ Name = "花子"; Age = 30 }
    [PSCustomObject]@{ Name = "次郎"; Age = 28 }
)
$people | Format-Table
$people | Where-Object { $_.Age -gt 27 }
$people | Sort-Object Age
```

## 配列 vs ハッシュテーブル vs PSCustomObject

| 特徴 | 配列 | ハッシュテーブル | PSCustomObject |
|---|---|---|---|
| アクセス | インデックス `$a[0]` | キー `$h["key"]` | プロパティ `$o.Name` |
| 順序 | ✅ 保持 | ❌ 不定 | ✅ 保持 |
| 用途 | リスト・コレクション | 設定・マッピング | 構造化データ・出力 |
| パイプライン | 各要素が個別に流れる | 1つのオブジェクトとして流れる | 1つのオブジェクトとして流れる |

## ハンズオン課題

```powershell
# 1. 1から100の配列を作り、偶数だけフィルタして合計を求める
$nums = 1..100
$evens = $nums | Where-Object { $_ % 2 -eq 0 }
($evens | Measure-Object -Sum).Sum  # 2550

# 2. PSCustomObject で構造化データを作成しテーブル表示
$servers = @(
    [PSCustomObject]@{ Name="web01"; IP="192.168.1.10"; Status="Running" }
    [PSCustomObject]@{ Name="db01";  IP="192.168.1.20"; Status="Running" }
    [PSCustomObject]@{ Name="app01"; IP="192.168.1.30"; Status="Stopped" }
)
$servers | Format-Table -AutoSize

# 3. ハッシュテーブルの操作
$inventory = @{}
$inventory["apple"] = 50
$inventory["banana"] = 30
$inventory["cherry"] = 20
$inventory.GetEnumerator() | Sort-Object Value -Descending
```
