---
title: テキスト処理
description: Select-String、正規表現マッチ、ログファイル解析
sidebar:
  order: 3
---

## Select-String — PowerShellの grep

```powershell
# ファイル内のテキスト検索
Select-String -Path ./log.txt -Pattern "ERROR"

# 複数ファイルで検索
Select-String -Path *.log -Pattern "failed" -CaseSensitive

# 再帰的に検索
Get-ChildItem -Recurse -Filter "*.ps1" | Select-String "Get-Process"

# 正規表現で検索
Select-String -Path ./data.txt -Pattern "\d{3}-\d{4}-\d{4}"  # 電話番号

# コンテキスト（前後の行も表示）
Select-String -Path ./log.txt -Pattern "ERROR" -Context 2,3  # 前2行、後3行

# マッチしない行を表示
Select-String -Path ./log.txt -Pattern "DEBUG" -NotMatch

# パイプラインで使用
Get-Content ./log.txt | Select-String "ERROR|WARN"
```

### Select-String の出力活用

```powershell
$matches = Select-String -Path ./access.log -Pattern '(\d+\.\d+\.\d+\.\d+).*"(\w+) (.*?)".*(\d{3})'
foreach ($m in $matches) {
    [PSCustomObject]@{
        IP     = $m.Matches.Groups[1].Value
        Method = $m.Matches.Groups[2].Value
        Path   = $m.Matches.Groups[3].Value
        Status = $m.Matches.Groups[4].Value
    }
}
```

## テキスト加工の実践パターン

```powershell
# ログファイルのエラー行を抽出して集計
Get-Content ./app.log -ErrorAction SilentlyContinue |
    Select-String "ERROR" |
    ForEach-Object { $_ -replace '.*ERROR:\s*', '' } |
    Group-Object |
    Sort-Object Count -Descending |
    Select-Object Count, Name -First 10

# CSV風テキストの解析
$rawData = @"
name,score,grade
Alice,95,A
Bob,82,B
Charlie,91,A
"@
$rawData | ConvertFrom-Csv | Where-Object { [int]$_.score -ge 90 }

# テキストの置換と加工
(Get-Content ./template.txt -Raw) -replace '{{DATE}}', (Get-Date -Format 'yyyy-MM-dd') |
    Set-Content ./output.txt
```

## まとめ

| ポイント | 内容 |
|---|---|
| `Select-String` | ファイル内のテキスト検索（`grep` 相当） |
| `-Pattern` | 正規表現パターンでマッチ |
| `-Context` | マッチ前後の行も表示 |
| `$m.Matches.Groups` | キャプチャグループでデータ抽出 |
| `Group-Object` | エラータイプの集計に有用 |

## ハンズオン課題

```powershell
# 1. PowerShellの履歴からGet-Processの使用回数を確認
$histPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $histPath) {
    $count = (Select-String -Path $histPath -Pattern "Get-Process" -SimpleMatch).Count
    "Get-Process の使用回数: $count"
}

# 2. 環境変数をPATHの区切りで分割して一覧表示
$env:PATH -split [IO.Path]::PathSeparator | ForEach-Object { 
    [PSCustomObject]@{ Path=$_; Exists=(Test-Path $_) }
} | Format-Table
```
