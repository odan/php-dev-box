Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Adjust these paths if needed
$apachePath = "C:\xampp\apache\bin"
$mysqlPath  = "C:\xampp\mysql\bin"

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "XAMPP Control Panel"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false

# Label for Apache status
$labelApache = New-Object System.Windows.Forms.Label
$labelApache.Location = New-Object System.Drawing.Point(30, 20)
$labelApache.Size = New-Object System.Drawing.Size(350, 20)
$labelApache.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$labelApache.Text = "Apache Status: Checking..."
$form.Controls.Add($labelApache)

# Button for Apache start/stop
$buttonApache = New-Object System.Windows.Forms.Button
$buttonApache.Location = New-Object System.Drawing.Point(30, 50)
$buttonApache.Size = New-Object System.Drawing.Size(80, 30)
$buttonApache.Text = "Start"
$form.Controls.Add($buttonApache)

# Label for MySQL status
$labelMySQL = New-Object System.Windows.Forms.Label
$labelMySQL.Location = New-Object System.Drawing.Point(30, 100)
$labelMySQL.Size = New-Object System.Drawing.Size(350, 20)
$labelMySQL.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$labelMySQL.Text = "MySQL Status: Checking..."
$form.Controls.Add($labelMySQL)

# Button for MySQL start/stop
$buttonMySQL = New-Object System.Windows.Forms.Button
$buttonMySQL.Location = New-Object System.Drawing.Point(30, 130)
$buttonMySQL.Size = New-Object System.Drawing.Size(80, 30)
$buttonMySQL.Text = "Start"
$form.Controls.Add($buttonMySQL)

# List box for logging events at the bottom
$logBox = New-Object System.Windows.Forms.ListBox
$logBox.Location = New-Object System.Drawing.Point(30, 180)
$logBox.Size = New-Object System.Drawing.Size(530, 160)
$form.Controls.Add($logBox)

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
function Is-ApacheRunning {
    Get-Process -Name "httpd" -ErrorAction SilentlyContinue | Out-Null
    return ($? -eq $true)
}

function Is-MySQLRunning {
    Get-Process -Name "mysqld" -ErrorAction SilentlyContinue | Out-Null
    return ($? -eq $true)
}

function Update-Status {
    # Apache
    if (Is-ApacheRunning) {
        $labelApache.Text = "Apache Status: Running"
        $buttonApache.Text = "Stop"
    } else {
        $labelApache.Text = "Apache Status: Stopped"
        $buttonApache.Text = "Start"
    }

    # MySQL
    if (Is-MySQLRunning) {
        $labelMySQL.Text = "MySQL Status: Running"
        $buttonMySQL.Text = "Stop"
    } else {
        $labelMySQL.Text = "MySQL Status: Stopped"
        $buttonMySQL.Text = "Start"
    }
}

function Log-Event($msg) {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $logBox.Items.Add("[${timestamp}] $msg")
    # Auto-scroll to the latest log entry
    $logBox.TopIndex = $logBox.Items.Count - 1
}

# ------------------------------------------------------------------------------
# Timer to poll the status periodically
# ------------------------------------------------------------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000 # 2 seconds
$timer.Add_Tick({
    Update-Status
})
$timer.Start()

# ------------------------------------------------------------------------------
# Event Handler: Start/Stop Apache
# ------------------------------------------------------------------------------
$buttonApache.Add_Click({
    # Disable the button for to prevent rapid clicks
    $buttonApache.Enabled = $false

    try {
        if (Is-ApacheRunning) {
            Log-Event "Stopping Apache..."
            Get-Process -Name "httpd" -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        else {
            Log-Event "Starting Apache..."
            Start-Process "$apachePath\httpd.exe" -WindowStyle Hidden
        }
    }
    catch {
        # Log the exception
        Log-Event "Error controlling Apache: $_"
    }

    Start-Sleep -Seconds 1
    Update-Status

    if (Is-ApacheRunning) {
        Log-Event "Apache is running"
   } else {
       Log-Event "Apache is stopped"
   }

    $buttonApache.Enabled = $true
})

# ------------------------------------------------------------------------------
# Event Handler: Start/Stop MySQL
# ------------------------------------------------------------------------------
$buttonMySQL.Add_Click({
    # Disable the button for 2 seconds
    $buttonMySQL.Enabled = $false

    try {
        if (Is-MySQLRunning) {
            Log-Event "Stopping MySQL..."
            $exePath = "$mysqlPath\mysqladmin.exe"
            $mySqlArgs = '-u root shutdown'
        
            Start-Process -FilePath $exePath `
                        -WorkingDirectory $mysqlPath `
                        -ArgumentList $mySqlArgs `
                        -NoNewWindow `
                        -Wait

            Get-Process -Name "mysqld" -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        else {
            Log-Event "Starting MySQL..."
            Start-Process "$mysqlPath\mysqld.exe" -WindowStyle Hidden
        }
    }
    catch {
        # Log the exception
        Log-Event "Error controlling MySQL: $_"
    }

    Start-Sleep -Seconds 1
    Update-Status

    if (Is-MySQLRunning) {
         Log-Event "MySQL is running"
    } else {
        Log-Event "MySQL is stopped"
    }

    $buttonMySQL.Enabled = $true
})

# ------------------------------------------------------------------------------
# Initialize and Show Form
# ------------------------------------------------------------------------------
Update-Status
[void] $form.ShowDialog()
