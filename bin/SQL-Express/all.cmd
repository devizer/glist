@echo off
call windows-version-vars-apply.cmd

If Defined IS_WINDOWS_6_1_OR_ABOVE (
  netsh advfirewall firewall add rule name="All ICMP V4" protocol=icmpv4:any,any dir=in action=allow
  netsh advfirewall firewall add rule name="Open Port 1433 (SQL Servers)" dir=in action=allow protocol=TCP localport=1433
) Else (
  netsh firewall set icmpsetting type=ALL mode=enable
  netsh firewall add portopening TCP 1433 "Open Port 1433 (SQL Servers)"
)

If Defined IS_WINDOWS_6_2_OR_ABOVE (If Defined IS_X64_WINDOWS (
  title [1/10] SQL Server 2017 Developer Edition
  type sql-dev-2017.ps1 | powershell -c -
))

If Defined IS_WINDOWS_6_2_OR_ABOVE (If Defined IS_X64_WINDOWS (
  title [2/10] SQL Server 2017 Express
  call SQL-Express-2017-Updated.cmd 
))

If Defined IS_WINDOWS_6_2_OR_ABOVE (If Defined IS_X64_WINDOWS (
  title [3/10] SQL Server 2016 Express
  call SQL-Express-2016-Updated.cmd
))

If Defined IS_WINDOWS_6_0_OR_ABOVE (
  title [4/10] SQL Server 2014 x86 Express
  call SQL-Express-2014-SP2-x86.cmd
)

If Defined IS_WINDOWS_6_0_OR_ABOVE (If Defined IS_X64_WINDOWS (
  title [5/10] SQL Server 2014 Express
  call SQL-Express-2014-SP1.cmd
))

If Defined IS_WINDOWS_6_0_OR_ABOVE (If Defined IS_X64_WINDOWS (
  title [6/10] SQL Server 2012 Express
  call SQL-Express-2012-SP3.cmd
))

title [7/10] SQL Server 2008 R2 x86 Express
call SQL-Express-2008-R2-SP2-x86.cmd

If Defined IS_X64_WINDOWS (
  title [8/10] SQL Server 2008 Express
  call SQL-Express-2008-SP3-x64.cmd 
)

title [9/10] SQL Server 2005 Express x86
call SQL-Express-2005-SP4-x86.cmd

title [10/10] SQL Server Managment Studio 2016/2017
call SSMS-Setup.cmd

type list-sql-services.ps1 | powershell -c -
