---
title: パイプライン対応関数
description: Begin/Process/EndとValueFromPipelineでパイプライン対応関数を作る
sidebar:
  order: 3
---

## Begin / Process / End ブロック

パイプライン入力を処理する関数では、3つのブロックが重要です：

```powershell
function ConvertTo-Upper {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Text
    )
    
    begin {
        Write-Verbose "処理開始"
        $count = 0
    }
    
    process {
        # パイプラインの各オブジェクトに対して実行される
        $count++
        $Text.ToUpper()
    }
    
    end {
        Write-Verbose "処理完了: $count 件"
    }
}

"hello", "world", "powershell" | ConvertTo-Upper -Verbose
```

## ValueFromPipeline vs ValueFromPipelineByPropertyName

```powershell
# ValueFromPipeline — オブジェクト全体を受け取る
function Get-FileSize {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.IO.FileInfo]$File
    )
    process {
        [PSCustomObject]@{
            Name = $File.Name
            SizeKB = [math]::Round($File.Length / 1KB, 2)
        }
    }
}
Get-ChildItem *.md | Get-FileSize

# ValueFromPipelineByPropertyName — プロパティ名で自動バインド
function Test-ServerConnection {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("HostName", "Server")]
        [string]$ComputerName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int]$Port = 80
    )
    process {
        "テスト: ${ComputerName}:${Port}"
    }
}

# プロパティ名でバインド
[PSCustomObject]@{ ComputerName="web01"; Port=443 },
[PSCustomObject]@{ ComputerName="db01"; Port=5432 } |
    Test-ServerConnection
```

## 実践例: ログ解析関数

```powershell
function ConvertFrom-LogLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Line
    )
    begin { $lineNum = 0 }
    process {
        $lineNum++
        if ($Line -match '^(\S+ \S+) (\w+): (.+)$') {
            [PSCustomObject]@{
                LineNumber = $lineNum
                Timestamp  = $Matches[1]
                Level      = $Matches[2]
                Message    = $Matches[3]
            }
        }
    }
}

# 使用例
@(
    "2025-03-15 10:00:00 INFO: Server started"
    "2025-03-15 10:00:05 ERROR: Connection failed"
    "2025-03-15 10:00:10 INFO: Retrying..."
) | ConvertFrom-LogLine | Where-Object Level -eq "ERROR"
```

## ハンズオン課題

```powershell
# パイプライン対応のファイルサイズ変換関数を作る
function ConvertTo-ReadableSize {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.IO.FileInfo]$File
    )
    process {
        $size = switch ($File.Length) {
            { $_ -ge 1GB } { "{0:N2} GB" -f ($_ / 1GB) }
            { $_ -ge 1MB } { "{0:N2} MB" -f ($_ / 1MB) }
            { $_ -ge 1KB } { "{0:N2} KB" -f ($_ / 1KB) }
            default        { "$_ B" }
        }
        [PSCustomObject]@{ Name=$File.Name; Size=$size; Bytes=$File.Length }
    }
}
Get-ChildItem ~ -File -ErrorAction SilentlyContinue | 
    ConvertTo-ReadableSize | Sort-Object Bytes -Descending | Select-Object -First 10
```
