Set WshShell = CreateObject("WScript.Shell")
InstallFolder = WshShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\Unrailed Backuper"
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & InstallFolder & "\unrailed-watcher.ps1""", 0, False