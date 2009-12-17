#!/bin/bash
usage () {
	echo "Usage: android_setenv.sh [ gfx ]
OPTIONAL:
	gfx: declare variables required for building GFX DDK
target_dir:
	directory path where you want binaries to be stored"
	exit 64 # command line usage error
}

until [ -z "$1" ]; do
	case "$1" in 
	gfx) gfx=1
	esac
	shift
done

if [ ! -d .repo ]; then
        echo "You are not in the directory where you ran repo init. "
        echo "Please rerun this script from that location."
	return 30 
fi

export MYDROID=`pwd`
echo ">>> Your variable MYDROID = $MYDROID"

if [ -d $MYDROID/logs ]; then
	echo ">>> logs directory already exist"
	export LOGS=$MYDROID/logs
	echo ">>> Your variable LOGS = $LOGS"
else
	echo ">>> Creating logs directory"
	mkdir $MYDROID/logs
	export LOGS=$MYDROID/logs
	echo ">>> Your variable LOGS = $LOGS"
fi

export PATH=$MYDROID/bootable/bootloader/u-boot/tools:$PATH
export TOOL_CHAIN_HOME=/usr/local/csl/arm-2008q3
export CROSS_COMPILE=$TOOL_CHAIN_HOME/bin/arm-none-linux-gnueabi-

echo "TOOL_CHAIN_HOME = $TOOL_CHAIN_HOME"
echo "CROSS_COMPILE = $CROSS_COMPILE"

#GFX DDK variables:
if [ -n "$gfx" ]; then
export CC_PATH=$TOOL_CHAIN_HOME
export KERNELDIR=$MYDROID/kernel/android-2.6.29
export ANDROID_ROOT=$MYDROID
export ANDROID_PRODUCT=zoom2
export DISCIMAGE=$MYDROID/out/target/product/zoom2
echo "Your GFX DDK variables are: 
CC_PATH = $CC_PATH
KERNELDIR = $KERNELDIR
ANDROID_ROOT = $ANDROID_ROOT
ANDROID_PRODUCT = $ANDROID_PRODUCT
DISCIMAGE = $DISCIMAGE"
fi
