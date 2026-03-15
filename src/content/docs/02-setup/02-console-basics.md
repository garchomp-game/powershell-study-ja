---
title: コンソール操作の基本
description: PowerShellコンソールの効率的な使い方を身につける
sidebar:
  order: 2
---

## PSReadLine — コンソール体験の要

**PSReadLine** はPowerShellのコマンドライン編集を強化するモジュールで、PowerShell 7にはデフォルトで組み込まれています。

### 基本的なキーバインド

| キー | 動作 |
|---|---|
| `Tab` | コマンド・パラメータの補完 |
| `Ctrl+Space` | 補完候補一覧の表示 |
| `↑` / `↓` | コマンド履歴の前後移動 |
| `Ctrl+R` | 逆方向の履歴検索（インクリメンタル） |
| `Ctrl+A` | 行頭に移動 |
| `Ctrl+E` | 行末に移動 |
| `Ctrl+W` | 直前の単語を削除 |
| `Ctrl+U` | カーソル位置から行頭まで削除 |
| `Ctrl+K` | カーソル位置から行末まで削除 |
| `Ctrl+L` | 画面クリア |
| `F2` | コマンド予測の表示切替 |

### コマンド予測（Predictive IntelliSense）

PowerShell 7.2以降では、入力中に過去の履歴やプラグインに基づく**コマンド予測**が表示されます。

```powershell
# 予測ソースの設定
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

# 予測の表示方法
Set-PSReadLineOption -PredictionViewStyle ListView  # リスト表示
Set-PSReadLineOption -PredictionViewStyle InlineView # インライン表示

# 色のカスタマイズ
Set-PSReadLineOption -Colors @{
    InlinePrediction = '#7d7d7d'
}
```

### 履歴管理

```powershell
# 履歴の検索
Get-History              # 現在セッションの履歴
Get-History | Where-Object CommandLine -like "*Get-Process*"  # 履歴をフィルタ

# 履歴ファイルのパスを確認
(Get-PSReadLineOption).HistorySavePath

# 履歴の保存件数を変更
Set-PSReadLineOption -MaximumHistoryCount 10000
```

## タブ補完

PowerShellのタブ補完は非常に強力で、以下を自動補完できます：

```powershell
# コマンドレット名の補完
Get-Pro<Tab>     # → Get-Process

# パラメータ名の補完
Get-Process -Na<Tab>  # → Get-Process -Name

# パラメータ値の補完
Get-Process -Name pw<Tab>  # → プロセス名の候補が表示

# パス補完
Get-ChildItem C:\Users\<Tab>  # → ユーザーフォルダの候補

# 変数補完
$PS<Tab>  # → $PSVersionTable, $PSHome, ...

# メンバー補完（ドットの後）
$Host.UI.<Tab>  # → UIオブジェクトのメンバー候補
```

### TabExpansion2

```powershell
# タブ補完の動作を確認
TabExpansion2 -inputScript 'Get-Pro' -cursorColumn 7
```

## エイリアス

エイリアスはコマンドの短縮名です。PowerShellには多くの組み込みエイリアスがあります。

### 主要な組み込みエイリアス

| エイリアス | 展開先 | 由来 |
|---|---|---|
| `ls`, `dir`, `gci` | `Get-ChildItem` | Unix/DOS/PS |
| `cd`, `sl` | `Set-Location` | Unix・DOS |
| `pwd` | `Get-Location` | Unix |
| `cat`, `gc`, `type` | `Get-Content` | Unix/PS/DOS |
| `cp`, `copy` | `Copy-Item` | Unix/DOS |
| `mv`, `move` | `Move-Item` | Unix/DOS |
| `rm`, `del` | `Remove-Item` | Unix/DOS |
| `mkdir`, `md` | `New-Item -ItemType Directory` | Unix/DOS |
| `echo`, `write` | `Write-Output` | Unix/DOS |
| `cls`, `clear` | `Clear-Host` | DOS/Unix |
| `?` | `Where-Object` | PS |
| `%` | `ForEach-Object` | PS |
| `select` | `Select-Object` | PS |
| `sort` | `Sort-Object` | PS |
| `measure` | `Measure-Object` | PS |
| `group` | `Group-Object` | PS |
| `fl` | `Format-List` | PS |
| `ft` | `Format-Table` | PS |
| `fw` | `Format-Wide` | PS |
| `iwr` | `Invoke-WebRequest` | PS |
| `irm` | `Invoke-RestMethod` | PS |
| `icm` | `Invoke-Command` | PS |

