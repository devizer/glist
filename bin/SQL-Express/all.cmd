call SQL-Express-2005-SP4-x86.cmd
call SQL-Express-2008-R2-SP2-x86.cmd
call SQL-Express-2008-x64.cmd
call SQL-Express-2012-SP3.cmd
call SQL-Express-2014-SP1.cmd
rem  TODO: SQL 2016
call SQL-Express-2017-Updated.cmd 

echo get-wmiobject win32_service ^| where {$_.Name.ToLower().IndexOf("sql") -ge 0 } ^| ft Name, DisplayName, StartMode, State | powershell -c -
