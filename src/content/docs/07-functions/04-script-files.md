---
title: スクリプトファイル
description: .ps1スクリプトの作成と実行・引数渡し・ドットソーシング
sidebar:
  order: 4
---

## スクリプトファイルの基本

PowerShellスクリプトは `.ps1` 拡張子のテキストファイルです。

```powershell
# hello.ps1
param(
    [string]$Name = "World"
)
Write-Host "Hello, $Name!" -ForegroundColor Cyan
```

### 実行方法

```powershell
# パスを指定して実行
./hello.ps1
./hello.ps1 -Name "太郎"

# フルパスで実行
& "/home/user/scripts/hello.ps1" -Name "花子"

# 現在のスコープで実行（ドットソーシング）
. ./hello.ps1 -Name "次郎"
```

### 実行 vs ドットソーシング

```powershell
# スクリプト内の変数・関数はスクリプト終了後に消える
./myscript.ps1   # 独自スコープで実行

# ドットソーシング: 変数・関数が現在のスコープに残る
. ./myscript.ps1  # 現在のスコープで実行
```

## スクリプトパラメータ

```powershell
# deploy.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment,

    [string]$Version = "latest",
    [switch]$DryRun
)

Write-Verbose "デプロイ開始: $Environment v$Version"
if ($DryRun) {
    Write-Host "[DRY RUN] デプロイをシミュレーション" -ForegroundColor Yellow
} else {
    Write-Host "デプロイ実行中..." -ForegroundColor Green
}
```

```powershell
# 実行
./deploy.ps1 -Environment Production -Version "2.1.0" -Verbose
./deploy.ps1 -Environment Staging -DryRun
```

## $PSScriptRoot と $MyInvocation

```powershell
# スクリプトファイルのディレクトリ
$PSScriptRoot

# スクリプト内から他のファイルを相対パスで読み込み
$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath | ConvertFrom-Json

# スクリプトの情報
$MyInvocation.MyCommand.Name        # スクリプト名
$MyInvocation.MyCommand.Path        # フルパス
$MyInvocation.BoundParameters       # 渡されたパラメータ
```

## #Requires ステートメント

```powershell
# スクリプトの実行要件を宣言
#Requires -Version 7.0
#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0" }
#Requires -PSEdition Core

# これらの要件が満たされない場合、スクリプトは実行されずにエラー
```

## ハンズオン課題

```powershell
# 1. スクリプトファイルを作成して実行
$script = @'
[CmdletBinding()]
param(
    [string]$Directory = ".",
    [string]$Extension = "*",
    [switch]$Recurse
)

$params = @{ Path = $Directory; File = $true }
if ($Extension -ne "*") { $params.Filter = "*.$Extension" }
if ($Recurse) { $params.Recurse = $true }

Get-ChildItem @params | 
    Measure-Object Length -Sum -Average |
    ForEach-Object {
        [PSCustomObject]@{
            Files = $_.Count
            TotalMB = [math]::Round($_.Sum / 1MB, 2)
            AvgKB = [math]::Round($_.Average / 1KB, 2)
        }
    }
'@
$script | Out-File /tmp/Get-DirStats.ps1
pwsh /tmp/Get-DirStats.ps1 -Directory ~ -Recurse -Verbose
```

---

## 🌙 寝る前チートシート

> **第7章の要点を3分で復習**

| 概念 | 書き方 |
|---|---|
| 基本関数 | `function Get-Greeting { param($Name) "Hello $Name" }` |
| パラメータ | `param([string]$Name, [int]$Age = 20)` |
| 必須パラメータ | `[Parameter(Mandatory)]$Name` |
| 入力検証 | `[ValidateSet("A","B")]$Choice` |
| CmdletBinding | `[CmdletBinding()] param(...)` で高度な関数に |
| パイプライン対応 | `process { $_ }` ブロックで1件ずつ処理 |

| スコープ | 意味 |
|---|---|
| `$local:var` | 現在のスコープのみ |
| `$script:var` | スクリプト全体 |
| `$global:var` | セッション全体 |

```powershell
# 定型パターン（丸暗記）
function Verb-Noun {}
    [CmdletBinding()]
    param()
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name
    )
    begin   { <# 初期化 #> }
    process { <# $_を処理 #> }
    end     { <# 後処理 #> }
}
```
