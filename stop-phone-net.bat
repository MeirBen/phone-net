@echo off

setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "LOG=%~dp0stop-phone-net.log"
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
set "BASE_DIR=%~dp0"
set "PT_DIR=%BASE_DIR%platform-tools"
set "ADB_EXE=%PT_DIR%\adb.exe"
set "GNI_EXE="

echo BASE_DIR="%BASE_DIR%"
echo.

REM ---- Ensure adb is available for THIS process (and for gnirehtet)
if exist "%ADB_EXE%" (
  set "PATH=%PT_DIR%;%PATH%"
  echo Using local adb: "%ADB_EXE%"
) else (
  echo [WARN] Local adb not found at "%ADB_EXE%". Will try PATH.
)

echo.
echo adb resolution:
where adb
echo.

REM ---- Find gnirehtet.exe
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command ^
  "$exe = Get-ChildItem -Path '%BASE_DIR%' -Recurse -Filter 'gnirehtet.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName; if($exe){$exe}"`) do set "GNI_EXE=%%I"

if not defined GNI_EXE (
  echo [ERROR] gnirehtet.exe not found under: "%BASE_DIR%"
  exit /b 1
)

echo Found Gnirehtet:
echo "%GNI_EXE%"
echo.

REM ---- Stop Gnirehtet (needs adb in PATH)
echo Stopping reverse tethering...
"%GNI_EXE%" stop

echo.
echo Stopping adb server...
adb kill-server

echo.
echo Killing any remaining adb.exe processes...
taskkill /F /IM adb.exe >nul 2>&1

echo.
echo All services stopped.
echo Phone network restored to normal.
echo.
exit /b 0
