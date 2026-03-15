---
title: Pester入門
description: PowerShellの標準テストフレームワーク Pester の基礎
sidebar:
  order: 1
---

## Pester とは

[Pester](https://github.com/pester/Pester) は、PowerShellの**BDDスタイルのテストフレームワーク**です。awesome-powershellでも最も人気のあるテストツールです。

```powershell
# インストール
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck

# バージョン確認
Get-Module Pester -ListAvailable | Select-Object Version
```

## テストの基本構文

```powershell
# MyMath.Tests.ps1
Describe "Add-Numbers 関数のテスト" {
    
    BeforeAll {
        # テスト対象の関数を定義（実際はドットソーシングでインポート）
        function Add-Numbers($a, $b) { $a + $b }
    }

    Context "正常な入力" {
        It "2 + 3 は 5 を返す" {
            Add-Numbers 2 3 | Should -Be 5
        }

        It "負の数にも対応する" {
            Add-Numbers -5 3 | Should -Be -2
        }

        It "0 を加算しても結果は変わらない" {
            Add-Numbers 42 0 | Should -Be 42
        }
    }

    Context "小数の計算" {
        It "小数の加算ができる" {
            Add-Numbers 1.5 2.5 | Should -Be 4.0
        }
    }
}
```

```powershell
# テストの実行
Invoke-Pester ./MyMath.Tests.ps1

# 詳細出力
Invoke-Pester ./MyMath.Tests.ps1 -Output Detailed
```

## Should アサーション

```powershell
# 等値
42 | Should -Be 42
"Hello" | Should -BeExactly "Hello"  # 大文字小文字区別

# 比較
10 | Should -BeGreaterThan 5
10 | Should -BeLessThan 20
10 | Should -BeGreaterOrEqual 10

# Null / Bool
$null | Should -BeNullOrEmpty
$true | Should -BeTrue
$false | Should -BeFalse

# 型
42 | Should -BeOfType [int]
"text" | Should -BeOfType [string]

# コレクション
@(1,2,3) | Should -Contain 2
@(1,2,3) | Should -HaveCount 3

# 文字列パターン
"PowerShell" | Should -BeLike "Power*"
"abc123" | Should -Match "\d+"

# 例外のテスト
{ throw "エラー" } | Should -Throw
{ throw "エラー" } | Should -Throw -ExpectedMessage "エラー"
{ 1 / 0 } | Should -Throw

# 否定
0 | Should -Not -Be 1
```

## Mock（モック）

外部依存をモック化してテストを分離します。

```powershell
Describe "バックアップ関数のテスト" {
    BeforeAll {
        function Backup-File {
            param([string]$Path)
            if (Test-Path $Path) {
                Copy-Item $Path "$Path.bak"
                return $true
            }
            return $false
        }
    }
    
    It "ファイルが存在する場合にコピーする" {
        Mock Test-Path { return $true }
        Mock Copy-Item {}

        Backup-File -Path "test.txt" | Should -BeTrue
        Should -Invoke Copy-Item -Times 1 -Exactly
    }

    It "ファイルが存在しない場合はコピーしない" {
        Mock Test-Path { return $false }
        Mock Copy-Item {}

        Backup-File -Path "missing.txt" | Should -BeFalse
        Should -Invoke Copy-Item -Times 0
    }
}
```

## PSScriptAnalyzer

```powershell
# インストール
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force

# スクリプトの静的解析
Invoke-ScriptAnalyzer -Path ./MyScript.ps1

# 文字列を直接解析
Invoke-ScriptAnalyzer -ScriptDefinition 'Write-Host "直接出力"'

# 特定ルールのみ
Invoke-ScriptAnalyzer -Path ./MyScript.ps1 -IncludeRule PSAvoidUsingWriteHost
```

## その他のセットアップブロック

```powershell
Describe "テスト" {
    BeforeAll  { }   # 全テスト実行前に1回
    BeforeEach { }   # 各 It ブロックの前に毎回
    AfterEach  { }   # 各 It ブロックの後に毎回
    AfterAll   { }   # 全テスト実行後に1回
}
```

## まとめ

| ポイント | 内容 |
|---|---|
| `Describe` / `Context` / `It` | テスト構造の定義（BDDスタイル） |
| `Should -Be` | アサーション（等値・比較・型・例外等） |
| `Mock` | 外部依存のモック化 |
| `Should -Invoke` | Mockが呼ばれた回数の検証 |
| `PSScriptAnalyzer` | 静的コード解析でベストプラクティスを確認 |

## ハンズオン課題

```powershell
# テストファイルを作成して実行
$testScript = @'
Describe "文字列操作テスト" {
    It "ToUpper が正しく動作する" {
        "hello".ToUpper() | Should -Be "HELLO"
    }
    It "Contains が True を返す" {
        "PowerShell".Contains("Shell") | Should -BeTrue
    }
    It "空文字列の判定" {
        [string]::IsNullOrEmpty("") | Should -BeTrue
        [string]::IsNullOrEmpty("text") | Should -BeFalse
    }
    It "Split が正しく分割する" {
        "a,b,c" -split "," | Should -HaveCount 3
    }
}
'@
$testScript | Out-File /tmp/String.Tests.ps1
Invoke-Pester /tmp/String.Tests.ps1 -Output Detailed
```
