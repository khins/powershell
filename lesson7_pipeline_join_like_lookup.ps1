# lesson7_pipeline_join_like_lookup.ps1
# Mental Model: Join/Lookup in Pipelines
# Concept 1 — Join/Lookup, combining data from two sources based on a common key
# SELECT
#     p.process_name,
#     p.pid,
#     c.category
# FROM processes p
# JOIN categories c
#    ON p.process_name = c.process_name
# PowerShell equivalent
# Sample data sources

Write-Host "=== PROCESS INVENTORY TO SQLITE ==="

# SQLite database path
# $PSScriptRoot means "the folder this script lives in".
$dbPath = Join-Path $PSScriptRoot "process_inventory.db"

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

# Process category lookup
$processCategoryLookup = @{
    "chrome"         = "Browser"
    "msedge"         = "Browser"
    "firefox"        = "Browser"
    "Code"           = "IDE"
    "devenv"         = "IDE"
    "powershell"     = "Shell"
    "pwsh"           = "Shell"
    "explorer"       = "Windows"
    "Creative Cloud" = "Adobe"
}

$createTableSql = @"
CREATE TABLE IF NOT EXISTS process_inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    process_name TEXT,
    pid INTEGER,
    cpu_seconds REAL,
    memory_mb REAL,
    category TEXT,
    collected_at TEXT
);
"@

# Create table
& $sqlite.Source $dbPath $createTableSql

# Extract + enrich + persist
Get-Process |
    Select-Object -First 20 |
    ForEach-Object {

        $category =
            if ($processCategoryLookup.ContainsKey($_.Name)) {
                $processCategoryLookup[$_.Name]
            }
            else {
                "Unknown"
            }

        $cpu =
            if ($null -eq $_.CPU) {
                0
            }
            else {
                [math]::Round($_.CPU, 2)
            }

        $memoryMB = [math]::Round($_.WorkingSet / 1MB, 2)

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $processName = $_.Name.Replace("'", "''")
        $safeCategory = $category.Replace("'", "''")

        $insertSql = @"
INSERT INTO process_inventory
(
    process_name,
    pid,
    cpu_seconds,
    memory_mb,
    category,
    collected_at
)
VALUES
(
    '$processName',
    $($_.Id),
    $cpu,
    $memoryMB,
    '$safeCategory',
    '$timestamp'
);
"@

        & $sqlite.Source $dbPath $insertSql
    }

Write-Host "Process inventory persisted to SQLite."
Write-Host "Database path: $dbPath"

Write-Host ""
Write-Host "=== RECENT ROWS ==="
& $sqlite.Source $dbPath @"
SELECT
    process_name,
    pid,
    memory_mb,
    category,
    collected_at
FROM process_inventory
ORDER BY id DESC
LIMIT 15;
"@

