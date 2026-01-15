@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "LOG=%~dp0start-phone-net.log"

del /q "%~dp0*.log" 2>nul

call :main >> "%LOG%" 2>&1

echo.
echo ============================
echo Done. Log saved to:
echo "%LOG%"
echo ============================
echo.
type "%LOG%" | more
pause
exit /b

:main
echo BASE_DIR="%~dp0"
echo.

set "BASE_DIR=%~dp0"
set "PT_DIR=%BASE_DIR%platform-tools"
set "PT_ZIP=%BASE_DIR%platform-tools.zip"
set "GNI_ZIP=%BASE_DIR%gnirehtet.zip"
set "GNI_EXE="

REM --- Find gnirehtet.exe (robust even with spaces)
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command ^
  "$exe = Get-ChildItem -Path '%BASE_DIR%' -Recurse -Filter 'gnirehtet.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName; if($exe){$exe}"`) do set "GNI_EXE=%%I"

if not defined GNI_EXE (
  echo Gnirehtet not found - downloading latest...

  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop';" ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
    "$rel = Invoke-RestMethod 'https://api.github.com/repos/Genymobile/gnirehtet/releases/latest';" ^
    "$asset = $rel.assets | Where-Object { $_.name -match 'gnirehtet-rust-win64-.*\.zip$' } | Select-Object -First 1;" ^
    "if(-not $asset){ throw 'Could not find gnirehtet-rust-win64 zip asset.' }" ^
    "Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%GNI_ZIP%';" ^
    "Expand-Archive -Path '%GNI_ZIP%' -DestinationPath '%BASE_DIR%' -Force;"

  for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command ^
    "$exe = Get-ChildItem -Path '%BASE_DIR%' -Recurse -Filter 'gnirehtet.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName; if($exe){$exe}"`) do set "GNI_EXE=%%I"
)

if not defined GNI_EXE (
  echo [ERROR] gnirehtet.exe not found after download/extract.
  exit /b 1
)

echo Found Gnirehtet: "%GNI_EXE%"
echo.

REM --- platform-tools only if missing
if exist "%PT_DIR%\adb.exe" (
  echo platform-tools already exists - skipping download
) else (
  echo Downloading Android platform-tools...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop';" ^
    "Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile '%PT_ZIP%';" ^
    "Expand-Archive -Path '%PT_ZIP%' -DestinationPath '%BASE_DIR%' -Force;"
)

echo.
echo ADB device check:
"%PT_DIR%\adb.exe" devices

echo.
echo Starting reverse tethering...

where adb
adb version

set "PATH=%PT_DIR%;%PATH%"
"%GNI_EXE%" run

exit /b 0
