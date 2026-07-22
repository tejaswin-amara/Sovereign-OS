$p = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\Skills\.agents\worker_m3\hold_lock.ps1" -PassThru
Write-Host "Started background lock holder PID: $($p.Id)"
Start-Sleep -Milliseconds 1500

Write-Host "Executing sovereign.ps1 while lock is held..."
try {
    $output = powershell.exe -ExecutionPolicy Bypass -File C:\Skills\sovereign.ps1 2>&1
    Write-Host "Sovereign output:"
    Write-Host $output
    Write-Host "Exit code: $LASTEXITCODE"
} catch {
    Write-Host "Caught error: $_"
}

Wait-Process -Id $p.Id
Write-Host "Background process exited."
