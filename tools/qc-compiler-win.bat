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
fteqcc-cli-win.exe -DFTE -Wall -srcfile ../progs/csqc.src
echo Compiling FTE SSQC..
fteqcc-cli-win.exe -O3 -DFTE -Wall -srcfile ../progs/ssqc.src
echo Compiling FTE MenuQC..
fteqcc-cli-win.exe -O3 -DFTE -Wall -srcfile ../progs/menu.src
echo Compiling Standard/Id SSQC..
fteqcc-cli-win.exe -O3 -Wall -srcfile ../progs/ssqc.src

echo End of script.
pause
