Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$DocumentsFolder = [Environment]::GetFolderPath("MyDocuments")
$BaseFolder = Join-Path $DocumentsFolder "Unrailed Backuper"
$SaveFolder = "$env:USERPROFILE\AppData\Local\Daedalic Entertainment GmbH\Unrailed\GameState\AllPlayers\SaveGames"
$BackupFolder = Join-Path $BaseFolder "Backups"

New-Item -ItemType Directory -Force -Path $BackupFolder | Out-Null

$counter = 1
$lastSignature = ""

function Get-WatchedSaveFiles {
    Get-ChildItem $SaveFolder -Filter "*.sav" -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '^SLOT([1-9]|10)\.sav$' -or
        $_.Name -match '^AUTO\.sav$'
    }
}

function Get-SaveSignature {
    $files = Get-WatchedSaveFiles | Sort-Object Name

    if ($null -eq $files) {
        return ""
    }

    ($files | ForEach-Object {
        "$($_.Name)|$($_.LastWriteTimeUtc.Ticks)|$($_.Length)"
    }) -join ";"
}

function Get-SaveNamesFromSignature {
    param ([string]$Signature)

    if ([string]::IsNullOrWhiteSpace($Signature)) {
        return @()
    }

    return $Signature.Split(";") | ForEach-Object {
        $_.Split("|")[0]
    }
}

function Set-Status {
    param ([string]$Text)
    $script:statusLabel.Text = $Text
}

function Backup-AllSlotSaves {
    Start-Sleep -Milliseconds 800

    $files = Get-WatchedSaveFiles

    if ($null -eq $files -or $files.Count -eq 0) {
        Set-Status "No SLOT save files found. Backup skipped."
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $checkpointFolder = Join-Path $BackupFolder "Checkpoint_$($script:counter.ToString('000'))_$timestamp"

    New-Item -ItemType Directory -Force -Path $checkpointFolder | Out-Null

    $files | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $checkpointFolder $_.Name) -Force
    }

    Set-Status "Backup saved: Checkpoint_$($script:counter.ToString('000'))_$timestamp"
    $script:counter++
}

function Restore-LatestSave {
    param ([string]$SaveName)

    $latestBackup = Get-ChildItem $BackupFolder -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            Test-Path (Join-Path $_.FullName $SaveName)
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $latestBackup) {
        Set-Status "No backup found for $SaveName"
        return
    }

    $sourcePath = Join-Path $latestBackup.FullName $SaveName
    $targetPath = Join-Path $SaveFolder $SaveName

    Copy-Item $sourcePath $targetPath -Force

    Set-Status "Restored $SaveName from $($latestBackup.Name)"
    $script:lastSignature = Get-SaveSignature
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Unrailed Backuper"
$form.Size = New-Object System.Drawing.Size(420, 280)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$title = New-Object System.Windows.Forms.Label
$title.Text = "Unrailed Backuper"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 15)
$title.Size = New-Object System.Drawing.Size(360, 30)
$form.Controls.Add($title)

$x = 25
$y = 65

for ($i = 1; $i -le 10; $i++) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "SLOT$i"
    $button.Tag = $i
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size(65, 35)

    $button.Add_Click({
        $slot = $this.Tag
        Restore-LatestSave -SaveName "SLOT$slot.sav"
    })

    $form.Controls.Add($button)

    $x += 70

    if ($i -eq 5) {
        $x = 25
        $y = 105
    }
}

$backupButton = New-Object System.Windows.Forms.Button
$backupButton.Text = "Create slot backup now"
$backupButton.Location = New-Object System.Drawing.Point(25, 165)
$backupButton.Size = New-Object System.Drawing.Size(170, 35)
$backupButton.Add_Click({
    Backup-AllSlotSaves
    $script:lastSignature = Get-SaveSignature
})
$form.Controls.Add($backupButton)

$folderButton = New-Object System.Windows.Forms.Button
$folderButton.Text = "Open backup folder"
$folderButton.Location = New-Object System.Drawing.Point(205, 165)
$folderButton.Size = New-Object System.Drawing.Size(170, 35)
$folderButton.Add_Click({
    Start-Process explorer.exe $BackupFolder
})
$form.Controls.Add($folderButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Starting..."
$statusLabel.Location = New-Object System.Drawing.Point(25, 215)
$statusLabel.Size = New-Object System.Drawing.Size(350, 40)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$form.Controls.Add($statusLabel)

Backup-AllSlotSaves
$lastSignature = Get-SaveSignature

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 700

$timer.Add_Tick({
    $currentSignature = Get-SaveSignature

    $oldNames = Get-SaveNamesFromSignature -Signature $script:lastSignature
    $newNames = Get-SaveNamesFromSignature -Signature $currentSignature

    $deletedOnly = $false

    if ($script:lastSignature -ne "" -and $currentSignature -ne $script:lastSignature) {
        $deletedNames = $oldNames | Where-Object { $_ -notin $newNames }
        $changedOrAddedNames = $newNames | Where-Object { $_ -notin $oldNames }

        if ($deletedNames.Count -gt 0 -and $changedOrAddedNames.Count -eq 0) {
            $deletedOnly = $true
        }
    }

    if ($currentSignature -ne "" -and $currentSignature -ne $script:lastSignature -and -not $deletedOnly) {
        $script:lastSignature = $currentSignature
        Backup-AllSlotSaves
        $script:lastSignature = Get-SaveSignature
    }

    if ($deletedOnly) {
        $script:lastSignature = $currentSignature
        Set-Status "Slot deletion detected. Backup skipped."
    }
})

$timer.Start()

$form.Add_FormClosed({
    $timer.Stop()
})

[System.Windows.Forms.Application]::Run($form)