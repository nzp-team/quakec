#!/usr/bin/env bash

cd ../
# create build directories
mkdir -p build/{pc,handheld,quakespasm,vita}
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
echo " compiling PSP & 3DS QC "
echo "========================"
echo ""
./fteqcc-cli-lin -srcfile ../progs/handheld.src
echo ""
echo "========================"
echo "compiling QUAKESPASM QC "
echo "========================"
echo ""
./fteqcc-cli-lin -srcfile ../progs/quakespasm.src