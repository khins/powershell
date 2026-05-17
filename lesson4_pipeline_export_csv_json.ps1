# lesson4_pipeline_export_csv_json.ps1

Write-Host "=== EXPORT PROCESS REPORTS ==="

# Concept 1 — Capture Pipeline Output
$report = Get-Process |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 10 `
        @{
            Name = "ProcessName"
            Expression = { $_.Name }
        },
        @{
            Name = "PID"
            Expression = { $_.Id }
        },
        @{
            Name = "CPUSeconds"
            Expression = {
                [math]::Round($_.CPU, 2)
            }
        },
        @{
            Name = "MemoryMB"
            Expression = {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        }

# Preview in console
$report

# Export CSV, Concept 2 — Export CSV
$report | Export-Csv `
    -Path ".\process_report.csv" `
    -NoTypeInformation

# Export JSON, Concept 3 — Convert JSON
# Concept 4 — Write File
# Pretty print: using ConvertTo-Json with -Depth parameter to handle nested objects and arrays
# Concept 5 — Relative Paths by using set-content with a relative path
$report | ConvertTo-Json | Set-Content ".\process_report.json"

Write-Host "Reports exported."

# Read It Back
Write-Host "=== READ BACK REPORTS ==="
# Read CSV
$csvReport = Import-Csv ".\process_report.csv"
$csvReport

# now print content of csvReport
Write-Host "=== CSV REPORT CONTENT ==="
$csvReport | Format-Table

# now print content of jsonReport
Write-Host "=== JSON REPORT CONTENT ==="
get-content ".\process_report.json" | ConvertFrom-Json

# Practice Drills
# Export only processes over 300MB:
Write-Host "=== PROCESSES USING MORE THAN 300MB RAM ==="
Get-Process |
    Where-Object { $_.WorkingSet -gt 300MB } |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 10 `
        Name,
        Id,
        @{
            Name = "MemoryMB"
            Expression = {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        } |
    Export-Csv -Path ".\process_report_over_300mb.csv" -NoTypeInformation

# Drill 2 create services_report.csv with Name, Status, StartType, and IsRunning (boolean if status is Running)
Write-Host "=== SERVICE REPORT ==="
Get-Service |
    Select-Object `
        Name,
        Status,
        StartType,
        @{
            Name = "IsRunning"
            Expression = { $_.Status -eq "Running" }
        } |
    Export-Csv -Path ".\services_report.csv" -NoTypeInformation

# Drill 3

# Create JSON file of top CPU consumers.
Write-Host "=== TOP CPU CONSUMERS ==="
Get-Process |
    Sort-Object CPU -Descending |
    Select-Object -First 10 `
        Name,
        Id,
        @{
            Name = "CPUSeconds"
            Expression = {
                [math]::Round($_.CPU, 2)
            }
        },
        @{
            Name = "MemoryMB"
            Expression = {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        } |
    ConvertTo-Json | Set-Content ".\top_cpu_consumers.json"

# Mini Challenge

# Build:

# heavy_processes.csv

# Requirements:

# memory > 500MB
# sort descending
# columns:
# ProcessName
# PID
# MemoryMB
# CPUSeconds

write-host "=== HEAVY PROCESSES REPORT > 500 MB==="
Get-Process |
    Where-Object { $_.WorkingSet -gt 500MB } |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 10 `
        @{
            Name = "ProcessName"
            Expression = { $_.Name }
        },
        @{
            Name = "PID"
            Expression = { $_.Id }
        },
        @{
            Name = "MemoryMB"
            Expression = {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        },
        @{
            Name = "CPUSeconds"
            Expression = {
                [math]::Round($_.CPU, 2)
            }
        } |
    Export-Csv -Path ".\heavy_processes.csv" -NoTypeInformation
