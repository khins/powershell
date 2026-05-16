# process_monitor_lesson1.ps1

Write-Host "=== PROCESS MONITOR ==="

$processes = Get-Process

Write-Host "Total processes running:" $processes.Count

$processes | Select-Object -First 10