using namespace System.Collections.Generic

<#
.SYNOPSIS
    PowerShell 上級テクニック集 — 1ファイルで学ぶ高度な機能
.DESCRIPTION
    このファイルは PowerShell 7.x の上級機能を網羅的にデモするスクリプトです。
    各セクションを個別に実行して動作を確認できます。

    収録テクニック:
    ───────────────────────────────────────
     1. begin/process/end パイプライン関数
     2. ValueFromPipeline / ByPropertyName
     3. 複数パラメータセット
     4. カスタムバリデーション属性
     5. Steppable Pipeline（パイプラインの手動制御）
     6. ScriptBlock パラメータと Closure
     7. .NETジェネリクス / LINQ的操作
     8. Runspace（並列処理の低レベル制御）
     9. インラインC#（Add-Type）
    10. Register-EngineEvent / イベント駆動
    11. クラス継承 + インターフェースパターン
    12. DSL（ドメイン固有言語）の実装
    13. Proxy Function（既存コマンドの拡張）
    14. 動的パラメータ（DynamicParam）
    ───────────────────────────────────────

.NOTES
    PowerShell 7.5+ / Linux環境を前提
    各セクションは #region で区切られています
#>

# ============================================================
#region 1. begin/process/end パイプライン関数
# ============================================================
<#
    パイプラインで「1件ずつ流れてくるオブジェクト」を処理するパターン。
    begin:   パイプライン開始前に1回だけ実行（初期化）
    process: パイプラインの各オブジェクトに対して実行（メイン処理）
    end:     パイプライン終了後に1回だけ実行（集計・クリーンアップ）
#>

function Measure-TextStats {
    <#
    .SYNOPSIS
        テキスト行の統計情報をパイプラインで集計する
    .EXAMPLE
        Get-Content ./somefile.txt | Measure-TextStats
        "Hello","World","PowerShell is awesome" | Measure-TextStats
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Line
    )

    begin {
        # ── パイプライン開始前: カウンター初期化 ──
        Write-Verbose "📊 統計収集を開始..."
        $totalLines   = 0
        $totalChars   = 0
        $totalWords   = 0
        $blankLines   = 0
        $longestLine  = ""
        $wordFrequency = @{}
    }

    process {
        # ── 各行に対して実行: $_ または $Line で受け取る ──
        $totalLines++
        $totalChars += $Line.Length

        if ([string]::IsNullOrWhiteSpace($Line)) {
            $blankLines++
            return  # 次の行へ（continue相当）
        }

        # 単語分割して集計
        $words = $Line -split '\s+' | Where-Object { $_ -ne '' }
        $totalWords += $words.Count

        foreach ($word in $words) {
            $lower = $word.ToLower() -replace '[^\p{L}\p{N}]', ''
            if ($lower) {
                $wordFrequency[$lower] = ($wordFrequency[$lower] ?? 0) + 1
            }
        }

        if ($Line.Length -gt $longestLine.Length) {
            $longestLine = $Line
        }
    }

    end {
        # ── パイプライン終了後: 結果をオブジェクトとして出力 ──
        $topWords = $wordFrequency.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 5 |
            ForEach-Object { "$($_.Key)($($_.Value))" }

        [PSCustomObject]@{
            Lines        = $totalLines
            BlankLines   = $blankLines
            ContentLines = $totalLines - $blankLines
            Words        = $totalWords
            Characters   = $totalChars
            AvgWordsLine = if ($totalLines -gt $blankLines) {
                [math]::Round($totalWords / ($totalLines - $blankLines), 1)
            } else { 0 }
            LongestLine  = $longestLine.Substring(0, [math]::Min(50, $longestLine.Length))
            TopWords     = $topWords -join ', '
        }

        Write-Verbose "📊 統計収集を完了"
    }
}

# 使用例:
# Get-Content /etc/passwd | Measure-TextStats -Verbose
# "Hello World", "PowerShell is great", "", "Goodbye" | Measure-TextStats

#endregion

# ============================================================
#region 2. ValueFromPipeline / ValueFromPipelineByPropertyName
# ============================================================
<#
    ValueFromPipeline:             パイプラインのオブジェクト全体を受け取る
    ValueFromPipelineByPropertyName: プロパティ名が一致する値だけ自動バインド
#>

