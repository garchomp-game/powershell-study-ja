---
title: "第12章 チートシート"
description: "高度な関数とツール作成 — 暗記用チートシート"
sidebar:
  order: 99
  badge:
    text: 暗記
    variant: tip
---

> **3分で復習 🌙**

## スプラッティング

```powershell
$params = @{
    Path    = "/tmp"
    Filter  = "*.txt"
    Recurse = $true
}
Get-ChildItem @params    # @で展開（$ではない！）
```

## ShouldProcess

```powershell
function Remove-OldFile {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)
    if ($PSCmdlet.ShouldProcess($Path, "Delete")) {
        Remove-Item $Path
    }
}
Remove-OldFile ./test.txt -WhatIf  # シミュレーション
```

## 出力ストリーム

| # | ストリーム | コマンド |
|---|---|---|
| 1 | Success | `Write-Output` |
| 2 | Error | `Write-Error` |
| 3 | Warning | `Write-Warning` |
| 4 | Verbose | `Write-Verbose` |
| 5 | Debug | `Write-Debug` |
| 6 | Information | `Write-Information` |
