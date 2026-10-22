@echo off
setlocal enabledelayedexpansion
title AGENT ACCESS - Start All

REM ============================================================
REM  AGENT ACCESS one-click startup script
REM    [1] Backend  : Spring Boot   http://localhost:8081
REM    [2] Frontend : Vite + Vue3   http://localhost:5173
REM
REM  Usage:
REM    double-click          -> start both services
REM    start.bat /check      -> only run environment checks, start nothing
REM    start.bat /checkonly  -> alias of /check
REM
REM  Each service runs in its own console window.
REM  Close a window (or run stop.bat) to stop that service.
REM ============================================================

set "ROOT=%~dp0"
set "BACKEND=%ROOT%springBootTest"
set "FRONTEND=%ROOT%vue-login"
set "BACKEND_PORT=8081"
set "FRONTEND_PORT=5173"
set "CHECKONLY=0"
if /i "%~1"=="/check" set "CHECKONLY=1"
if /i "%~1"=="/checkonly" set "CHECKONLY=1"

set "FAIL=0"

echo ============================================================
echo  [Step 0] Environment check
echo ============================================================

REM ---------- Java ----------
java -version >nul 2>&1
if errorlevel 1 (
    echo   [FAIL] java not found in PATH ^(need JDK 17+^)
    set "FAIL=1"
) else (
    for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do set "JAVAVER=%%v"
    echo   [ OK ] java !JAVAVER!
)

REM ---------- Node / npm ----------
REM NOTE: npm is npm.cmd on Windows. Calling a .cmd from a .bat WITHOUT
REM "call" transfers control away and never returns - that is why we use
REM "where" to probe npm, and only invoke it through a for/f child shell.
node -v >nul 2>&1
if errorlevel 1 (
    echo   [FAIL] node not found in PATH
    set "FAIL=1"
) else (
    for /f %%v in ('node -v') do set "NODEVER=%%v"
    echo   [ OK ] node !NODEVER!
)
where npm >nul 2>&1
if errorlevel 1 (
    echo   [FAIL] npm not found in PATH
    set "FAIL=1"
) else (
    set "NPMVER=?"
    for /f %%v in ('call npm -v 2^>nul') do set "NPMVER=%%v"
    echo   [ OK ] npm  !NPMVER!
)

REM ---------- Project folders ----------
if exist "%BACKEND%\mvnw.cmd" (
    echo   [ OK ] backend folder found
) else (
    echo   [FAIL] missing %BACKEND%\mvnw.cmd
    set "FAIL=1"
)
if exist "%FRONTEND%\package.json" (
    echo   [ OK ] frontend folder found
) else (
    echo   [FAIL] missing %FRONTEND%\package.json
    set "FAIL=1"
)

REM ---------- Frontend dependencies ----------
if exist "%FRONTEND%\node_modules" (
    echo   [ OK ] node_modules present
) else (
    echo   [WARN] node_modules missing - npm install will run first
)

if "%FAIL%"=="1" (
    echo.
    echo  ------------------------------------------------------------
    echo   Environment check FAILED. Fix the items marked [FAIL].
    echo  ------------------------------------------------------------
    if "%CHECKONLY%"=="1" exit /b 1
    pause
    exit /b 1
)

echo.
echo  [Step 1] Port availability
call :checkport %BACKEND_PORT%
call :checkport %FRONTEND_PORT%

if "%CHECKONLY%"=="1" (
    echo.
    echo  Check finished. Nothing was started.
    echo.
    pause
    exit /b 0
)

echo.
echo ============================================================
echo  [Step 2] Starting backend  : Spring Boot on port %BACKEND_PORT%
echo ============================================================
start "backend-springboot" cmd /k "cd /d %BACKEND% && mvnw.cmd spring-boot:run -Dspring-boot.run.arguments=--server.port=%BACKEND_PORT%"

echo  [Step 3] Starting frontend : Vite on port %FRONTEND_PORT%
if not exist "%FRONTEND%\node_modules" (
    echo           node_modules not found, installing dependencies first.
    echo           This may take a few minutes on first run...
    start "frontend-vite" cmd /k "cd /d %FRONTEND% && npm install && npm run dev"
) else (
    start "frontend-vite" cmd /k "cd /d %FRONTEND% && npm run dev"
)

echo.
echo  Waiting for services to become ready (up to 120 seconds each)...
echo.

set /a T1=0
:wait_backend
timeout /t 2 /nobreak >nul
netstat -ano | findstr /r /c:":%BACKEND_PORT% " | findstr /i "LISTENING" >nul
if not errorlevel 1 goto backend_ok
set /a T1+=1
if %T1% lss 60 goto wait_backend
echo   [WARN] backend did not open port %BACKEND_PORT% within 120s - read its window for the error.
goto wait_front

:backend_ok
echo   [ OK ] backend  is listening on %BACKEND_PORT%

:wait_front
set /a T2=0
:wait_frontend
timeout /t 2 /nobreak >nul
netstat -ano | findstr /r /c:":%FRONTEND_PORT% " | findstr /i "LISTENING" >nul
if not errorlevel 1 goto frontend_ok
set /a T2+=1
if %T2% lss 60 goto wait_frontend
echo   [WARN] frontend did not open port %FRONTEND_PORT% within 120s - read its window for the error.
goto summary

:frontend_ok
echo   [ OK ] frontend is listening on %FRONTEND_PORT%
start "" http://127.0.0.1:%FRONTEND_PORT%

:summary
echo.
echo ============================================================
echo   Backend  : http://127.0.0.1:%BACKEND_PORT%
echo   Frontend : http://127.0.0.1:%FRONTEND_PORT%
echo   Stop all : double-click stop.bat
echo ============================================================
echo.
pause
exit /b 0

REM ============================================================
REM  Subroutine: check whether a port is free, offer to free it
REM ============================================================
:checkport
set "PORT=%~1"
set "PID="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /r /c:":%PORT% " ^| findstr /i "LISTENING"') do set "PID=%%a"
if not defined PID (
    echo   [ OK ] port %PORT% is free
    exit /b 0
)
set "IMG=unknown"
for /f "tokens=1 delims=," %%n in ('tasklist /FI "PID eq %PID%" /NH /FO CSV 2^>nul') do set "IMG=%%~n"
echo   [WARN] port %PORT% is already in use  -  PID !PID!  ^(!IMG!^)
if "%CHECKONLY%"=="1" (
    echo          Run stop.bat, or close that process, then start again.
    exit /b 0
)
choice /c YN /n /m "          Kill PID !PID! and reuse the port? [Y/N] "
if errorlevel 2 (
    echo          Kept it. The service on port %PORT% will probably fail to start.
) else (
    taskkill /PID !PID! /F >nul 2>&1
    echo          Killed PID !PID!, port %PORT% released.
    timeout /t 1 /nobreak >nul
)
exit /b 0
