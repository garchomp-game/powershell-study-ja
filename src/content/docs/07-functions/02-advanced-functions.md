---
title: 高度な関数（CmdletBinding）
description: CmdletBindingとパラメータ検証属性で堅牢な関数を作る
sidebar:
  order: 2
---

## CmdletBinding

`[CmdletBinding()]` を追加すると、関数がコマンドレットと同等の機能を持つ**高度な関数（Advanced Function）**になります。

```powershell
function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    Write-Verbose "接続先: $ComputerName"
    [PSCustomObject]@{
        Computer = $ComputerName
        OS       = $IsLinux ? "Linux" : "Windows"
        PS       = $PSVersionTable.PSVersion.ToString()
    }
}

# 共通パラメータが自動的に追加される
Get-SystemInfo -ComputerName "localhost" -Verbose
```

### CmdletBinding で得られる機能

- **共通パラメータ**: `-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction` 等
- **$PSCmdlet 変数**: `ShouldProcess`等のメソッドにアクセス
- **厳密なパラメータバインディング**: 未知のパラメータでエラー

## パラメータ検証属性

```powershell
function New-User {
    [CmdletBinding()]
    param(
        # 必須パラメータ
        [Parameter(Mandatory, HelpMessage="ユーザー名を入力")]
        [string]$Name,

        # 範囲制限
        [ValidateRange(1, 150)]
        [int]$Age,

        # 許可値リスト
        [ValidateSet("Admin", "User", "Guest")]
        [string]$Role = "User",

        # 正規表現検証
        [ValidatePattern("^[\w.]+@[\w.]+\.\w+$", ErrorMessage="無効なメール形式")]
        [string]$Email,

        # カスタム検証
        [ValidateScript({ Test-Path $_ }, ErrorMessage="パスが存在しません")]
        [string]$ConfigPath,

        # 空文字・Null禁止
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        # 文字列長
        [ValidateLength(3, 50)]
        [string]$DisplayName,

        # 要素数制限（配列パラメータ向け）
        [ValidateCount(1, 5)]
        [string[]]$Tags
    )
    
    [PSCustomObject]@{ Name=$Name; Age=$Age; Role=$Role; Email=$Email }
}
```

| 属性 | 説明 | 例 |
|---|---|---|
| `Mandatory` | 必須パラメータ | `[Parameter(Mandatory)]` |
| `ValidateSet` | 許可値のリスト | `[ValidateSet("A","B","C")]` |
| `ValidateRange` | 数値の範囲 | `[ValidateRange(1,100)]` |
| `ValidatePattern` | 正規表現パターン | `[ValidatePattern("^\d+$")]` |
| `ValidateScript` | カスタムスクリプト検証 | `[ValidateScript({$_ -gt 0})]` |
| `ValidateLength` | 文字列長 | `[ValidateLength(1,255)]` |
| `ValidateCount` | 配列の要素数 | `[ValidateCount(1,10)]` |
| `ValidateNotNull` | Null禁止 | `[ValidateNotNull()]` |
| `ValidateNotNullOrEmpty` | Null・空禁止 | `[ValidateNotNullOrEmpty()]` |

## パラメータセット

同じ関数で異なるパラメータの組み合わせを定義できます。

```powershell
function Get-Data {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Mandatory)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ById', Mandatory)]
        [int]$Id,

        [Parameter()]  # 共通パラメータ
        [switch]$Detailed
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ByName' { "名前で検索: $Name" }
        'ById'   { "IDで検索: $Id" }
    }
}

Get-Data -Name "test"   # ByName セット
Get-Data -Id 42         # ById セット
```

## ハンズオン課題

```powershell
# 検証属性付きの関数を作成してテスト
function New-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppName,

        [ValidateRange(1024, 65535)]
        [int]$Port = 8080,

        [ValidateSet("Development", "Staging", "Production")]
        [string]$Environment = "Development"
    )

    Write-Verbose "設定作成: $AppName ($Environment) on port $Port"
    [PSCustomObject]@{ App=$AppName; Port=$Port; Env=$Environment }
}

# テスト
New-Config -AppName "MyApp" -Verbose
New-Config -AppName "MyApp" -Port 3000 -Environment "Production"
# New-Config -AppName "MyApp" -Port 80  # エラー: 範囲外
```
