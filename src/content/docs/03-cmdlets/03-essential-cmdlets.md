---
title: 必須コマンドレット50選
description: PowerShellで頻繁に使うコマンドレットのカテゴリ別リファレンス
sidebar:
  order: 3
---

## 概要

PowerShellには数千のコマンドレットがありますが、日常的に使うのはその一部です。ここでは**カテゴリ別に50の必須コマンドレット**をリファレンスとしてまとめます。

## 🔍 情報取得・探索（8個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 1 | `Get-Command` | `gcm` | コマンドを検索する |
| 2 | `Get-Help` | `help`, `man` | ヘルプを表示する |
| 3 | `Get-Member` | `gm` | オブジェクトのメンバーを表示 |
| 4 | `Get-Alias` | `gal` | エイリアスを確認する |
| 5 | `Get-Module` | `gmo` | ロード済みモジュールを確認 |
| 6 | `Get-Variable` | `gv` | 変数を取得する |
| 7 | `Get-History` | `h`, `history` | コマンド履歴を表示 |
| 8 | `Get-PSProvider` | — | プロバイダー一覧 |

```powershell
# 使用例
Get-Command *-Process        # Process関連コマンドの検索
Get-Help Get-Service -Examples  # サービスコマンドの使用例
"Hello" | Get-Member          # 文字列のメンバー探索
```

## 📁 ファイル・ディレクトリ操作（10個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 9 | `Get-ChildItem` | `ls`, `dir`, `gci` | ファイル・フォルダの一覧 |
| 10 | `Get-Content` | `cat`, `gc`, `type` | ファイルの内容を読み込み |
| 11 | `Set-Content` | `sc` | ファイルに書き込み（上書き） |
| 12 | `Add-Content` | `ac` | ファイルに追記 |
| 13 | `New-Item` | `ni` | ファイル・フォルダの新規作成 |
| 14 | `Copy-Item` | `cp`, `copy` | コピー |
| 15 | `Move-Item` | `mv`, `move` | 移動・名前変更 |
| 16 | `Remove-Item` | `rm`, `del` | 削除 |
| 17 | `Rename-Item` | `ren` | 名前変更 |
| 18 | `Test-Path` | — | パスの存否テスト |

```powershell
# ファイル操作の一連の流れ
New-Item -Path ./demo -ItemType Directory          # フォルダ作成
New-Item -Path ./demo/test.txt -ItemType File      # ファイル作成
Set-Content -Path ./demo/test.txt -Value "Hello"   # 内容を書き込み
Get-Content ./demo/test.txt                        # 内容を読み込み
Copy-Item ./demo/test.txt ./demo/test2.txt         # コピー
Test-Path ./demo/test2.txt                         # 存在確認 → True
Remove-Item ./demo -Recurse -Force                 # フォルダごと削除
```

## 📂 ナビゲーション（5個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 19 | `Set-Location` | `cd`, `sl` | ディレクトリを移動 |
| 20 | `Get-Location` | `pwd` | 現在のディレクトリを取得 |
| 21 | `Push-Location` | `pushd` | 現在地を保存して移動 |
| 22 | `Pop-Location` | `popd` | 保存した位置に戻る |
| 23 | `Resolve-Path` | — | パスをフルパスに解決 |

## 🔄 パイプライン操作（10個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 24 | `Where-Object` | `?`, `where` | 条件でフィルタリング |
| 25 | `ForEach-Object` | `%`, `foreach` | 各要素に処理を実行 |
| 26 | `Select-Object` | `select` | プロパティの選択・件数制限 |
| 27 | `Sort-Object` | `sort` | 並べ替え |
| 28 | `Group-Object` | `group` | グループ化 |
| 29 | `Measure-Object` | `measure` | 集計（件数・合計・平均） |
| 30 | `Compare-Object` | `compare`, `diff` | 2つのオブジェクトの比較 |
| 31 | `Tee-Object` | `tee` | 出力を分岐（変数/ファイルに保存しつつパイプ継続） |
| 32 | `Select-String` | `sls` | テキストでの文字列検索（grepに相当） |
| 33 | `Out-Null` | — | 出力を破棄 |

