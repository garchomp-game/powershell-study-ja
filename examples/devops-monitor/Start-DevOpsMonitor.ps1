<#
.SYNOPSIS
    DevOps Monitor Toolkit — メインエントリーポイント
.DESCRIPTION
    対話メニューから各ツールを起動するランチャー
    
    使用機能: switch / do-while / Read-Host / Write-Host / 
             スクリプト呼び出し / エラー処理
.EXAMPLE
    ./Start-DevOpsMonitor.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot

# 設定ロード
$configPath = Join-Path $scriptRoot "config/settings.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

function Show-Banner {
    $banner = @"

    ██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗ ███████╗
    ██╔══██╗██╔════╝██║   ██║██╔═══██╗██╔══██╗██╔════╝
    ██║  ██║█████╗  ██║   ██║██║   ██║██████╔╝███████╗
    ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔═══╝ ╚════██║
    ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║     ███████║
    ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝     ╚══════╝
                  Monitor Toolkit v$($config.Version)

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Show-Menu {
    Write-Host "┌──────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "│  📋 メニュー                              │" -ForegroundColor DarkGray
    Write-Host "├──────────────────────────────────────────┤" -ForegroundColor DarkGray
    Write-Host "│  [1] 🏥 システムヘルスチェック           │" -ForegroundColor White
    Write-Host "│  [2] 📊 プロジェクト統計分析             │" -ForegroundColor White
    Write-Host "│  [3] 📡 リアルタイム監視                 │" -ForegroundColor White
    Write-Host "│  [4] 🌐 API統合ダッシュボード            │" -ForegroundColor White
    Write-Host "│  [5] ℹ️  システム情報表示                 │" -ForegroundColor White
    Write-Host "│  [Q] 🚪 終了                             │" -ForegroundColor White
    Write-Host "└──────────────────────────────────────────┘" -ForegroundColor DarkGray
}

function Show-SystemInfo {
    Write-Host "`n📋 システム情報" -ForegroundColor Cyan
    Write-Host ("─" * 50) -ForegroundColor DarkGray

    $info = [ordered]@{
        "ホスト名"     = hostname
        "OS"           = $PSVersionTable.OS
        "カーネル"     = (uname -r)
        "PowerShell"   = $PSVersionTable.PSVersion.ToString()
        "エディション" = $PSVersionTable.PSEdition
        ".NETランタイム" = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
        "プロセスID"   = $PID
        "作業ディレクトリ" = $PWD.Path
        "ユーザー"     = $env:USER
        "ホームDir"    = $HOME
        "シェル"       = $env:SHELL
        "ロケール"     = (Get-Culture).DisplayName
    }

    $info.GetEnumerator() | ForEach-Object {
        Write-Host ("  {0,-18} : {1}" -f $_.Key, $_.Value) -ForegroundColor Gray
    }

    # PSドライブ一覧
    Write-Host "`n📂 PSドライブ:" -ForegroundColor Yellow
    Get-PSDrive | Where-Object { $_.Provider.Name -eq 'FileSystem' } |
        Format-Table Name, Root, 
            @{L='Used(GB)';E={"{0:N1}" -f ($_.Used/1GB)};A='Right'},
            @{L='Free(GB)';E={"{0:N1}" -f ($_.Free/1GB)};A='Right'} -AutoSize

    # ロード済みモジュール
    Write-Host "📦 ロード済みモジュール:" -ForegroundColor Yellow
    Get-Module | Format-Table Name, Version, ModuleType -AutoSize

    # 環境変数（一部）
    Write-Host "🔧 主要環境変数:" -ForegroundColor Yellow
    @('PATH', 'HOME', 'USER', 'SHELL', 'LANG', 'TERM') | ForEach-Object {
        $val = [Environment]::GetEnvironmentVariable($_)
        if ($val) {
            $display = if ($val.Length -gt 80) { $val.Substring(0, 77) + "..." } else { $val }
            Write-Host ("  {0,-8} = {1}" -f $_, $display) -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# ── メインループ ──
Clear-Host
Show-Banner

do {
    Show-Menu
    $choice = Read-Host "`n選択"

    switch ($choice) {
        '1' {
            try {
                & (Join-Path $scriptRoot "tools/Invoke-SystemHealthCheck.ps1")
            }
            catch { Write-Warning "エラー: $_" }
        }
        '2' {
            $path = Read-Host "分析対象ディレクトリ (Enter=カレント)"
            if ([string]::IsNullOrWhiteSpace($path)) { $path = $PWD.Path }
            $showTodo = (Read-Host "TODO/FIXMEも検出？ (y/N)") -eq 'y'
            try {
                $params = @{ Path = $path }
                if ($showTodo) { $params['ShowTodos'] = $true }
                & (Join-Path $scriptRoot "tools/Get-ProjectStats.ps1") @params
            }
            catch { Write-Warning "エラー: $_" }
        }
        '3' {
            $interval = Read-Host "計測間隔（秒、Enter=3）"
            $duration = Read-Host "計測期間（秒、Enter=15）"
            if ([string]::IsNullOrWhiteSpace($interval)) { $interval = 3 }
            if ([string]::IsNullOrWhiteSpace($duration)) { $duration = 15 }
            try {
                & (Join-Path $scriptRoot "tools/Watch-SystemMetrics.ps1") -IntervalSeconds ([int]$interval) -Duration ([int]$duration)
            }
            catch { Write-Warning "エラー: $_" }
        }
        '4' {
            $repo = Read-Host "GitHubリポジトリ（Enter=PowerShell/PowerShell）"
            if ([string]::IsNullOrWhiteSpace($repo)) { $repo = "PowerShell/PowerShell" }
            try {
                & (Join-Path $scriptRoot "tools/Invoke-ApiDashboard.ps1") -GitHubRepo $repo
            }
            catch { Write-Warning "エラー: $_" }
        }
        '5' {
            Show-SystemInfo
        }
        'Q' { }
        'q' { }
        default {
            Write-Host "  ❌ 無効な選択です" -ForegroundColor Red
        }
    }

    if ($choice -notin 'Q','q') {
        Write-Host ""
        Read-Host "Enter で メニューに戻る"
        Clear-Host
        Show-Banner
    }
} while ($choice -notin 'Q', 'q')

Write-Host "`n👋 さようなら!`n" -ForegroundColor Cyan
