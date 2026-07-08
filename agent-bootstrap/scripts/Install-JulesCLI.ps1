[CmdletBinding()]
param()

$npmCheck = Get-Command "npm" -ErrorAction SilentlyContinue

if ($npmCheck) {
    Write-Host "Installing Jules CLI (@google/jules)..."
    npm install -g @google/jules
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Jules CLI installed successfully."
    } else {
        throw "Failed to install Jules CLI. Exit code: $LASTEXITCODE"
    }
} else {
    Write-Warning "npm is not installed on this system. Jules CLI cannot be installed via npm."
    Write-Warning "Graceful fallback: You can continue using the REST API integration without the CLI."
}
