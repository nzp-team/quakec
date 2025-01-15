#!/bin/bash

./qc-compiler-gnu.sh
cp ../build/fte/* ~/nzp-mac/nzp/
cd ~/nzp-mac/
wine nzportable-sdl64.exe +map ndu