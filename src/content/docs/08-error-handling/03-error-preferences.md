---
title: ErrorAction と ErrorVariable
description: エラー動作の制御とエラー情報の収集
sidebar:
  order: 3
---

## $ErrorActionPreference

セッション全体のエラー動作を制御するグローバル設定です。

```powershell
$ErrorActionPreference         # デフォルト: "Continue"

# 設定例: 全エラーを停止に変更
$ErrorActionPreference = "Stop"  # 全エラーが try/catch で捕捉可能に

# 推奨: スクリプトの先頭で設定
$ErrorActionPreference = "Stop"  # スクリプト全体で厳格なエラー処理
```

## -ErrorAction パラメータ

個々のコマンドで `$ErrorActionPreference` を上書きします。

```powershell
# 値の比較
Get-Item "不明.txt" -ErrorAction Continue          # エラー表示して続行
Get-Item "不明.txt" -ErrorAction SilentlyContinue  # エラー非表示で続行
Get-Item "不明.txt" -ErrorAction Stop              # エラーで停止
Get-Item "不明.txt" -ErrorAction Ignore            # 完全に無視
```

## -ErrorVariable

エラーを指定した変数に収集します。

```powershell
# エラーを変数に格納
$files = "file1.txt", "file2.txt", "file3.txt"
$results = $files | ForEach-Object {
    Get-Item $_ -ErrorAction SilentlyContinue -ErrorVariable +collectedErrors
}

# 収集したエラーを確認
$collectedErrors | ForEach-Object {
    "エラー: $($_.TargetObject) — $($_.Exception.Message)"
}
```

> **注意:** `-ErrorVariable` の変数名に `+` を付けると**追記モード**、付けないと**上書きモード**です。

## Write-Error と throw の使い分け

```powershell
# Write-Error — 非終了エラーを生成（処理は続行）
function Test-WriteError {
    Write-Error "これは非終了エラー"
    Write-Host "この行は実行される"
}

# throw — 終了エラーを生成（処理を停止）
function Test-Throw {
    throw "これは終了エラー"
    Write-Host "この行は実行されない"
}
```

| 方法 | エラー種類 | 用途 |
|---|---|---|
| `Write-Error` | 非終了エラー | 処理を続行したい場合 |
| `throw` | 終了エラー | 処理を停止すべき場合 |
| `$PSCmdlet.ThrowTerminatingError()` | 終了エラー | 高度な関数での正式な方法 |

## デバッグのヒント

```powershell
# Write-Verbose でトレース
function Process-Data {
    [CmdletBinding()]
    param([string]$InputData)
    Write-Verbose "入力: $InputData"
    Write-Debug "デバッグ情報: 処理開始"
    # ... 処理 ...
    Write-Verbose "処理完了"
}
Process-Data -InputData "test" -Verbose

# Set-PSBreakpoint（スクリプトファイルのデバッグ）
Set-PSBreakpoint -Script ./myscript.ps1 -Line 10
Set-PSBreakpoint -Variable x -Mode Write  # 変数が書き換わった時に停止

# ブレークポイント一覧と削除
Get-PSBreakpoint
Remove-PSBreakpoint -Id 0
```

## ハンズオン課題

```powershell
# ErrorAction の違いを比較
"=== Continue ===" ; Get-Item "x.txt" -EA Continue ; "続行"
"=== SilentlyContinue ===" ; Get-Item "x.txt" -EA SilentlyContinue ; "続行"
"=== Ignore ===" ; Get-Item "x.txt" -EA Ignore ; "続行"

# ErrorVariable でエラー収集
$null = 1..5 | ForEach-Object {
    Get-Item "file$_.txt" -EA SilentlyContinue -EV +errs
}
"エラー数: $($errs.Count)"
```

