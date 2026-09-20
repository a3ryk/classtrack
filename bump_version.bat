@echo off
setlocal
cd /d "%~dp0"
python scripts\build_wizard.py --type bump-only %*
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [Version Assistant exited with error code %ERRORLEVEL%]
    pause
)
