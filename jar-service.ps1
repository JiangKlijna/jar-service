# ----------------------
# @name      jar-service
# @author    jiangKlijna
# ----------------------

param(
    [string]$Command,
    [string]$Arg
)

$BAT_PATH = $PWD.Path

# Match command
switch ($Command) {
    "install"  { JarServiceInstall $Arg }
    "remove"  { JarServiceRemove $Arg }
    "regist"  { JarServiceRegist $Arg }
    "unreg"   { JarServiceUnreg $Arg }
    "start"   { JarServiceStart $Arg }
    "stop"    { JarServiceStop $Arg }
    "reboot"  { JarServiceReboot $Arg }
    default   { EchoUsage }
}

Set-Location $BAT_PATH
exit 0

# [install] unzip jar_file to jar_dir
function JarServiceInstall {
    param([string]$JarFile)

    $java = GetJava
    $jarCmd = GetJarCmd

    $jarFilePath = Split-Path -Parent $JarFile
    $jarName = [System.IO.Path]::GetFileNameWithoutExtension($JarFile)
    $jarSuffix = [System.IO.Path]::GetExtension($JarFile)

    Set-Location $jarFilePath

    if (Test-Path $jarName) {
        Remove-Item -Path $jarName -Recurse -Force
    }
    New-Item -ItemType Directory -Path $jarName -Force | Out-Null
    
    Move-Item -Path "$JarFile" -Destination "$jarName/"

    Set-Location $jarName
    & $jarCmd -xvf "$jarName$jarSuffix"
    Move-Item -Path "$jarName$jarSuffix" -Destination "../"

    $mainClass = GetJarMainClass "$jarFilePath/$jarName"
    Write-Host "jar_dir is $PWD"
    Write-Host "start cmd is $java -cp `"$PWD`" $mainClass"
    
    "$java -cp `"$PWD`" $mainClass" | Out-File -FilePath "$PWD/startup.bat" -Encoding ASCII
    Write-Host "install success!"
}

# [remove] delete jar_dir
function JarServiceRemove {
    param([string]$JarFile)

    $jarFilePath = Split-Path -Parent $JarFile
    $jarName = [System.IO.Path]::GetFileNameWithoutExtension($JarFile)

    Set-Location $jarFilePath

    if (Test-Path $jarName) {
        Remove-Item -Path $jarName -Recurse -Force
    }
    Write-Host "remove success!"
}

# [regist] regist system service
function JarServiceRegist {
    param([string]$JarDir)

    $jarDirPath = (Resolve-Path $JarDir).Path
    $jarDirName = Split-Path -Leaf $JarDir
    $ServiceName = "JarService-$jarDirName"

    Write-Host "ServiceName set $ServiceName"
    Write-Host "JarDir set $jarDirPath"

    $mainClass = GetJarMainClass $jarDirPath
    Write-Host "MainClass set $mainClass"

    $instsrvPath = Join-Path $BAT_PATH "tool/instsrv.exe"
    $srvanyPath = Join-Path $BAT_PATH "tool/srvany.exe"

    # Note: PowerShell cannot directly run instsrv.exe, use sc command instead
    & cmd /c "`"$instsrvPath`" `"$ServiceName`" `"$srvanyPath`""

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName\Parameters"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    New-ItemProperty -Path $regPath -Name "AppDirectory" -Value $jarDirPath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $regPath -Name "Application" -Value "$jarDirPath/startup.bat" -PropertyType String -Force | Out-Null

    Write-Host "regist system service success!"
}

# [unreg] unregist system service
function JarServiceUnreg {
    param([string]$JarDir)

    $jarDirName = Split-Path -Leaf $JarDir
    $ServiceName = "JarService-$jarDirName"

    Write-Host "delete $ServiceName"
    & sc.exe delete $ServiceName
}

# [start] service
function JarServiceStart {
    param([string]$JarDir)

    $jarDirName = Split-Path -Leaf $JarDir
    $ServiceName = "JarService-$jarDirName"

    Write-Host "start $ServiceName"
    & sc.exe start $ServiceName
}

# [stop] service
function JarServiceStop {
    param([string]$JarDir)

    $jarDirName = Split-Path -Leaf $JarDir
    $ServiceName = "JarService-$jarDirName"

    Write-Host "stop $ServiceName"
    # Get PID and kill process
    $pid = (Get-WmiObject Win32_Service -Filter "Name='$ServiceName'").ProcessId
    if ($pid -and $pid -ne 0) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
}

# [reboot] service
function JarServiceReboot {
    param([string]$JarDir)

    JarServiceStop $JarDir
    JarServiceStart $JarDir
}

# [GetJava] get java command
function GetJava {
    if ($env:JAVA_HOME) {
        return Join-Path $env:JAVA_HOME "bin/java.exe"
    }
    return "java"
}

# [GetJarCmd] get jar command
function GetJarCmd {
    if ($env:JAVA_HOME) {
        return Join-Path $env:JAVA_HOME "bin/jar.exe"
    }
    return "jar"
}

# [GetJarMainClass] get Main-Class from META-INF/MANIFEST.MF
function GetJarMainClass {
    param([string]$JarDir)

    $manifestPath = Join-Path $JarDir "META-INF/MANIFEST.MF"
    if (-not (Test-Path $manifestPath)) {
        Write-Host "$manifestPath Not Found Main-Class"
        return $null
    }

    $content = Get-Content $manifestPath -Raw
    if ($content -match "Main-Class:\s*(.+)") {
        return $matches[1].Trim()
    }
    
    Write-Host "$manifestPath Not Found Main-Class"
    return $null
}

# [EchoUsage]
function EchoUsage {
    Write-Host "jar-service 0.1"
    Write-Host "Usage:"
    Write-Host "    jar-service install  xxx.jar"
    Write-Host "    jar-service remove  xxx.jar"
    Write-Host "    jar-service regist jar_dir"
    Write-Host "    jar-service unreg  jar_dir"
    Write-Host "    jar-service start  jar_dir"
    Write-Host "    jar-service stop   jar_dir"
    Write-Host "    jar-service reboot jar_dir"
}
