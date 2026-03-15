---
title: 演算子
description: PowerShellの算術・比較・論理・特殊演算子を網羅的に解説
sidebar:
  order: 4
---

## 算術演算子

```powershell
10 + 3    # 13（加算）
10 - 3    # 7（減算）
10 * 3    # 30（乗算）
10 / 3    # 3.33...（除算）
10 % 3    # 1（剰余）

# 文字列との演算
"Hello" + " World"  # "Hello World"（結合）
"abc" * 3            # "abcabcabc"（繰り返し）
@(1,2) * 3           # 1,2,1,2,1,2（配列の繰り返し）

# 代入演算子
$x = 10
$x += 5    # $x = $x + 5  → 15
$x -= 3    # 12
$x *= 2    # 24
$x /= 4    # 6
$x %= 4    # 2
$x++       # 3（インクリメント）
$x--       # 2（デクリメント）
```

## 比較演算子

PowerShellの比較演算子はデフォルトで**大文字小文字を区別しません**。

| 演算子 | 意味 | 大文字小文字区別版 |
|---|---|---|
| `-eq` | 等しい | `-ceq` |
| `-ne` | 等しくない | `-cne` |
| `-gt` | より大きい | `-cgt` |
| `-lt` | より小さい | `-clt` |
| `-ge` | 以上 | `-cge` |
| `-le` | 以下 | `-cle` |
| `-like` | ワイルドカード一致 | `-clike` |
| `-notlike` | ワイルドカード不一致 | `-cnotlike` |
| `-match` | 正規表現一致 | `-cmatch` |
| `-notmatch` | 正規表現不一致 | `-cnotmatch` |

```powershell
# 大文字小文字を区別しない（デフォルト）
"Hello" -eq "hello"     # True
"Hello" -ceq "hello"    # False（区別する）

# 配列に対する比較（フィルタとして動作）
1,2,3,4,5 -gt 3         # 4, 5（条件に一致する要素を返す）
"apple","BANANA","Cherry" -like "*an*"  # BANANA（一致する要素）
```

## 論理演算子

```powershell
$true -and $true     # True
$true -and $false    # False
$true -or $false     # True
$false -or $false    # False
-not $true           # False
!$false              # True（-notの短縮形）
$true -xor $false    # True（排他的論理和）
$true -xor $true     # False
```

## 包含演算子

```powershell
# -contains / -notcontains（コレクション側が左）
@(1, 2, 3) -contains 2        # True
@("a","b") -notcontains "c"   # True

# -in / -notin（値が左、コレクションが右）
2 -in @(1, 2, 3)              # True
"c" -notin @("a", "b")        # True

# 使い分け
$status = "Running"
$status -in "Running", "Paused"  # 自然な書き方
```

## 型演算子

```powershell
# -is / -isnot（型の判定）
42 -is [int]             # True
"hello" -is [string]     # True
42 -isnot [string]       # True

# -as（安全な型変換、失敗時は $null）
"42" -as [int]           # 42
"abc" -as [int]          # $null
```

## 文字列演算子

```powershell
# -replace（正規表現置換）
"Hello World" -replace "World", "PS"        # Hello PS
"abc 123 def" -replace "\d+", "[NUM]"       # abc [NUM] def
"2025-03-15" -replace "(\d{4})-(\d{2})-(\d{2})", '$3/$2/$1'  # 15/03/2025

# -split（分割）
"one,two,three" -split ","                  # @("one","two","three")
"one  two  three" -split "\s+"              # @("one","two","three")
"a.b.c.d" -split "\.", 3                    # @("a","b","c.d")（最大3分割）

# -join（結合）
"a","b","c" -join "-"                       # "a-b-c"
1..5 -join ", "                              # "1, 2, 3, 4, 5"
```

## 特殊演算子

```powershell
# 三項演算子（PowerShell 7+）
$result = $IsLinux ? "Linux" : "Other"

# Null合体演算子（PowerShell 7+）
$value = $null
$value ?? "デフォルト値"        # "デフォルト値"

# Null合体代入演算子（PowerShell 7+）
$x = $null
$x ??= "初期値"               # $x は "初期値" になる

# Null条件アクセス演算子（PowerShell 7.1+）
$obj?.Property               # $obj が $null なら $null を返す（プロパティアクセス用）
${obj}?.Method()              # メソッド呼び出しには ${} が必要

# パイプラインチェーン演算子（PowerShell 7+）
Get-Process pwsh && Write-Host "見つかった"   # 成功時のみ
Get-Process nonexist || Write-Host "見つからない"  # 失敗時のみ

# 範囲演算子
1..5                           # 1, 2, 3, 4, 5
5..1                           # 5, 4, 3, 2, 1

# サブ式演算子
"ファイル数: $( (Get-ChildItem).Count )"

# 呼び出し演算子
& { Write-Host "スクリプトブロック実行" }
& "pwsh" "-c" "Write-Host 'hello'"
```

## 演算子の優先順位

```
1. ()           — グループ化
2. ++ / --      — インクリメント・デクリメント
3. -not / !     — 論理否定
4. * / / / %    — 乗除・剰余
5. + / -        — 加減
6. 比較演算子     — -eq, -gt, -like, -match, ...
7. -and         — 論理AND
8. -or / -xor   — 論理OR / XOR
9. =, +=, ...   — 代入
```

## ハンズオン課題

```powershell
# 1. 比較演算子の動作確認
"PowerShell" -eq "powershell"     # True (case-insensitive)
"PowerShell" -ceq "powershell"    # False (case-sensitive)

# 2. 配列フィルタリング
$numbers = 1..20
$numbers -gt 15               # 16以上
$numbers | Where-Object { $_ % 3 -eq 0 }  # 3の倍数

# 3. Null合体演算子の活用
$config = $null
$port = $config ?? 8080
"ポート: $port"

# 4. 三項演算子でプラットフォーム判定
$os = $IsLinux ? "Linux" : ($IsMacOS ? "macOS" : "Windows")
"OS: $os"
```

