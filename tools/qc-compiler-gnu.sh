#!/usr/bin/env bash

FTEQCC=fteqcc-cli-lin

# Switch to macOS fteqcc binary if on that platform.
if [[ "$OSTYPE" == "darwin"* ]]; then
	FTEQCC=fteqcc-cli-mac
fi

cd ../

# generate hash table
echo "Generating Hash Table.."
python3 bin/qc_hash_generator.py -i tools/asset_conversion_table.csv -o source/server/hash_table.qc

# create build directories
mkdir -p build/{fte,standard}

cd bin/

# build..
echo "Compiling FTE CSQC.."
./$FTEQCC -srcfile ../progs/csqc.src | grep -E -i "warning |error |defined |not |unknown |branches"
echo "Compiling FTE SSQC.."
./$FTEQCC -O3 -DFTE -srcfile ../progs/ssqc.src | grep -E -i "warning |error |defined |not |unknown |branches"
echo "Compiling FTE MenuQC.."
./$FTEQCC -O3 -DFTE -srcfile ../progs/menu.src | grep -E -i "warning |error |defined |not |unknown |branches"
echo "Compiling Standard/Id SSQC.."
./$FTEQCC -O3 -srcfile ../progs/ssqc.src | grep -E -i "warning |error |defined |not |unknown |branches"

echo "End of script."
