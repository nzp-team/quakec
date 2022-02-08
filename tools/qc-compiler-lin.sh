#!/usr/bin/env bash

cd ../
# create build directories
mkdir -p build/{pc,psp,nx,vita}
cd bin/
echo ""
echo "===================="
echo " compiling FTE CCQC "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile ../progs/fte-client.src
echo ""
echo "===================="
echo " compiling FTE SSQC "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile ../progs/fte-server.src
echo ""
echo "===================="
echo "  compiling PSP QC  "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile ../progs/psp.src
echo ""
echo "===================="
echo " compiling NX-QS QC "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile ../progs/nx.src
echo ""
echo "===================="
echo " compiling VITA QC  "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile ../progs/vita.src