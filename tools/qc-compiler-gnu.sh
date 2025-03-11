#!/usr/bin/env bash
set -o errexit

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
QUAKEC_ROOT=$(dirname "${SCRIPT_DIR}")
QUAKEC_LOG="/tmp/qc.log"

FTEQCC="fteqcc-cli-lin"
RC="0"

# Switch to macOS fteqcc binary if on that platform.
if [[ "${OSTYPE}" == "darwin"* ]]; then
	FTEQCC="fteqcc-cli-mac"
fi

# Arguments
while true; do
    case "$1" in
        -t | --test-mode ) TEST_FLAG="-DQUAKEC_TEST"; shift 1 ;;
        * ) break ;;
    esac
done

function setup()
{
	cd "${QUAKEC_ROOT}"
	echo "[INFO]: Generating Hash Table"
	local command="python3 bin/qc_hash_generator.py -i tools/asset_conversion_table.csv -o source/server/hash_table.qc"
	echo "[${command}]"
	$command
	echo "---------------"

	mkdir -p build/{fte,standard}
}

function compile_progs()
{
	local src_file="$1"
	local name="$2"
	local flags="$3"
	local failure="1"

	echo "[INFO]: Compiling using [${src_file}] (${name}).."
	local command="bin/${FTEQCC} ${flags} -srcfile progs/${src_file}.src"
	echo "[${command}]"
	$command 2>&1 | tee -a "${QUAKEC_LOG}" > /dev/null
	local return_code=$?

	sed 's/^.\{16\}//' "${QUAKEC_LOG}" | grep -E "warning|error|defined|not|unknown|branches" || failure="0"
	rm -rf "${QUAKEC_LOG}"

	if [[ "${failure}" -ne "0" ]]; then
		echo "[ERROR]: FAILED to build!"
		RC="1"
	fi

	echo "---------------"
}

function main()
{
	setup;
	compile_progs "csqc" "FTE CSQC" "-DFTE -Wall"
	compile_progs "ssqc" "FTE SSQC" "-O3 -DFTE ${TEST_FLAG} -Wall"
	compile_progs "menu" "FTE MenuQC" "-O3 -DFTE -Wall"
	compile_progs "ssqc" "Vril SSQC" "-O3 -Wall"
	exit ${RC}
}

main;