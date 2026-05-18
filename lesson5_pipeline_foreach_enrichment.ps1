# lesson5_pipeline_foreach_enrichment.ps1

Write-Host "=== PROCESS ENRICHMENT REPORT ==="

# Concept 1 — ForEach-Object, for each object in pipeline, run code block
Get-Process |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 10 |
    ForEach-Object {

        # Concept 2 — Temporary Variables, store intermediate values for enrichment calculations
        $memoryMB = [math]::Round($_.WorkingSet / 1MB, 2)
        $cpuSecs  = [math]::Round($_.CPU, 2)

        # Concept 3 — Conditional Logic, enrich data with new calculated property based on condition
        $memoryStatus =
            if ($memoryMB -gt 500) {
                "HIGH"
            }
            else {
                "NORMAL"
            }

            # Concept 4 — PSCustomObject, create a new custom object with enriched properties for output
        [PSCustomObject]@{
            ProcessName  = $_.Name
            PID          = $_.Id
            CPUSeconds   = $cpuSecs
            MemoryMB     = $memoryMB
            MemoryStatus = $memoryStatus
        }
    }

# Risk calculation example:
Get-Process |
ForEach-Object {

    $cpu = [math]::Round($_.CPU, 2)

    $risk =
        if ($cpu -gt 200) {
            "CRITICAL"
        }
        elseif ($cpu -gt 50) {
            "WARNING"
        }
        else {
            "NORMAL"
        }

    [PSCustomObject]@{
        Name = $_.Name
        CPU = $cpu
        Risk = $risk
    }
}

# CpuStatus
# Rules:
# 200 = HIGH
# 50 = MEDIUM
# else LOW
get-process |
    ForEach-Object {
        $cpu = [math]::Round($_.CPU, 2)

        $cpuStatus =
            if ($cpu -gt 200) {
                "HIGH"
            }
            elseif ($cpu -gt 50) {
                "MEDIUM"
            }
            else {
                "LOW"
            }

        [PSCustomObject]@{
            Name = $_.Name
            CPU = $cpu
            CpuStatus = $cpuStatus
        }
    }

# ThreadCount
# Rules:
# 100 = HIGH
# 20 = MEDIUM
# else LOW
write-host "=== THREAD COUNT ENRICHMENT ==="
get-process |
    ForEach-Object {
        $threads = $_.Threads.Count

        $threadStatus =
            if ($threads -gt 100) {
                "HIGH"
            }
            elseif ($threads -gt 20) {
                "MEDIUM"
            }
            else {
                "LOW"
            }

        [PSCustomObject]@{
            Name = $_.Name
            Threads = $threads
            ThreadStatus = $threadStatus
        }
    }

#Filter only HIGH memory processes.
write-host "=== HIGH MEMORY PROCESSES ==="
get-process |
    ForEach-Object {
        $memoryMB = [math]::Round($_.WorkingSet / 1MB, 2)

        if ($memoryMB -gt 500) {
            [PSCustomObject]@{
                ProcessName = $_.Name
                PID         = $_.Id
                MemoryMB    = $memoryMB
            }
        }
    }