#!/bin/bash
# author: Luis Gonzalez (lgonzalez@ti.com)

usage () {
	echo "Usage: build_android.sh <targets> [ nand | cp-nand -t <target_dir> | eclair]
targets:[ uboot | xloader | kernel | afs | gfx | all ]
	uboot: builds u-boot
	xloader: builds x-loader
	kernel: builds kernel and its modules
	afs: builds Android File System
	gfx: builds GFX DDK
	all: builds all of the above targets
OPTIONAL:
	nand: creates NAND images and copies them to TARGET_DIR
	cp-nand: only copies NAND images to TARGET_DIR
target_dir:
	directory path where you want binaries to be stored
	eclair: copies files to filesystem for eclair"
	exit 64 # command line usage error
}

# process command line arguments
if [ -z "$1" ]; then
	echo "No arguments passed"
	usage
else
until [ -z "$1" ]; do
	case "$1" in
	uboot) uboot=1;;
	xloader) xloader=1;;
	kernel) kernel=1;;
	afs) afs=1;;
	all)
		uboot=1
		xloader=1
		kernel=1
		afs=1
		gfx=1
		;;
	gfx) gfx=1;;
	nand)
		nand=1
		cpnand=1
		;;
	cp-nand) cpnand=1;;
	eclair) eclair=1;;
	-t)
		shift
		TARGET_DIR=$1
		;;
	*)
		echo "Wrong argument: $1"
		usage
	esac
	shift
done
fi

if [ -n "$cpnand" ] && [ -z "$TARGET_DIR" ]; then
	echo "No target dir specified. Please enter a valid directory path as your target dir: "
	read TARGET_DIR
fi

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
export PATH=$MYDROID/bootable/bootloader/u-boot/tools:$PATH

# U-BOOT build block
if [ -n "$uboot" ]; then
cd $MYDROID/bootable/bootloader/u-boot
make distclean
make omap3430zoom2_config
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/uboot.log make 2>&1 |tee $MYDROID/logs/uboot.log
fi

# X-LOADER build block
if [ -n "$xloader" ]; then
cd $MYDROID/bootable/bootloader/x-loader
make distclean
make omap3430zoom2_config
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/xloader.log make ift 2>&1 |tee $MYDROID/logs/xloader.log
fi

# KERNEL build block
if [ -n "$kernel" ]; then
cd $MYDROID/kernel/android-2.6.29
make distclean
make zoom2_defconfig
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/kernel.log make uImage 2>&1 |tee $MYDROID/logs/kernel.log

/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/kernel_modules.log make modules 2>&1 |tee $MYDROID/logs/kernel_modules.log
fi

# Android File System build block
if [ -n "$afs" ]; then
cd $MYDROID/system/wlan/ti/wilink_6_1/platforms/os/linux
export ARCH=arm
export HOST_PLATFORM=zoom2
export KERNEL_DIR=$MYDROID/kernel/android-2.6.29
make clean
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/wifi.log make 2>&1 |tee $MYDROID/logs/wifi.log

cd $MYDROID
cp -f vendor/ti/zoom2/buildspec.mk.default buildspec.mk
/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/AFS.log make -j4 >&1 |tee $MYDROID/logs/AFS.log
fi

# Build GFX DDK
if [ -n "$gfx" ]; then
	if [ -d GFX_Linux_DDK ]; then
		export CC_PATH=$TOOL_CHAIN_HOME
		export KERNELDIR=$MYDROID/kernel/android-2.6.29
		export ANDROID_ROOT=$MYDROID
		export ANDROID_PRODUCT=zoom2
		cd GFX_Linux_DDK
		chmod +x build_DDK.sh
		./build_DDK.sh --build clobber
		/usr/bin/time -f "Time taken to run command:\n\treal: %E \n\tuser: %U \n\tsystem: %S\n\n" -a -o $MYDROID/logs/gfx_build.log ./build_DDK.sh --build release 2>&1 |tee gfx_build.log
		if cat gfx_build.log |grep rc.pvr &> /dev/null; then
			export DISCIMAGE=$MYDROID/out/target/product/zoom2
			./build_DDK.sh --install release
		else
			echo "GFX build was unsuccessful :("
			exit 1
		fi
	else
		echo "GFX_Linux_DDK directory does not exist. Please get the correct directory from ClearCase"
		exit 1
	fi
fi

