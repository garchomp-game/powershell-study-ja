---
title: 正規表現の基礎
description: PowerShellでの正規表現の使い方 — -match、-replace、-split、名前付きキャプチャ
sidebar:
  order: 1
---

## 基本的な正規表現演算子

### -match / -notmatch

```powershell
# 基本マッチ
"PowerShell 7.4" -match "\d+"      # True
$Matches[0]                         # "7"（最初のマッチ）

# キャプチャグループ
"2025-03-15" -match "(\d{4})-(\d{2})-(\d{2})"
$Matches[0]   # "2025-03-15"（全体）
$Matches[1]   # "2025"（年）
$Matches[2]   # "03"（月）
$Matches[3]   # "15"（日）

# 名前付きキャプチャ
"taro@example.com" -match "(?<user>[\w.]+)@(?<domain>[\w.]+)"
$Matches.user    # "taro"
$Matches.domain  # "example.com"

# 配列に対する-match（フィルタとして動作）
$emails = "user@test.com", "invalid", "admin@site.org"
$emails -match "@"  # "user@test.com", "admin@site.org"
```

### -replace

```powershell
# 基本置換
"Hello World" -replace "World", "PowerShell"

# 正規表現を使った置換
"abc 123 def 456" -replace "\d+", "[NUM]"

# キャプチャグループの参照（$1, $2）
"2025-03-15" -replace "(\d{4})-(\d{2})-(\d{2})", '$2/$3/$1'
# → "03/15/2025"

# 大文字小文字を区別（-creplace）
"Hello hello HELLO" -replace "hello", "world"   # "world world world"
"Hello hello HELLO" -creplace "hello", "world"  # "Hello world HELLO"
```

### -split

```powershell
# 正規表現で分割
"one, two,  three" -split "\s*,\s*"   # @("one","two","three")

# 最大分割数
"a-b-c-d-e" -split "-", 3             # @("a","b","c-d-e")
```

## よく使う正規表現パターン

| パターン | 意味 | 例 |
|---|---|---|
| `\d` | 数字 | `"abc123" -match "\d+"` → "123" |
| `\w` | 英数字+アンダースコア | `\w+` → 単語にマッチ |
| `\s` | 空白文字 | `\s+` → スペース・タブ |
| `^` | 行頭 | `^Error` → "Error"で始まる行 |
| `$` | 行末 | `\.ps1$` → ".ps1"で終わる |
| `.` | 任意の1文字 | `a.c` → "abc", "aXc" 等 |
| `*` | 直前の0回以上 | `ab*c` → "ac", "abc", "abbc" |
| `+` | 直前の1回以上 | `\d+` → 1桁以上の数字 |
| `?` | 直前の0〜1回 | `colou?r` → "color", "colour" |
| `{n,m}` | n回以上m回以下 | `\d{2,4}` → 2〜4桁の数字 |
| `[abc]` | 文字クラス | `[aeiou]` → 母音 |
| `[^abc]` | 否定文字クラス | `[^\d]` → 数字以外 |
| `(...)` | キャプチャグループ | `(\d{4})-(\d{2})` |
| `(?:...)` | 非キャプチャグループ | `(?:ab)+` |
| `(?=...)` | 先読み | `\d+(?=円)` → "100円"の"100" |
| `(?<=...)` | 後読み | `(?<=\$)\d+` → "$100"の"100" |

## [regex] クラス

```powershell
# 全マッチの取得（-matchは最初の1つのみ）
$text = "price: $100, tax: $10, total: $110"
[regex]::Matches($text, '\$(\d+)') | ForEach-Object {
    "金額: $($_.Groups[1].Value)"
}

# 正規表現オブジェクト
$pattern = [regex]::new('\b[\w.]+@[\w.]+\.\w+\b')
$pattern.Matches("Contact: a@b.com or c@d.org") | ForEach-Object { $_.Value }

# 置換（デリゲート使用）
[regex]::Replace("hello world", "\b\w", { $args[0].Value.ToUpper() })
# → "Hello World"（各単語の先頭を大文字に）
```

## まとめ

| ポイント | 内容 |
|---|---|
| `-match` | 最初のマッチを検出、`$Matches` に格納 |
| `-replace` | 正規表現で置換（`$1`, `$2` でキャプチャ参照） |
| `-split` | 正規表現で分割 |
| 名前付きキャプチャ | `(?<name>...)` で可読性の高いマッチ |
| `[regex]::Matches` | 全マッチを取得（`-match` は1つのみ） |

> **ヒント:** 第5章（演算子）や第10章（テキスト処理）で部分的に登場した正規表現の内容を、この章で体系的にまとめています。

## ハンズオン課題

```powershell
# 1. IPアドレスの抽出
$log = "Connection from 192.168.1.100 to 10.0.0.1 on port 443"
[regex]::Matches($log, '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') | ForEach-Object { $_.Value }

# 2. メールアドレスの検証
function Test-Email {
    param([string]$Email)
    $Email -match '^[\w.+-]+@[\w-]+\.[\w.]+$'
}
Test-Email "user@example.com"   # True
Test-Email "invalid"            # False

# 3. テキストからURLを抽出
$text = "Visit https://example.com or http://test.org/page for info"
[regex]::Matches($text, 'https?://[\w./%-]+') | ForEach-Object { $_.Value }
```


