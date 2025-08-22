# PowerShell script to fully automate Flutter APK release and update.json for app_updates repo
# Enhanced with patch update support

# Set variables
$projectRoot = "D:\ECCAT_PERSONAL_PROJECTS\app_project\app"
$updateRepo = "D:\ECCAT_PERSONAL_PROJECTS\app_updates"
$pubspec = "$projectRoot\pubspec.yaml"
$apkBaseUrl = "https://waytoo-average.github.io/app_updates"  # Update repo URL

# Helper Functions
function Create-PatchFile {
    param($versionNumber)
    
    $patchDir = "$projectRoot\temp_patch"
    $patchFile = "$projectRoot\patch-v$versionNumber.zip"
    
    # Create temp directory
    if (Test-Path $patchDir) {
        Remove-Item $patchDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $patchDir -Force | Out-Null
    
    # Copy patchable files (assets, configs)
    $patchableFiles = @()
    $sourceFiles = @(
        "lib\assets\*.json",
        "assets\**\*.*",
        "lib\l10n\*.arb"
    )
    
    foreach ($pattern in $sourceFiles) {
        $files = Get-ChildItem -Path "$projectRoot\$pattern" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($projectRoot.Length + 1)
            $destPath = Join-Path $patchDir $relativePath
            $destDir = Split-Path $destPath -Parent
            
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            Copy-Item $file.FullName $destPath -Force
            $patchableFiles += $relativePath
            Write-Host "  + $relativePath" -ForegroundColor Green
        }
    }
    
    if ($patchableFiles.Count -eq 0) {
        Write-Host "No patchable files found!" -ForegroundColor Yellow
        return $null
    }
    
    # Create ZIP file
    Push-Location $patchDir
    Compress-Archive -Path "*" -DestinationPath $patchFile -Force
    Pop-Location
    
    # Clean up temp directory
    Remove-Item $patchDir -Recurse -Force
    
    Write-Host "Patch file created: $patchFile ($($patchableFiles.Count) files)" -ForegroundColor Green
    return $patchFile
}

# Get version from pubspec.yaml
$versionLine = Get-Content $pubspec | Select-String '^version:' | Select-Object -First 1
$version = $versionLine -replace 'version:\s*', '' -replace '\s*#.*$', ''
$versionNumber = $version.Split('+')[0].Trim()

Write-Host "Detected version: $versionNumber" -ForegroundColor Yellow

# Ask for update type
Write-Host "`nUpdate Type Options:" -ForegroundColor Cyan
Write-Host "1. Full APK Update (recommended for code changes)"
Write-Host "2. Patch Update (for assets/config only)"
$updateChoice = Read-Host "Select update type (1-2)"

$updateType = if ($updateChoice -eq "2") { "patch" } else { "full" }
Write-Host "Selected: $updateType update" -ForegroundColor Yellow

if ($updateType -eq "full") {
    # Step 1: Build the APK
    Write-Host "`nBuilding APK..." -ForegroundColor Cyan
    Push-Location $projectRoot
    flutter build apk --release
    Pop-Location

    # Check if build was successful
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed! Please fix the errors and try again." -ForegroundColor Red
        exit 1
    }

    Write-Host "Build completed successfully!" -ForegroundColor Green

    # Compose APK filename and URL
    $apkFileName = "focus-zone-v$versionNumber.apk"
    $apkSource = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"
    $apkUrl = "$apkBaseUrl/$apkFileName"

    # Check if APK exists
    if (-not (Test-Path $apkSource)) {
        Write-Host "APK not found at: $apkSource" -ForegroundColor Red
        Write-Host "Please check the build output directory." -ForegroundColor Red
        exit 1
    }

    Write-Host "Found APK at: $apkSource" -ForegroundColor Green
    $apkSize = [math]::Round((Get-Item $apkSource).Length / 1MB, 1)
}

# Step 2: Prompt for changelog and mandatory flag
$changelog = Read-Host "`nEnter changelog (use \\n for new lines)"
$mandatoryInput = Read-Host "Is this update mandatory? (true/false)"

# Fix boolean parsing
$mandatory = $false
if ($mandatoryInput -eq "true" -or $mandatoryInput -eq "True" -or $mandatoryInput -eq "TRUE") {
    $mandatory = $true
}

