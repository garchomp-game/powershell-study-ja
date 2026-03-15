---
title: ループ
description: for、foreach、while、do-while/do-untilループの使い方
sidebar:
  order: 2
---

## for ループ

C言語スタイルのカウンタループです。

```powershell
# 基本構文
for ($i = 0; $i -lt 5; $i++) {
    "カウント: $i"
}

# 逆順
for ($i = 10; $i -ge 0; $i--) {
    "カウントダウン: $i"
}

# ステップ指定
for ($i = 0; $i -le 100; $i += 10) {
    "進捗: $i%"
}
```

## foreach 文

コレクションの各要素に対して反復処理する、最もよく使うループです。

```powershell
# 基本構文
$fruits = "apple", "banana", "cherry"
foreach ($fruit in $fruits) {
    "フルーツ: $fruit"
}

# ファイル一覧を処理
foreach ($file in Get-ChildItem *.txt) {
    "ファイル: $($file.Name), サイズ: $($file.Length)"
}

# ハッシュテーブルの反復
$config = @{ Host = "localhost"; Port = 8080 }
foreach ($key in $config.Keys) {
    "$key = $($config[$key])"
}
```

## while ループ

条件が `$true` の間繰り返します。

```powershell
# 基本構文
$count = 0
while ($count -lt 5) {
    "カウント: $count"
    $count++
}

# ファイルが作られるまで待機
while (-not (Test-Path ./ready.txt)) {
    Write-Host "待機中..." -NoNewline
    Start-Sleep -Seconds 1
}
```

## do-while / do-until

最低1回は実行されるループです。

```powershell
# do-while（条件がTrueの間続ける）
$answer = ""
do {
    $answer = Read-Host "yesと入力してください"
} while ($answer -ne "yes")

# do-until（条件がTrueになるまで続ける）
$dice = 0
do {
    $dice = Get-Random -Minimum 1 -Maximum 7
    "サイコロ: $dice"
} until ($dice -eq 6)
"6が出ました！"
```

## break / continue

```powershell
# break — ループを中断
foreach ($i in 1..100) {
    if ($i -gt 5) { break }
    "処理: $i"
}
# 出力: 1〜5まで

# continue — 現在の反復をスキップして次へ
foreach ($i in 1..10) {
    if ($i % 2 -eq 0) { continue }  # 偶数をスキップ
    "奇数: $i"
}
# 出力: 1, 3, 5, 7, 9
```

## ループのラベル

ネストしたループで外側のループを制御できます。

```powershell
:outer foreach ($x in 1..5) {
    foreach ($y in 1..5) {
        if ($x * $y -gt 10) {
            break outer   # 外側のループごと抜ける
        }
        "$x × $y = $($x * $y)"
    }
}
```

## foreach 文 vs ForEach-Object の比較

| 特徴 | `foreach` 文 | `ForEach-Object` (`%`) |
|---|---|---|
| 構文 | `foreach ($x in $col) { }` | `$col \| ForEach-Object { }` |
| メモリ | 全データをメモリに保持 | ストリーミング処理 |
| 速度 | **高速**（2〜3倍速い） | やや遅い |
| パイプライン | 使えない | 使える |
| Begin/Process/End | なし | あり |
| 用途 | 変数に格納されたデータ | パイプラインでの処理 |

```powershell
# パフォーマンス比較
$data = 1..100000

# foreach 文（高速）
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$sum = 0
foreach ($n in $data) { $sum += $n }
$sw.Stop()
"foreach文: $($sw.ElapsedMilliseconds)ms"

# ForEach-Object（パイプライン経由、遅いがストリーミング可能）
$sw.Restart()
$sum = 0
$data | ForEach-Object { $sum += $_ }
$sw.Stop()
"ForEach-Object: $($sw.ElapsedMilliseconds)ms"
```

## ハンズオン課題

```powershell
# 1. 九九の表を作成
for ($i = 1; $i -le 9; $i++) {
    $line = ""
    for ($j = 1; $j -le 9; $j++) {
        $line += "{0,4}" -f ($i * $j)
    }
    $line
}

# 2. ランダムパスワード生成器
$chars = [char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%'
$password = -join (1..16 | ForEach-Object { $chars | Get-Random })
"生成されたパスワード: $password"

# 3. foreach vs ForEach-Object の速度比較を体験
$data = 1..50000
Measure-Command { foreach ($n in $data) { $null = $n * 2 } } |
    Select-Object @{N='Method';E={'foreach文'}}, TotalMilliseconds
Measure-Command { $data | ForEach-Object { $null = $_ * 2 } } |
    Select-Object @{N='Method';E={'ForEach-Object'}}, TotalMilliseconds
```

