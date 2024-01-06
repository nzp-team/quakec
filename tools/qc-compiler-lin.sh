#!/usr/bin/env bash

cd ../

# generate hash table
echo "Generating Hash Table.."
python bin/qc_hash_generator.py -i tools/asset_conversion_table.csv -o source/server/hash_table.qc

# create build directories
mkdir -p build/{fte,standard}

cd bin/

# build..
echo "Compiling FTE CSQC.."
./fteqcc-cli-lin -srcfile ../progs/fte-client.src | grep -E -i "warning |error |defined |not |unknown"
echo "Compiling FTE SSQC.."
./fteqcc-cli-lin -O2 -srcfile ../progs/fte-server.src | grep -E -i "warning |error |defined |not |unknown"
echo "Compiling Standard/Id SSQC.."
./fteqcc-cli-lin -O2 -srcfile ../progs/standard.src | grep -E -i "warning |error |defined |not |unknown"

echo "End of script."