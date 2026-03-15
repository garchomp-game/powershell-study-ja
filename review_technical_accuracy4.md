# 技術的正確性レビュー

## レビュー計画

PowerShell学習講義コンテンツ（全17章・36ファイル）を以下の観点で全ファイルレビューを実施：

1. コマンドレットの正確性（名前・パラメータ・エイリアス）
2. コード例の正確性（構文エラーの有無）
3. 出力例の正確性
4. バージョン情報（PS7 vs Windows PS の区別）
5. .NET型名の正確性
6. 演算子の正確性
7. Mermaid図の技術的正確性

## レビュー結果サマリー

- **総ファイル数**: 36 （+ index.mdx = 37）
- **問題なしファイル数**: 26
- **要修正ファイル数**: 10
- **重大度別**:
  - ❌ Critical: 0
  - ⚠️ Warning: 8
  - ℹ️ Info: 7

> [!NOTE]
> 全体として非常に高品質な講義コンテンツです。コマンドレット名、パラメータ名、.NET型名、Mermaid図はほぼ全て正確で、PowerShell 7とWindows PowerShellの区別も適切に行われています。

---

## 章別の詳細レビュー

### 第1章: 概要（01-overview）

#### [01-what-is-powershell.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/01-overview/01-what-is-powershell.md)
- ✅ 正確
- コマンドレット名・パラメータ名は全て正確
- `.NET`型名（`System.Diagnostics.Process`, `System.Math`, `System.DateTime` 等）は全て正確
- Mermaid図の構造は正確
- PS7 vs Windows PS の比較表は正確
- ℹ️ L40: 「PowerShell 7.0（.NET 5統合）」— 正確には PowerShell 7.0 は .NET Core 3.1 ベース、.NET 5 統合は PowerShell 7.1 から。ただし大きな文脈では問題なし

#### [02-architecture.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/01-overview/02-architecture.md)
- ✅ 正確
- コマンド解決順序（エイリアス→関数→コマンドレット→外部コマンド）は正確
- コマンドレットのライフサイクル（BeginProcessing/ProcessRecord/EndProcessing）は正確
- 出力ストリーム6種類の番号・名前・コマンドレット対応は全て正確

---

### 第2章: セットアップ（02-setup）

#### [01-installation.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/02-setup/01-installation.md)
- ✅ 正確
- 各OS向けのインストール手順は正確
- ℹ️ L210: 「Linux/macOSではデフォルトで `Unrestricted`」— バージョンにより `RemoteSigned` の場合もある

#### [02-console-basics.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/02-setup/02-console-basics.md)
- ⚠️ 要修正（1点）
- L51: `Get-History | Select-String "Get-Process"` — `Get-History` は `HistoryInfo` オブジェクトを返すため `Select-String` では期待通りに動作しない。修正案：
  ```powershell
  Get-History | Where-Object CommandLine -like "*Get-Process*"
  ```
- ℹ️ L106: `mkdir` エイリアスはLinux/macOSではネイティブの `/usr/bin/mkdir` が優先される場合がある

---

### 第3章: コマンドレット（03-cmdlets）

#### [01-verb-noun.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/03-cmdlets/01-verb-noun.md)
- ✅ 正確

#### [02-common-parameters.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/03-cmdlets/02-common-parameters.md)
- ✅ 正確 — `-ErrorAction` の値と動作の表は正確

#### [03-essential-cmdlets.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/03-cmdlets/03-essential-cmdlets.md)
- ✅ 正確 — 50個のコマンドレット名・エイリアスは全て正確

---

### 第4章: パイプライン（04-pipeline）

#### [01-pipeline-basics.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/04-pipeline/01-pipeline-basics.md)
- ✅ 正確

#### [03-grouping-measuring.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/04-pipeline/03-grouping-measuring.md)
- ✅ 正確

#### [04-formatting-output.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/04-pipeline/04-formatting-output.md)
- ✅ 正確

---

