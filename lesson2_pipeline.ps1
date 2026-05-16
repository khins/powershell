# lesson2_pipeline.ps1 Pipeline Fundamentals
write-host "=== PIPELINE FUNDAMENTALS ==="
# Get all processes, sort by CPU usage, and select the top 5
# The Pipe Operator (|) takes the output of one command and passes it as input to the next command
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

# Find top 10 processes using more than 500MB RAM.
Get-Process | Where-Object { $_.WorkingSet -gt 500MB } | Sort-Object WorkingSet -Descending | Select-Object -First 10