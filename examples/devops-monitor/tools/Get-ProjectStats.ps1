<#
.SYNOPSIS
    プロジェクト統計分析 — コードベースの言語別・カテゴリ別分析
.DESCRIPTION
    指定ディレクトリを再帰走査し、ファイル種別/言語/行数/TODO検出を行う
    
    使用機能: ValueFromPipeline / ValidateScript / Select-String / 
             Group-Object / Measure-Object / 計算プロパティ / Regex
.EXAMPLE
    ./Get-ProjectStats.ps1 -Path ~/workspace/powershell-study
    ./Get-ProjectStats.ps1 -Path . -ShowTodos
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,

    [switch]$ShowTodos,

    [int]$TopN = 10
)

$ErrorActionPreference = "Stop"
$Path = Resolve-Path $Path

# ── 言語マッピング ──
$langMap = @{
    '.ps1'='.ps1 PowerShell'; '.psm1'='.ps1 PowerShell'; '.py'='.py Python'
    '.js'='.js JavaScript'; '.ts'='.ts TypeScript'; '.tsx'='.tsx TypeScript(React)'
    '.go'='.go Go'; '.rs'='.rs Rust'; '.java'='.java Java'; '.cs'='.cs C#'
    '.rb'='.rb Ruby'; '.sh'='.sh Shell'; '.lua'='.lua Lua'
    '.md'='.md Markdown'; '.mdx'='.mdx MDX'
    '.json'='.json JSON'; '.yaml'='.yaml YAML'; '.yml'='.yaml YAML'
    '.toml'='.toml TOML'; '.html'='.html HTML'; '.css'='.css CSS'
    '.scss'='.scss SCSS'; '.sql'='.sql SQL'; '.astro'='.astro Astro'
    '.vue'='.vue Vue'; '.svelte'='.svelte Svelte'
}

# ── 除外パターン（スプラッティング用） ──
$excludeDirs = 'node_modules|\.git|vendor|__pycache__|\.venv|dist|\.next|target|\.astro'

Write-Host "`n📊 Project Stats: $(Split-Path $Path -Leaf)" -ForegroundColor Cyan
Write-Host ("─" * 50) -ForegroundColor DarkGray

# ── ファイル収集（パイプライン） ──
$files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $excludeDirs }

$totalSize = ($files | Measure-Object Length -Sum).Sum
Write-Host "📁 ファイル数: $($files.Count) | 総サイズ: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Gray

# ── 拡張子別集計（Group-Object + 計算プロパティ） ──
Write-Host "`n📝 拡張子別ファイル数:" -ForegroundColor Yellow
$files | Group-Object Extension |
    Sort-Object Count -Descending |
    Select-Object -First $TopN @{L='拡張子';E={if($_.Name){"$($_.Name)"}else{"(なし)"}}},
        Count,
        @{L='サイズ(KB)';E={[math]::Round(($_.Group | Measure-Object Length -Sum).Sum / 1KB, 1)}} |
    Format-Table -AutoSize

# ── ソースコード行数分析 ──
Write-Host "💻 言語別コード行数:" -ForegroundColor Yellow

$textExts = $langMap.Keys
$codeFiles = $files | Where-Object { $_.Extension.ToLower() -in $textExts }

$langStats = $codeFiles | ForEach-Object {
    $ext = $_.Extension.ToLower()
    $lang = ($langMap[$ext] -split ' ', 2)[1]
    $lines = try { (Get-Content $_.FullName -ErrorAction SilentlyContinue).Count } catch { 0 }
    [PSCustomObject]@{ Language = $lang; Lines = $lines; File = $_.FullName }
} | Group-Object Language |
    Select-Object @{L='言語';E={$_.Name}},
        @{L='ファイル';E={$_.Count}},
        @{L='行数';E={($_.Group | Measure-Object Lines -Sum).Sum}},
        @{L='平均行数';E={[math]::Round(($_.Group | Measure-Object Lines -Average).Average, 0)}} |
    Sort-Object 行数 -Descending

$langStats | Format-Table -AutoSize

$totalLines = ($langStats | Measure-Object -Property 行数 -Sum).Sum
Write-Host "  📝 総コード行数: $($totalLines.ToString('N0'))" -ForegroundColor Green

# ── 巨大ファイル検出 ──
Write-Host "`n📦 巨大ファイル Top $TopN :" -ForegroundColor Yellow
$codeFiles | Sort-Object Length -Descending | Select-Object -First $TopN |
    ForEach-Object {
        $lines = try { (Get-Content $_.FullName -ErrorAction SilentlyContinue).Count } catch { 0 }
        [PSCustomObject]@{
            ファイル = $_.FullName -replace [regex]::Escape($Path), '.'
            サイズ   = "{0:N1} KB" -f ($_.Length / 1KB)
            行数     = $lines
        }
    } | Format-Table -AutoSize

# ── TODO/FIXME/HACK 検出（Select-String） ──
if ($ShowTodos) {
    Write-Host "🔍 TODO/FIXME/HACK マーカー:" -ForegroundColor Yellow
    
    $markers = $codeFiles | ForEach-Object {
        Select-String -Path $_.FullName -Pattern '\b(TODO|FIXME|HACK|XXX|BUG)\b' -AllMatches -ErrorAction SilentlyContinue
    }

    if ($markers) {
        $markers | Select-Object -First 20 |
            ForEach-Object {
                $shortPath = $_.Path -replace [regex]::Escape($Path), '.'
                [PSCustomObject]@{
                    ファイル = $shortPath
                    行       = $_.LineNumber
                    内容     = $_.Line.Trim().Substring(0, [math]::Min(80, $_.Line.Trim().Length))
                }
            } | Format-Table -AutoSize

        $markerStats = $markers | ForEach-Object {
            $_.Matches | ForEach-Object { $_.Value }
        } | Group-Object | Select-Object Name, Count | Sort-Object Count -Descending

        Write-Host "  集計:" -ForegroundColor Gray
        $markerStats | ForEach-Object { Write-Host "    $($_.Name): $($_.Count)件" -ForegroundColor Gray }
    }
    else {
        Write-Host "  ✅ マーカーは見つかりませんでした" -ForegroundColor Green
    }
}

# ── 依存関係検出 ──
Write-Host "`n📦 依存関係:" -ForegroundColor Yellow
$depFiles = @(
    @{ File = "package.json";      Label = "Node.js" }
    @{ File = "requirements.txt";  Label = "Python" }
    @{ File = "go.mod";            Label = "Go" }
    @{ File = "Cargo.toml";        Label = "Rust" }
    @{ File = "Gemfile";           Label = "Ruby" }
    @{ File = "composer.json";     Label = "PHP" }
)

$depFiles | ForEach-Object {
    $depPath = Join-Path $Path $_.File
    if (Test-Path $depPath) {
        $depCount = switch ($_.Label) {
            "Node.js" {
                $pkg = Get-Content $depPath -Raw | ConvertFrom-Json
                $d = if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties.Count } else { 0 }
                $dd = if ($pkg.devDependencies) { $pkg.devDependencies.PSObject.Properties.Count } else { 0 }
                "deps=$d, devDeps=$dd"
            }
            "Python" { "$(( Get-Content $depPath | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }).Count) packages" }
            default  { "検出" }
        }
        Write-Host "  ✅ $($_.Label): $($_.File) ($depCount)" -ForegroundColor Green
    }
}

Write-Host "`n🏁 分析完了!`n" -ForegroundColor Green
