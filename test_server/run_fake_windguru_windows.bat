@echo off
setlocal

cd /d "%~dp0\.."

echo Starting fake Windguru server from:
echo %CD%
echo.

where py >nul 2>nul
if %ERRORLEVEL%==0 (
  py -3 test_server\fake_windguru_server.py
  goto end
)

where python >nul 2>nul
if %ERRORLEVEL%==0 (
  python test_server\fake_windguru_server.py
  goto end
)

echo Python was not found.
echo Please install Python 3 and make sure "py" or "python" works in Command Prompt.
echo Recommended easy option: install Python from the Microsoft Store.
echo.

:end
echo.
pause