# Step 3: Create update.json content based on type
if ($updateType -eq "full") {
    $json = @{
        latest_version = $versionNumber
        apk_url = $apkUrl
        update_type = "full"
        changelog = $changelog
        mandatory = $mandatory
        size_mb = $apkSize
    } | ConvertTo-Json
} else {
    # Create patch file
    Write-Host "`nCreating patch file..." -ForegroundColor Cyan
    $patchFile = Create-PatchFile $versionNumber
    
    if (-not $patchFile) {
        Write-Host "Failed to create patch file! Falling back to full APK update." -ForegroundColor Yellow
        $updateType = "full"
        # Build APK as fallback
        Push-Location $projectRoot
        flutter build apk --release
        Pop-Location
        
        $apkFileName = "focus-zone-v$versionNumber.apk"
        $apkSource = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"
        $apkUrl = "$apkBaseUrl/$apkFileName"
        $apkSize = [math]::Round((Get-Item $apkSource).Length / 1MB, 1)
        
        $json = @{
            latest_version = $versionNumber
            apk_url = $apkUrl
            update_type = "full"
            changelog = $changelog
            mandatory = $mandatory
            size_mb = $apkSize
        } | ConvertTo-Json
    } else {
        $patchFileName = "patch-v$versionNumber.zip"
        $patchUrl = "$apkBaseUrl/$patchFileName"
        $patchSize = [math]::Round((Get-Item $patchFile).Length / 1MB, 1)
        
        $json = @{
            latest_version = $versionNumber
            patch_url = $patchUrl
            update_type = "patch"
            changelog = $changelog
            mandatory = $mandatory
            size_mb = $patchSize
        } | ConvertTo-Json
    }
}

# Write to update.json in project root
$updateJsonPath = "$projectRoot\update.json"
$json | Set-Content -Path $updateJsonPath -Encoding UTF8
Write-Host "update.json created at $updateJsonPath"

# Step 4: Copy files to update repo
# Check if update repo exists
if (-not (Test-Path $updateRepo)) {
    Write-Host "Update repo not found at: $updateRepo" -ForegroundColor Red
    Write-Host "Please clone the app_updates repo to this location first." -ForegroundColor Red
    exit 1
}

$updateJsonDest = "$updateRepo\update.json"

if ($updateType -eq "full") {
    $apkDest = "$updateRepo\$apkFileName"
    Copy-Item $apkSource $apkDest -Force
    Write-Host "Copied $apkFileName to $updateRepo" -ForegroundColor Green
    $filesToCommit = @($apkFileName, "update.json")
} else {
    $patchDest = "$updateRepo\$patchFileName"
    Copy-Item $patchFile $patchDest -Force
    Remove-Item $patchFile -Force  # Clean up local patch file
    Write-Host "Copied $patchFileName to $updateRepo" -ForegroundColor Green
    $filesToCommit = @($patchFileName, "update.json")
}

Copy-Item $updateJsonPath $updateJsonDest -Force
Write-Host "Copied update.json to $updateRepo" -ForegroundColor Green

# Step 4.5: Copy APK to focus-zone-website assets (for full updates only)
if ($updateType -eq "full") {
    $websiteAssetsDir = "D:\ECCAT_PERSONAL_PROJECTS\focus-zone-website\assets"
    
    # Check if website assets directory exists
    if (Test-Path $websiteAssetsDir) {
        $websiteApkDest = "$websiteAssetsDir\$apkFileName"
        Copy-Item $apkSource $websiteApkDest -Force
        Write-Host "Copied $apkFileName to focus-zone-website assets" -ForegroundColor Green
    } else {
        Write-Host "Warning: focus-zone-website assets directory not found at: $websiteAssetsDir" -ForegroundColor Yellow
        Write-Host "Skipping website assets copy." -ForegroundColor Yellow
    }
}

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
    # Add specific files
    foreach ($file in $filesToCommit) {
        git add $file
    }
    
    $sizeText = if ($updateType -eq "full") { "$apkSize MB" } else { "$patchSize MB" }
    $commitMsg = "Release v$versionNumber ($updateType update - $sizeText)"
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

# Summary
Write-Host "`n=== Release Complete ===" -ForegroundColor Green
Write-Host "Version: $versionNumber" -ForegroundColor Cyan
Write-Host "Type: $updateType update" -ForegroundColor Cyan
if ($updateType -eq "full") {
    Write-Host "Size: $apkSize MB" -ForegroundColor Cyan
    Write-Host "File: $apkFileName" -ForegroundColor Cyan
} else {
    Write-Host "Size: $patchSize MB" -ForegroundColor Cyan
    Write-Host "File: $patchFileName" -ForegroundColor Cyan
}
Write-Host "Mandatory: $mandatory" -ForegroundColor Cyan
Write-Host "Changelog: $changelog" -ForegroundColor Cyan 