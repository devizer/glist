get-wmiobject win32_service | where {$_.Name.ToLower().IndexOf("sql") -ge 0 } | sort-object -Property "DisplayName" | ft Name, DisplayName, StartMode, State
