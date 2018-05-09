get-wmiobject win32_service | where {$_.Name.ToLower().IndexOf("sql") -ge 0 } | ft Name, DisplayName, StartMode, State
