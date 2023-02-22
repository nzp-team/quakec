@ECHO OFF
CD ../
REM ****** create build directories ******
MKDIR build\pc\ 2>nul
MKDIR build\handheld\ 2>nul
MKDIR build\quakespasm\ 2>nul
MKDIR build\vita\ 2>nul
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
echo  compiling PSP & 3DS QC
echo ========================
echo.
fteqcc-cli-win.exe -srcfile ../progs/handheld.src
echo.
echo ========================
echo  compiling QUAKESPASM QC
echo ========================
echo.
fteqcc-cli-win.exe -srcfile ../progs/quakespasm.src
pause