function ConvertTo-HumanSize {
    <#
    .SYNOPSIS
        バイト数を人間が読みやすい形式に変換
    .EXAMPLE
        Get-ChildItem ~ -File | ConvertTo-HumanSize | Format-Table Name, HumanSize
        1GB, 500MB, 1234 | ConvertTo-HumanSize
    #>
    [CmdletBinding()]
    param(
        # プロパティ名 "Length" を自動バインド（Get-ChildItemの出力と互換）
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("Length", "Size")]  # Length, Size のどちらでもバインド可能
        [long]$Bytes
    )

    begin {
        $units = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    }

    process {
        $value = [double]$Bytes
        $unitIndex = 0

        while ($value -ge 1024 -and $unitIndex -lt ($units.Count - 1)) {
            $value /= 1024
            $unitIndex++
        }

        # 入力オブジェクトがファイルなら名前を保持
        $name = if ($_ -is [System.IO.FileInfo]) { $_.Name } else { $null }

        [PSCustomObject]@{
            Name      = $name
            Bytes     = $Bytes
            HumanSize = "{0:N1} {1}" -f $value, $units[$unitIndex]
        }
    }
}

# 使用例:
# Get-ChildItem ~ -File | ConvertTo-HumanSize | Format-Table Name, HumanSize
# 1073741824, 5242880, 1234 | ConvertTo-HumanSize

#endregion

# ============================================================
#region 3. 複数パラメータセット
# ============================================================
<#
    1つの関数に複数の呼び出しパターンを定義できる。
    たとえば「名前で検索」と「IDで検索」を同じ関数で。
#>

function Find-Item {
    <#
    .SYNOPSIS
        名前 or ID or パターンで検索する多機能検索関数
    .EXAMPLE
        Find-Item -Name "*.ps1" -Path ~
        Find-Item -Id 12345
        Find-Item -Pattern "TODO|FIXME" -Path ./src
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ById', Mandatory)]
        [int]$Id,

        [Parameter(ParameterSetName = 'ByPattern', Mandatory)]
        [string]$Pattern,

        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByPattern')]
        [string]$Path = $PWD
    )

    # どのパラメータセットが使われたかを判定
    switch ($PSCmdlet.ParameterSetName) {
        'ByName' {
            Write-Host "🔍 名前で検索: $Name in $Path" -ForegroundColor Cyan
            Get-ChildItem -Path $Path -Filter $Name -Recurse -ErrorAction SilentlyContinue |
                Select-Object FullName, Length, LastWriteTime
        }
        'ById' {
            Write-Host "🔍 プロセスID: $Id" -ForegroundColor Yellow
            Get-Process -Id $Id -ErrorAction SilentlyContinue
        }
        'ByPattern' {
            Write-Host "🔍 パターン検索: $Pattern in $Path" -ForegroundColor Green
            Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
                Select-String -Pattern $Pattern -ErrorAction SilentlyContinue |
                Select-Object -First 20 Path, LineNumber, Line
        }
    }
}

#endregion

# ============================================================
#region 4. カスタムバリデーション属性
# ============================================================
<#
    ValidateScript で独自のバリデーションロジックを定義できる。
    失敗時のメッセージも ErrorMessage でカスタマイズ可能。
#>

function Set-ProjectConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ファイルが存在するかチェック
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "パスが存在しません: $_"
            }
            if (-not ($_ -match '\.(json|yaml|yml|toml)$')) {
                throw "対応形式: .json, .yaml, .yml, .toml（指定: $_）"
            }
            $true
        })]
        [string]$ConfigPath,

        # 1~65535の有効なポート番号
        [ValidateRange(1, 65535)]
        [int]$Port = 8080,

        # 正規表現でメールアドレス形式を検証
        [ValidatePattern('^[\w.+-]+@[\w-]+\.[\w.]+$',
            ErrorMessage = "'{0}' は有効なメールアドレスではありません")]
        [string]$AdminEmail,

        # 文字列の長さ制限
        [ValidateLength(1, 100)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectName,

        # カスタムValidateSetジェネレーター（動的）
        [ValidateSet('Development', 'Staging', 'Production')]
        [string]$Environment = 'Development'
    )

    if ($PSCmdlet.ShouldProcess("$ProjectName ($Environment)", "設定を更新")) {
        [PSCustomObject]@{
            Project     = $ProjectName
            Config      = $ConfigPath
            Port        = $Port
            AdminEmail  = $AdminEmail
            Environment = $Environment
            UpdatedAt   = Get-Date
        }
    }
}

#endregion

# ============================================================
#region 5. Steppable Pipeline（パイプラインの手動制御）
# ============================================================
<#
    通常のパイプラインはPowerShellが自動制御するが、
    SteppablePipeline を使うと「手動で1要素ずつ流す」ことができる。
    Proxy Functionや条件付きパイプラインで威力を発揮する。
#>

