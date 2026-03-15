---
title: ファイル操作
description: ファイルとディレクトリの作成・読み書き・コピー・移動・削除
sidebar:
  order: 1
---

## ファイルの読み書き

### ファイルの読み込み

```powershell
# Get-Content — 行の配列として読み込み
$lines = Get-Content ./data.txt
$lines[0]  # 先頭行
$lines[-1] # 末尾行

# -Raw — ファイル全体を1つの文字列として読み込み
$text = Get-Content ./data.txt -Raw

# -Head / -Tail — 先頭/末尾のN行
Get-Content ./log.txt -Head 10   # 先頭10行
Get-Content ./log.txt -Tail 20   # 末尾20行

# -Wait — ファイル監視（tail -f相当）
Get-Content ./log.txt -Wait -Tail 5

# エンコーディング指定
Get-Content ./data.txt -Encoding UTF8
```

### ファイルの書き込み

```powershell
# Set-Content — 上書き
Set-Content -Path ./output.txt -Value "Hello, World!"
"line 1", "line 2", "line 3" | Set-Content ./output.txt

# Add-Content — 追記
Add-Content -Path ./output.txt -Value "追記行"
Get-Date | Add-Content ./log.txt

# Out-File — 書式付きで出力
Get-Process | Out-File ./processes.txt
Get-Process | Out-File ./processes.txt -Append  # 追記

# エンコーディング指定
Set-Content -Path ./utf8.txt -Value "日本語テキスト" -Encoding UTF8
```

## アイテム操作

```powershell
# New-Item — 新規作成
New-Item -Path ./newfile.txt -ItemType File
New-Item -Path ./newfolder -ItemType Directory
New-Item -Path ./newfile.txt -Value "初期内容" -Force  # 上書き作成

# Copy-Item — コピー
Copy-Item ./source.txt ./dest.txt
Copy-Item ./folder1 ./folder2 -Recurse  # フォルダごとコピー

# Move-Item — 移動・名前変更
Move-Item ./old.txt ./new.txt          # 名前変更
Move-Item ./file.txt ./archive/        # フォルダに移動

# Remove-Item — 削除
Remove-Item ./temp.txt
Remove-Item ./folder -Recurse -Force   # フォルダごと強制削除

# Rename-Item — 名前変更
Rename-Item ./old.txt -NewName new.txt

# Test-Path — 存在確認
Test-Path ./config.json                # True / False
Test-Path ./folder -PathType Container # ディレクトリか
Test-Path ./file.txt -PathType Leaf    # ファイルか
```

## Get-ChildItem の活用

```powershell
# 基本
Get-ChildItem                          # カレントディレクトリ
Get-ChildItem -Path /tmp               # パス指定

# フィルタリング
Get-ChildItem -Filter "*.txt"          # ワイルドカードフィルタ（高速）
Get-ChildItem -Include "*.txt","*.md"  # 複数パターン
Get-ChildItem -Exclude "*.tmp"         # 除外パターン

# オプション
Get-ChildItem -Recurse                 # 再帰的
Get-ChildItem -Recurse -Depth 2        # 深さ制限
Get-ChildItem -File                    # ファイルのみ
Get-ChildItem -Directory               # ディレクトリのみ
Get-ChildItem -Hidden                  # 隠しファイル含む
Get-ChildItem -Force                   # 隠しファイル含む

# 実践: 大きなファイルを探す
Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 10 FullName, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}
```

## パス操作

```powershell
# Join-Path — パスの結合
Join-Path $HOME "Documents" "file.txt"

# Split-Path — パスの分解
Split-Path "/home/user/docs/report.txt"          # /home/user/docs
Split-Path "/home/user/docs/report.txt" -Leaf     # report.txt
Split-Path "/home/user/docs/report.txt" -Extension # .txt (PS7.0+)

# Resolve-Path — 相対パスをフルパスに
Resolve-Path ./

# [System.IO.Path] — .NETのパスユーティリティ
[IO.Path]::GetExtension("file.txt")       # .txt
[IO.Path]::GetFileNameWithoutExtension("report.csv")  # report
[IO.Path]::Combine("/tmp", "sub", "file.txt")
[IO.Path]::GetTempPath()                   # 一時フォルダ
[IO.Path]::GetTempFileName()               # 一時ファイル作成
```

## ハンズオン課題

```powershell
# ファイル管理の一連を実践
$dir = "/tmp/ps-file-demo"
New-Item $dir -ItemType Directory -Force
1..5 | ForEach-Object { Set-Content "$dir/file$_.txt" "Content of file $_" }
Get-ChildItem $dir | Format-Table Name, Length
Copy-Item "$dir/file1.txt" "$dir/file1_backup.txt"
Get-Content "$dir/file1.txt"
Remove-Item $dir -Recurse -Force
```
