#!/bin/bash

# build flags
#uboot=0
#xloader=0
#kernel=0
#afs=0
#all=0

usage () {
	echo "Usage: ecloud.sh -l <build label> <targets>
targets:[uboot|xloader|kernel|afs|all]
	uboot: builds u-boot
	xloader: builds x-loader
	kernel: builds kernel and its modules
	afs: builds Android File System
	all: builds all of the above targets
label: [LXX.XX|LinuxXX.XX|Any_char(s)XX.XX]"
	exit 64 # command line usage error
}

# process command line arguments
until [ -z "$1" ]; do
	case "$1" in
	-l)
		shift
		label=$1
		;;
	uboot) uboot=1;;
	xloader) xloader=1;;
	kernel) kernel=1;;
	afs) afs=1;;
	all)
		uboot=1
		xloader=1
		kernel=1
		afs=1
		;;
	*)
		echo "Wrong argument: $1"
		usage
	esac
	shift
done

if [ -z "$uboot" ] && [ -z "$xloader" ] && [ -z "$kernel" ] && [ -z "$afs" ]
then 
	echo "No target selected"
	usage
fi

while [[ ! $label =~ [[:alpha:]]+[[:digit:]]{2}.*\.[[:digit:]]{2} ]]; do
	echo "No label or wrong label format, please type a correct label: "
	read label
done

if [ ! -d .repo ]; then
        echo "You are not in the directory where you ran repo init. "
        echo "Please rerun this script from that location."
        exit
fi

export MYDROID=`pwd`
echo ">>> Your variable MYDROID = $MYDROID"

if [ -d $MYDROID/logs ]; then
        echo ">>> logs directory already exist"
        LOGS=$MYDROID/logs
        echo ">>> Your variable LOGS = $LOGS"
else
        echo ">>> Creating logs directory"
        mkdir $MYDROID/logs
        LOGS=$MYDROID/logs
        echo ">>> Your variable LOGS = $LOGS"
fi

# Change these variables according to your local settings:
JAVA_HOME=/usr/lib/jvm/java-1.5.0-sun
TOOL_CHAIN_HOME=/usr/local/csl/arm-2008q3
export CROSS_COMPILE=$TOOL_CHAIN_HOME/bin/arm-none-linux-gnueabi-
export PATH=$MYDROID/bootable/bootloader/u-boot/tools:$PATH:/opt/ecloud/i686_Linux/bin

# Electric Cloud basic settings:
EC_MANAGER=10.87.226.192
EC_CLASS=android
EC_MAXAGENTS=12
#EC_ROOT=$JAVA_HOME/bin:/home/lgonzalez/bin:$MYDROID:$TOOL_CHAIN_HOME:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
EC_ROOT=/home/lgonzalez/bin:$MYDROID:$TOOL_CHAIN_HOME:/usr/bin:/usr/sbin:/usr/lib:/usr/include:/usr/share/bison
EC_HISTORYDIR=/home/lgonzalez/emake_history
EC_BUILD_LBL=$label

# U-BOOT build block
if [ -n "$uboot" ]; then
cd $MYDROID/bootable/bootloader/u-boot
make clean
make omap3430zoom2_config
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/emake_uboot.out emake \
--emake-cm=$EC_MANAGER \
--emake-class=$EC_CLASS \
--emake-maxagents=$EC_MAXAGENTS \
--emake-build-label=$EC_BUILD_LBL \
--emake-root=$EC_ROOT \
--emake-annofile=$MYDROID/logs/emake_build_uboot.xml \
--emake-annodetail=basic \
--emake-historyfile=$EC_HISTORYDIR/emake_uboot.data $@ 2>&1 |tee $MYDROID/logs/emake_uboot.out
fi

# X-LOADER build block
if [ -n "$xloader" ]; then
cd $MYDROID/bootable/bootloader/x-loader
make clean
make omap3430zoom2_config
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/emake_xloader.out emake \
--emake-cm=$EC_MANAGER \
--emake-class=$EC_CLASS \
--emake-maxagents=$EC_MAXAGENTS \
--emake-build-label=$EC_BUILD_LBL \
--emake-root=$EC_ROOT \
--emake-annofile=$MYDROID/logs/emake_build_xloader.xml \
--emake-annodetail=basic \
--emake-historyfile=$EC_HISTORYDIR/emake_xloader.data $@ ift 2>&1 |tee $MYDROID/logs/emake_xloader.out
fi

# KERNEL build block
if [ -n "$kernel" ]; then
cd $MYDROID/kernel/android-2.6.29
make clean
make zoom2_defconfig
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/emake_kernel.out emake \
--emake-cm=$EC_MANAGER \
--emake-class=$EC_CLASS \
--emake-maxagents=$EC_MAXAGENTS \
--emake-build-label=$EC_BUILD_LBL \
--emake-root=$EC_ROOT \
--emake-annofile=$MYDROID/logs/emake_build_kernel.xml \
--emake-annodetail=basic \
--emake-historyfile=$EC_HISTORYDIR/emake_kernel.data $@ uImage 2>&1 |tee $MYDROID/logs/emake_kernel.out

/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/emake_modules.out emake \
--emake-cm=$EC_MANAGER \
--emake-class=$EC_CLASS \
--emake-maxagents=$EC_MAXAGENTS \
--emake-build-label=$EC_BUILD_LBL \
--emake-root=$EC_ROOT \
--emake-annofile=$MYDROID/logs/emake_build_modules.xml \
--emake-annodetail=basic \
--emake-historyfile=$EC_HISTORYDIR/emake_modules.data $@ modules 2>&1 |tee $MYDROID/logs/emake_modules.out
fi

# Android File System build block
if [ -n "$afs" ]; then
cd $MYDROID/system/wlan/ti/wilink_6_1/platforms/os/linux
export ARCH=arm
export HOST_PLATFORM=zoom2
export KERNEL_DIR=$MYDROID/kernel/android-2.6.29
make clean
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/emake_wifi.out emake \
--emake-cm=$EC_MANAGER \
--emake-class=$EC_CLASS \
--emake-maxagents=$EC_MAXAGENTS \
--emake-build-label=$EC_BUILD_LBL \
--emake-root=$EC_ROOT \
--emake-annofile=$MYDROID/logs/emake_build.xml \
--emake-annodetail=basic \
--emake-historyfile=$EC_HISTORYDIR/emake_wifi.data $@ 2>&1 |tee $MYDROID/logs/emake_wifi.out

cd $MYDROID
cp -f vendor/ti/zoom2/buildspec.mk.default buildspec.mk
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/emake_AFS.out emake \
--emake-cm=$EC_MANAGER \
--emake-class=$EC_CLASS \
--emake-maxagents=$EC_MAXAGENTS \
--emake-build-label=$EC_BUILD_LBL \
--emake-root=$EC_ROOT:/etc/alternatives \
--emake-annofile=$MYDROID/logs/emake_build_AFS.xml \
--emake-annodetail=basic,history,file \
--emake-annoupload=1 \
--emake-historyfile=$EC_HISTORYDIR/emake_AFS.data $@ 2>&1 |tee $MYDROID/logs/emake_AFS.out
fi
