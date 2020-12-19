#!/bin/bash

BOLD='\033[1m'
GRN='\033[01;32m'
CYAN='\033[0;36m'
RED='\033[01;31m'
RST='\033[0m'
echo "Cloning dependencies if they don't exist...."

if [ ! -d clang ]
then
	mkdir clang
	cd clang
	echo "Downloading clang...."
	wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/android-9.0.0_r8/clang-4639204.tar.gz &>> /dev/null
	tar -zxf clang-4639204.tar.gz &>> /dev/null
	rm clang-4639204.tar.gz
	cd ..
fi

if [ ! -d gcc ]
then
        echo "Downloading gcc...."
	git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 gcc
fi

echo "Done"

KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/arch/arm64/boot/Image.gz"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_USER=ayush
export KBUILD_BUILD_HOST=gcp

function compile() {

    echo -e "${CYAN}"
    make -j$(nproc) exynos9610-m21dd_defconfig
    make -j$(nproc)
    SUCCESS=$?
    echo -e "${RST}"
	
	if [ $SUCCESS -eq 0 ] && [ -f "$IMAGE" ]
        	then
		echo -e "${GRN}"
		echo "------------------------------------------------------------"
		echo "Compilation successful..."
        	echo "Image.gz can be found at out/arch/arm64/boot/Image.gz"
		echo  "------------------------------------------------------------"
		echo -e "${RST}"
	else
		echo -e "${RED}"
                echo "------------------------------------------------------------"
		echo "Compilation failed..check build logs for errors"
                echo "------------------------------------------------------------"
		echo -e "${RST}"
	fi

}

compile