```powershell
# エイリアスの確認
Get-Alias           # 全エイリアス一覧
Get-Alias ls        # 特定のエイリアスの詳細
Get-Alias -Definition Get-ChildItem  # コマンドレットに対応するエイリアス

# カスタムエイリアスの作成
Set-Alias -Name g -Value git
Set-Alias -Name np -Value notepad

# エイリアスの削除
Remove-Alias -Name g
```

> **注意:** エイリアスはセッション間で保持されません。永続化するには `$PROFILE` に記述してください。

## 基本的なナビゲーション

```powershell
# 現在のディレクトリを確認
Get-Location  # または pwd

# ディレクトリの移動
Set-Location ~          # ホームディレクトリへ
Set-Location ..         # 親ディレクトリへ
Set-Location /tmp       # 絶対パスで移動

# ディレクトリスタック（Push/Pop）
Push-Location /tmp      # 現在地を記憶して移動
Pop-Location            # 記憶した位置に戻る

# 直前のディレクトリに戻る
Set-Location -          # PowerShell 7.4+
```

## 画面の見方と出力制御

### 色付きメッセージ

```powershell
# Write-Host で色付き出力
Write-Host "成功!" -ForegroundColor Green
Write-Host "警告!" -ForegroundColor Yellow -BackgroundColor Red
Write-Host "情報" -ForegroundColor Cyan -NoNewline
Write-Host " ← 改行なし" -ForegroundColor White
```

### 画面の制御

```powershell
# 画面クリア
Clear-Host  # または cls

# ページング出力（長い出力をページ単位で表示）
Get-Command | Out-Host -Paging

# 出力の抑制
$null = Get-Process    # $null に代入
Get-Process | Out-Null # Out-Null にパイプ
```

## 便利なショートカットと小技

```powershell
# 直前のコマンドの実行結果を参照
# $$ — 直前のコマンドの最後のトークン
# $^ — 直前のコマンドの最初のトークン

# 複数行入力
Get-Process |          # パイプの後の改行は継続行
    Where-Object {     # 中括弧内は自動的に継続
        $_.CPU -gt 10
    }

# バッククォートで明示的な継続行
Get-Process `
    -Name "pwsh"

# コマンドチェーン（PowerShell 7+）
Get-Process pwsh && Write-Host "見つかりました"  # 成功時のみ実行
Get-Process nonexistent || Write-Host "見つかりませんでした"  # 失敗時のみ実行

# 三項演算子（PowerShell 7+）
$isLinux = $IsLinux ? "Linux" : "Not Linux"
```

## まとめ

| ポイント | 内容 |
|---|---|
| PSReadLine | コマンド補完・予測・履歴管理を提供 |
| タブ補完 | コマンド名・パラメータ・パス・変数を補完 |
| エイリアス | Unix/DOSライクな短縮名が豊富に用意 |
| ナビゲーション | `Push-Location`/`Pop-Location` でスタック管理 |
| PS7+の新機能 | `&&`/`||` チェーン、三項演算子 |

## ハンズオン課題

```powershell
# 1. PSReadLineの設定を確認
Get-PSReadLineOption | Select-Object EditMode, PredictionSource, HistorySavePath

# 2. エイリアスの探索
Get-Alias | Measure-Object  # エイリアスの総数
Get-Alias | Where-Object { $_.Definition -like "Get-*" }  # Get系のエイリアス

# 3. ディレクトリスタックを試す
Push-Location /tmp
Get-Location
Push-Location ~
Get-Location
Pop-Location         # /tmp に戻る
Pop-Location         # 元の場所に戻る

# 4. コマンド予測を設定（プロファイルにも追加推奨）
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
```
