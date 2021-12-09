
@rem ----------------------
@rem @name		jar-service
@rem @author	jiangKlijna
@rem ----------------------
@echo off

set ServiceName=%1

for /f "tokens=2 " %%a in ('tasklist /SVC ^|findstr "%ServiceName%"') do taskkill /t /f /pid %%a
