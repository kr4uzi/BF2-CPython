@echo off
setlocal enabledelayedexpansion
call :ensure-vsdevcmd
set PYTHON_VERSION=2.7.18

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

set SKIP_PATCH=false
set BUILTINS=true
:CheckOpts
if "%~1" == "-skip-patch" (set SKIP_PATCH=true) & shift & goto CheckOpts
pushd "python-%PYTHON_VERSION%"

if "%SKIP_PATCH%" == "true" goto :patched

echo Applying patches...
for %%f in ("..\patches\*.patch") do (
    echo Applying %%~nxf
    git apply "%%f" || goto :patch-error
)

:patched

pushd PCbuild
REM currently not building with -e --no-tkinter flag as bf2 does not need externals by default
REM if desired, DLLs (pyd) can be added to the default "PATH" (/admin /python/bf2 /mods/bf2/python)
call build -m -c Release -p Win32 "/p:WindowsTargetPlatformVersion=%UCRTVersion%" "/p:PlatformToolset=%PTVER%"
xcopy /y win32\dice_py.dll ..\..\.
popd

if not exist "..\pylib-2.3.4.zip" powershell -Command "Compress-Archive -Path Lib\* -DestinationPath ..\pylib-2.3.4.zip"
popd

echo Build completed successfully.
goto :exit-success

:ensure-vsdevcmd
if defined VCINSTALLDIR goto :EOF
set "PF86=%ProgramFiles(x86)%"
if "%PF86%" == "" set "PF86=%ProgramFiles%"
if not exist "%PF86%\Microsoft Visual Studio\Installer\vswhere.exe" (
    echo Visual Studio could not be detected.
    goto :ensure-vsdevcmd-failed
)

SET "VSWHERE=%PF86%\Microsoft Visual Studio\Installer\vswhere.exe"
("%VSWHERE%" -legacy -prerelease -latest -format text -nologo | findstr "installationPath:")>temp & (set /p VSPATH=)<temp & (del temp)
SET "VSPATH=%VSPATH:~18%"
call "%VSPATH%\Common7\Tools\VsDevCmd.bat"
if defined VCINSTALLDIR goto :EOF

:ensure-vsdevcmd-failed
echo Please execute this batch in the 'Developer Command Prompt from VS'
goto :exit-error

:build-error
echo ERROR: Build failed.
goto :exit-error

:patch-error
echo Failed to apply patch
set /P IGNORE_PATCH_ERROR=Continue (Y/[N])?
if /I "%IGNORE_PATCH_ERROR%"=="Y" goto :patched
goto :exit-error

:exit-error
pause
exit /b 1

:exit-success
pause
exit /b 0