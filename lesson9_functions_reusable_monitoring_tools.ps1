# lesson9_functions_reusable_monitoring_tools.ps1
# Concepts Introduced
# Functions

# Reusable commands:

Write-Host "=== LESSON 9 MONITORING TOOLKIT ==="

# -------------------------------
# SQLITE CONFIG
# -------------------------------
$dbPath = Join-Path $PSScriptRoot "process_health.db"

function Get-SqlitePath {
    $sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue

    if (-not $sqlite) {
        Write-Host "SQLite CLI was not found. PowerShell is looking for a command named sqlite3." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Install option:"
        Write-Host "  winget install SQLite.SQLite"
        Write-Host ""
        Write-Host "After installing, close and reopen PowerShell, then run this lesson again."
        return $null
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

    return $sqlitePath
}

# -------------------------------
# DATABASE INIT
# -------------------------------
function Initialize-Database {
    param(
        [string]$DatabasePath,
        [string]$SqlitePath
    )

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

    & $SqlitePath $DatabasePath $createTableSql
}

# -------------------------------
# PROCESS COLLECTION
# -------------------------------
function Get-ProcessHealth {
    $report = @()

    Get-Process | ForEach-Object {

        try {
            $cpu =
                if ($null -eq $_.CPU) {
                    0
                }
                else {
                    [math]::Round($_.CPU, 2)
                }

            $memoryMB =
                if ($null -eq $_.WorkingSet) {
                    0
                }
                else {
                    [math]::Round($_.WorkingSet / 1MB, 2)
                }

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
        catch {
            Write-Warning "Failed processing process $($_.Name)"
        }
    }

    return $report
}

# -------------------------------
# SAVE TO SQLITE
# -------------------------------
function Save-ProcessReport {
    param(
        [array]$Report,
        [string]$DatabasePath,
        [string]$SqlitePath
    )

    foreach ($row in $Report) {
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

        & $SqlitePath $DatabasePath $insertSql
    }
}

# -------------------------------
# QUERY SQLITE
# -------------------------------
function Get-TopSavedProcesses {
    param(
        [string]$DatabasePath,
        [string]$SqlitePath
    )

    $querySql = @"
SELECT process_name, pid, memory_mb, cpu_seconds
FROM process_health
ORDER BY memory_mb DESC
LIMIT 10;
"@

    & $SqlitePath -csv $DatabasePath $querySql |
        ConvertFrom-Csv -Header "ProcessName", "PID", "MemoryMB", "CPUSeconds"
}

# -------------------------------
# MAIN EXECUTION
# -------------------------------
$sqlitePath = Get-SqlitePath

if (-not $sqlitePath) {
    return
}

Initialize-Database -DatabasePath $dbPath -SqlitePath $sqlitePath

$report = Get-ProcessHealth

$report |
    Sort-Object MemoryMB -Descending |
    Select-Object -First 10

Save-ProcessReport -Report $report -DatabasePath $dbPath -SqlitePath $sqlitePath

Write-Host "`n=== TOP SAVED SQLITE RECORDS ==="

Get-TopSavedProcesses -DatabasePath $dbPath -SqlitePath $sqlitePath