function Invoke-ConditionalPipeline {
    <#
    .SYNOPSIS
        条件に応じてパイプラインの先を切り替える
    .EXAMPLE
        1..10 | Invoke-ConditionalPipeline -Condition { $_ % 2 -eq 0 } `
            -TrueCommand { Format-Table } -FalseCommand { Out-Null }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [scriptblock]$Condition,

        [scriptblock]$OnTrue  = { Write-Host "✅ $_" -ForegroundColor Green },
        [scriptblock]$OnFalse = { Write-Host "❌ $_" -ForegroundColor Red }
    )

    begin {
        $trueCount = 0; $falseCount = 0
    }

    process {
        if (& $Condition) {
            $trueCount++
            $_ | ForEach-Object $OnTrue
        }
        else {
            $falseCount++
            $_ | ForEach-Object $OnFalse
        }
    }

    end {
        Write-Host "`n📊 True: $trueCount / False: $falseCount" -ForegroundColor Cyan
    }
}

# 使用例:
# 1..20 | Invoke-ConditionalPipeline -Condition { $_ % 3 -eq 0 }

#endregion

# ============================================================
#region 6. ScriptBlockパラメータと Closure
# ============================================================
<#
    ScriptBlock をパラメータとして受け取り、
    呼び出し側がロジックを注入できる「高階関数」パターン。
#>

function Invoke-Retry {
    <#
    .SYNOPSIS
        失敗時に自動リトライする汎用ラッパー
    .EXAMPLE
        Invoke-Retry -ScriptBlock { Invoke-RestMethod "https://api.example.com/data" } -MaxRetries 3
        Invoke-Retry { Get-Content "/tmp/maybe-exists.txt" } -Delay 1 -MaxRetries 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock,

        [ValidateRange(1, 20)]
        [int]$MaxRetries = 3,

        [ValidateRange(0, 60)]
        [double]$Delay = 1,

        [switch]$ExponentialBackoff
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            $result = & $ScriptBlock
            Write-Verbose "✅ 成功（試行 $attempt/$MaxRetries）"
            return $result
        }
        catch {
            $lastError = $_
            Write-Warning "❌ 試行 $attempt/$MaxRetries 失敗: $($_.Exception.Message)"

            if ($attempt -lt $MaxRetries) {
                $waitSec = if ($ExponentialBackoff) {
                    $Delay * [math]::Pow(2, $attempt - 1)  # 1, 2, 4, 8...
                } else { $Delay }

                Write-Verbose "⏳ ${waitSec}秒後にリトライ..."
                Start-Sleep -Seconds $waitSec
            }
        }
    }

    throw "⛔ $MaxRetries 回の試行全て失敗: $($lastError.Exception.Message)"
}

# ── クロージャ（外側の変数をキャプチャ） ──
function New-Counter {
    <#
    .SYNOPSIS
        クロージャで状態を持つカウンターを作成
    .EXAMPLE
        $counter = New-Counter -Start 10
        & $counter  # → 10
        & $counter  # → 11
        & $counter  # → 12
    #>
    param([int]$Start = 0)
    $count = $Start
    # GetNewClosure() で $count を「閉じ込める」
    return { ($script:count++) }.GetNewClosure()
}

# 使用例:
# $c = New-Counter -Start 100
# & $c  # → 100
# & $c  # → 101

#endregion

# ============================================================
#region 7. .NETジェネリクス / LINQ的操作
# ============================================================
<#
    PowerShellから.NETの型を直接使うことで、
    パフォーマンスが求められる場面で威力を発揮する。
#>

function Invoke-LinqDemo {
    <#
    .SYNOPSIS
        .NETジェネリクスとLINQ的操作のデモ
    #>
    [CmdletBinding()]
    param()

    # ※ using namespace はファイル先頭で宣言済み

    Write-Host "`n💎 .NET ジェネリクス / LINQ的操作デモ" -ForegroundColor Cyan
    Write-Host ("─" * 50) -ForegroundColor DarkGray

    # Dictionary<string, List<int>>
    $data = [Dictionary[string, List[int]]]::new()
    $data['scores']  = [List[int]]@(85, 92, 78, 95, 88, 73, 91, 86)
    $data['ages']    = [List[int]]@(25, 30, 35, 28, 42, 31, 27, 33)

    # HashSet — 重複自動除去
    $visited = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    "Tokyo", "Osaka", "tokyo", "OSAKA", "Kyoto" | ForEach-Object { $null = $visited.Add($_) }
    Write-Host "HashSet（重複除去）: $($visited -join ', ')"
    # → Tokyo, Osaka, Kyoto  （大文字小文字を無視）

    # Sortメソッド + ラムダ的な使い方
    $scores = $data['scores']
    $sorted = [List[int]]::new($scores)
    $sorted.Sort()  # インプレースソート
    Write-Host "ソート済みスコア: $($sorted -join ', ')"

    # LINQ的: 条件フィルタ → 平均
    $highScores = $scores | Where-Object { $_ -ge 85 }
    $avg = ($highScores | Measure-Object -Average).Average
    Write-Host "85点以上の平均: $([math]::Round($avg, 1))"

    # Tuple — 複数値のグループ化
    $point = [Tuple]::Create("Server-01", 98.5, [DateTime]::Now)
    Write-Host "Tuple: $($point.Item1) = $($point.Item2)% at $($point.Item3.ToString('HH:mm:ss'))"

    # Stopwatch — 高精度タイマー
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    1..100000 | ForEach-Object { $null = $_ * $_ } | Out-Null
    $sw.Stop()
    Write-Host "100,000回の計算: $($sw.ElapsedMilliseconds) ms"

    # StringBuilder — 大量文字列結合の高速化
    $sb = [System.Text.StringBuilder]::new()
    1..1000 | ForEach-Object { $null = $sb.AppendLine("Line $_") }
    Write-Host "StringBuilder: $($sb.Length) chars generated"
}

