sudo rm -rf /tmp/abi-test
mkdir -p /tmp/abi-test
cd /tmp/abi-test

sudo apt -y install abi-dumper abi-compliance-checker

GRANITE_A_LP_BRANCH="lp:granite/0.4"
GRANITE_A_VERSION="4"
GRANITE_B_LP_BRANCH="lp:granite"
GRANITE_B_VERSION="0.5"

mkdir -p \
	/tmp/"$GRANITE_A_VERSION-prefix" \
	/tmp/"$GRANITE_B_VERSION-prefix"

bzr export "$GRANITE_A_VERSION-branch" "$GRANITE_A_LP_BRANCH"
cd "$GRANITE_A_VERSION-branch"
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/tmp/abi-test/"$GRANITE_A_VERSION-prefix" -DCMAKE_BUILD_TYPE=Debug
sudo make -j install

cd /tmp/abi-test

abi-dumper \
	/tmp/abi-test/"$GRANITE_A_VERSION-prefix"/lib/libgranite.so \
	-o /tmp/abi-test/"$GRANITE_A_VERSION".dump \
	-lver "$GRANITE_A_VERSION"

bzr export "$GRANITE_B_VERSION-branch" "$GRANITE_B_LP_BRANCH"
cd "$GRANITE_B_VERSION-branch"
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/tmp/abi-test/"$GRANITE_B_VERSION-prefix" -DCMAKE_BUILD_TYPE=Debug
sudo make -j install

cd /tmp/abi-test

abi-dumper \
	/tmp/abi-test/"$GRANITE_B_VERSION-prefix"/lib/libgranite.so \
	-o /tmp/abi-test/"$GRANITE_B_VERSION".dump \
	-lver "$GRANITE_B_VERSION"

abi-compliance-checker -l granite -old /tmp/abi-test/"$GRANITE_A_VERSION".dump -new /tmp/abi-test/"$GRANITE_B_VERSION".dump