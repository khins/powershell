# lesson8_pipeline_error_handling_resilient_queries.ps1

Write-Host "=== RESILIENT PROCESS REPORT ==="

# Concept 5 — Array Accumulation to collect results even if some items fail, allowing the pipeline to complete and return partial results instead of failing entirely.
$report = @()

Get-Process | ForEach-Object {

    # Concept 1 — try/catch for error handling
    try {

        $cpu =
            if ($null -eq $_.CPU) {
                0
            }
            else {
                [math]::Round($_.CPU, 2)
            }

            # Concept 4 — Null Safety with conditional logic to handle missing properties
        $memoryMB =
            if ($null -eq $_.WorkingSet) {
                0
            }
            else {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }

            # Concept 2 — Nested try/catch for specific properties that may throw
        $startTime =
            try {
                $_.StartTime
            }
            catch {
                "ACCESS_DENIED"
            }

        $report += [PSCustomObject]@{
            ProcessName = $_.Name
            PID         = $_.Id
            CPUSeconds  = $cpu
            MemoryMB    = $memoryMB
            StartTime   = $startTime
        }

    }
    # Concept 3 — Write-Warning to log issues without stopping the pipeline
    catch {
        Write-Warning "Failed processing process $($_.Name)"
    }
}

$report |
    Sort-Object MemoryMB -Descending |
    Select-Object -First 15

# -------------------------------
# SQLITE PERSISTENCE
# -------------------------------

# Store the database beside this lesson file so the script does not depend on
# folders like C:\sqlite or C:\PowerShell\process-monitor already existing.
$dbPath = Join-Path $PSScriptRoot "process_health.db"

$sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue

if (-not $sqlite) {
    Write-Host "SQLite CLI was not found. PowerShell is looking for a command named sqlite3." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Install option:"
    Write-Host "  winget install SQLite.SQLite"
    Write-Host ""
    Write-Host "After installing, close and reopen PowerShell, then run this lesson again."
    return
}

$sqlitePath = $sqlite.Source

if ($sqlitePath -like "*\Microsoft\WinGet\Links\sqlite3.exe") {
    $wingetSqlite = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter sqlite3.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*SQLite.SQLite*" } |
        Select-Object -First 1

    if ($wingetSqlite) {
        $sqlitePath = $wingetSqlite.FullName
    }
}

$createTableSql = @"
CREATE TABLE IF NOT EXISTS process_health (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    process_name TEXT,
    pid INTEGER,
    cpu_seconds REAL,
    memory_mb REAL,
    start_time TEXT,
    collected_at TEXT
);
"@

& $sqlitePath $dbPath $createTableSql

# Insert report rows
foreach ($row in $report) {
    $processName = $row.ProcessName.Replace("'", "''")
    $startTime =
        if ($null -eq $row.StartTime) {
            "UNKNOWN"
        }
        else {
            $row.StartTime.ToString().Replace("'", "''")
        }

    $collectedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $insertSql = @"
INSERT INTO process_health
(
    process_name,
    pid,
    cpu_seconds,
    memory_mb,
    start_time,
    collected_at
)
VALUES
(
    '$processName',
    $($row.PID),
    $($row.CPUSeconds),
    $($row.MemoryMB),
    '$startTime',
    '$collectedAt'
);
"@

    & $sqlitePath $dbPath $insertSql
}

Write-Host "SQLite persistence complete."
Write-Host "Database path: $dbPath"

Write-Host ""
Write-Host "=== RECENT ROWS ==="
& $sqlitePath $dbPath @"
SELECT
    process_name,
    pid,
    memory_mb,
    start_time,
    collected_at
FROM process_health
ORDER BY id DESC
LIMIT 15;
"@
