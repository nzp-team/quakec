#!/bin/bash
#
# Nazi Zombies: Portable
# QuakeC Round 100 test runs on every bundled map.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.10.
#
set -o errexit

# tzdata will try to display an interactive install prompt by
# default, so make sure we define our system as non-interactive.
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

WORKING_DIRECTORY="/working"
OUTPUT_LOG="${WORKING_DIRECTORY}/run.log"
REPO_PWD=$(pwd)

function setup_container()
{
    echo "[INFO]: Installing dependancies.."
    apt update -y
    apt install libsdl2-dev wget zip python3 python3-pip -y
    wget https://raw.githubusercontent.com/nzp-team/QCHashTableGenerator/main/requirements.txt
    pip install -r requirements.txt --break-system-packages
    rm requirements.txt
    mkdir -p "${WORKING_DIRECTORY}"
}

function download_nzp()
{
    echo "[INFO]: Obtaining latest Nazi Zombies: Portable Linux x86_64 release.."
    cd "${WORKING_DIRECTORY}"
    wget https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-linux64.zip
    mkdir nzportable-linux64
    unzip nzportable-linux64.zip -d nzportable-linux64/
    chmod +x nzportable-linux64/nzportable64-sdl
}

function build_quakec()
{
    echo "[INFO]: Building QuakeC.."
    cd "${REPO_PWD}/tools"
    local cmd="./qc-compiler-gnu.sh"
    ${cmd}

    echo "[INFO]: Moving QuakeC to game download.."
    cp "${REPO_PWD}/build/fte/qwprogs.dat" "${WORKING_DIRECTORY}/nzportable-linux64/nzp/"
}

function run_test()
{
    echo "[INFO]: Running tests.."
    cd "${WORKING_DIRECTORY}/nzportable-linux64/"

    # Iterate through every map..
    while read -r map; do
        local pretty_name=$(basename ${map} .bsp)
        echo "[INFO]: Running [${pretty_name}].."

        local cmd="./nzportable64-sdl +map ${pretty_name} +vid_renderer headless +sys_testmode 2 +slowmo 100"
        ${cmd}
    done < <(find nzp/maps/ -type f -name "*.bsp")

    echo "[INFO]: TEST PASSED."
}

function main()
{
    setup_container;
    download_nzp;
    build_quakec;
    run_test;
}

main;