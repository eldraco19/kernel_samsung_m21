#!/bin/bash

BOLD='\033[1m'
GRN='\033[01;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[01;31m'
RST='\033[0m'

KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/arch/arm64/boot/Image"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export KBUILD_BUILD_USER=ayush
export KBUILD_BUILD_HOST=gcp
TANGGAL=$(date +"%Y%m%d-%H")

function compile() {

    echo -e "${CYAN}"

    echo "Cloning dependencies if they don't exist...."
	if [ ! -d clang ]; then
		mkdir clang
		cd clang
		echo "Downloading clang...."
		wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/android-9.0.0_r8/clang-4639204.tar.gz &>> /dev/null
		tar -zxf clang-4639204.tar.gz &>> /dev/null
		rm clang-4639204.tar.gz
		cd ..
	fi
	if [ ! -d gcc ]; then
        	echo "Downloading gcc...."
		git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 gcc 
	fi
	echo "Done"

    make -j$(nproc) exynos9610-m21dd_defconfig
    make -j$(nproc)
    SUCCESS=$?
    echo -e "${RST}"
	
	if [ $SUCCESS -eq 0 ] && [ -f "$IMAGE" ]
        	then
		echo -e "${GRN}"
		echo "------------------------------------------------------------"
		echo "Compilation successful..."
        	echo "Image can be found at out/arch/arm64/boot/Image"
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
function makebootimg() {
	echo -e "${YELLOW}"
	echo "Creating boot image...."
	if [ ! -d out ]
	then
		mkdir out
	fi
	if [ ! -d out/AIK ]
	then
		git clone https://github.com/m21-dev/AIK-Linux --depth=1 out/AIK
	fi
	cd out/AIK
	echo "You may need to enter password at sudo prompt for some files in ramdisk/..."
	./unpackimg.sh --local boot.img
	cp $IMAGE split_img/boot.img-zImage
	./repackimg.sh
	mv image-new.img ../boot-${TANGGAL}.img
	echo "Boot image stored at out/boot-${TANGGAL}.img"
	sudo ./cleanup.sh
	echo -e "${RST}"
}

while true; do
	echo -e "\n[1] Build Kernel"
	echo -e "[2] Create boot image"
	echo -e "[3] Quit"
	echo -ne "\n(i) Enter a choice[1-3]: "

	read choice

	if [ "$choice" == "1" ]; then
		compile
	fi
	if [ "$choice" == "2" ]; then
		if [ -f "$IMAGE" ]
		then
			makebootimg
		else
			echo -e "${RED}"
			echo "Compile kernel first...."
			echo -e "${RST}"
		fi
	fi
	if [ "$choice" == "3" ]; then
		exit;
	fi
done
