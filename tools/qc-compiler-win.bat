@ECHO OFF
CD ../
REM ****** create build directories ******
MKDIR build\fte\ 2>nul
MKDIR build\standard\ 2>nul
CD bin/
echo.
echo ========================
echo    compiling FTE CCQC
echo ========================
echo.
fteqcc-cli-win.exe -srcfile ../progs/fte-client.src
echo.
echo ========================
echo    compiling FTE SSQC
echo ========================
echo.
fteqcc-cli-win.exe -srcfile ../progs/fte-server.src
echo.
echo ========================
echo   compiling STANDARD QC
echo ========================
echo.
fteqcc-cli-win.exe -O2 -srcfile ../progs/standard.src
pause
