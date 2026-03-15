---
title: CSV・JSON・XMLの操作
description: 構造化データフォーマットの読み書きとデータ変換
sidebar:
  order: 2
---

## CSV

```powershell
# CSVエクスポート
$data = @(
    [PSCustomObject]@{ Name="太郎"; Age=25; City="東京" }
    [PSCustomObject]@{ Name="花子"; Age=30; City="大阪" }
    [PSCustomObject]@{ Name="次郎"; Age=28; City="名古屋" }
)
$data | Export-Csv /tmp/users.csv -NoTypeInformation -Encoding UTF8

# CSVインポート
$users = Import-Csv /tmp/users.csv
$users | Format-Table
$users | Where-Object { [int]$_.Age -gt 27 }

# ConvertTo/From-Csv（文字列として）
$csvText = $data | ConvertTo-Csv -NoTypeInformation
$objects = $csvText | ConvertFrom-Csv

# 区切り文字の変更
$data | Export-Csv /tmp/users.tsv -Delimiter "`t" -NoTypeInformation
Import-Csv /tmp/users.tsv -Delimiter "`t"
```

## JSON

```powershell
# JSONに変換
$config = @{
    app = "MyApp"
    port = 8080
    features = @("auth", "logging", "cache")
    database = @{
        host = "localhost"
        port = 5432
    }
}
$json = $config | ConvertTo-Json -Depth 3
$json | Out-File /tmp/config.json

# JSONから読み込み
$loaded = Get-Content /tmp/config.json -Raw | ConvertFrom-Json
$loaded.app            # MyApp
$loaded.database.host  # localhost
$loaded.features       # auth, logging, cache

# REST APIからのJSON
$repo = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell"
$repo | Select-Object name, stargazers_count, language
```

## XML

```powershell
# XMLの読み込み
[xml]$xml = Get-Content ./data.xml
# または
[xml]$xml = @"
<users>
    <user name="太郎" age="25"/>
    <user name="花子" age="30"/>
</users>
"@

# XMLアクセス
$xml.users.user              # ノードの配列
$xml.users.user[0].name      # "太郎"

# Select-Xml でXPathクエリ
$nodes = Select-Xml -Xml $xml -XPath "//user[@age>27]"
$nodes.Node.name             # "花子"
```

## データ変換パイプライン

```powershell
# CSV → フィルタ → JSON 変換
Import-Csv /tmp/users.csv |
    Where-Object { [int]$_.Age -ge 28 } |
    ConvertTo-Json |
    Out-File /tmp/filtered-users.json

# プロセス情報 → CSV保存
Get-Process |
    Select-Object Name, Id, CPU, WorkingSet64 |
    Export-Csv /tmp/processes.csv -NoTypeInformation
```

## ハンズオン課題

```powershell
# JSONで設定ファイルを作成・読み込み
$settings = [ordered]@{
    appName = "PowerShell学習"
    version = "1.0"
    debug = $true
    modules = @("Pester", "PSScriptAnalyzer")
}
$settings | ConvertTo-Json | Out-File /tmp/settings.json
$loaded = Get-Content /tmp/settings.json -Raw | ConvertFrom-Json
"アプリ: $($loaded.appName), モジュール数: $($loaded.modules.Count)"
```
