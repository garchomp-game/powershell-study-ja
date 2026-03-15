---
title: モジュールの作成
description: 独自のPowerShellモジュール（.psm1 / .psd1）を作成する
sidebar:
  order: 3
---

## スクリプトモジュール（.psm1）

最もシンプルなモジュール形式です。関数を定義したスクリプトファイルを `.psm1` 拡張子で保存します。

```powershell
# MyUtils.psm1
function Get-DiskUsage {
    [CmdletBinding()]
    param([string]$Path = ".")
    
    Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum |
        ForEach-Object {
            [PSCustomObject]@{
                Path = (Resolve-Path $Path)
                Files = $_.Count
                SizeMB = [math]::Round($_.Sum / 1MB, 2)
            }
        }
}

function ConvertTo-Base64 {
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Text)
    process {
        [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))
    }
}

# エクスポートする関数を明示
Export-ModuleMember -Function Get-DiskUsage, ConvertTo-Base64
```

## モジュールマニフェスト（.psd1）

```powershell
# マニフェストの自動生成
New-ModuleManifest -Path ./MyUtils/MyUtils.psd1 `
    -RootModule "MyUtils.psm1" `
    -ModuleVersion "1.0.0" `
    -Author "Your Name" `
    -Description "Utility functions for daily tasks" `
    -FunctionsToExport @("Get-DiskUsage", "ConvertTo-Base64") `
    -PowerShellVersion "7.0"
```

## モジュールのディレクトリ構成

```
MyUtils/
├── MyUtils.psd1        # マニフェスト
├── MyUtils.psm1        # メインモジュール
├── Public/             # 公開関数
│   ├── Get-DiskUsage.ps1
│   └── ConvertTo-Base64.ps1
├── Private/            # 内部関数
│   └── helpers.ps1
└── Tests/              # Pesterテスト
    └── MyUtils.Tests.ps1
```

```powershell
# 分割された関数を自動読み込みする .psm1
$public = Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue
$private = Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue

foreach ($file in @($public + $private)) {
    . $file.FullName
}

Export-ModuleMember -Function $public.BaseName
```

## ハンズオン課題

```powershell
# 簡単なモジュールを作成して使う
$modulePath = "/tmp/MyTestModule"
New-Item -Path $modulePath -ItemType Directory -Force

# .psm1 作成
@'
function Get-Greeting {
    param([string]$Name = "World")
    "Hello, $Name! 現在時刻: $(Get-Date -Format 'HH:mm:ss')"
}
Export-ModuleMember -Function Get-Greeting
'@ | Out-File "$modulePath/MyTestModule.psm1"

# インポートして使用
Import-Module $modulePath -Force
Get-Greeting -Name "PowerShell"
Remove-Module MyTestModule
```


