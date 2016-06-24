#!/bin/sh
set -e

GRANITE_A_LP_BRANCH="lp:granite/0.4"
GRANITE_A_VERSION="0.4"
GRANITE_B_LP_BRANCH="lp:granite"
GRANITE_B_VERSION="0.5"

sudo rm -rf /tmp/abi-test
mkdir -p /tmp/abi-test
cd /tmp/abi-test || exit

sudo apt-get -y install abi-dumper abi-compliance-checker > /dev/null

function get_code() {
	GRANITE_LP_BRANCH="$1"
	GRANITE_VERSION="$2"
	mkdir -p /tmp/abi-test/"$GRANITE_VERSION"-prefix
	echo "Downloading version $GRANITE_VERSION code from $GRANITE_LP_BRANCH..."
	bzr export "$GRANITE_VERSION-branch" "$GRANITE_LP_BRANCH" --quiet
	cd "$GRANITE_VERSION-branch" || exit
	mkdir build
	cd build || exit
	cmake .. -DCMAKE_INSTALL_PREFIX=/tmp/abi-test/"$GRANITE_VERSION-prefix" -DCMAKE_BUILD_TYPE=Debug > /dev/null
	sudo make -j install > /dev/null
}

function dump_abi() {
	GRANITE_VERSION="$1"
	echo "Dumping ABI version $GRANITE_VERSION..."
	abi-dumper \
		/tmp/abi-test/"$GRANITE_VERSION-prefix"/lib/libgranite.so \
		-o /tmp/abi-test/"$GRANITE_VERSION".dump \
		-lver "$GRANITE_VERSION" \
		> /dev/null
}

function compare_abi() {
	GRANITE_A_VERSION="$1"
	GRANITE_B_VERSION="$2"
	cd /tmp/abi-test || exit
	echo "Comparing ABI versions $GRANITE_A_VERSION and $GRANITE_B_VERSION..."
	abi-compliance-checker -l granite -old /tmp/abi-test/"$GRANITE_A_VERSION".dump -new /tmp/abi-test/"$GRANITE_B_VERSION".dump
	echo "Report is at /tmp/abi-test/compat_reports/granite/"$GRANITE_A_VERSION"_to_"$GRANITE_B_VERSION"/compat_report.html"
}

get_code "$GRANITE_A_LP_BRANCH" "$GRANITE_A_VERSION"
get_code "$GRANITE_B_LP_BRANCH" "$GRANITE_B_VERSION"
dump_abi "$GRANITE_A_VERSION"
dump_abi "$GRANITE_B_VERSION"
compare_abi "$GRANITE_A_VERSION" "$GRANITE_B_VERSION"