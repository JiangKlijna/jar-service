
@rem ----------------------
@rem @name		jar-service
@rem @author	jiangKlijna
@rem ----------------------
@echo off

set BAT_PATH=%cd%

@rem match method
if "%1" == "install" (
    call:jarServiceIntall %2
) else if "%1" == "remove" (
    call:jarServiceRemove %2
) else if "%1" == "regist" (
    call:jarServiceRegist %2
) else if "%1" == "unreg" (
    call:jarServiceUnreg %2
) else if "%1" == "start" (
    call:jarServiceStart %2
) else if "%1" == "stop" (
    call:jarServiceStop %2
) else if "%1" == "reboot" (
    call:jarServiceReboot %2
) else (
    call:echoUsage
)
cd %BAT_PATH%
exit /B

@rem [install] unzip jar_file to jar_dir
:jarServiceIntall
    call:setJava
    call:setJarFile %1
    cd "%jar_file_path%"
    if exist %jar_name% (
        del /Q %jar_name%
        rd /S /Q %jar_name%
    )
    mkdir %jar_name%
    move %jar_name%.jar %jar_name%
    cd %jar_name%
    "%RUN_JAR%" -xvf %jar_name%.jar
    move %jar_name%.jar ..
    @rem ren BOOT-INF WEB-INF
    call:setJarMainClass %jar_file_path%\%jar_name%
    echo jar_dir is "%cd%"
    echo start cmd is "%RUN_JAVA%" -cp "%cd%" %MainClass%
    echo "%RUN_JAVA%" -cp "%cd%" %MainClass% > "%cd%"/startup.bat
    echo install success!
goto:eof

@rem [remove] delete jar_dir
:jarServiceRemove
    call:setJarFile %1
    cd "%jar_file_path%"
    if exist %jar_name% (
        del /Q %jar_name%
        rd /S /Q %jar_name%
    )
    echo remove success!
goto:eof

@rem [regist] regist system service
:jarServiceRegist
    set jar_dir_path=%~f1
    set jar_dir_name=%~n1%~x1
    set ServiceName=JarService-%jar_dir_name%
    echo ServiceName set %ServiceName%

    echo JarDir set %jar_dir_path%
    call:setJarMainClass %jar_dir_path%
    echo MainClass set %MainClass%
    call:setTool

    "%instsrv_path%" "%ServiceName%" "%srvany_path%"
    reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServiceName%\Parameters
    reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServiceName%\Parameters /v AppDirectory /t REG_SZ /d "%jar_dir_path%"
    reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServiceName%\Parameters /v Application /t REG_SZ /d "%jar_dir_path%/startup.bat"
    echo regist system service success!
goto:eof

@rem [unreg] unregist system service
:jarServiceUnreg
    set jar_dir_name=%~n1%~x1
    echo delete JarService-%jar_dir_name%
    sc delete JarService-%jar_dir_name%
goto:eof

@rem [start] service
:jarServiceStart
    set jar_dir_name=%~n1%~x1
    echo start JarService-%jar_dir_name%
    sc start JarService-%jar_dir_name%
goto:eof

@rem [stop] service
:jarServiceStop
    set jar_dir_name=%~n1%~x1
    echo stop JarService-%jar_dir_name%
    @rem sc stop JarService-%jar_dir_name%
    for /f "tokens=2 " %%a in ('tasklist /SVC ^|findstr "JarService-%jar_dir_name%"') do taskkill /t /f /pid %%a
goto:eof

@rem [reboot] service
:jarServiceReboot
    call:jarServiceStop %1
    call:jarServiceStart %1
goto:eof

@rem util function

@rem [setJava] set run java cmd
:setJava
    if "%JAVA_HOME%" == "" (
        set "RUN_JAVA=%JAVA_HOME%\bin\java"
        set "RUN_JAR=%JAVA_HOME%\bin\jar"
    ) else (
        set RUN_JAVA=java
        set RUN_JAR=jar
    )
goto:eof

@rem [setJarFile] set jar file params
:setJarFile
    set jar_file_path=%~dp1
    set jar_suffix=%~x1
    set jar_name=%~n1
goto:eof

@rem [setJarMainClass] set jar META-INF/MANIFEST.MF Main-Class
:setJarMainClass
    for /f "tokens=2 delims= " %%i in ('type "%1\META-INF\MANIFEST.MF" ^|find "Main-Class"') do set MainClass=%%i
    if "%MainClass%" == "" (
        echo %1\META-INF\MANIFEST.MF Not Found Main-Class
        exit /B
    )
goto:eof

@rem [setTool]
:setTool
    set instsrv_path=%BAT_PATH%\tool\instsrv.exe
    set srvany_path=%BAT_PATH%\tool\srvany.exe
goto:eof

@rem [echoUsage]
:echoUsage
    echo jar-service 0.1
    echo Useage:
    echo	jar-service install	xxx.jar
    echo	jar-service remove	xxx.jar
    echo	jar-service regist	jar_dir
    echo	jar-service unreg	jar_dir
    echo	jar-service start	jar_dir
    echo	jar-service stop	jar_dir
    echo	jar-service reboot	jar_dir
goto:eof