#!/bin/sh
set -e

GRANITE_A_LP_BRANCH="lp:granite/0.4"
GRANITE_A_VERSION="0.4"
GRANITE_B_LP_BRANCH="lp:granite"
GRANITE_B_VERSION="0.5"

TEST_ROOT="/tmp/abi-test"
sudo rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"
cd "$TEST_ROOT" || exit

sudo apt-get -y install abi-dumper abi-compliance-checker > /dev/null

get_code() {
	GRANITE_LP_BRANCH="$1"
	GRANITE_VERSION="$2"
	mkdir -p "$TEST_ROOT"/"$GRANITE_VERSION"-prefix
	echo "Downloading version $GRANITE_VERSION code from $GRANITE_LP_BRANCH..."
	bzr export "$GRANITE_VERSION-branch" "$GRANITE_LP_BRANCH" --quiet
	cd "$GRANITE_VERSION-branch" || exit
	mkdir build
	cd build || exit
	cmake .. -DCMAKE_INSTALL_PREFIX="$TEST_ROOT"/"$GRANITE_VERSION-prefix" -DCMAKE_BUILD_TYPE=Debug > /dev/null
	sudo make -j install > /dev/null
}

dump_abi() {
	GRANITE_VERSION="$1"
	echo "Dumping ABI version $GRANITE_VERSION..."
	abi-dumper \
		"$TEST_ROOT"/"$GRANITE_VERSION-prefix"/lib/libgranite.so \
		-o "$TEST_ROOT"/"$GRANITE_VERSION".dump \
		-lver "$GRANITE_VERSION" \
		> /dev/null
}

compare_abi() {
	GRANITE_A_VERSION="$1"
	GRANITE_B_VERSION="$2"
	cd "$TEST_ROOT" || exit
	echo "Comparing ABI versions $GRANITE_A_VERSION and $GRANITE_B_VERSION..."
	abi-compliance-checker \
		-l granite \
		-old "$TEST_ROOT"/"$GRANITE_A_VERSION".dump \
		-new "$TEST_ROOT"/"$GRANITE_B_VERSION".dump
	echo "Report is at $TEST_ROOT/compat_reports/granite/"$GRANITE_A_VERSION"_to_"$GRANITE_B_VERSION"/compat_report.html"
}

get_code "$GRANITE_A_LP_BRANCH" "$GRANITE_A_VERSION"
get_code "$GRANITE_B_LP_BRANCH" "$GRANITE_B_VERSION"
dump_abi "$GRANITE_A_VERSION"
dump_abi "$GRANITE_B_VERSION"
compare_abi "$GRANITE_A_VERSION" "$GRANITE_B_VERSION"