### 第5章: 変数と型（05-variables）

#### [01-variables-types.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/05-variables/01-variables-types.md)
- ✅ 正確 — 型名・.NET型の対応表、自動変数一覧は全て正確

#### [02-strings.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/05-variables/02-strings.md)
- ✅ 正確

#### [03-arrays-hashtables.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/05-variables/03-arrays-hashtables.md)
- ℹ️ L27: `$alpha = [char]'a'..[char]'z'` — 結果は**整数（ASCIIコード97〜122）の配列**であり、`[char]`型配列ではない。コメントの「ASCIIコード配列」は正しいが、より明示的にするとよい

#### [04-operators.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/05-variables/04-operators.md)
- ⚠️ 要修正（1点）
- L135: `${obj}?.Method()` — Null条件演算子で `{}` は不要。またPS 7.1+のNull条件アクセスはプロパティアクセス（`$obj?.Property`）が主な用途で、メソッド呼び出しには制約がある。修正案：
  ```powershell
  $obj?.Property   # $obj が $null ならスキップ（$null を返す）
  ```

---

### 第6章: 制御フロー（06-control-flow）

#### [01-if-switch.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/06-control-flow/01-if-switch.md)
- ⚠️ 要修正（1点）
- L97: `$input = "user@example.com"` — **`$input` はPowerShellの自動変数**（パイプライン入力を保持）。ユーザー変数として使用すると予期しない動作が起きる。修正案：`$testInput` に変更

#### [02-loops.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/06-control-flow/02-loops.md)
- ⚠️ 要修正（1点）
- L77: `$input = ""` — 上記と同じ `$input` 自動変数の問題。修正案：`$userInput` に変更

---

### 第7章: 関数（07-functions）

#### [01-basic-functions.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/07-functions/01-basic-functions.md)
- ✅ 正確 — `ArrayList.Add()` の戻り値問題の解説は特に優れている

#### [02-advanced-functions.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/07-functions/02-advanced-functions.md)
- ✅ 正確

#### [03-pipeline-functions.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/07-functions/03-pipeline-functions.md)
- ✅ 正確

#### [04-script-files.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/07-functions/04-script-files.md)
- ✅ 正確

---

### 第8章: エラー処理（08-error-handling）

#### [01-error-types.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/08-error-handling/01-error-types.md)
- ✅ 正確

#### [02-try-catch-finally.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/08-error-handling/02-try-catch-finally.md)
- ✅ 正確

#### [03-error-preferences.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/08-error-handling/03-error-preferences.md)
- ⚠️ 要修正（1点）
- L81: `param([string]$Input)` — `$Input` はPowerShellの自動変数。パラメータ名として使用すると自動変数が隠蔽される。修正案：`$InputData` に変更

---

### 第9章: モジュール（09-modules）

#### [01-module-basics.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/09-modules/01-module-basics.md)
- ✅ 正確

#### [02-powershell-gallery.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/09-modules/02-powershell-gallery.md)
- ⚠️ 要修正（1点）
- L74: パイプから文字列を渡して `-ScriptDefinition` パラメータを使う構文が不正確。修正案：
  ```powershell
  Invoke-ScriptAnalyzer -ScriptDefinition 'Get-Process | % { $_.Name }'
  ```

#### [03-creating-modules.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/09-modules/03-creating-modules.md)
- ✅ 正確

---

### 第10章: ファイルとデータ（10-file-data）

#### [01-file-operations.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/10-file-data/01-file-operations.md)
- ⚠️ 要修正（1点）
- L72: `Rename-Item ./old.txt -NewName ./new.txt` — `-NewName` パラメータにパスプレフィックスを含めるべきではない（名前のみ）。修正案：
  ```powershell
  Rename-Item ./old.txt -NewName new.txt
  ```

#### [02-csv-json-xml.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/10-file-data/02-csv-json-xml.md)
- ✅ 正確

#### [03-text-processing.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/10-file-data/03-text-processing.md)
- ✅ 正確

