@echo off
setlocal enabledelayedexpansion

set PYTHON_VERSION=2.7.18

if not defined VCINSTALLDIR (
    echo Please execute this batch in the 'Developer Command Prompt from VS'
    pause
    exit /b 1
)

:: Identify the latest PlatformToolset version
set "VCVERDIR=%VSINSTALLDIR%\MSBuild\Microsoft\VC"
if not exist "%VCVERDIR%" (
    echo Could not find VC Version directory.
    exit /b 1
)

:: Find latest vXXX directory
set "VCVER="
for /f "delims=" %%d in ('dir /b /ad "%VCVERDIR%" ^| findstr /r "^v[0-9][0-9][0-9]$"') do (
    set "VCVER=%%d"
)

if [%VCVER%] == [] (
    echo Could not identify latest VC Version.
    exit /b 1
)

set "PTVER="
for /f "delims=" %%d in ('dir /b /ad "%VCVERDIR%\%VCVER%\Platforms\Win32\PlatformToolsets" ^| findstr /r "^v[0-9][0-9][0-9]$"') do (
    set "PTVER=%%d"
)

if [%PTVER%] == [] (
    echo Could not identify latest Platform Toolset.
    exit /b 1
)

:: Download the source archive
if not exist "python-%PYTHON_VERSION%" (
    git clone --depth=1 --branch v%PYTHON_VERSION% https://github.com/python/cpython.git python-%PYTHON_VERSION%
)

cd "python-%PYTHON_VERSION%"
if "%~1" == "-skip-patch" goto patched
echo Applying patches...
for %%f in ("..\patches\*.patch") do (
    echo Applying %%~nxf
    git apply "%%f" || goto :patch-error
)
:patched

:: Build with MSBuild
for /f "tokens=*" %%a in ('wmic cpu get NumberOfCores ^| find /v "NumberOfCores"') do (
    set COMPILE_THREADS=%%a
    goto :compile
)
:compile

set "CFG=Release"
if "%~1" == "-cfg:debug" set "CFG=Debug"
msbuild PCbuild\pythoncore.vcxproj /p:Configuration=%CFG% /p:Platform=Win32 /p:WindowsTargetPlatformVersion=%WindowsSDKVersion% /p:PlatformToolset=%PTVER% -maxCpuCount:%COMPILE_THREADS% || goto :error
xcopy /y PCbuild\win32\*.dll ..\.
xcopy /y PCbuild\win32\*.lib ..\.
if not exist "..\pylib-2.3.4.zip" powershell -Command "Compress-Archive -Path Lib\* -DestinationPath ..\pylib-2.3.4.zip"
echo Build completed successfully.
exit /b 0

:error
echo ERROR: Build failed.
exit /b 1

:patch-error
echo Failed to patch - if already patched used '-skip-patch'
exit /b 1