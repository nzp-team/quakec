#!/usr/bin/env bash

cd ../
# create build directories
mkdir -p build/{fte,standard}
cd bin/
echo ""
echo "========================"
echo "   compiling FTE CCQC   "
echo "========================"
echo ""
./fteqcc-cli-lin -srcfile ../progs/fte-client.src
echo ""
echo "========================"
echo "   compiling FTE SSQC   "
echo "========================"
echo ""
./fteqcc-cli-lin -srcfile ../progs/fte-server.src
echo ""
echo "========================"
echo "  compiling STANDARD QC "
echo "========================"
echo ""
./fteqcc-cli-lin -O2 -srcfile ../progs/standard.src
