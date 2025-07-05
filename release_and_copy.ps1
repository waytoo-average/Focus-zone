# PowerShell script to fully automate Flutter APK release and update.json for app_updates repo

# Set variables
$projectRoot = "D:\ECCAT_PERSONAL_PROJECTS\app_project\app"
$updateRepo = "D:\ECCAT_PERSONAL_PROJECTS\app_updates"
$pubspec = "$projectRoot\pubspec.yaml"
$apkBaseUrl = "https://waytoo-average.github.io/app_updates"  # Update repo URL

# Step 1: Build the APK
Write-Host "Building APK..."
Push-Location $projectRoot
$buildResult = flutter build apk --release
Pop-Location

# Check if build was successful
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please fix the errors and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Build completed successfully!" -ForegroundColor Green

# Get version from pubspec.yaml - Fixed parsing
$versionLine = Get-Content $pubspec | Select-String '^version:' | Select-Object -First 1
$version = $versionLine -replace 'version:\s*', '' -replace '\s*#.*$', ''  # Remove comments
$versionNumber = $version.Split('+')[0].Trim()  # Only use the X.Y.Z part and trim whitespace

Write-Host "Detected version: $versionNumber" -ForegroundColor Yellow

# Compose APK filename and URL
$apkFileName = "focus-zone-v$versionNumber.apk"
$apkSource = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"  # Use the default name
$apkUrl = "$apkBaseUrl/$apkFileName"

# Check if APK exists
if (-not (Test-Path $apkSource)) {
    Write-Host "APK not found at: $apkSource" -ForegroundColor Red
    Write-Host "Please check the build output directory." -ForegroundColor Red
    exit 1
}

Write-Host "Found APK at: $apkSource" -ForegroundColor Green

# Step 2: Prompt for changelog and mandatory flag
$changelog = Read-Host "Enter changelog (use \\n for new lines)"
$mandatoryInput = Read-Host "Is this update mandatory? (true/false)"

# Fix boolean parsing
$mandatory = $false
if ($mandatoryInput -eq "true" -or $mandatoryInput -eq "True" -or $mandatoryInput -eq "TRUE") {
    $mandatory = $true
}

# Step 3: Create update.json content
$json = @{
    latest_version = $versionNumber
    apk_url = $apkUrl
    changelog = $changelog
    mandatory = $mandatory
} | ConvertTo-Json

# Write to update.json in project root
$updateJsonPath = "$projectRoot\update.json"
$json | Set-Content -Path $updateJsonPath -Encoding UTF8
Write-Host "update.json created at $updateJsonPath"

# Step 4: Copy APK and update.json to update repo
$apkDest = "$updateRepo\$apkFileName"
$updateJsonDest = "$updateRepo\update.json"

# Check if update repo exists
if (-not (Test-Path $updateRepo)) {
    Write-Host "Update repo not found at: $updateRepo" -ForegroundColor Red
    Write-Host "Please clone the app_updates repo to this location first." -ForegroundColor Red
    exit 1
}

Copy-Item $apkSource $apkDest -Force
Copy-Item $updateJsonPath $updateJsonDest -Force
Write-Host "Copied $apkFileName and update.json to $updateRepo"

# Step 5: Commit and push in update repo
Push-Location $updateRepo

# Check if this is the first commit
$firstCommit = $false
try {
    git log --oneline -1 | Out-Null
} catch {
    $firstCommit = $true
}

if ($firstCommit) {
    Write-Host "First commit detected. Initializing repository..." -ForegroundColor Yellow
    git add .
    git commit -m "Initial commit - Release v$versionNumber"
} else {
    git add $apkFileName update.json
    $commitMsg = "Release v$versionNumber"
    git commit -m $commitMsg
}

# Try to push with authentication handling
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
try {
    git push origin main
    Write-Host "Successfully pushed to main branch" -ForegroundColor Green
} catch {
    Write-Host "Failed to push to main branch. Trying master..." -ForegroundColor Yellow
    try {
        git push origin master
        Write-Host "Successfully pushed to master branch" -ForegroundColor Green
    } catch {
        Write-Host "Push failed. You may need to configure Git authentication." -ForegroundColor Red
        Write-Host "Options:" -ForegroundColor Yellow
        Write-Host "1. Use Personal Access Token: git remote set-url origin https://username:token@github.com/waytoo-average/app_updates.git" -ForegroundColor Yellow
        Write-Host "2. Use SSH: git remote set-url origin git@github.com:waytoo-average/app_updates.git" -ForegroundColor Yellow
        Write-Host "3. Use GitHub CLI: gh auth login" -ForegroundColor Yellow
        Write-Host "Files are ready in $updateRepo - you can push manually." -ForegroundColor Green
    }
}

Pop-Location

Write-Host "Release process complete! APK and update.json are ready." -ForegroundColor Green 