#!/usr/bin/env bash

cd ../

# generate hash table
echo "Generating Hash Table.."
python3 bin/qc_hash_generator.py -i tools/asset_conversion_table.csv -o source/server/hash_table.qc

# create build directories
mkdir -p build/{fte,standard}

cd bin/

# build..
echo "Compiling FTE CSQC.."
./fteqcc-cli-lin -srcfile ../progs/csqc.src | grep -E -i "warning |error |defined |not |unknown |branches"
echo "Compiling FTE SSQC.."
./fteqcc-cli-lin -O3 -DFTE -srcfile ../progs/ssqc.src | grep -E -i "warning |error |defined |not |unknown |branches"
echo "Compiling Standard/Id SSQC.."
./fteqcc-cli-lin -O3 -srcfile ../progs/ssqc.src | grep -E -i "warning |error |defined |not |unknown |branches"

echo "End of script."