#endregion

# ============================================================
#region 8. Runspace（並列処理の低レベル制御）
# ============================================================
<#
    ForEach-Object -Parallel は内部でRunspaceを使っている。
    直接Runspaceを制御することで、より細かい並列処理が可能。
#>

function Invoke-ParallelDemo {
    <#
    .SYNOPSIS
        Runspace Pool による並列HTTP呼び出しのデモ
    .EXAMPLE
        Invoke-ParallelDemo
    #>
    [CmdletBinding()]
    param(
        [int]$MaxConcurrency = 4
    )

    $urls = @(
        "https://httpbin.org/delay/1"
        "https://httpbin.org/get"
        "https://httpbin.org/uuid"
        "https://httpbin.org/headers"
    )

    Write-Host "`n🚀 Runspace Pool 並列デモ (MaxConcurrency=$MaxConcurrency)" -ForegroundColor Cyan

    # ── 方法1: ForEach-Object -Parallel（簡単） ──
    Write-Host "`n[方法1] ForEach-Object -Parallel:" -ForegroundColor Yellow
    $timer = Measure-Command {
        $results = $urls | ForEach-Object -Parallel {
            $uri = $_
            try {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                $null = Invoke-WebRequest -Uri $uri -TimeoutSec 5 -Method Head
                $sw.Stop()
                [PSCustomObject]@{ Url = $uri; Ms = $sw.ElapsedMilliseconds; Status = "OK" }
            }
            catch {
                [PSCustomObject]@{ Url = $uri; Ms = -1; Status = "Error" }
            }
        } -ThrottleLimit $MaxConcurrency
    }
    $results | Format-Table -AutoSize
    Write-Host "合計: $([math]::Round($timer.TotalMilliseconds)) ms" -ForegroundColor Gray

    # ── 方法2: Start-ThreadJob（ジョブベース） ──
    Write-Host "[方法2] Start-ThreadJob:" -ForegroundColor Yellow
    $timer2 = Measure-Command {
        $jobs = $urls | ForEach-Object {
            $uri = $_
            Start-ThreadJob -ScriptBlock {
                param($u)
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    $null = Invoke-WebRequest -Uri $u -TimeoutSec 5 -Method Head
                    $sw.Stop()
                    [PSCustomObject]@{ Url = $u; Ms = $sw.ElapsedMilliseconds; Status = "OK" }
                } catch {
                    [PSCustomObject]@{ Url = $u; Ms = -1; Status = "Error" }
                }
            } -ArgumentList $_
        }
        $results2 = $jobs | Receive-Job -Wait -AutoRemoveJob
    }
    $results2 | Format-Table -AutoSize
    Write-Host "合計: $([math]::Round($timer2.TotalMilliseconds)) ms" -ForegroundColor Gray
}

#endregion

# ============================================================
#region 9. インラインC#（Add-Type）
# ============================================================
<#
    PowerShellからC#コードを直接コンパイル・実行できる。
    パフォーマンスが必要な処理やPowerShellで表現しにくい処理に使う。
#>

