[Setup]
AppName=Unrailed Backuper
AppVersion=1.0.0
DefaultDirName={localappdata}\Unrailed Backuper
DefaultGroupName=Unrailed Backuper
OutputDir=..\dist
OutputBaseFilename=UnrailedBackuperSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
UninstallDisplayName=Unrailed Backuper

[Files]
Source: "..\files\unrailed-watcher.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\files\unrailed-restore-window.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\files\start-unrailed-watcher-hidden.vbs"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{userdocs}\Unrailed Backuper"
Name: "{userdocs}\Unrailed Backuper\Backups"

[Icons]
Name: "{group}\Start Unrailed Backuper"; Filename: "wscript.exe"; Parameters: """{app}\start-unrailed-watcher-hidden.vbs"""
Name: "{group}\Uninstall Unrailed Backuper"; Filename: "{uninstallexe}"

[Tasks]
Name: "autostart"; Description: "Start Unrailed Backuper with Windows"; GroupDescription: "Startup options:"; Flags: checkedonce

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Unrailed Backuper"; ValueData: "wscript.exe ""{app}\start-unrailed-watcher-hidden.vbs"""; Tasks: autostart

[Run]
Filename: "wscript.exe"; Parameters: """{app}\start-unrailed-watcher-hidden.vbs"""; Description: "Start Unrailed Backuper now"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userdocs}\Unrailed Backuper\Backups"