type sql-dev-2017.ps1 | powershell -c -
call SQL-Express-2017-Updated.cmd 
call SQL-Express-2016-Updated.cmd
call SQL-Express-2014-SP1.cmd
call SQL-Express-2012-SP3.cmd
call SQL-Express-2008-R2-SP2-x86.cmd
call SQL-Express-2008-SP3-x64.cmd 
call SQL-Express-2005-SP4-x86.cmd

call SSMS-Setup.cmd

type list-sql-services.ps1 | powershell -c -