function Invoke-CSharpDemo {
    <#
    .SYNOPSIS
        PowerShellからC#を呼び出すデモ
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n⚡ インラインC# デモ" -ForegroundColor Cyan

    # C#クラスを定義・コンパイル
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Linq;

namespace PsDemo {
    public class MathHelper {
        // フィボナッチ数列（イテレータ）
        public static IEnumerable<long> Fibonacci(int count) {
            long a = 0, b = 1;
            for (int i = 0; i < count; i++) {
                yield return a;
                (a, b) = (b, a + b);
            }
        }

        // 素数判定
        public static bool IsPrime(long n) {
            if (n < 2) return false;
            if (n < 4) return true;
            if (n % 2 == 0 || n % 3 == 0) return false;
            for (long i = 5; i * i <= n; i += 6)
                if (n % i == 0 || n % (i + 2) == 0) return false;
            return true;
        }

        // 文字列のレーベンシュタイン距離
        public static int EditDistance(string s, string t) {
            var d = new int[s.Length + 1, t.Length + 1];
            for (int i = 0; i <= s.Length; i++) d[i, 0] = i;
            for (int j = 0; j <= t.Length; j++) d[0, j] = j;
            for (int i = 1; i <= s.Length; i++)
                for (int j = 1; j <= t.Length; j++)
                    d[i, j] = Math.Min(Math.Min(
                        d[i - 1, j] + 1,
                        d[i, j - 1] + 1),
                        d[i - 1, j - 1] + (s[i - 1] == t[j - 1] ? 0 : 1));
            return d[s.Length, t.Length];
        }
    }
}
"@ -ErrorAction SilentlyContinue

    # C#メソッドをPowerShellから呼び出す
    Write-Host "フィボナッチ(15): $([PsDemo.MathHelper]::Fibonacci(15) -join ', ')"
    Write-Host "IsPrime(997): $([PsDemo.MathHelper]::IsPrime(997))"
    Write-Host "EditDistance('PowerShell','PowerSell'): $([PsDemo.MathHelper]::EditDistance('PowerShell','PowerSell'))"

    # パフォーマンス比較: C# vs PowerShell
    Write-Host "`n⏱️ パフォーマンス比較 (素数カウント 1-10000):" -ForegroundColor Yellow

    $csharpTime = Measure-Command {
        $csharpCount = (1..10000 | Where-Object { [PsDemo.MathHelper]::IsPrime($_) }).Count
    }

    $psTime = Measure-Command {
        $psCount = (1..10000 | Where-Object {
            $n = $_
            if ($n -lt 2) { return $false }
            if ($n -lt 4) { return $true }
            if ($n % 2 -eq 0) { return $false }
            $limit = [math]::Sqrt($n)
            for ($i = 3; $i -le $limit; $i += 2) {
                if ($n % $i -eq 0) { return $false }
            }
            $true
        }).Count
    }

    Write-Host "  C#:         $($csharpTime.TotalMilliseconds.ToString('N0')) ms ($csharpCount primes)"
    Write-Host "  PowerShell: $($psTime.TotalMilliseconds.ToString('N0')) ms ($psCount primes)"
    Write-Host "  速度差:     $([math]::Round($psTime.TotalMilliseconds / $csharpTime.TotalMilliseconds, 1))倍" -ForegroundColor Cyan
}

#endregion

# ============================================================
#region 10. イベント駆動プログラミング
# ============================================================
<#
    PowerShellにはイベントシステムがあり、
    ファイル変更やタイマーなどのイベントに反応できる。
#>

function Start-FileWatcher {
    <#
    .SYNOPSIS
        指定ディレクトリのファイル変更を監視する
    .EXAMPLE
        $watcher = Start-FileWatcher -Path /tmp -Filter "*.txt"
        # /tmp でテキストファイルを作成・変更すると通知される
        # 停止: $watcher.Dispose()
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,

        [string]$Filter = "*.*",
        [switch]$IncludeSubdirectories
    )

    $watcher = [System.IO.FileSystemWatcher]::new($Path, $Filter)
    $watcher.IncludeSubdirectories = $IncludeSubdirectories
    $watcher.EnableRaisingEvents = $true

    # イベントハンドラをScriptBlockで登録
    $action = {
        $event = $Event.SourceEventArgs
        $time  = $Event.TimeGenerated.ToString("HH:mm:ss")
        $changeType = $event.ChangeType
        $name = $event.Name

        switch ($changeType) {
            'Created' { Write-Host "[$time] ✅ 作成: $name" -ForegroundColor Green }
            'Changed' { Write-Host "[$time] 📝 変更: $name" -ForegroundColor Yellow }
            'Deleted' { Write-Host "[$time] 🗑  削除: $name" -ForegroundColor Red }
            'Renamed' { Write-Host "[$time] 📋 リネーム: $($event.OldName) → $name" -ForegroundColor Cyan }
        }
    }

    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action | Out-Null

    Write-Host "👁  ファイル監視開始: $Path ($Filter)" -ForegroundColor Cyan
    Write-Host "   停止するには: `$watcher.Dispose(); Get-EventSubscriber | Unregister-Event" -ForegroundColor Gray

    return $watcher
}

