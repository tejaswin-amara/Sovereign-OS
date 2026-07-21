# scan_bloat.ps1 - Scan for large uncommitted, untracked, binary or bloat files
param (
    [string]$Root = "C:\Skills",
    [long]$SizeThresholdBytes = 500000 # 500 KB threshold
)

Write-Output "=== 1. UNTRACKED FILES IN GIT ==="
$untracked = git -C $Root ls-files --others --exclude-standard
if ($untracked) {
    foreach ($u in $untracked) {
        $item = Get-Item -Path (Join-Path $Root $u) -ErrorAction SilentlyContinue
        if ($item) {
            Write-Output ("UNTRACKED: {0} ({1:N2} KB)" -f $u, ($item.Length / 1KB))
        } else {
            Write-Output ("UNTRACKED DIR/FILE: {0}" -f $u)
        }
    }
} else {
    Write-Output "No untracked files (excluding .agents metadata)."
}

Write-Output "`n=== 2. IGNORED FILES IN GIT ==="
$ignored = git -C $Root ls-files --others --ignored --exclude-standard
if ($ignored) {
    foreach ($ig in $ignored) {
        $item = Get-Item -Path (Join-Path $Root $ig) -ErrorAction SilentlyContinue
        if ($item) {
            Write-Output ("IGNORED: {0} ({1:N2} KB)" -f $ig, ($item.Length / 1KB))
        }
    }
} else {
    Write-Output "No ignored files found by git ls-files."
}

Write-Output "`n=== 3. ALL FILES LARGER THAN 500KB IN REPO ==="
$largeFiles = Get-ChildItem -Path $Root -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Length -gt $SizeThresholdBytes }
if ($largeFiles) {
    foreach ($lf in $largeFiles) {
        $relPath = $lf.FullName.Replace("$Root\", "")
        $trackedStatus = git -C $Root ls-files $relPath
        $isTracked = if ($trackedStatus) { "TRACKED" } else { "UNTRACKED/IGNORED" }
        Write-Output ("LARGE FILE ({0}): {1} ({2:N2} MB)" -f $isTracked, $relPath, ($lf.Length / 1MB))
    }
} else {
    Write-Output "No files larger than 500KB found."
}

Write-Output "`n=== 4. BINARY EXTENSION FILE SCAN ==="
$binExtensions = "*.exe","*.dll","*.bin","*.zip","*.tar","*.gz","*.7z","*.iso","*.so","*.dylib","*.node","*.pyc"
$binFiles = Get-ChildItem -Path $Root -Recurse -File -Include $binExtensions | Where-Object { $_.FullName -notmatch '\\\.git\\' }
if ($binFiles) {
    foreach ($bf in $binFiles) {
        $relPath = $bf.FullName.Replace("$Root\", "")
        $trackedStatus = git -C $Root ls-files $relPath
        $isTracked = if ($trackedStatus) { "TRACKED" } else { "UNTRACKED/IGNORED" }
        Write-Output ("BINARY FILE ({0}): {1} ({2:N2} KB)" -f $isTracked, $relPath, ($bf.Length / 1KB))
    }
} else {
    Write-Output "No binary executable/archive files found."
}