```powershell
# パイプライン操作の組み合わせ
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object CPU -Descending |
    Select-Object Name, CPU, WorkingSet64 -First 10 |
    Format-Table -AutoSize
```

## 📊 フォーマット・出力（6個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 34 | `Format-Table` | `ft` | 表形式で表示 |
| 35 | `Format-List` | `fl` | リスト形式で表示 |
| 36 | `Format-Wide` | `fw` | 幅広形式で表示 |
| 37 | `Out-File` | — | ファイルに出力 |
| 38 | `Export-Csv` | `epcsv` | CSV形式でエクスポート |
| 39 | `ConvertTo-Json` | — | JSON形式に変換 |

```powershell
# 出力フォーマットの比較
Get-Service | Format-Table Name, Status -AutoSize
Get-Service | Format-List Name, Status, DisplayName
Get-Process | Select-Object Name, CPU | Export-Csv ./procs.csv -NoTypeInformation
Get-Process | Select-Object Name, CPU | ConvertTo-Json
```

## ⚙️ プロセス・サービス管理（5個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 40 | `Get-Process` | `ps`, `gps` | プロセス一覧 |
| 41 | `Stop-Process` | `kill` | プロセスを停止 |
| 42 | `Get-Service` | `gsv` | サービス一覧 |
| 43 | `Start-Service` | `sasv` | サービスを開始 |
| 44 | `Stop-Service` | `spsv` | サービスを停止 |

## 🌐 ネットワーク・Web（3個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 45 | `Invoke-WebRequest` | `iwr` | HTTPリクエストの送信 |
| 46 | `Invoke-RestMethod` | `irm` | REST APIの呼び出し |
| 47 | `Test-Connection` | — | Ping相当のネットワークテスト |

```powershell
# Webリクエスト
Invoke-WebRequest -Uri "https://httpbin.org/get" | Select-Object StatusCode

# REST API呼び出し（JSONを自動パース）
$data = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell"
$data.stargazers_count

# ネットワークテスト
Test-Connection -TargetName "google.com" -Count 3
```

## 🛠️ ユーティリティ（3個）

| # | コマンドレット | エイリアス | 説明 |
|:---:|---|---|---|
| 48 | `Write-Output` | `echo`, `write` | 出力をパイプラインに送る |
| 49 | `Write-Host` | — | コンソールに直接表示 |
| 50 | `Read-Host` | — | ユーザー入力の受付 |

```powershell
# Write-Output vs Write-Host
Write-Output "パイプラインに流れる" | Measure-Object  # Count: 1
Write-Host "画面表示のみ" | Measure-Object             # Count: 0（パイプに流れない）

# ユーザー入力
$name = Read-Host "名前を入力してください"
$pass = Read-Host "パスワード" -AsSecureString  # 入力がマスクされる
```

## コマンドレット暗記チェックリスト

以下のタスクをコマンドレット名なしで実行できるようになれば、基本はマスターです：

- [ ] ファイル一覧を表示する
- [ ] ファイルの内容を読む
- [ ] ファイルを作成する
- [ ] ファイルをコピー/移動/削除する
- [ ] プロセス一覧を表示する
- [ ] 条件で絞り込む
- [ ] 並べ替える
- [ ] 件数を数える
- [ ] コマンドのヘルプを見る
- [ ] オブジェクトのプロパティを調べる

## ハンズオン課題

```powershell
# 1. ホームディレクトリの全ファイルの総容量を計算
Get-ChildItem ~ -File -Recurse -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum

# 2. 実行中のプロセスをCPU使用量でソートし上位5つを表示
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU

# 3. 現在のIPアドレスをREST APIで取得
Invoke-RestMethod -Uri "https://api.ipify.org?format=json"

# 4. カレントディレクトリのファイルを拡張子別に集計
Get-ChildItem -File | Group-Object Extension | Sort-Object Count -Descending

# 5. サービス一覧をCSVファイルにエクスポート
Get-Service | Select-Object Name, Status, DisplayName |
    Export-Csv -Path ./services.csv -NoTypeInformation
Get-Content ./services.csv | Select-Object -First 5
```
