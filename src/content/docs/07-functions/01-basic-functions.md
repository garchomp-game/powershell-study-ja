---
title: 基本的な関数
description: PowerShell関数の定義・パラメータ・戻り値・スコープ
sidebar:
  order: 1
---

## 関数の定義

```powershell
# 最もシンプルな関数
function Say-Hello {
    "Hello, PowerShell!"
}
Say-Hello  # → Hello, PowerShell!

# パラメータ付き関数
function Get-Greeting {
    param(
        [string]$Name,
        [string]$Time = "今日"  # デフォルト値
    )
    "$Time は、$Name さん！"
}
Get-Greeting -Name "太郎"
Get-Greeting -Name "花子" -Time "こんばんは"
```

### パラメータの宣言方法

```powershell
# 方法1: param ブロック（推奨）
function Get-UserInfo {
    param(
        [string]$Name,
        [int]$Age,
        [string]$City = "東京"
    )
    [PSCustomObject]@{ Name=$Name; Age=$Age; City=$City }
}

# 方法2: 関数名の後に直接（シンプルな関数向け）
function Add-Numbers($a, $b) {
    $a + $b
}

# 必須パラメータ
function Get-FileInfo {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    Get-Item $Path
}
# Get-FileInfo  # → プロンプトが表示される
```

## 戻り値

PowerShellの関数は、関数内で**出力されたすべてのオブジェクト**が戻り値になります。`return` は明示的にも使えますが、通常は不要です。

```powershell
# 暗黙的な戻り値（出力されたものすべて）
function Get-DoubleNumbers {
    param([int[]]$Numbers)
    foreach ($n in $Numbers) {
        $n * 2  # これが出力（戻り値）
    }
}
$result = Get-DoubleNumbers -Numbers 1,2,3,4,5
$result  # 2, 4, 6, 8, 10

# return による明示的な戻り値
function Test-IsEven {
    param([int]$Number)
    if ($Number % 2 -eq 0) {
        return $true
    }
    return $false
}

# ⚠️ 注意: 意図しない出力に気をつける
function Get-Something {
    $list = [System.Collections.ArrayList]::new()
    $list.Add("item1")  # Add() はインデックスを返す！ → 0 が出力される
    $list.Add("item2")  # → 1 が出力される
    return $list
}
# 修正版: [void] で出力を抑制
function Get-Something-Fixed {
    $list = [System.Collections.ArrayList]::new()
    [void]$list.Add("item1")
    [void]$list.Add("item2")
    return $list
}
```

## スコープ

```powershell
$x = "グローバル"

function Test-Scope {
    "関数内から: $x"       # 親スコープの変数を読める
    $x = "ローカル"        # ローカル変数を作成（親は変更されない）
    "変更後: $x"
}

Test-Scope
"関数外: $x"  # まだ "グローバル"

# 親スコープを変更するには $script: や $global: を使う
function Set-GlobalVar {
    $global:appName = "MyApp"
    $script:counter = 0
}
```

## ハンズオン課題

```powershell
# 1. BMI計算関数を作成
function Get-BMI {
    param(
        [Parameter(Mandatory)][double]$WeightKg,
        [Parameter(Mandatory)][double]$HeightCm
    )
    $heightM = $HeightCm / 100
    [math]::Round($WeightKg / ($heightM * $heightM), 1)
}
Get-BMI -WeightKg 70 -HeightCm 175

# 2. ファイルサイズを人間が読める形式に変換する関数
function ConvertTo-HumanSize {
    param([long]$Bytes)
    switch ($Bytes) {
        { $_ -ge 1TB } { "{0:N2} TB" -f ($_ / 1TB); break }
        { $_ -ge 1GB } { "{0:N2} GB" -f ($_ / 1GB); break }
        { $_ -ge 1MB } { "{0:N2} MB" -f ($_ / 1MB); break }
        { $_ -ge 1KB } { "{0:N2} KB" -f ($_ / 1KB); break }
        default  { "$_ B" }
    }
}
ConvertTo-HumanSize 1234567890
```
