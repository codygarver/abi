#!/bin/sh
set -e

GRANITE_GIT_URL="https://github.com/elementary/granite"
GRANITE_A_COMMIT="4c3c936"
GRANITE_B_COMMIT="30ed300"

TEST_ROOT="/tmp/abi-test"
sudo rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"
cd "$TEST_ROOT" || exit

sudo apt-get -y install abi-dumper abi-compliance-checker > /dev/null

get_code() {
	GRANITE_COMMIT="$1"
	mkdir -p "$TEST_ROOT"/"$GRANITE_COMMIT"-prefix
	echo "Downloading commit $GRANITE_COMMIT code from $GRANITE_GIT_URL..."
	git clone "$GRANITE_GIT_URL" "$GRANITE_COMMIT-branch"
	cd "$GRANITE_COMMIT-branch" || exit
	git reset --hard "$GRANITE_COMMIT"
	mkdir build
	cd build || exit
	cmake .. -DCMAKE_INSTALL_PREFIX="$TEST_ROOT"/"$GRANITE_COMMIT-prefix" -DCMAKE_BUILD_TYPE=Debug > /dev/null
	sudo make -j install > /dev/null
}

dump_abi() {
	GRANITE_COMMIT="$1"
	echo "Dumping ABI version $GRANITE_COMMIT..."
	abi-dumper \
		"$TEST_ROOT"/"$GRANITE_COMMIT-prefix"/lib/libgranite.so \
		-o "$TEST_ROOT"/"$GRANITE_COMMIT".dump \
		-lver "$GRANITE_COMMIT" \
		> /dev/null
}

compare_abi() {
	GRANITE_A_COMMIT="$1"
	GRANITE_B_COMMIT="$2"
	cd "$TEST_ROOT" || exit
	echo "Comparing ABI versions $GRANITE_A_COMMIT and $GRANITE_B_COMMIT..."
	abi-compliance-checker \
		-l granite \
		-old "$TEST_ROOT"/"$GRANITE_A_COMMIT".dump \
		-new "$TEST_ROOT"/"$GRANITE_B_COMMIT".dump
	echo "Report is at $TEST_ROOT/compat_reports/granite/"$GRANITE_A_COMMIT"_to_"$GRANITE_B_COMMIT"/compat_report.html"
}

get_code "$GRANITE_A_COMMIT"
get_code "$GRANITE_B_COMMIT"
dump_abi "$GRANITE_A_COMMIT"
dump_abi "$GRANITE_B_COMMIT"
compare_abi "$GRANITE_A_COMMIT" "$GRANITE_B_COMMIT"
