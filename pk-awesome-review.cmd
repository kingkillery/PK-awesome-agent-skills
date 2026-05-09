@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pk-awesome-review.ps1" %*
exit /b %ERRORLEVEL%
