[Setup]
AppName=Unrailed Backuper
AppVersion=1.0
DefaultDirName={autopf}\Unrailed Backuper
DefaultGroupName=Unrailed Backuper
OutputDir=Output
OutputBaseFilename=UnrailedBackuperSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
UninstallDisplayName=Unrailed Backuper

[Files]
Source: "Files\unrailed-watcher.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Files\unrailed-restore-window.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Files\start-unrailed-watcher-hidden.vbs"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{userdocs}\Unrailed Backuper"
Name: "{userdocs}\Unrailed Backuper\Backups"

[Icons]
Name: "{group}\Start Unrailed Backuper"; Filename: "wscript.exe"; Parameters: """{app}\start-unrailed-watcher-hidden.vbs"""
Name: "{group}\Uninstall Unrailed Backuper"; Filename: "{uninstallexe}"

[Tasks]
Name: "autostart"; Description: "Start Unrailed Backuper automatically with Windows"; GroupDescription: "Startup options:"; Flags: unchecked

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Unrailed Backuper"; ValueData: "wscript.exe ""{app}\start-unrailed-watcher-hidden.vbs"""; Tasks: autostart

[Run]
Filename: "wscript.exe"; Parameters: """{app}\start-unrailed-watcher-hidden.vbs"""; Description: "Start Unrailed Backuper now"; Flags: nowait postinstall skipifsilent