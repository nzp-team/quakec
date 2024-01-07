@ECHO OFF

CD ../

REM ****** generate hash table ******
echo Generating Hash Table..
python3 bin\qc_hash_generator.py -i tools\asset_conversion_table.csv -o source\server\hash_table.qc

REM ****** create build directories ******
MKDIR build\fte\ 2>nul
MKDIR build\standard\ 2>nul

CD bin/

REM ****** build.. ******
echo Compiling FTE CSQC..
fteqcc-cli-win.exe -srcfile ../progs/fte-client.src
echo Compiling FTE SSQC..
fteqcc-cli-win.exe -O2 -srcfile ../progs/fte-server.src
echo Compiling Standard/Id SSQC..
fteqcc-cli-win.exe -O2 -srcfile ../progs/standard.src

echo End of script.
pause