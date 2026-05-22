# lesson6_pipeline_grouping_aggregation.ps1
# aggregation + summarization

# Think SQL:

# GROUP BY
# COUNT()
# SUM()
# AVG()
# MAX()

Write-Host "=== PROCESS ANALYTICS REPORT ==="

# Concept 1 — Group-Object, group processes by memory usage tier (HIGH, MEDIUM, LOW) based on calculated MemoryMB property
# Concept 2 — Sort-Object, sort groups by count of processes in each tier
# Concept 3 — Select-Object, select group name (MemoryTier) and count of processes in each tier for final report output
# concept 4 — Custom Grouping Logic, define custom grouping logic using calculated properties and conditional statements to categorize processes into memory usage tiers
Get-Process |
    ForEach-Object {

        $memoryMB = [math]::Round($_.WorkingSet / 1MB, 2)

        $memoryTier =
            if ($memoryMB -gt 1000) {
                "CRITICAL"
            }
            elseif ($memoryMB -gt 500) {
                "HIGH"
            }
            elseif ($memoryMB -gt 200) {
                "MEDIUM"
            }
            else {
                "LOW"
            }

        [PSCustomObject]@{
            ProcessName = $_.Name
            MemoryMB    = $memoryMB
            MemoryTier  = $memoryTier
        }
    } |
    Group-Object MemoryTier |
    Sort-Object Count -Descending |
    Select-Object Name, Count

write-host "=== TOP MEMORY CONSUMERS BY NAME ==="
    Get-Process |
    ForEach-Object {
        [PSCustomObject]@{
            Name      = $_.Name
            MemoryMB  = [math]::Round($_.WorkingSet / 1MB, 2)
        }
    } |
    Where-Object {$_.MemoryMB -gt 200} |
    Group-Object Name |
    Sort-Object Count -Descending