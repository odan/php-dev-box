<#
  - Must run as Administrator
  - Requires PowerShell 5.0+
#>

# -----------------------------
# Variables: Adjust as needed
# -----------------------------
$apacheUrl = "https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250207-win64-VS17.zip"
$phpUrl = "https://windows.php.net/downloads/releases/php-8.4.5-Win32-vs17-x64.zip"
#$mysqlUrl = "https://dev.mysql.com/get/Downloads/MySQL-9.2/mysql-9.2.0-winx64.zip"
$mysqlUrl = "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-8.4.4-winx64.zip"
$xdebugUrl = "https://xdebug.org/files/php_xdebug-3.4.2-8.4-ts-vs17-x86_64.dll"
$browsCapUrl = "https://browscap.org/stream?q=Lite_PHP_BrowsCapINI"
$caCertificateUrl = "https://curl.se/ca/cacert.pem"

$xamppRoot = "C:\xampp"
$apacheDir = "$xamppRoot\apache"
$phpDir = "$xamppRoot\php"
$mySqlDir = "$xamppRoot\mysql"
$tempDir = "$xamppRoot\tmp"
$phpIniFile = "$phpDir\php.ini"
$mySqlIniFile = "$mySqlDir\bin\my.ini"
$htdocsDir = "$xamppRoot\htdocs"
$startUrl = "http://localhost"

# Windows temp folder
$tempFolder = $env:TEMP

# Derive local ZIP filenames from the URLs, stored in temp
$apacheZip = Join-Path $tempFolder ([System.IO.Path]::GetFileName($apacheUrl))
$phpZip = Join-Path $tempFolder ([System.IO.Path]::GetFileName($phpUrl))
$mySqlZip = Join-Path $tempFolder ([System.IO.Path]::GetFileName($mysqlUrl))

# The path to httpd.conf
$httpdConf = Join-Path $apacheDir "conf\httpd.conf"

# Ask the user
$installMySql = Read-Host "Should MySql be installed? (y/n)"
$installXdebug = Read-Host "Should Xdebug be installed? (y/n)"

# -----------------------------
# Ensure the directories exist
# -----------------------------
if (Test-Path $xamppRoot) {
    Write-Host "The path $xamppRoot already exists"
    Exit 1
}

if (-not (Test-Path $xamppRoot)) {
    Write-Host "Creating $xamppRoot ..."
    New-Item -Path $xamppRoot -ItemType Directory | Out-Null
}

if (-not (Test-Path $htdocsDir)) {
    Write-Host "Creating directory: $htdocsDir"
    New-Item -ItemType Directory -Path $htdocsDir | Out-Null
}

