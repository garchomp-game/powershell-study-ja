# PowerShell 体系的学習ガイド

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

PowerShellを基礎から上級まで体系的に学ぶための全17章・39ページの講義コンテンツです。  
Astro Starlight 上に構築されたドキュメントサイトで、全文検索・ダークモード・Mermaid図解に対応しています。

## 📚 カリキュラム

### 第1部: 基礎（第1〜6章）

| 章 | テーマ | 内容 |
|:---:|---|---|
| 1 | PowerShellの世界 | 定義・歴史（Monad）・Win PS vs PS7・アーキテクチャ |
| 2 | 環境構築 | インストール（Win/Mac/Linux）・VS Code・PSReadLine |
| 3 | コマンドレット | Verb-Noun・`Get-Command`/`Help`/`Member`・必須50選 |
| 4 | パイプライン | オブジェクトパイプライン・Where/Sort/Select/ForEach・Group/Measure・Format |
| 5 | 変数・データ型 | 型システム・文字列・配列/ハッシュテーブル・演算子 |
| 6 | 制御構文 | if/switch（Wildcard/Regex）・ループ（for/foreach/while） |

### 第2部: 中級（第7〜11章）

| 章 | テーマ | 内容 |
|:---:|---|---|
| 7 | 関数 | 基本関数・CmdletBinding・Begin/Process/End・スクリプトファイル |
| 8 | エラー処理 | 終了/非終了エラー・try/catch/finally・ErrorAction |
| 9 | モジュール | モジュール基礎・PowerShell Gallery・独自モジュール作成 |
| 10 | ファイル/データ | ファイル操作・CSV/JSON/XML・テキスト処理 |
| 11 | プロバイダー | FileSystem/Env/Variable/Registry・カスタムPSDrive |

### 第3部: 上級（第12〜17章）

| 章 | テーマ | 内容 |
|:---:|---|---|
| 12 | 高度なツール | スプラッティング・ShouldProcess・出力ストリーム |
| 13 | 正規表現 | -match/-replace/-split・名前付きキャプチャ・[regex] |
| 14 | クラス | クラス定義・コンストラクタ・継承・Enum |
| 15 | リモート管理 | Invoke-Command・PSSession・ジョブ・ForEach-Object -Parallel |
| 16 | テスト | Pester（Describe/It/Should/Mock）・PSScriptAnalyzer |
| 17 | ベストプラクティス | コーディング規約・セキュリティ・エコシステム |

## 🛠 技術スタック

- **[Astro](https://astro.build/)** + **[Starlight](https://starlight.astro.build/)** — ドキュメントサイトフレームワーク
- **[Bun](https://bun.sh/)** — パッケージマネージャ・ランタイム
- **[Mermaid](https://mermaid.js.org/)** — 図解の自動レンダリング
- **[Pagefind](https://pagefind.app/)** — 全文検索

## 🚀 開発

```bash
# 依存関係のインストール
bun install

# 開発サーバー起動（http://localhost:4321）
bun run dev

# プロダクションビルド
bun run build

# ビルド結果のプレビュー
bun run preview
```

## 📁 ディレクトリ構成

```
src/content/docs/
├── 01-overview/          # 第1章: PowerShellの世界
├── 02-setup/             # 第2章: 環境構築
├── 03-cmdlets/           # 第3章: コマンドレット
├── 04-pipeline/          # 第4章: パイプライン
├── 05-variables/         # 第5章: 変数・データ型
├── 06-control-flow/      # 第6章: 制御構文
├── 07-functions/         # 第7章: 関数
├── 08-error-handling/    # 第8章: エラー処理
├── 09-modules/           # 第9章: モジュール
├── 10-file-data/         # 第10章: ファイル/データ
├── 11-providers/         # 第11章: プロバイダー
├── 12-advanced-tools/    # 第12章: 高度なツール
├── 13-regex/             # 第13章: 正規表現
├── 14-classes/           # 第14章: クラス
├── 15-remoting/          # 第15章: リモート管理
├── 16-testing/           # 第16章: テスト
├── 17-best-practices/    # 第17章: ベストプラクティス
└── index.mdx             # ランディングページ
```

## 📖 各章の構成

- **概念説明** — 「なぜ」「何のために」を先に理解
- **Mermaid図解** — アーキテクチャ・フローの視覚化
- **豊富なコード例** — 日本語コメント付き実例
- **比較表** — 類似概念の違いを整理
- **ハンズオン課題** — ターミナルで実行可能な段階的課題