#endregion

# ============================================================
#region 11. クラス継承 + インターフェースパターン
# ============================================================
<#
    PowerShell classは継承とメソッドオーバーライドをサポートする。
    抽象基底クラスのようなパターンで「プロバイダー型」の設計が可能。
#>

class DataExporter {
    [string]$Name
    [string]$OutputPath

    DataExporter([string]$name, [string]$path) {
        $this.Name = $name
        $this.OutputPath = $path
    }

    # 基底メソッド（サブクラスでオーバーライド）
    [string] Export([PSCustomObject[]]$Data) {
        throw "Export()はサブクラスで実装してください"
    }

    # 共通ユーティリティ
    [void] EnsureDirectory() {
        $dir = Split-Path $this.OutputPath -Parent
        if ($dir -and -not (Test-Path $dir)) {
            $null = New-Item -Path $dir -ItemType Directory -Force
        }
    }
}

class CsvExporter : DataExporter {
    CsvExporter([string]$path) : base("CSV", $path) { }

    [string] Export([PSCustomObject[]]$Data) {
        $this.EnsureDirectory()
        $Data | Export-Csv -Path $this.OutputPath -NoTypeInformation -Encoding utf8
        return "✅ CSV出力: $($this.OutputPath) ($($Data.Count) rows)"
    }
}

class JsonExporter : DataExporter {
    [int]$Depth = 3

    JsonExporter([string]$path) : base("JSON", $path) { }

    [string] Export([PSCustomObject[]]$Data) {
        $this.EnsureDirectory()
        $Data | ConvertTo-Json -Depth $this.Depth | Out-File $this.OutputPath -Encoding utf8
        return "✅ JSON出力: $($this.OutputPath) ($($Data.Count) items)"
    }
}

class MarkdownExporter : DataExporter {
    MarkdownExporter([string]$path) : base("Markdown", $path) { }

    [string] Export([PSCustomObject[]]$Data) {
        $this.EnsureDirectory()
        $sb = [System.Text.StringBuilder]::new()
        $null = $sb.AppendLine("# Export Report")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("| $(($Data[0].PSObject.Properties.Name) -join ' | ') |")
        $null = $sb.AppendLine("| $(($Data[0].PSObject.Properties.Name | ForEach-Object { '---' }) -join ' | ') |")
        foreach ($row in $Data) {
            $vals = $row.PSObject.Properties.Value -join ' | '
            $null = $sb.AppendLine("| $vals |")
        }
        $sb.ToString() | Out-File $this.OutputPath -Encoding utf8
        return "✅ Markdown出力: $($this.OutputPath) ($($Data.Count) rows)"
    }
}

# ファクトリパターン
function New-Exporter {
    <#
    .SYNOPSIS
        フォーマットに応じた適切なExporterを返すファクトリ
    .EXAMPLE
        $exporter = New-Exporter -Format JSON -Path /tmp/out.json
        $exporter.Export(@([PSCustomObject]@{Name="Test";Value=42}))
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('CSV', 'JSON', 'Markdown')]
        [string]$Format,
        [string]$Path
    )

    switch ($Format) {
        'CSV'      { [CsvExporter]::new($Path) }
        'JSON'     { [JsonExporter]::new($Path) }
        'Markdown' { [MarkdownExporter]::new($Path) }
    }
}

#endregion

# ============================================================
#region 12. DSL（ドメイン固有言語）の実装
# ============================================================
<#
    PowerShellのScriptBlockを活用して、
    宣言的な構文を持つ「ミニ言語」を作れる。
    PesterのDescribe/It構文もこのパターン。
#>

function Deploy-Application {
    <#
    .SYNOPSIS
        デプロイ手順を宣言的に定義するDSL
    .EXAMPLE
        Deploy-Application "my-app" {
            Step "依存関係インストール" { Write-Host "npm install..." }
            Step "ビルド" { Write-Host "npm run build..." }
            Step "テスト" { Write-Host "npm test..." }
            Step "デプロイ" { Write-Host "rsync to server..." }
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$AppName,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$Definition
    )

    # DSL用の関数を定義
    function Step {
        param([string]$Name, [scriptblock]$Action)
        $script:steps += @{ Name = $Name; Action = $Action }
    }

    $script:steps = @()

    # DSLブロックを実行（Step関数が呼ばれてstepsに蓄積される）
    & $Definition

    Write-Host "`n🚀 Deploying: $AppName ($($script:steps.Count) steps)" -ForegroundColor Cyan
    Write-Host ("─" * 50) -ForegroundColor DarkGray

    $stepNum = 0
    foreach ($step in $script:steps) {
        $stepNum++
        Write-Host "[$stepNum/$($script:steps.Count)] $($step.Name)..." -NoNewline -ForegroundColor Yellow

        $timer = Measure-Command {
            try {
                & $step.Action
            }
            catch {
                Write-Host " ❌ FAILED" -ForegroundColor Red
                throw "Step '$($step.Name)' failed: $_"
            }
        }

        Write-Host " ✅ ($([math]::Round($timer.TotalMilliseconds))ms)" -ForegroundColor Green
    }

    Write-Host "`n🎉 Deploy complete: $AppName`n" -ForegroundColor Green
}

