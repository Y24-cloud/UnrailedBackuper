Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$BaseFolder = "C:\Users\Yannick\Documents\Unrailed Backuper"
$GameProcessName = "UnrailedGameEpic"
$RestoreScript = Join-Path $BaseFolder "unrailed-restore-window.ps1"
$VbsLauncher = Join-Path $BaseFolder "start-unrailed-watcher-hidden.vbs"
$StartupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Unrailed Backuper.lnk"

$restoreProcess = $null
$wasGameRunning = $false

function Test-AutostartEnabled {
    return Test-Path $StartupShortcut
}

function Enable-Autostart {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($StartupShortcut)
    $shortcut.TargetPath = $VbsLauncher
    $shortcut.WorkingDirectory = $BaseFolder
    $shortcut.IconLocation = "powershell.exe,0"
    $shortcut.Save()
}

function Disable-Autostart {
    if (Test-Path $StartupShortcut) {
        Remove-Item $StartupShortcut -Force
    }
}

function Restart-Watcher {
    if ($script:restoreProcess -ne $null -and -not $script:restoreProcess.HasExited) {
        Stop-Process -Id $script:restoreProcess.Id -Force
    }

    Start-Process wscript.exe "`"$VbsLauncher`""

    $script:notifyIcon.Visible = $false
    $script:notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
}

function Exit-Watcher {
    if ($script:restoreProcess -ne $null -and -not $script:restoreProcess.HasExited) {
        Stop-Process -Id $script:restoreProcess.Id -Force
    }

    $script:notifyIcon.Visible = $false
    $script:notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
}

function Update-AutostartMenuText {
    if (Test-AutostartEnabled) {
        $script:autostartItem.Text = "Autostart: An"
    } else {
        $script:autostartItem.Text = "Autostart: Aus"
    }
}

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Text = "Unrailed Backuper"
$notifyIcon.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip

$statusItem = $menu.Items.Add("Status: wartet auf Unrailed")
$statusItem.Enabled = $false

$menu.Items.Add("-") | Out-Null

$restartItem = $menu.Items.Add("Neustarten")
$autostartItem = $menu.Items.Add("Autostart: Aus")
$exitItem = $menu.Items.Add("Beenden")

$notifyIcon.ContextMenuStrip = $menu

Update-AutostartMenuText

$restartItem.Add_Click({
    Restart-Watcher
})

$autostartItem.Add_Click({
    if (Test-AutostartEnabled) {
        Disable-Autostart
    } else {
        Enable-Autostart
    }

    Update-AutostartMenuText
})

$exitItem.Add_Click({
    Exit-Watcher
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

$timer.Add_Tick({
    $gameRunning = $null -ne (Get-Process -Name $GameProcessName -ErrorAction SilentlyContinue)

    if ($gameRunning -and -not $script:wasGameRunning) {
        $script:restoreProcess = Start-Process powershell.exe `
            -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$RestoreScript`"" `
            -WindowStyle Hidden `
            -PassThru

        $script:wasGameRunning = $true
        $script:statusItem.Text = "Status: Unrailed läuft"
        $script:notifyIcon.Text = "Unrailed Backuper läuft"
    }

    if (-not $gameRunning -and $script:wasGameRunning) {
        if ($script:restoreProcess -ne $null -and -not $script:restoreProcess.HasExited) {
            Stop-Process -Id $script:restoreProcess.Id -Force
        }

        $script:restoreProcess = $null
        $script:wasGameRunning = $false
        $script:statusItem.Text = "Status: wartet auf Unrailed"
        $script:notifyIcon.Text = "Unrailed Backuper"
    }
})

$timer.Start()
[System.Windows.Forms.Application]::Run()