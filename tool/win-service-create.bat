
@rem ----------------------
@rem @name		jar-service
@rem @author	jiangKlijna
@rem ----------------------
@echo off
set BAT_PATH=%cd%

set ServiceName=%1
set exe_path=%~f2
set dir_name=%~dp2

echo ServiceName = %ServiceName%
echo dir_name = %dir_name%
echo exe_path = %exe_path%

"%BAT_PATH%\instsrv.exe" "%ServiceName%" "%BAT_PATH%\srvany.exe"
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServiceName%\Parameters
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServiceName%\Parameters /v AppDirectory /t REG_SZ /d "%dir_name%"
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServiceName%\Parameters /v Application /t REG_SZ /d "%exe_path%"
echo regist [%ServiceName%] system service success!
