<#
.SYNOPSIS
    REST API統合ダッシュボード — 外部API呼び出し + データ加工
.DESCRIPTION
    複数のAPIを呼び出し、データを集約してレポートを生成する
    
    使用機能: Invoke-RestMethod / Invoke-WebRequest / ConvertFrom-Json /
             ForEach-Object -Parallel / Measure-Command / try/catch /
             PSCustomObject / 計算プロパティ
.EXAMPLE
    ./Invoke-ApiDashboard.ps1
    ./Invoke-ApiDashboard.ps1 -GitHubRepo "PowerShell/PowerShell"
#>
[CmdletBinding()]
param(
    [string]$GitHubRepo = "PowerShell/PowerShell",
    [int]$TimeoutSec = 10
)

$ErrorActionPreference = "Stop"

Write-Host "`n🌐 API Integration Dashboard" -ForegroundColor Cyan
Write-Host ("─" * 60) -ForegroundColor DarkGray

$results = @{}

# ── 1. パブリックIP取得 ──
Write-Host "`n[1/5] 🌍 パブリックIP取得..." -ForegroundColor Yellow
try {
    $timer = Measure-Command {
        $ipInfo = Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec $TimeoutSec
    }
    $results['PublicIP'] = $ipInfo.ip
    Write-Host "  IP: $($ipInfo.ip) (${[math]::Round($timer.TotalMilliseconds)}ms)" -ForegroundColor Green
}
catch {
    Write-Warning "  IP取得失敗: $_"
    $results['PublicIP'] = "N/A"
}

# ── 2. GitHub リポジトリ情報 ──
Write-Host "[2/5] 🐙 GitHub: $GitHubRepo ..." -ForegroundColor Yellow
try {
    $timer = Measure-Command {
        $repo = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo" -TimeoutSec $TimeoutSec
    }
    
    $repoInfo = [PSCustomObject]@{
        名前         = $repo.full_name
        説明         = $repo.description.Substring(0, [math]::Min(60, $repo.description.Length)) + "..."
        スター       = $repo.stargazers_count.ToString('N0')
        フォーク     = $repo.forks_count.ToString('N0')
        Issues       = $repo.open_issues_count
        言語         = $repo.language
        最終更新     = ([datetime]$repo.updated_at).ToString("yyyy-MM-dd HH:mm")
        ライセンス   = $repo.license.name
        サイズ       = "{0:N1} MB" -f ($repo.size / 1024)
    }
    $results['GitHub'] = $repoInfo

    Write-Host "  ⭐ $($repo.stargazers_count.ToString('N0')) stars | 🍴 $($repo.forks_count.ToString('N0')) forks | 📝 $($repo.language)" -ForegroundColor Green
    $repoInfo | Format-List
}
catch {
    Write-Warning "  GitHub API失敗: $_"
}

# ── 3. GitHub コントリビューター ──
Write-Host "[3/5] 👥 コントリビューター取得..." -ForegroundColor Yellow
try {
    $contributors = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo/contributors?per_page=10" -TimeoutSec $TimeoutSec
    
    Write-Host "  Top 10 コントリビューター:" -ForegroundColor Green
    $contributors | 
        Select-Object -First 10 |
        ForEach-Object {
            [PSCustomObject]@{
                ユーザー    = $_.login
                コミット数  = $_.contributions
                プロフィール = $_.html_url
            }
        } | Format-Table -AutoSize

    $results['Contributors'] = $contributors.Count
}
catch {
    Write-Warning "  コントリビューター取得失敗: $_"
}

# ── 4. 最新リリース ──
Write-Host "[4/5] 📦 最新リリース情報..." -ForegroundColor Yellow
try {
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo/releases?per_page=5" -TimeoutSec $TimeoutSec
    
    $releases | Select-Object -First 5 | ForEach-Object {
        [PSCustomObject]@{
            バージョン = $_.tag_name
            名前       = $_.name.Substring(0, [math]::Min(40, $_.name.Length))
            日付       = ([datetime]$_.published_at).ToString("yyyy-MM-dd")
            DL数       = ($_.assets | Measure-Object -Property download_count -Sum).Sum
        }
    } | Format-Table -AutoSize

    $results['LatestRelease'] = $releases[0].tag_name
}
catch {
    Write-Warning "  リリース情報取得失敗: $_"
}

# ── 5. HTTPベンチマーク（複数URLの応答速度計測） ──
Write-Host "[5/5] ⚡ HTTP応答速度ベンチマーク..." -ForegroundColor Yellow

$urls = @(
    @{ Name = "Google"; Url = "https://www.google.com" }
    @{ Name = "GitHub"; Url = "https://github.com" }
    @{ Name = "Cloudflare DNS"; Url = "https://1.1.1.1" }
    @{ Name = "httpbin"; Url = "https://httpbin.org/get" }
)

$benchResults = $urls | ForEach-Object {
    $entry = $_
    try {
        $timer = Measure-Command {
            $response = Invoke-WebRequest -Uri $entry.Url -TimeoutSec 5 -Method Head -ErrorAction SilentlyContinue
        }
        [PSCustomObject]@{
            サイト     = $entry.Name
            URL        = $entry.Url
            ステータス = $response.StatusCode
            応答時間   = "{0:N0} ms" -f $timer.TotalMilliseconds
            応答ms     = [math]::Round($timer.TotalMilliseconds)
        }
    }
    catch {
        [PSCustomObject]@{
            サイト     = $entry.Name
            URL        = $entry.Url
            ステータス = "Error"
            応答時間   = "Timeout"
            応答ms     = 99999
        }
    }
}

$benchResults | 
    Sort-Object 応答ms |
    Select-Object サイト, ステータス, 応答時間 |
    Format-Table -AutoSize

$avgMs = ($benchResults | Where-Object { $_.応答ms -lt 99999 } | Measure-Object -Property 応答ms -Average).Average
Write-Host "  📊 平均応答時間: $([math]::Round($avgMs)) ms" -ForegroundColor Cyan

# ── サマリー ──
Write-Host ("─" * 60) -ForegroundColor DarkGray
Write-Host "📋 テスト結果サマリー" -ForegroundColor Cyan

[PSCustomObject]@{
    パブリックIP   = $results['PublicIP']
    GitHubリポ     = $GitHubRepo
    最新バージョン = $results['LatestRelease'] ?? 'N/A'
    コントリビュータ = $results['Contributors'] ?? 0
    平均応答時間   = "$([math]::Round($avgMs)) ms"
    テスト日時     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} | Format-List

Write-Host "🏁 完了!`n" -ForegroundColor Green
