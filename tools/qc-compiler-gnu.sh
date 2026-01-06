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

	generate_asset_hashtable;

	if [[ -n "${TEST_FLAG}" ]]; then
		generate_test_list;
	fi

	mkdir -p build/{fte,standard}
}

function generate_asset_hashtable()
{
	echo "[INFO]: Generating Hash Table"
	local command="python3 bin/qc_hash_generator.py -i tools/asset_conversion_table.csv -o source/server/hash_table.qc"
	echo "[${command}]"
	$command
	echo "---------------"
}

function generate_test_list()
{
	echo "[INFO]: Running in Unit Test mode, generating unit test list.."

	rm -rf source/server/tests/test_list.qc

	unit_tests=$(grep -r "void() Test_" source/server/tests/ --exclude="test_module.qc")

	i=1;
	while read test_line; do 
		unit_test_name=$(echo ${test_line} | awk '{print $2}')
		echo "#append unit_test_funcs FUNC(${unit_test_name})" >> source/server/tests/test_list.qc
		i=$(($i+1)); 
	done <<< "$unit_tests"

	echo "#define FUNC(name) {name, #name}," >> source/server/tests/test_list.qc
	echo "var struct { void() test_func; string test_name; } qc_unit_tests[] = {" >> source/server/tests/test_list.qc
	echo "unit_test_funcs" >> source/server/tests/test_list.qc
	echo "};" >> source/server/tests/test_list.qc
	echo "#undef FUNC" >> source/server/tests/test_list.qc
	echo "---------------"
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