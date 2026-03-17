# 🚀 PowerShell DevOps Monitor Toolkit

PowerShellの機能をフル活用した、システム監視 + DevOps ツールキット。

## 機能

| 機能 | 使用するPS機能 |
|---|---|
| システムメトリクス収集 | class / enum / Get-Process / Get-PSDrive |
| REST API統合 | Invoke-RestMethod / ConvertFrom-Json |
| リアルタイム監視 | Jobs / ForEach-Object -Parallel |
| HTMLダッシュボード生成 | ヒアストリング / ConvertTo-Html |
| タスクスケジューラ | ScriptBlock / タイマー |
| ログシステム | プロバイダー / ストリーム / Out-File |
| 設定管理 | JSON / PSD1 / スプラッティング |
| コードベース分析 | Select-String / Regex / Measure-Object |
| Pesterテスト | Describe / It / Should / Mock |

## 使い方

```powershell
# メインスクリプトの実行
./Start-DevOpsMonitor.ps1

# 個別のツール
./tools/Invoke-SystemHealthCheck.ps1
./tools/Get-ProjectStats.ps1 -Path ~/workspace/my-project
./tools/Watch-SystemMetrics.ps1 -IntervalSeconds 3 -Duration 30
./tools/Invoke-ApiDashboard.ps1
```

## ディレクトリ構成

```
tmp/
├── Start-DevOpsMonitor.ps1      # メインエントリーポイント
├── config/
│   └── settings.json            # 設定ファイル
├── modules/
│   ├── DevOpsCore/              # コアモジュール
│   │   ├── DevOpsCore.psm1
│   │   └── DevOpsCore.psd1
│   └── HtmlReporter/            # HTML生成モジュール
│       └── HtmlReporter.psm1
├── tools/
│   ├── Invoke-SystemHealthCheck.ps1
│   ├── Get-ProjectStats.ps1
│   ├── Watch-SystemMetrics.ps1
│   └── Invoke-ApiDashboard.ps1
├── tests/
│   └── DevOpsCore.Tests.ps1
└── README.md
```