# 使用例:
# Deploy-Application "my-web-app" {
#     Step "環境チェック"    { $PSVersionTable.PSVersion }
#     Step "ディレクトリ作成" { New-Item -Path /tmp/deploy-test -ItemType Directory -Force }
#     Step "ファイルコピー"  { "hello" | Out-File /tmp/deploy-test/index.html }
#     Step "クリーンアップ"  { Remove-Item /tmp/deploy-test -Recurse -Force }
# }

#endregion

# ============================================================
#region 13. Proxy Function（既存コマンドの拡張）
# ============================================================
<#
    既存のコマンドレットをラップして、追加機能を注入するパターン。
    元のコマンドの全パラメータを透過的に引き継ぐ。
#>

function Get-ColoredChildItem {
    <#
    .SYNOPSIS
        Get-ChildItem の出力にファイル種別の色を付ける拡張版
    .EXAMPLE
        Get-ColoredChildItem ~
        Get-ColoredChildItem -Path /tmp -Recurse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = $PWD,

        [switch]$Recurse,
        [string]$Filter
    )

    # スプラッティングで元のコマンドにパラメータを転送
    $params = @{ Path = $Path }
    if ($Recurse) { $params['Recurse'] = $true }
    if ($Filter)  { $params['Filter'] = $Filter }

    Get-ChildItem @params -ErrorAction SilentlyContinue | ForEach-Object {
        $color = switch -Regex ($_.Extension) {
            '\.(ps1|psm1|sh|bash)$'  { 'Green' }
            '\.(md|txt|doc)$'        { 'Cyan' }
            '\.(json|yaml|yml|xml)$' { 'Yellow' }
            '\.(jpg|png|gif|svg)$'   { 'Magenta' }
            '\.(zip|tar|gz)$'        { 'Red' }
            default {
                if ($_.PSIsContainer) { 'Blue' } else { 'White' }
            }
        }

        $size = if (-not $_.PSIsContainer) {
            $val = $_.Length
            if ($val -ge 1GB) { "{0,8:N1} GB" -f ($val / 1GB) }
            elseif ($val -ge 1MB) { "{0,8:N1} MB" -f ($val / 1MB) }
            elseif ($val -ge 1KB) { "{0,8:N1} KB" -f ($val / 1KB) }
            else { "{0,8} B " -f $val }
        } else { "    <DIR> " }

        $icon = switch -Regex ($_.Extension) {
            '\.(ps1|psm1)$'  { '⚡' }
            '\.(sh|bash)$'   { '🐚' }
            '\.(md|txt)$'    { '📄' }
            '\.(json|yaml)$' { '⚙️' }
            '\.(jpg|png)$'   { '🖼 ' }
            default { if ($_.PSIsContainer) { '📁' } else { '📃' } }
        }

        Write-Host "$icon $size  " -NoNewline -ForegroundColor DarkGray
        Write-Host $_.Name -ForegroundColor $color
    }
}

#endregion

# ============================================================
#region 14. 動的パラメータ（DynamicParam）
# ============================================================
<#
    DynamicParamブロックを使うと、
    他のパラメータの値に応じてパラメータリストを動的に変更できる。
    例: -Format "JSON" の時だけ -Indent パラメータが出現する。
#>

