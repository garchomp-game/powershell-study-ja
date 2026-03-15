---
title: スプラッティングと高度なテクニック
description: スプラッティング、プロキシ関数、動的パラメータ
sidebar:
  order: 1
---

## スプラッティング

スプラッティングは、ハッシュテーブルまたは配列を使ってパラメータをまとめて渡すテクニックです。可読性が大幅に向上します。

```powershell
# 通常の書き方（長くなりがち）
Copy-Item -Path ./source.txt -Destination ./backup/ -Force -Verbose

# スプラッティング（ハッシュテーブル）
$params = @{
    Path        = "./source.txt"
    Destination = "./backup/"
    Force       = $true
    Verbose     = $true
}
Copy-Item @params  # @ で展開

# 条件に応じたパラメータ構築
$params = @{
    Path = "~/documents"
    File = $true
}
if ($recursive) { $params.Recurse = $true }
if ($filter) { $params.Filter = $filter }
Get-ChildItem @params

# 配列でのスプラッティング（位置パラメータ）
$copyArgs = "source.txt", "dest.txt"
Copy-Item @copyArgs
```

## ShouldProcess の実装

`-WhatIf` と `-Confirm` を独自関数で対応させる方法です。

```powershell
function Remove-OldLogs {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [string]$Path = "./logs",
        [int]$DaysOld = 30
    )
    
    $cutoff = (Get-Date).AddDays(-$DaysOld)
    $oldFiles = Get-ChildItem $Path -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    
    foreach ($file in $oldFiles) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Delete file")) {
            Remove-Item $file.FullName
            Write-Verbose "削除: $($file.Name)"
        }
    }
}

# -WhatIf で安全にテスト
Remove-OldLogs -Path /tmp -DaysOld 7 -WhatIf

# -Confirm で確認付き実行
Remove-OldLogs -Path /tmp -DaysOld 7 -Confirm
```

## 出力ストリームの活用

```powershell
function Invoke-ComplexTask {
    [CmdletBinding()]
    param([string]$Name)
    
    Write-Verbose "開始: $Name"                  # ストリーム4
    Write-Debug "デバッグ: パラメータ=$Name"     # ストリーム5
    Write-Information "情報: 処理中" -Tags "info" # ストリーム6
    
    # メインの出力（ストリーム1）
    [PSCustomObject]@{ Task=$Name; Status="Complete" }
    
    Write-Verbose "完了: $Name"
}

# 各ストリームの制御
$result = Invoke-ComplexTask -Name "Test" -Verbose -InformationVariable infoMsgs
$infoMsgs  # Information ストリームの内容
```

## ハンズオン課題

```powershell
# スプラッティングでGet-ChildItemを柔軟に使う
function Find-Files {
    [CmdletBinding()]
    param(
        [string]$Path = ".",
        [string]$Filter,
        [switch]$Recurse,
        [int]$MinSizeMB
    )
    $params = @{ Path = $Path; File = $true }
    if ($Filter) { $params.Filter = $Filter }
    if ($Recurse) { $params.Recurse = $true; $params.ErrorAction = "SilentlyContinue" }
    
    $files = Get-ChildItem @params
    if ($MinSizeMB) { $files = $files | Where-Object { $_.Length -gt ($MinSizeMB * 1MB) } }
    $files | Select-Object Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime
}

Find-Files -Path ~ -Recurse -MinSizeMB 10
```


