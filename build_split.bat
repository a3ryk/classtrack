@echo off
setlocal
cd /d "%~dp0"
python scripts\build_wizard.py --type split %*
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [Build Assistant exited with error code %ERRORLEVEL%]
    pause
)