if (-not (Test-Path $tempDir)) {
    Write-Host "Creating directory: $tempDir"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# -----------------------------
# Apache
# -----------------------------
Write-Host "`nDownloading Apache from $apacheUrl using curl ..."
Invoke-Expression "curl.exe -L `"$apacheUrl`" -o `"$apacheZip`""

# Check if the Apache ZIP actually exists
if (-not (Test-Path $apacheZip)) {
    Write-Host "ERROR: Apache ZIP did not download correctly: $apacheZip"
    exit 1
}

Write-Host "`nExtracting Apache to $apacheDir ..."
if (Test-Path $apacheDir) {
    Write-Host "Removing existing Apache folder: $apacheDir"
    Remove-Item -Recurse -Force $apacheDir
}
Expand-Archive -Path $apacheZip -DestinationPath $xamppRoot -Force

# The ZIP might extract to C:\xampp\Apache24; rename if found
$extractedApache = Join-Path $xamppRoot "Apache24"
if (Test-Path $extractedApache) {
    Rename-Item $extractedApache "apache"
}

# Remove the downloaded Apache ZIP
Remove-Item $apacheZip -Force
Remove-Item -Path "$xamppRoot\ReadMe.txt" -Force
Remove-Item -Path "$xamppRoot\-- Win64 VS17  --" -Force

# Confirm Apache was extracted
if (-not (Test-Path $apacheDir)) {
    Write-Host "ERROR: Apache folder not found at $apacheDir after extraction."
    exit 1
}

<# 
# OPTIONAL: If you want to install as a Windows service, uncomment:

# Write-Host "Installing Apache as 'ApacheXAMPP' service..."
# & "$apacheDir\bin\httpd.exe" -k install -n "ApacheXAMPP"

# Write-Host "Starting ApacheXAMPP service..."
# Start-Service -Name "ApacheXAMPP"
#>

# Modify httpd.conf
if (-not (Test-Path $httpdConf)) {
    Write-Host "`nERROR: The httpd.conf file was not found at $httpdConf."
    exit 1
}

Write-Host "`nModifying $httpdConf ..."
$backupConf = $httpdConf + ".bak"
if (-not (Test-Path $backupConf)) {
    Copy-Item $httpdConf $backupConf
    Write-Host "Created backup: $backupConf"
}
else {
    Write-Host "Backup already exists: $backupConf"
}

$lines = Get-Content $backupConf
$newLines = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {

    # Define SRVROOT and XROOT
    if ($line -match '^\s*Define\s+SRVROOT') {
        $newLines.Add('Define SRVROOT "c:/xampp/apache"') | Out-Null
        $newLines.Add('Define XROOT "c:/xampp"') | Out-Null
        continue
    }

    # Replace DocumentRoot
    if ($line -eq 'DocumentRoot "${SRVROOT}/htdocs"') {
        $newLines.Add('DocumentRoot "${XROOT}/htdocs"') | Out-Null
        continue
    }

    # Replace first <Directory ...> with <Directory "${XROOT}/htdocs">
    if ($line -eq '<Directory "${SRVROOT}/htdocs">') {
        $newLines.Add('<Directory "${XROOT}/htdocs">') | Out-Null
        continue
    }

    if ($line -eq '#ServerName www.example.com:80') {
        $newLines.Add('ServerName localhost:80') | Out-Null
        continue
    }

    # Enable mod_rewrite
    if ($line -eq '#LoadModule rewrite_module modules/mod_rewrite.so') {
        $newLines.Add('LoadModule rewrite_module modules/mod_rewrite.so') | Out-Null
        continue
    }

    # Keep all other lines
    $newLines.Add($line) | Out-Null
}

# Find the <Directory "${XROOT}/htdocs"> block and replace AllowOverride
$content = [regex]::Replace(
    $content,
    '(<Directory\s+"(?:\$\{XROOT\}|\\$\{XROOT\})/htdocs">.*?)(AllowOverride\s+)(None)',
    '${1}${2}All',
    'Singleline'
)

# Append PHP config lines
$newLines.Add('') | Out-Null
$newLines.Add('# ------------------------------------') | Out-Null
$newLines.Add('# PHP 8.x Configuration') | Out-Null
$newLines.Add("LoadModule php_module `"$phpDir\php8apache2_4.dll`"") | Out-Null
$newLines.Add('AddHandler application/x-httpd-php .php') | Out-Null
$newLines.Add("PHPIniDir `"$phpDir`"") | Out-Null
$newLines.Add('DirectoryIndex index.php index.html') | Out-Null
$newLines.Add('# ------------------------------------') | Out-Null

# Write the modified lines to httpd.conf
$newLines | Out-File -Encoding UTF8 $httpdConf
Write-Host "httpd.conf has been updated."

# -----------------------------
# PHP
# -----------------------------
Write-Host "`nDownloading PHP from $phpUrl ..."
Invoke-Expression "curl.exe -L `"$phpUrl`" -o `"$phpZip`""

if (-not (Test-Path $phpZip)) {
    Write-Host "ERROR: PHP ZIP did not download correctly: $phpZip"
    exit 1
}

Write-Host "`nExtracting PHP to $phpDir ..."
if (Test-Path $phpDir) {
    Write-Host "Removing existing PHP folder: $phpDir"
    Remove-Item -Recurse -Force $phpDir
}

New-Item -Path $phpDir -ItemType Directory | Out-Null
Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force

# Remove the downloaded PHP ZIP
Remove-Item $phpZip -Force

# Confirm PHP was extracted
if (-not (Test-Path $phpDir)) {
    Write-Host "ERROR: PHP folder not found at $phpDir after extraction."
    exit 1
}

Write-Host "`nDownloading browscap.ini"
Invoke-Expression "curl.exe -L `"$browsCapUrl`" -o `"$phpDir\extras\browscap.ini`""

Write-Host "`nDownloading CA certificates"
Invoke-Expression "curl.exe -L `"$caCertificateUrl`" -o `"$apacheDir\bin\curl-ca-bundle.crt`""

# Configure php.ini
Rename-Item -Path "$phpDir\php.ini-development" -NewName "$phpDir\php.ini"

$content = Get-Content "$phpDir\php.ini"
$content = $content -replace '^;include_path = "\.:/php/includes"$', 'include_path = "."'
$content = $content -replace '^;extension_dir = "ext"$', 'extension_dir = "\xampp\php\ext"'
$content = $content -replace '^;upload_tmp_dir =$', 'upload_tmp_dir = "\xampp\tmp"'
$content = $content -replace '^;extension=bz2$', 'extension=bz2'
$content = $content -replace '^;extension=curl$', 'extension=curl'
$content = $content -replace '^;extension=fileinfo$', 'extension=fileinfo'
$content = $content -replace '^;extension=gd$', 'extension=gd'
$content = $content -replace '^;extension=intl$', 'extension=intl'
$content = $content -replace '^;extension=mbstring$', 'extension=mbstring'
$content = $content -replace '^;extension=mysqli$', 'extension=mysqli'
$content = $content -replace '^;extension=pdo_mysql$', 'extension=pdo_mysql'
$content = $content -replace '^;extension=pdo_sqlite$', 'extension=pdo_sqlite'
$content = $content -replace '^;extension=zip$', 'extension=zip'
$content = $content -replace '^;browscap = extra/browscap.ini$', 'browscap = "\xampp\php\extras\browscap.ini"'
$content = $content -replace '^;session.save_path = "/tmp"$', 'session.save_path = "\xampp\tmp"'
$content = $content -replace '^;curl.cainfo =$', 'curl.cainfo = "\xampp\apache\bin\curl-ca-bundle.crt"'

# Write the updated content back to the file
$content | Set-Content "$phpDir\php.ini"

# Create a simple PHP file
$indexPhp = Join-Path $htdocsDir "index.php"
"<?php phpinfo();" | Set-Content -Path $indexPhp -Encoding UTF8

Write-Host "A new index.php has been created at $indexPhp"

# -----------------------------
# Xdebug
# -----------------------------
if ($installXdebug -eq 'y') {
    # Download the Xdebug DLL
    Write-Host "Downloading Xdebug..."
    $xdebugFilePath = "$phpDir\ext\php_xdebug.dll"
    Invoke-Expression "curl.exe -L `"$xdebugUrl`" -o `"$xdebugFilePath`""

    Write-Host "Creating Xdebug settings"

    $xdebugConfig = @(
        "",
        "[Xdebug]",
        "zend_extension=xdebug",
        "xdebug.mode=debug",
        "xdebug.start_with_request=trigger"
    )

    if (-not (Test-Path $phpIniFile)) {
        Write-Host "ERROR: Cannot find php.ini at $phpIniFile."
        exit 1
    }

    Add-Content -Path $phpIniFile -Value $xdebugConfig

    Write-Host "XDebug installation successfully"
}

# -----------------------------
# MySql
# -----------------------------
if ($installMySql) {
    # Download MySQL
    Write-Host "Downloading MySQL..."
    Invoke-Expression "curl.exe -L `"$mysqlUrl`" -o `"$mysqlZip`""

    if (-not (Test-Path $mysqlZip)) {   
        Write-Host "ERROR: MySQL ZIP did not download correctly: $mysqlZip"
        exit 1
    }

    New-Item -Path $mysqlDir -ItemType Directory | Out-Null
    # Expand-Archive -Path $mysqlZip -DestinationPath $mysqlDir -Force
    tar -xf $mysqlZip --strip-components=1 -C $mysqlDir

    # Remove the downloaded MySQL ZIP
    Remove-Item $mysqlZip -Force

    # Confirm MySQL was extracted
    if (-not (Test-Path $mysqlDir)) {
        Write-Host "ERROR: MySQL folder not found at $mysqlDir after extraction."
        exit 1
    }

    Write-Host "Creating MySql settings"

    $mySqlConfig = @(
        "[mysqld]",
        "basedir=c:/xampp/mysql",
        "datadir=c:/xampp/mysql/data",
        "innodb_buffer_pool_size=1024M",
        "",
        "[client]",
        "ssl-mode=DISABLED"
    )

    Add-Content -Path $mySqlIniFile -Value $mySqlConfig

    # Initializing the data directory
    New-Item -Path "C:\xampp\mysql\bin\data" -ItemType Directory -Force | Out-Null

    # Initialize the MySQL data directory
    $exePath = "$mysqlDir\bin\mysqld.exe"
    $workingDir = "$mysqlDir\bin"
    $mySqlArgs = '--initialize-insecure=on --basedir="C:\xampp\mysql" --datadir="C:\xampp\mysql\data"'

    Start-Process -FilePath $exePath `
        -WorkingDirectory $workingDir `
        -ArgumentList $mySqlArgs `
        -NoNewWindow `
        -Wait

    Write-Host "MySQL data directory has been initialized."
    Write-Host "MySql installation successfully"
}

Write-Host "`n==============================================="
Write-Host " Installation completed successfully!"
Write-Host "==============================================="

# Start the control panel
.\xampp-control.ps1

