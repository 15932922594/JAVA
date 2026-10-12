@echo off
title AGENT ACCESS - Start All

REM ============================================================
REM  AGENT ACCESS one-click startup script
REM  Starts:
REM    [1] Backend  : Spring Boot  (http://localhost:8081)
REM    [2] Frontend : Vite + Vue3 (http://localhost:5173)
REM  Usage: double-click this file, two console windows will
REM         open (one backend, one frontend). Close a window
REM         to stop that service.
REM ============================================================

set "ROOT=%~dp0"
set "BACKEND=%ROOT%springBootTest"
set "FRONTEND=%ROOT%vue-login"
set "BACKEND_PORT=8081"

REM ---------- [1/2] Backend: Spring Boot ----------
echo [1/2] Starting backend  : Spring Boot on port %BACKEND_PORT% ...
start "backend-springboot" cmd /k "cd /d %BACKEND% && mvnw.cmd spring-boot:run -Dspring-boot.run.arguments=--server.port=%BACKEND_PORT%"

REM ---------- [2/2] Frontend: Vite ----------
echo [2/2] Starting frontend : Vite on port 5173 ...
if not exist "%FRONTEND%\node_modules" (
    echo     node_modules not found, installing dependencies first.
    echo     This may take a few minutes on first run...
    start "frontend-vite" cmd /k "cd /d %FRONTEND% && npm install && npm run dev"
) else (
    start "frontend-vite" cmd /k "cd /d %FRONTEND% && npm run dev"
)

echo.
echo ============================================================
echo  Both services are starting in separate windows:
echo    Backend  : http://localhost:%BACKEND_PORT%
echo    Frontend : http://localhost:5173   ^(open this in browser^)
echo  Wait until backend window shows "Started SpringBootTestApplication"
echo  and frontend window shows "Local: http://localhost:5173/".
echo ============================================================
echo.
pause
