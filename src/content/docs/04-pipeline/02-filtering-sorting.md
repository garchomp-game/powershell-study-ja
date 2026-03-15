---
title: フィルタリングとソート
description: Where-Object、Sort-Object、Select-Object、ForEach-Objectの活用
sidebar:
  order: 2
---

## Where-Object — フィルタリング

```powershell
# 基本構文（スクリプトブロック形式）
Get-Process | Where-Object { $_.CPU -gt 10 }

# 簡易構文（比較構文）— PowerShell 3.0+
Get-Process | Where-Object CPU -gt 10

# 文字列のフィルタリング
Get-Service | Where-Object Status -eq "Running"
Get-ChildItem | Where-Object Name -like "*.log"

# 複合条件
Get-Process | Where-Object { $_.CPU -gt 5 -and $_.WorkingSet -gt 100MB }

# Nullチェック
Get-Process | Where-Object Company | Select-Object Name, Company  # Companyがnullでないもの
```

## Sort-Object — ソート

```powershell
# 単一プロパティでソート
Get-Process | Sort-Object CPU -Descending

# 複数プロパティでソート
Get-ChildItem | Sort-Object @{Expression="Extension"}, @{Expression="Length"; Descending=$true}

# 簡略構文
Get-ChildItem | Sort-Object Extension, Length

# ユニークな値のみ
"apple","banana","apple","cherry" | Sort-Object -Unique
```

## Select-Object — 選択と射影

```powershell
# プロパティの選択
Get-Process | Select-Object Name, CPU, WorkingSet

# 先頭/末尾
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
Get-Process | Select-Object -Last 3

# ユニーク
Get-Process | Select-Object -ExpandProperty Name -Unique

# 計算プロパティ（カスタム列）
Get-Process | Select-Object Name,
    @{Name='MemMB'; Expression={[math]::Round($_.WorkingSet / 1MB, 1)}},
    @{N='CPUs'; E={$_.CPU}}
```

### 計算プロパティの構文

```powershell
# @{Name='表示名'; Expression={計算式}}
# 短縮形: @{N='名前'; E={式}} または @{L='ラベル'; E={式}}

Get-ChildItem ~/Documents -File | Select-Object Name,
    @{N='SizeMB'; E={[math]::Round($_.Length / 1MB, 2)}},
    @{N='Age';    E={(Get-Date) - $_.LastWriteTime | Select-Object -ExpandProperty Days}}
```

## ForEach-Object — 変換処理

```powershell
# スクリプトブロック形式
1..5 | ForEach-Object { $_ * $_ }

# メソッド呼び出しの短縮形（.NET メソッド）
"hello","world" | ForEach-Object ToUpper

# プロパティ展開
Get-Process | ForEach-Object Name

# 複雑な変換
Get-ChildItem *.txt | ForEach-Object {
    [PSCustomObject]@{
        File = $_.Name
        Lines = (Get-Content $_ | Measure-Object -Line).Lines
        SizeKB = [math]::Round($_.Length / 1KB, 1)
    }
}
```

## 組み合わせパターン

```powershell
# フィルタ → ソート → 選択 → 出力
Get-Process |
    Where-Object { $_.CPU -gt 0 } |
    Sort-Object CPU -Descending |
    Select-Object -First 10 Name, CPU, @{N='MemMB';E={[math]::Round($_.WorkingSet/1MB)}} |
    Format-Table -AutoSize

# ファイルの拡張子別集計
Get-ChildItem ~ -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 1MB |
    Group-Object Extension |
    Sort-Object Count -Descending |
    Select-Object Count, Name -First 10
```

## まとめ

| コマンドレット | 用途 | エイリアス |
|---|---|---|
| `Where-Object` | 条件でフィルタリング | `?`, `where` |
| `Sort-Object` | プロパティでソート | `sort` |
| `Select-Object` | プロパティの選択・先頭/末尾 | `select` |
| `ForEach-Object` | 各要素に対する変換処理 | `%`, `foreach` |

## ハンズオン課題

```powershell
# 1. プロセスのTop 5（CPU使用率順）
Get-Process | Where-Object CPU | Sort-Object CPU -Descending |
    Select-Object -First 5 Name, @{N='CPU(s)';E={[math]::Round($_.CPU,1)}}

# 2. ホームディレクトリの大きいファイルTop 10
Get-ChildItem ~ -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 10 @{N='SizeMB';E={[math]::Round($_.Length/1MB,1)}}, FullName

# 3. 実行中のサービス一覧（Linuxではsystemd経由で取得可能な範囲）
Get-Service -ErrorAction SilentlyContinue |
    Where-Object Status -eq "Running" |
    Sort-Object DisplayName |
    Select-Object DisplayName, Status
```