# Creates NAND images
if [ -n "$nand" ] && [ -d $MYDROID/out/target/product/zoom2 ]; then
	cd $MYDROID/out/target/product/zoom2
	echo "Removing NAND files... "
	rm -fv *.img
	rm -fv obj/PACKAGING/systemimage_unopt_intermediates/system.img
	echo "Modifying init.rc for NAND boot"
	cp -fv root/init.omapzoom2.rc root/init.rc
	sed -i 's/chmod 0660 \/dev\/ttyS0/#chmod 0660 \/dev\/ttyS0\//' root/init.rc
	sed -i 's/chown radio radio \/dev\/ttyS0/#chown radio radio \/dev\/ttyS0/' root/init.rc
	sed -i  's/#    mount yaffs2 mtd@system \/system$/mount yaffs2 mtd@system \/system/' root/init.rc
	sed -i 's/#    mount yaffs2 mtd@userdata \/data nosuid nodev/     mount yaffs2 mtd@userdata \/data nosuid nodev/' root/init.rc
	sed -i 's/#    mount yaffs2 mtd@cache \/cache nosuid nodev/     mount yaffs2 mtd@cache \/cache nosuid nodev/' root/init.rc
	if [ -n "$gfx" ]; then echo "# Start of SGX driver
service pvrsvr /system/bin/sh /rc.pvr start
user root
oneshot" >> root/init.rc; fi	

	if [ -z "$eclair" ]; then
		cp -fv $MYDROID/system/wlan/ti/wilink_6_1/platforms/os/linux/tiwlan* root
		cp -fv $MYDROID/system/wlan/ti/wilink_6_1/platforms/os/linux/sdio.ko root
	else
		if [ ! -d system/etc/wifi ]; then mkdir -p system/etc/wifi; fi
		cp -fv $MYDROID/system/wlan/ti/wilink_6_1/platforms/os/linux/tiwlan* system/etc/wifi
		cp -fv $MYDROID/system/wlan/ti/wilink_6_1/config/tiwlan.ini system/etc/wifi
	fi

	cd $MYDROID; make -j4
elif [ ! -d out/target/product/zoom2 ] && [ -n "$nand" ]; then
	echo "You have not built AFS. Please build AFS to create NAND images"
	exit 1
fi

# Copies NAND binaries and filesystem
if [ -n "$cpnand" ] && [ -d $MYDROID/out/target/product/zoom2 ]; then
	if [ ! -d $TARGET_DIR/myfs ]; then 
		mkdir -p $TARGET_DIR/myfs
	else
		rm -rf $TARGET_DIR/myfs/* 
	fi
	echo "Copying binaries to $TARGET_DIR"
	cp -fv $MYDROID/out/target/product/zoom2/*.img $TARGET_DIR
	cp -fv $MYDROID/bootable/bootloader/u-boot/u-boot.bin $TARGET_DIR
	cp -fv $MYDROID/bootable/bootloader/x-loader/MLO $TARGET_DIR
	cp -fv $MYDROID/kernel/android-2.6.29/arch/arm/boot/*Image $TARGET_DIR
	cp -fv $MYDROID/bootable/bootloader/u-boot/tools/mkimage $TARGET_DIR
	cp -fv $MYDROID/out/host/linux-x86/bin/fastboot $TARGET_DIR
	cd $MYDROID/out/target/product/zoom2
	echo "Creating filesystem for SD card in $TARGET_DIR/myfs"
	cp -rf root/* $TARGET_DIR/myfs
	cp -rf system $TARGET_DIR/myfs
	cp -rf data $TARGET_DIR/myfs
	cd $TARGET_DIR/myfs
	if [ -n "$eclair" ]; then
		cp -f $MYDROID/vendor/ti/zoom2/omapzoom2-mmc.rc init.rc
	else
		cp -f init.omapzoom2.rc init.rc
	fi
	sed -i 's/chmod 0660 \/dev\/ttyS0/#chmod 0660 \/dev\/ttyS0\//' init.rc
	sed -i 's/chown radio radio \/dev\/ttyS0/#chown radio radio \/dev\/ttyS0/' init.rc
	echo "Done!"
elif [ ! -d $MYDROID/out/target/product/zoom2 ] && [ -n "$cpnand" ]; then
	echo "You have not built AFS. Please build AFS to create NAND images"
	exit 1
fi
