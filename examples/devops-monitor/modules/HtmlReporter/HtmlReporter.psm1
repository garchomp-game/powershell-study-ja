# ===========================================================================
# HtmlReporter.psm1 — ダークテーマのHTMLダッシュボード生成モジュール
# 
# 使用機能: ヒアストリング / パイプライン関数 / 計算プロパティ /
#          ConvertTo-Html / Format演算子 / Switch
# ===========================================================================

function New-DashboardHtml {
    <#
    .SYNOPSIS
        SystemReportオブジェクトからリッチなHTMLダッシュボードを生成
    .PARAMETER Report
        Invoke-HealthCheck の出力
    .PARAMETER OutputPath
        HTMLファイルの出力先
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Report,

        [Parameter()]
        [string]$OutputPath = "/tmp/devops-reports/dashboard.html"
    )

    process {
        if ($PSCmdlet.ShouldProcess($OutputPath, "HTMLダッシュボード生成")) {
            $dir = Split-Path $OutputPath -Parent
            if (-not (Test-Path $dir)) {
                $null = New-Item -Path $dir -ItemType Directory -Force
            }

            # ── ステータスバッジ ──
            $statusBadge = switch ($Report.OverallStatus.ToString()) {
                'Healthy'  { '<span class="badge healthy">✅ Healthy</span>' }
                'Degraded' { '<span class="badge degraded">⚠️ Degraded</span>' }
                'Critical' { '<span class="badge critical">🔴 Critical</span>' }
                default    { '<span class="badge unknown">❓ Unknown</span>' }
            }

            # ── メトリクスカード ──
            $cpuMetric = $Report.Metrics | Where-Object { $_.Type -eq 'CPU' -and $_.Name -eq 'Total' }
            $memMetric = $Report.Metrics | Where-Object { $_.Type -eq 'Memory' -and $_.Name -eq 'Used' }
            $memMBMetric = $Report.Metrics | Where-Object { $_.Type -eq 'Memory' -and $_.Name -eq 'UsedMB' }
            $uptimeMetric = $Report.Metrics | Where-Object { $_.Type -eq 'Uptime' }

            $cpuVal = if ($cpuMetric) { "{0:N1}%" -f $cpuMetric.Value } else { "N/A" }
            $memVal = if ($memMetric) { "{0:N1}%" -f $memMetric.Value } else { "N/A" }
            $memDetail = if ($memMBMetric) { "{0:N0} MB" -f $memMBMetric.Value } else { "" }
            $uptimeVal = if ($uptimeMetric) { "{0:N1} hrs" -f $uptimeMetric.Value } else { "N/A" }

            $cpuColor = Get-GaugeColor -Value $cpuMetric.Value -Warn 70 -Crit 90
            $memColor = Get-GaugeColor -Value $memMetric.Value -Warn 80 -Crit 95

            # ── プロセステーブル ──
            $procRows = $Report.TopProcesses | ForEach-Object {
                @"
                <tr>
                    <td class="mono">$($_.PID)</td>
                    <td><strong>$($_.Name)</strong></td>
                    <td class="num">$($_.CPU_Sec)</td>
                    <td class="num">$($_.MemoryMB)</td>
                    <td class="num">$($_.Threads)</td>
                    <td>$($_.StartTime)</td>
                    <td>$($_.RunningFor)</td>
                </tr>
"@
            }

            # ── ディスクテーブル ──
            $diskRows = $Report.DiskUsage | ForEach-Object {
                $barColor = Get-GaugeColor -Value $_.UsedPercent -Warn 85 -Crit 95
                @"
                <tr>
                    <td class="mono">$($_.Root)</td>
                    <td class="num">$($_.TotalGB) GB</td>
                    <td class="num">$($_.UsedGB) GB</td>
                    <td class="num">$($_.FreeGB) GB</td>
                    <td>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width:$($_.UsedPercent)%;background:$barColor">
                                $($_.UsedPercent)%
                            </div>
                        </div>
                    </td>
                </tr>
"@
            }

            # ── アラート ──
            $alertHtml = if ($Report.Alerts.Count -gt 0) {
                $items = $Report.Alerts | ForEach-Object { "<li>$_</li>" }
                "<div class='card alert-card'><h2>🚨 アラート ($($Report.Alerts.Count))</h2><ul>$($items -join '')</ul></div>"
            } else {
                "<div class='card ok-card'><h2>✅ 異常なし</h2><p>全てのメトリクスが正常範囲内です。</p></div>"
            }

            # ── メトリクスの全リスト ──
            $metricRows = $Report.Metrics | ForEach-Object {
                $sClass = switch ($_.Status.ToString()) {
                    'Healthy'  { 'healthy' }
                    'Degraded' { 'degraded' }
                    'Critical' { 'critical' }
                    default    { '' }
                }
                "<tr class='$sClass'><td>$($_.Type)</td><td>$($_.Name)</td><td class='num'>{0:N2}</td><td>$($_.Unit)</td><td>$($_.Status)</td></tr>" -f $_.Value
            }

            # ── HTML組み立て ──
            $html = @"
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>DevOps Dashboard — $($Report.Hostname)</title>
<style>
:root{--bg:#0d1117;--card:#161b22;--border:#21262d;--text:#c9d1d9;--dim:#8b949e;--blue:#58a6ff;--green:#3fb950;--yellow:#d29922;--red:#f85149;--purple:#bc8cff}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:var(--bg);color:var(--text);line-height:1.6}
.container{max-width:1400px;margin:0 auto;padding:1.5rem}
header{display:flex;justify-content:space-between;align-items:center;margin-bottom:2rem;padding-bottom:1rem;border-bottom:1px solid var(--border)}
h1{font-size:1.6rem;background:linear-gradient(135deg,var(--blue),var(--purple));-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.meta{color:var(--dim);font-size:.85rem}
.badge{padding:.3rem .8rem;border-radius:20px;font-weight:600;font-size:.85rem}
.badge.healthy{background:#0d3117;color:var(--green)}.badge.degraded{background:#3d2e00;color:var(--yellow)}.badge.critical{background:#3d1418;color:var(--red)}.badge.unknown{background:#1c1c1c;color:var(--dim)}
.grid{display:grid;gap:1.2rem}
.grid-4{grid-template-columns:repeat(auto-fit,minmax(220px,1fr))}
.grid-2{grid-template-columns:repeat(auto-fit,minmax(500px,1fr))}
.card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:1.2rem}
.alert-card{border-color:var(--yellow)}
.alert-card ul{list-style:none;margin-top:.5rem}
.alert-card li{padding:.3rem 0;font-size:.9rem}
.ok-card{border-color:var(--green)}
.stat-card{text-align:center;padding:1.5rem}
.stat-value{font-size:2.2rem;font-weight:700;display:block}
.stat-label{font-size:.8rem;color:var(--dim);margin-top:.2rem;display:block}
.stat-detail{font-size:.75rem;color:var(--dim);margin-top:.1rem}
h2{font-size:1.1rem;color:var(--blue);margin-bottom:.8rem;padding-bottom:.4rem;border-bottom:1px solid var(--border)}
table{width:100%;border-collapse:collapse;font-size:.85rem}
th{text-align:left;color:var(--dim);font-weight:600;padding:.5rem .6rem;border-bottom:1px solid var(--border)}
td{padding:.4rem .6rem;border-bottom:1px solid #161b22}
tr:hover{background:#1c2128}
.num{text-align:right;font-variant-numeric:tabular-nums}
.mono{font-family:'Cascadia Code','Fira Code',monospace;font-size:.82rem}
.progress-bar{background:#21262d;border-radius:6px;height:22px;overflow:hidden;min-width:120px}
.progress-fill{height:100%;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:.75rem;font-weight:600;color:#fff;transition:width .5s}
tr.healthy td:last-child{color:var(--green)}
tr.degraded td:last-child{color:var(--yellow)}
tr.critical td:last-child{color:var(--red)}
footer{text-align:center;padding:2rem;color:#30363d;font-size:.75rem}
.gauge{width:100px;height:100px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto .5rem;font-size:1.3rem;font-weight:700;border:4px solid}
@media(max-width:768px){.grid-4{grid-template-columns:1fr 1fr}.grid-2{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="container">

<header>
    <div>
        <h1>🖥️ DevOps Dashboard</h1>
        <div class="meta">$($Report.Hostname) | $($Report.OS) | PowerShell $($Report.PowerShellVersion)</div>
    </div>
    <div style="text-align:right">
        $statusBadge
        <div class="meta" style="margin-top:.3rem">$($Report.GeneratedAt.ToString("yyyy-MM-dd HH:mm:ss"))</div>
    </div>
</header>

$alertHtml

<div class="grid grid-4" style="margin-bottom:1.2rem">
    <div class="card stat-card">
        <div class="gauge" style="border-color:$cpuColor;color:$cpuColor">$cpuVal</div>
        <span class="stat-label">CPU使用率</span>
    </div>
    <div class="card stat-card">
        <div class="gauge" style="border-color:$memColor;color:$memColor">$memVal</div>
        <span class="stat-label">メモリ使用率</span>
        <span class="stat-detail">$memDetail</span>
    </div>
    <div class="card stat-card">
        <span class="stat-value" style="color:var(--blue)">$uptimeVal</span>
        <span class="stat-label">Uptime</span>
    </div>
    <div class="card stat-card">
        <span class="stat-value" style="color:var(--purple)">$($Report.TopProcesses.Count)</span>
        <span class="stat-label">アクティブプロセス</span>
    </div>
</div>

<div class="grid grid-2">
    <div class="card">
        <h2>⚡ プロセス Top $($Report.TopProcesses.Count) (CPU順)</h2>
        <table>
            <tr><th>PID</th><th>Name</th><th>CPU(s)</th><th>MEM(MB)</th><th>Threads</th><th>Start</th><th>稼働</th></tr>
            $($procRows -join "`n")
        </table>
    </div>

    <div class="card">
        <h2>💾 ディスク使用状況</h2>
        <table>
            <tr><th>マウント</th><th>合計</th><th>使用</th><th>空き</th><th>使用率</th></tr>
            $($diskRows -join "`n")
        </table>
    </div>
</div>

<div class="card" style="margin-top:1.2rem">
    <h2>📊 全メトリクス</h2>
    <table>
        <tr><th>種別</th><th>名前</th><th>値</th><th>単位</th><th>ステータス</th></tr>
        $($metricRows -join "`n")
    </table>
</div>

<footer>Generated by PowerShell DevOps Monitor Toolkit 🚀 | $(Get-Date -Format 'yyyy')</footer>
</div>
</body>
</html>
"@

            $html | Out-File -FilePath $OutputPath -Encoding utf8
            Write-Verbose "✅ Dashboard生成: $OutputPath"
            return $OutputPath
        }
    }
}

function Get-GaugeColor {
    <#
    .SYNOPSIS
        値に応じたゲージ色を返すヘルパー
    #>
    [CmdletBinding()]
    param(
        [double]$Value, 
        [double]$Warn = 70, 
        [double]$Crit = 90
    )
    if ($Value -ge $Crit) { return 'var(--red)' }
    if ($Value -ge $Warn) { return 'var(--yellow)' }
    return 'var(--green)'
}

Export-ModuleMember -Function 'New-DashboardHtml', 'Get-GaugeColor'
