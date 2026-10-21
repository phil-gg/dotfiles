Set WinScriptHost = CreateObject("WScript.Shell")
WinScriptHost.Run "wsl.exe -d Debian -- bash -lic 'sps'", 0, False
