#!/bin/bash
#
# Nazi Zombies: Portable
# QuakeC Unit test runner.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
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
	local packages=(ffmpeg libgl1 libgl1-mesa-dri libglu1-mesa libsdl2-2.0-0 libsdl2-mixer-2.0-0 unzip wget xauth xvfb zip python3 python3-pip)

	if [[ -n "${VRIL_REF}" ]]; then
		packages+=(build-essential git libgl-dev libglu1-mesa-dev libsdl2-dev libsdl2-mixer-dev make pkg-config)
	fi
	if [[ -n "${ASSETS_REF}" ]]; then
		packages+=(git libicu-dev)
	fi

    echo "[INFO]: Installing dependancies.."
    apt update -y
    apt install -y "${packages[@]}"
    wget https://raw.githubusercontent.com/nzp-team/QCHashTableGenerator/main/requirements.txt
    pip install -r requirements.txt --break-system-packages
    rm requirements.txt
    mkdir -p "${WORKING_DIRECTORY}"
}

function apply_vril_override()
{
    if [[ -z "${VRIL_REF}" ]]; then
        return 0
    fi

    echo "[INFO]: Building Vril commit: [${VRIL_REF}].."
    make -C "${VRIL_SOURCE_DIRECTORY}" -f Makefile.sdl -j"$(nproc)"

    echo "[INFO]: Replacing Vril binary.."
    cp "${VRIL_SOURCE_DIRECTORY}/build/sdl/nzportable" "${WORKING_DIRECTORY}/nzportable-linux64/nzportable64"
    chmod +x "${WORKING_DIRECTORY}/nzportable-linux64/nzportable64"
}

function apply_assets_override()
{
    if [[ -z "${ASSETS_REF}" ]]; then
        return 0
    fi

    local zone_tool_directory="${WORKING_DIRECTORY}/spawn-zone-tool"

    echo "[INFO]: Building assets commit: [${ASSETS_REF}].."
    git clone --recursive https://github.com/nzp-team/spawn-zone-tool.git "${zone_tool_directory}"
    python3 -m pip install -r "${zone_tool_directory}/requirements.txt" --break-system-packages

    bash "${ASSETS_SOURCE_DIRECTORY}/tools/compile-wads.sh"
    bash "${ASSETS_SOURCE_DIRECTORY}/tools/compile-maps.sh" --full --zone-tool-path "${zone_tool_directory}"
    bash "${ASSETS_SOURCE_DIRECTORY}/tools/assemble-assets.sh"

    echo "[INFO]: Replacing assets.."
    rm -rf "${WORKING_DIRECTORY}/nzportable-linux64/nzp"
    unzip -o "${ASSETS_SOURCE_DIRECTORY}/tmp/pc-nzp-assets.zip" -d "${WORKING_DIRECTORY}/nzportable-linux64/"
}

function download_nzp()
{
    echo "[INFO]: Obtaining latest Nazi Zombies: Portable Linux x86_64 release.."
    cd "${WORKING_DIRECTORY}"
    wget https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-linux64.zip
    mkdir nzportable-linux64
    unzip nzportable-linux64.zip -d nzportable-linux64/
    chmod +x nzportable-linux64/nzportable64
}

function build_quakec()
{
    echo "[INFO]: Building QuakeC.."
    cd "${REPO_PWD}/tools"
    local cmd="./qc-compiler-gnu.sh --test-mode"
    ${cmd}

    echo "[INFO]: Moving QuakeC to game download.."
    cp "${REPO_PWD}/build/standard/progs.dat" "${WORKING_DIRECTORY}/nzportable-linux64/nzp/"
}

function run_test()
{
    touch "${OUTPUT_LOG}"
    
    echo "[INFO]: Running unit tests.."
    cd "${WORKING_DIRECTORY}/nzportable-linux64/"
    local cmd=(./nzportable64 +map nzp_warehouse +vid_renderer headless)

    set +o errexit
    "${cmd[@]}" | tee "${OUTPUT_LOG}"
    local game_status=${PIPESTATUS[0]}
    set -o errexit

    if [[ "${game_status}" -ne "0" ]]; then
        echo "[ERROR]: Game exited with status [${game_status}]!"
        exit 1
    fi

    local failed_count
    failed_count=$(awk '/^\* Failed: / { print $3 }' "${OUTPUT_LOG}")
    if [[ -z "${failed_count}" ]]; then
        echo "[ERROR]: Unit Test summary was not generated! Bailing!"
        exit 1
    fi

    if [[ "${failed_count}" -ne "0" ]]; then
        echo "[ERROR]: [${failed_count}] failures occurred while running unit tests!"
        exit 1
    fi

    echo "[INFO]: UNIT TEST PASSED."
}

function main()
{
    setup_container;
    download_nzp;
    apply_vril_override;
    apply_assets_override;
    build_quakec;
    run_test;
}

main;