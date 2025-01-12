@echo off
setlocal
set SCRIPT_DIR=%~dp0
echo SCRIPT_DIR is %SCRIPT_DIR%
cd /d "%SCRIPT_DIR%"
if exist tic80.exe (
    echo Found tic80.exe
    tic80.exe --fs %SCRIPT_DIR%
) else (
    echo tic80.exe not found in %SCRIPT_DIR%
)
endlocal
pause