# lesson3_pipeline_custom_objects.ps1, Pipeline with Custom Objects
write-host "=== PIPELINE WITH CUSTOM OBJECTS ==="
# Create a custom object for a process with selected properties
# Concept 1 — Select-Object Projection
Get-Process |
    Sort-Object CPU -Descending |
    Select-Object -First 10 `
        Name,
        Id,
        CPU,
        @{
            # Concept 2 — Hashtable Syntax (Think dictionary / map: key-value pairs)
            Name = "MemoryMB"
            # Concept 3 — Expression Block (Script block that calculates a value)
            Expression = {
                # Concept 4 — $_ is the current object in the pipeline (the process object)
                #Still the pipeline current object.
                # Concept 5 — 1MB Constant (1MB = 1 * 1024 * 1024 bytes)
                # Concept 6 — Static .NET Method Call (Calling a method on a .NET class without creating an instance)
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        }

# Only processes over 500MB:
Write-Host "=== PROCESSES USING MORE THAN 500MB RAM ==="
Get-Process |
    Where-Object { $_.WorkingSet -gt 500MB } |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 10 `
        Name,
        Id,
        @{
            Name = "MemoryMB"
            Expression = {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        }

# Build service report:
Write-Host "====================="
Write-Host "=== SERVICE REPORT ==="
Get-Service |
    Select-Object `
        Name,
        Status,
        StartType,
        @{
            Name = "IsRunning"
            Expression = { $_.Status -eq "Running" }
        }

# TOP MEMORY CONSUMERS:
Write-Host "====================="
Write-Host "=== TOP MEMORY CONSUMERS ==="
Get-Process |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 10 `
        Name,
        Id,
        @{
            Name = "MemoryMB"
            Expression = {
                [math]::Round($_.WorkingSet / 1MB, 2)
            }
        }