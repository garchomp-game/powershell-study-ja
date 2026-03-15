---
title: 文字列操作
description: PowerShellの文字列処理を完全に理解する
sidebar:
  order: 2
---

## 文字列の種類

PowerShellには**2種類の文字列**があります。

| 種類 | 記法 | 変数展開 | エスケープ |
|---|---|:---:|---|
| 展開可能文字列 | `"..."` | ✅ あり | `` ` `` バッククォート |
| リテラル文字列 | `'...'` | ❌ なし | `''` シングルクォート2つ |

```powershell
$name = "PowerShell"

# 展開可能文字列（ダブルクォート）
"Hello, $name!"           # → Hello, PowerShell!
"バージョン: $($PSVersionTable.PSVersion)"  # 式を $() で囲む

# リテラル文字列（シングルクォート）
'Hello, $name!'           # → Hello, $name!（変数は展開されない）
'It''s PowerShell'        # → It's PowerShell（' は '' でエスケープ）
```

### サブ式演算子 `$()`

ダブルクォート内で式やメソッド呼び出しを埋め込むには `$()` を使います。

```powershell
"現在時刻: $(Get-Date -Format 'HH:mm:ss')"
"プロセス数: $((Get-Process).Count)"
"大文字: $("hello".ToUpper())"
"計算結果: $(2 + 3 * 4)"
```

### ヒア文字列（Here-String）

複数行の文字列を簡単に記述できます。

```powershell
# 展開可能ヒア文字列
$message = @"
こんにちは、$name さん
今日は $(Get-Date -Format 'yyyy年MM月dd日') です。
PowerShell バージョン: $($PSVersionTable.PSVersion)
"@

# リテラルヒア文字列
$template = @'
変数は展開されません: $name
そのまま出力: $(Get-Date)
'@
```

> **注意:** `@"` と `"@` はそれぞれ行の先頭に置く必要があります。

## 文字列メソッド

.NETの `System.String` クラスの全メソッドが使えます。

```powershell
$s = "Hello, PowerShell World"

# 変換
$s.ToUpper()               # HELLO, POWERSHELL WORLD
$s.ToLower()               # hello, powershell world

# 検索
$s.Contains("PowerShell")  # True
$s.StartsWith("Hello")     # True
$s.EndsWith("World")       # True
$s.IndexOf("Power")        # 7

# 抽出
$s.Substring(7, 10)        # PowerShell
$s.Substring(7)            # PowerShell World

# 置換
$s.Replace("World", "7")   # Hello, PowerShell 7

# 分割・結合
"a,b,c,d".Split(",")      # @("a","b","c","d")
[string]::Join("-", @("a","b","c"))  # "a-b-c"

# トリミング
"  hello  ".Trim()         # "hello"
"  hello  ".TrimStart()    # "hello  "
"  hello  ".TrimEnd()      # "  hello"
"###hello###".Trim('#')    # "hello"

# パディング
"42".PadLeft(5, '0')       # "00042"
"42".PadRight(5, '-')      # "42---"

# null/空チェック
[string]::IsNullOrEmpty("")         # True
[string]::IsNullOrWhiteSpace("  ")  # True
```

## 文字列演算子

```powershell
# -replace（正規表現置換）
"Hello World" -replace "World", "PS"     # Hello PS
"abc123def" -replace "\d+", "***"        # abc***def

# -split（分割）
"one,two,three" -split ","       # @("one","two","three")
"one  two  three" -split "\s+"   # 正規表現で分割

# -join（結合）
@("one","two","three") -join ", "  # "one, two, three"

# -match（正規表現マッチ）
"PowerShell 7.4" -match "(\d+)\.(\d+)"
$Matches[0]  # "7.4"（全体マッチ）
$Matches[1]  # "7"（キャプチャ1）
$Matches[2]  # "4"（キャプチャ2）

# -like（ワイルドカードマッチ）
"PowerShell" -like "Power*"    # True
"PowerShell" -like "?ower*"    # True

# 文字列の繰り返し
"abc" * 3                     # "abcabcabc"
"-" * 40                      # "----------------------------------------"

# 文字列の連結
"Hello" + " " + "World"       # "Hello World"
$parts = "Hello", "World"
$parts -join " "               # "Hello World"
```

## 書式指定（-f 演算子）

```powershell
# 基本的な書式指定
"名前: {0}, 年齢: {1}" -f "太郎", 25    # 名前: 太郎, 年齢: 25

# 数値フォーマット
"{0:N2}" -f 1234.5678     # "1,234.57"（小数2桁区切り）
"{0:C}" -f 1234.56        # 通貨形式
"{0:P1}" -f 0.857         # "85.7%"
"{0:X}" -f 255            # "FF"（16進数）
"{0:D5}" -f 42            # "00042"（5桁ゼロ埋め）

# 日付フォーマット
"{0:yyyy-MM-dd HH:mm}" -f (Get-Date)

# パディング
"{0,-20} {1,10}" -f "左寄せ", "右寄せ"
```

## まとめ

| ポイント | 内容 |
|---|---|
| `"..."` | 変数展開あり、式は `$()` で埋め込み |
| `'...'` | 変数展開なし（リテラル） |
| `@"..."@` | ヒア文字列（複数行・変数展開あり） |
| `-replace` | 正規表現で置換 |
| `-split` / `-join` | 分割・結合 |
| `-f` 演算子 | 書式指定文字列 |

## ハンズオン課題

```powershell
# 1. 変数展開とリテラル文字列の違いを確認
$lang = "PowerShell"
"展開あり: $lang"   # PowerShell
'展開なし: $lang'   # $lang

# 2. ファイル名から拡張子を取得
$filename = "report-2025.final.xlsx"
$filename.Split(".")[-1]                    # メソッド方式
[System.IO.Path]::GetExtension($filename)   # .NET方式

# 3. 書式指定でテーブル風出力
Get-Process | Select-Object -First 5 | ForEach-Object {
    "{0,-20} {1,8} {2,10:N0}" -f $_.Name, $_.Id, $_.WorkingSet64
}

# 4. -match で情報を抽出
$logLine = "2025-03-15 10:30:45 ERROR: Connection failed"
if ($logLine -match "^(\d{4}-\d{2}-\d{2}) (\S+) (\w+): (.+)$") {
    "日付: $($Matches[1]), 時刻: $($Matches[2]), レベル: $($Matches[3])"
}
```
