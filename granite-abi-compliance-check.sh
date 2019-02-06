#!/bin/sh
set -e

GRANITE_GIT_URL="https://github.com/elementary/granite"
GRANITE_A_COMMIT="6d0dac2"
GRANITE_B_COMMIT="c1d97d8"

TEST_ROOT="/tmp/abi-test"
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"

export VERBOSE=1

get_code() {
	GRANITE_COMMIT="$1"
	cd "$TEST_ROOT" || exit
	mkdir -p "$TEST_ROOT"/"$GRANITE_COMMIT"-prefix
	echo "Downloading commit $GRANITE_COMMIT code from $GRANITE_GIT_URL..."
	git clone --quiet "$GRANITE_GIT_URL" "$GRANITE_COMMIT-branch"
	cd "$GRANITE_COMMIT-branch" || exit
	git reset --quiet --hard "$GRANITE_COMMIT"
	meson build --prefix "$TEST_ROOT"/"$GRANITE_COMMIT-prefix" > /dev/null
	echo "Compiling $GRANITE_COMMIT..."
	ninja -C build install > /dev/null
}

dump_abi() {
	GRANITE_COMMIT="$1"
	echo "Dumping ABI version $GRANITE_COMMIT..."
	abi-dumper \
		"$TEST_ROOT"/"$GRANITE_COMMIT-prefix"/lib*/libgranite.so \
		-o "$TEST_ROOT"/"$GRANITE_COMMIT".dump \
		-lver "$GRANITE_COMMIT" \
		-quiet \
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
		-new "$TEST_ROOT"/"$GRANITE_B_COMMIT".dump \
		-report-path "$TEST_ROOT"/compat_report.html
}

get_code "$GRANITE_A_COMMIT"
get_code "$GRANITE_B_COMMIT"
dump_abi "$GRANITE_A_COMMIT"
dump_abi "$GRANITE_B_COMMIT"
compare_abi "$GRANITE_A_COMMIT" "$GRANITE_B_COMMIT"
