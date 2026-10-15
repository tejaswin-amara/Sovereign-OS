@echo off
REM Sovereign-OS v18 Command Router
if "%~1"=="" (
    powershell -ExecutionPolicy Bypass -File "%~dp0sovereign.ps1"
) else if "%~2"=="" (
    powershell -ExecutionPolicy Bypass -File "%~dp0sovereign.ps1" -Command %1
) else (
    powershell -ExecutionPolicy Bypass -File "%~dp0sovereign.ps1" -Command %1 -CommandArgs %2 %3 %4 %5
)
