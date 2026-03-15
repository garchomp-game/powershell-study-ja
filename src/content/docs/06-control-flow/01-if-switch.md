---
title: 条件分岐（if / switch）
description: if/elseif/elseとswitch文による条件分岐を理解する
sidebar:
  order: 1
---

## if / elseif / else

```powershell
# 基本構文
$score = 85

if ($score -ge 90) {
    "優秀"
} elseif ($score -ge 70) {
    "良好"
} elseif ($score -ge 50) {
    "合格"
} else {
    "不合格"
}

# 変数への代入（if文は値を返す）
$grade = if ($score -ge 60) { "Pass" } else { "Fail" }

# 三項演算子（PowerShell 7+ の短縮形）
$grade = $score -ge 60 ? "Pass" : "Fail"
```

### 条件式で使われるパターン

```powershell
# Nullチェック
if ($null -eq $value) { "nullです" }         # $null を左に置くのがベストプラクティス
if ([string]::IsNullOrEmpty($str)) { "空です" }

# ファイル存在確認
if (Test-Path ./config.json) { "設定ファイルあり" }

# 型チェック
if ($value -is [int]) { "整数です" }

# 複合条件
if ($age -ge 18 -and $hasLicense) { "運転可能" }
if ($status -eq "Error" -or $retryCount -gt 3) { "処理停止" }

# 否定
if (-not (Test-Path $file)) { "ファイルがありません" }
if (!(Get-Process -Name "pwsh" -ErrorAction SilentlyContinue)) { "未起動" }

# 正規表現マッチ
if ($email -match "^[\w.]+@[\w.]+$") { "メールアドレス形式OK" }
```

## switch 文

`switch` はmatch-based な分岐構文で、PowerShellでは**複数条件にマッチ**することも可能です。

```powershell
# 基本的なswitch
$day = (Get-Date).DayOfWeek
switch ($day) {
    "Monday"    { "月曜日" }
    "Tuesday"   { "火曜日" }
    "Wednesday" { "水曜日" }
    "Thursday"  { "木曜日" }
    "Friday"    { "金曜日" }
    "Saturday"  { "土曜日" }
    "Sunday"    { "日曜日" }
}

# default（どれにも一致しない場合）
$status = "Unknown"
switch ($status) {
    "Running" { "実行中" }
    "Stopped" { "停止中" }
    default   { "不明な状態: $status" }
}
```

### switch の高度な使い方

```powershell
# -Wildcard オプション
$file = "report.xlsx"
switch -Wildcard ($file) {
    "*.txt"  { "テキストファイル" }
    "*.csv"  { "CSVファイル" }
    "*.xls*" { "Excelファイル" }
    "*.pdf"  { "PDFファイル" }
    default  { "不明な形式" }
}

# -Regex オプション
$testInput = "user@example.com"
switch -Regex ($testInput) {
    "^\d+$"          { "数値のみ" }
    "^[\w.]+@[\w.]+" { "メールアドレス" }
    "^https?://"     { "URL" }
    default          { "その他の文字列" }
}

# ScriptBlock 条件
$num = 42
switch ($num) {
    { $_ -lt 0 }    { "負の数" }
    { $_ -eq 0 }    { "ゼロ" }
    { $_ -gt 0 }    { "正の数" }
    { $_ % 2 -eq 0 } { "偶数" }   # 複数条件にマッチ可能！
}
# 出力: "正の数" と "偶数" の両方が出力される

# break で最初のマッチのみにする
switch ($num) {
    { $_ -lt 0 }     { "負の数"; break }
    { $_ -eq 0 }     { "ゼロ"; break }
    { $_ -gt 0 -and $_ % 2 -eq 0 } { "正の偶数"; break }
    { $_ -gt 0 }     { "正の奇数"; break }
}
```

### switch で配列を処理

```powershell
# 配列の各要素を評価
$fruits = "apple", "banana", "cherry", "date"
switch ($fruits) {
    "apple"  { "$_ → りんご" }
    "banana" { "$_ → バナナ" }
    default  { "$_ → その他" }
}
# 出力:
# apple → りんご
# banana → バナナ
# cherry → その他
# date → その他
```

## if vs switch の使い分け

| 状況 | 推奨 |
|---|---|
| 2〜3の条件分岐 | `if/elseif/else` |
| 多数の値との比較 | `switch` |
| ワイルドカードや正規表現 | `switch -Wildcard` / `-Regex` |
| 複雑な論理条件 | `if` |
| 配列の各要素の分類 | `switch` |

## ハンズオン課題

```powershell
# 1. FizzBuzz（1-30）
1..30 | ForEach-Object {
    if ($_ % 15 -eq 0) { "FizzBuzz" }
    elseif ($_ % 3 -eq 0) { "Fizz" }
    elseif ($_ % 5 -eq 0) { "Buzz" }
    else { $_ }
}

# 2. ファイル拡張子をswitch -Wildcardで分類
Get-ChildItem ~ -File -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object {
    $category = switch -Wildcard ($_.Extension) {
        ".txt"  { "テキスト" }
        ".md"   { "Markdown" }
        ".ps1"  { "PowerShell" }
        ".json" { "JSON" }
        ".csv"  { "CSV" }
        default { "その他 ($_)" }
    }
    [PSCustomObject]@{ Name = $_.Name; Category = $category }
} | Format-Table
```
