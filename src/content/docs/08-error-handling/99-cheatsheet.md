---
title: "第8章 チートシート"
description: "エラー処理とデバッグ — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## エラーの種類

| | 終了エラー | 非終了エラー |
|---|---|---|
| 動作 | スクリプト停止 | 表示して続行 |
| 捕捉 | `try/catch` で可能 | `-ErrorAction Stop` で変換 |

## ErrorAction

| 値 | 表示 | 続行 | 記録 |
|---|:---:|:---:|:---:|
| `Continue` | ✅ | ✅ | ✅ |
| `SilentlyContinue` | ❌ | ✅ | ✅ |
| `Stop` | ✅ | ❌ | ✅ |
| `Ignore` | ❌ | ✅ | ❌ |

## 定型パターン

```powershell
try {
    Get-Item "存在しない.txt" -ErrorAction Stop
}
catch {
    Write-Warning "エラー: $_"
}
finally {
    # 必ず実行（クリーンアップ）
}

$Error[0]                    # 直近のエラー
$Error[0].Exception.Message  # メッセージ
$Error.Clear()               # 履歴クリア
```
