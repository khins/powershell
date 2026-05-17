# lesson4_pipeline_export_csv_json.ps1

Write-Host "=== EXPORT PROCESS REPORTS ==="

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

# Export CSV
$report | Export-Csv `
    -Path ".\process_report.csv" `
    -NoTypeInformation

# Export JSON
$report | ConvertTo-Json | Set-Content ".\process_report.json"

Write-Host "Reports exported."