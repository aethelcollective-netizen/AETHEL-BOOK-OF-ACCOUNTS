@echo off
setlocal
set "APP_PATH=%~dp0AethelAccounting.html"
if not exist "%APP_PATH%" (
  echo AethelAccounting.html must stay beside this launcher.
  pause
  exit /b 1
)
set "APP_URL=file:///%APP_PATH:\=/%"
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app="%APP_URL%"
  exit /b
)
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --app="%APP_URL%"
  exit /b
)
start "" msedge --app="%APP_URL%"
endlocal