function Export-Data {
    <#
    .SYNOPSIS
        動的パラメータのデモ — 形式に応じてオプションが変わる
    .EXAMPLE
        Export-Data -Format JSON -Indent 4 -Data @([PSCustomObject]@{A=1})
        Export-Data -Format CSV -Delimiter ";" -Data @([PSCustomObject]@{A=1})
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('JSON', 'CSV', 'XML')]
        [string]$Format,

        [Parameter(Mandatory)]
        [PSCustomObject[]]$Data
    )

    DynamicParam {
        $paramDict = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        if ($Format -eq 'JSON') {
            # -Indent パラメータを動的に追加
            $attr = [System.Management.Automation.ParameterAttribute]::new()
            $attr.HelpMessage = "JSONインデント幅"
            $validateAttr = [System.Management.Automation.ValidateRangeAttribute]::new(0, 8)
            $param = [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Indent', [int], [System.Collections.ObjectModel.Collection[System.Attribute]]@($attr, $validateAttr)
            )
            $param.Value = 2
            $paramDict.Add('Indent', $param)
        }

        if ($Format -eq 'CSV') {
            # -Delimiter パラメータを動的に追加
            $attr = [System.Management.Automation.ParameterAttribute]::new()
            $attr.HelpMessage = "CSV区切り文字"
            $param = [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Delimiter', [string], [System.Collections.ObjectModel.Collection[System.Attribute]]@($attr)
            )
            $param.Value = ','
            $paramDict.Add('Delimiter', $param)
        }

        return $paramDict
    }

    process {
        switch ($Format) {
            'JSON' {
                $indent = $PSBoundParameters['Indent'] ?? 2
                $Data | ConvertTo-Json -Depth 4
            }
            'CSV' {
                $delim = $PSBoundParameters['Delimiter'] ?? ','
                $Data | ConvertTo-Csv -Delimiter $delim -NoTypeInformation
            }
            'XML' {
                $Data | ConvertTo-Xml -As String -Depth 3
            }
        }
    }
}

#endregion

# ============================================================
#region メインメニュー
# ============================================================

function Start-AdvancedDemo {
    <#
    .SYNOPSIS
        全デモを対話的に実行するメニュー
    #>
    $demos = [ordered]@{
        '1'  = @{ Name = 'begin/process/end パイプライン';   Action = { "Hello World", "PowerShell is awesome", "", "Testing 1 2 3" | Measure-TextStats } }
        '2'  = @{ Name = 'ValueFromPipeline';              Action = { 1GB, 500MB, 1234, 42KB | ConvertTo-HumanSize | Format-Table } }
        '3'  = @{ Name = '複数パラメータセット';              Action = { Find-Item -Name "*.md" -Path $PSScriptRoot } }
        '5'  = @{ Name = 'Conditional Pipeline';           Action = { 1..15 | Invoke-ConditionalPipeline -Condition { $_ % 3 -eq 0 } } }
        '6a' = @{ Name = 'Invoke-Retry';                   Action = { Invoke-Retry { Get-Date } -MaxRetries 2 -Verbose } }
        '6b' = @{ Name = 'Closure Counter';                Action = { $c = New-Counter -Start 100; "1st: $(& $c)", "2nd: $(& $c)", "3rd: $(& $c)" } }
        '7'  = @{ Name = '.NET / LINQ';                    Action = { Invoke-LinqDemo } }
        '9'  = @{ Name = 'インラインC#';                    Action = { Invoke-CSharpDemo } }
        '11' = @{ Name = 'クラス継承 Exporter';             Action = {
            $data = @([PSCustomObject]@{Name="Alice";Score=95}, [PSCustomObject]@{Name="Bob";Score=82})
            $exporter = New-Exporter -Format JSON -Path /tmp/demo-export.json
            $exporter.Export($data)
        }}
        '12' = @{ Name = 'DSL デプロイ';                    Action = {
            Deploy-Application "demo-app" {
                Step "環境チェック"   { $PSVersionTable.PSVersion }
                Step "ファイル作成"   { "test" | Out-File /tmp/dsl-test.txt }
                Step "クリーンアップ" { Remove-Item /tmp/dsl-test.txt -Force }
            }
        }}
        '13' = @{ Name = 'Colored ls';                     Action = { Get-ColoredChildItem $HOME } }
    }

    Write-Host "`n⚡ PowerShell 上級テクニック デモ" -ForegroundColor Cyan
    Write-Host ("━" * 50) -ForegroundColor DarkGray

    foreach ($key in $demos.Keys) {
        Write-Host "  [$key] $($demos[$key].Name)" -ForegroundColor White
    }
    Write-Host "  [A] 全て実行" -ForegroundColor Yellow
    Write-Host "  [Q] 終了" -ForegroundColor DarkGray

    $choice = Read-Host "`n選択"

    if ($choice -eq 'A') {
        foreach ($key in $demos.Keys) {
            Write-Host "`n{'='*50}`n▶ $($demos[$key].Name)" -ForegroundColor Cyan
            & $demos[$key].Action
        }
    }
    elseif ($demos.ContainsKey($choice)) {
        & $demos[$choice].Action
    }
}

#endregion

# 使い方:
# . ./Advanced-Techniques.ps1   ← ドットソースで関数を読み込み
# Start-AdvancedDemo            ← メニュー起動
# または個別に:
# "Hello","World" | Measure-TextStats
# Invoke-CSharpDemo
# Invoke-LinqDemo