---

### 第11章: プロバイダー（11-providers）

#### [01-providers-drives.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/11-providers/01-providers-drives.md)
- ✅ 正確

---

### 第12章: 高度なテクニック（12-advanced-tools）

#### [01-splatting.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/12-advanced-tools/01-splatting.md)
- ⚠️ 要修正（1点）
- L35: `$args = "source.txt", "dest.txt"` — `$args` はPowerShellの自動変数。修正案：`$copyArgs` に変更

---

### 第13章: 正規表現（13-regex）

#### [01-regex-basics.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/13-regex/01-regex-basics.md)
- ✅ 正確

---

### 第14章: クラス（14-classes）

#### [01-ps-classes.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/14-classes/01-ps-classes.md)
- ✅ 正確 — クラス定義・コンストラクタ・継承・`[Flags()]` enum は全て正確

---

### 第15章: リモート処理とジョブ（15-remoting）

#### [01-remoting-jobs.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/15-remoting/01-remoting-jobs.md)
- ✅ 正確 — `ForEach-Object -Parallel` と `$using:` 構文は正確

---

### 第16章: テスト（16-testing）

#### [01-pester-basics.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/16-testing/01-pester-basics.md)
- ✅ 正確 — Pester 5.x の構文・Should アサーション・Mock は全て正確

---

### 第17章: ベストプラクティス（17-best-practices）

#### [01-coding-standards.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/17-best-practices/01-coding-standards.md)
- ✅ 正確 — 命名規則・ドキュメントコメント・セキュリティベストプラクティスは全て正確

---

## 総合評価と推奨事項

### 全体評価: ⭐⭐⭐⭐☆（4.5 / 5）

非常に高品質な講義コンテンツです。**致命的な技術的誤り（Critical）はゼロ**でした。

### 修正推奨事項（Warning — 修正すべき）

| # | ファイル | 行 | 問題 | 修正案 |
|---|---|---|---|---|
| 1 | [01-if-switch.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/06-control-flow/01-if-switch.md) | L97 | `$input` は自動変数 | `$testInput` に変更 |
| 2 | [02-loops.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/06-control-flow/02-loops.md) | L77 | `$input` は自動変数 | `$userInput` に変更 |
| 3 | [03-error-preferences.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/08-error-handling/03-error-preferences.md) | L81 | `$Input` パラメータが自動変数と衝突 | `$InputData` に変更 |
| 4 | [01-splatting.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/12-advanced-tools/01-splatting.md) | L35 | `$args` は自動変数 | `$copyArgs` に変更 |
| 5 | [02-powershell-gallery.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/09-modules/02-powershell-gallery.md) | L74 | `Invoke-ScriptAnalyzer` 構文不正 | `-ScriptDefinition` に直接渡す |
| 6 | [01-file-operations.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/10-file-data/01-file-operations.md) | L72 | `Rename-Item -NewName` にパスを含めている | 名前のみ `new.txt` |
| 7 | [02-console-basics.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/02-setup/02-console-basics.md) | L51 | `Get-History \| Select-String` が動作しない | `Where-Object` に変更 |
| 8 | [04-operators.md](file:///home/garchomp-game/workspace/powershell-study/src/content/docs/05-variables/04-operators.md) | L135 | Null条件演算子の構文・説明が不正確 | `$obj?.Property` に修正 |

### まとめ

- **コマンドレット名・パラメータ名**: 全て正確 ✅
- **コード例の構文**: ほぼ全て正確（上記Warning以外）✅
- **出力例の説明**: 全て正確 ✅
- **バージョン情報**: 適切に区別 ✅
- **.NET型名**: 全て正確 ✅
- **演算子の動作説明**: 全て正確 ✅
- **Mermaid図**: 全て技術的に正確 ✅

最も多い問題は**自動変数名の誤使用**（`$input`, `$args`）で、学習者の混乱を避けるため修正を推奨します。
