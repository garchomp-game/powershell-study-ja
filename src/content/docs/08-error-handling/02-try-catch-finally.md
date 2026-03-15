---
title: Try / Catch / Finally
description: 構造化された例外処理の実装
sidebar:
  order: 2
---

## 基本構文

```powershell
try {
    # エラーが発生する可能性のあるコード
    $content = Get-Content ./config.json -ErrorAction Stop
    $config = $content | ConvertFrom-Json
    "設定を読み込みました: $($config.appName)"
}
catch {
    # エラー発生時の処理
    Write-Warning "設定の読み込みに失敗: $($_.Exception.Message)"
}
finally {
    # エラーの有無にかかわらず必ず実行
    Write-Verbose "処理完了"
}
```

## 型別 catch

特定の例外型に応じた処理が可能です。

```powershell
try {
    $data = Get-Content ./data.json -ErrorAction Stop | ConvertFrom-Json
    $result = 10 / $data.divisor
}
catch [System.IO.FileNotFoundException] {
    Write-Warning "ファイルが見つかりません"
}
catch [System.DivideByZeroException] {
    Write-Warning "ゼロ除算エラー"
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Warning "アイテムが見つかりません"
}
catch {
    # その他のすべてのエラー
    Write-Warning "予期しないエラー: $($_.Exception.GetType().Name): $($_.Exception.Message)"
}
```

## 非終了エラーの捕捉

非終了エラーは `-ErrorAction Stop` で終了エラーに変換しないと `catch` できません。

```powershell
# ❌ 非終了エラーは catch されない
try {
    Get-Item "存在しない.txt"  # 非終了エラー → catch されない
}
catch {
    "このブロックは実行されない"
}

# ✅ -ErrorAction Stop で変換すると catch される
try {
    Get-Item "存在しない.txt" -ErrorAction Stop
}
catch {
    "エラーを捕捉: $($_.Exception.Message)"
}
```

## throw と $PSCmdlet.ThrowTerminatingError

```powershell
# throw — カスタム例外を発生させる
function Test-Condition {
    param([int]$Value)
    if ($Value -lt 0) {
        throw "値は0以上でなければなりません（指定値: $Value）"
    }
    "OK: $Value"
}

# .NET例外を投げる
throw [System.InvalidOperationException]::new("無効な操作です")
```

## 実践パターン: リトライ処理

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            return & $ScriptBlock
        }
        catch {
            Write-Warning "試行 $i/$MaxRetries 失敗: $($_.Exception.Message)"
            if ($i -eq $MaxRetries) { throw }
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

# 使用例
Invoke-WithRetry -ScriptBlock {
    Invoke-RestMethod "https://api.example.com/data"
} -MaxRetries 3 -DelaySeconds 5
```

## ハンズオン課題

```powershell
# エラー処理付きのファイル読み込み関数
function Read-ConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    try {
        if (-not (Test-Path $Path)) { throw "ファイルが見つかりません: $Path" }
        $content = Get-Content $Path -Raw -ErrorAction Stop
        $config = $content | ConvertFrom-Json -ErrorAction Stop
        Write-Verbose "設定読み込み完了: $Path"
        return $config
    }
    catch [System.ArgumentException] {
        Write-Error "JSONパースエラー: $($_.Exception.Message)"
    }
    catch {
        Write-Error "読み込みエラー: $($_.Exception.Message)"
    }
}

# テスト
'{"name":"test","port":8080}' | Out-File /tmp/test-config.json
Read-ConfigFile -Path /tmp/test-config.json -Verbose
Read-ConfigFile -Path /tmp/nonexist.json
```
