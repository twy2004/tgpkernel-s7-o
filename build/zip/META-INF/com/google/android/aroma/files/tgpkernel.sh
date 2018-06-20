#!/sbin/sh
# ------------------------------
# TGPKERNEL INSTALLER 4.10.2
# Created by @djb77
#
# Credit also goes to @Tkkg1994,
# @lyapota, @Morogoku, 
# @dwander, and @Chainfire
# for bits of code and/or ideas.
# ------------------------------

# Read option number from updater-script
OPTION=$1

# Variables
TGPTEMP=/tmp/tgptemp
AROMA=/tmp/aroma
CONFIG=/data/media/0/TGPKernel/config
KERNELPATH=$TGPTEMP/kernels
BUILDPROP=/system/build.prop
remove_list="init.services.rc init.PRIME-Kernel.rc init.spectrum.sh init.spectrum.rc init.primal.rc init.noto.rc kernelinit.sh wakelock.sh super.sh cortexbrain-tune.sh spectrum.sh kernelinit.sh spa init_d.sh initd.sh moro-init.sh sysinit.sh"

if [ $OPTION == "setup" ]; then
	## Set Permissions
	chmod 755 $AROMA/adb
	chmod 755 $AROMA/adb.bin
	chmod 755 $AROMA/fastboot
	chmod 755 $AROMA/busybox
	chmod 755 $AROMA/tar
	chmod 755 $AROMA/tgpkernel.sh
	exit 10
fi

if [ $OPTION == "config_check" ]; then
	## Config Check
	# If config backup is present, alert installer
	mount /dev/block/platform/155a0000.ufs/by-name/USERDATA /data
	if [ -e $CONFIG/tgpkernel-backup.prop ]; then
		echo "install=1" > /tmp/aroma/backup.prop
	fi
	exit 10
fi

if [ $OPTION == "variant_check" ]; then
	## Variant Checks
	getprop ro.boot.bootloader >> /tmp/variant_model
	if grep -q G930 /tmp/variant_model; then
		echo "install=1" > $AROMA/g930x.prop
	fi
	if grep -q G935 /tmp/variant_model; then
		echo "install=1" > $AROMA/g935x.prop
	fi
	rm -f /tmp/variant_model
	exit 10
fi

if [ $OPTION == "setup_extract" ]; then
	## Extract System Files and Kernels
	cd $TGPTEMP
	tar -Jxf kernels.tar.xz
	tar -Jxf system.tar.xz
	exit 10
fi

if [ $OPTION == "rom_check" ]; then
	## ROM Check
	# Initially set for S7
	echo "install=1" > $AROMA/check_s7.prop
	# Check for Deodexed ROMs
	if [ ! -d /system/framework/arm64 ]; then
		echo "install=1" > $AROMA/deodexed.prop
	fi
	# Set for S9 Ports
	if grep -q ro.build.product=star $BUILDPROP; then
		echo "install=0" > $AROMA/check_s7.prop
		echo "install=1" > $AROMA/check_s9port.prop
	fi
	# Set for N8 Oreo Ports
	if grep -q ro.build.product=great $BUILDPROP; then
		if grep -q ro.build.version.release=8.0.0 $BUILDPROP; then
			echo "install=0" > $AROMA/check_s7.prop
			echo "install=0" > $AROMA/check_s9port.prop
			echo "install=1" > $AROMA/check_n8port.prop
		fi
	fi
	exit 10
fi

if [ $OPTION == "config_backup" ]; then
	## Backup Config
	# Check if TGP folder exists on Internal Memory, if not, it is created
	if [ ! -d /data/media/0/TGPKernel ]; then
		mkdir /data/media/0/TGPKernel
		chmod 777 /data/media/0/TGPKernel
	fi
	# Check if config folder exists, if it does, delete it 
	if [ -d $CONFIG-backup ]; then
		rm -rf $CONFIG-backup
	fi
	# Check if config folder exists, if it does, ranme to backup
	if [ -d $CONFIG ]; then
		mv -f $CONFIG $CONFIG-backup
	fi
	# Check if config folder exists, if not, it is created
	if [ ! -d $CONFIG ]; then
		mkdir $CONFIG
		chmod 777 $CONFIG
	fi
	# Copy files from $AROMA to backup location
	cp -f $AROMA/* $CONFIG
	# Delete any files from backup that are not .prop files
	find $CONFIG -type f ! -iname "*.prop" -delete
	# Remove unwanted .prop files from the backup
	cd $CONFIG
	[ -f "$CONFIG/check_s7.prop" ] && rm -f $CONFIG/check_s7.prop
	[ -f "$CONFIG/check_n8port.prop" ] && rm -f $CONFIG/check_n8port.prop
	[ -f "$CONFIG/check_s9port.prop" ] && rm -f $CONFIG/check_s9port.prop
	[ -f "$CONFIG/g930x.prop" ] && rm -f $CONFIG/g930x.prop
	[ -f "$CONFIG/g935x.prop" ] && rm -f $CONFIG/g935x.prop
	for delete_prop in *.prop 
	do
		if grep "item" "$delete_prop"; then
			rm -f $delete_prop
		fi
		if grep "install=0" "$delete_prop"; then
			rm -f $delete_prop
		fi 
	done
	exit 10
fi

if [ $OPTION == "config_restore" ]; then
	## Restore Config
	# Copy backed up config files to $AROMA
	cp -f $CONFIG/* $AROMA
	exit 10
fi

if [ $OPTION == "wipe_magisk_su" ]; then
	## Wipe Magisk / SuperSU
	rm -rf /cache/*magisk* /cache/unblock /data/*magisk* /data/cache/*magisk* /data/property/*magisk* \
        /data/Magisk.apk /data/busybox /data/custom_ramdisk_patch.sh /data/app/com.topjohnwu.magisk* \
        /data/user*/*/magisk.db /data/user*/*/com.topjohnwu.magisk /data/user*/*/.tmp.magisk.config \
        /data/adb/*magisk* 2>/dev/null
	rm -rf /data/su.img /data/stock_boot*.gz /data/supersu /supersu
	exit 10
fi

if [ $OPTION == "kernel_flash" ]; then
	## Flash Kernel (@dwander)
	# Clean up old kernels
	for i in $remove_list; do
		if test -f $i; then
			[ -f $1 ] && rm -f $i
			[ -f sbin/$1 ] && rm -f sbin/$i
			sed -i "/$i/d" init.rc 
			sed -i "/$i/d" init.samsungexynos8890.rc 
		fi
		if test -f sbin/$i; then
			[ -f sbin/$1 ] && rm -f sbin/$i
			sed -i "/sbin\/$i/d" init.rc 
			sed -i "/sbin\/$i/d" init.samsungexynos8890.rc 
		fi
	done
	for i in $(ls ./res); do
		test $i != "images" && rm -R ./res/$i
	done
	[ -f /system/bin/uci ] && rm -f /system/bin/uci
	[ -f /system/xbin/uci ] && rm -f /system/xbin/uci
	# Flash new Image
	cd $KERNELPATH
	if grep -q install=1 $AROMA/g930x.prop; then
		dd of=/dev/block/platform/155a0000.ufs/by-name/BOOT if=$KERNELPATH/boot-s7.img
	fi
	if grep -q install=1 $AROMA/g935x.prop; then
		dd of=/dev/block/platform/155a0000.ufs/by-name/BOOT if=$KERNELPATH/boot-s7e.img
	fi
	sync
	exit 10
fi

if [ $OPTION == "system_patch" ]; then
	## System Patches
	cd $TGPTEMP
	# Copy system
	cp -rf system/. /system
	# Remove unwanted file from /system/app/mcRegistry
	rm -f /system/app/mcRegistry/ffffffffd0000000000000000000000a.tlbin
	# Clean Apex data
	rm -rf /data/data/com.sec.android.app.apex
	# Remove init.d Placeholder
	rm -f /system/etc/init.d/placeholder
	# Delete Wakelock.sh 
	rm -f /magisk/phh/su.d/wakelock*
	rm -f /su/su.d/wakelock*
	rm -f /system/su.d/wakelock*
	rm -f /system/etc/init.d/wakelock*
	exit 10
fi

if [ $OPTION == "splash_flash" ]; then
	## Custom Splash Screen (@Tkkg1994)
	cd /tmp/splash
	mkdir /tmp/splashtmp
	cd /tmp/splashtmp
	$AROMA/tar -xf /dev/block/platform/155a0000.ufs/by-name/PARAM
	cp /tmp/splash/logo.jpg .
	chown root:root *
	chmod 444 logo.jpg
	touch *
	$AROMA/tar -pcvf ../new.tar *
	cd ..
	cat new.tar > /dev/block/platform/155a0000.ufs/by-name/PARAM
	cd /
	rm -rf /tmp/splashtmp
	rm -f /tmp/new.tar
	sync
	exit 10
fi

if [ $OPTION == "supersu" ]; then
	## SuperSU Script (@Chainfire)
	rm -f /data/.supersu
	rm -f /cache/.supersu
	if [ -f "$AROMA/install.prop" ]; then
		INSTALL=`cat $AROMA/install.prop | grep "selected.0" | cut -f 2 -d '='`
		if [ "$INSTALL" = "2" ]; then
			# System
			echo "SYSTEMLESS=false">>/data/.supersu
		elif [ "$INSTALL" = "3" ]; then
			# Systemless Image
			echo "SYSTEMLESS=true">>/data/.supersu
			echo "BINDSBIN=false">>/data/.supersu
		elif [ "$INSTALL" = "4" ]; then
			# Systemless SBIN
			echo "SYSTEMLESS=true">>/data/.supersu
			echo "BINDSBIN=true">>/data/.supersu
		fi
	fi
	if [ -f "$AROMA/encrypt.prop" ]; then
		KEEPVERITY=`cat $AROMA/encrypt.prop | grep "selected.1" | cut -f 2 -d '='`
		if [ "$KEEPVERITY" = "2" ]; then
			# Remove
			echo "KEEPVERITY=false">>/data/.supersu
		elif [ "$KEEPVERITY" = "3" ]; then
			# Keep
			echo "KEEPVERITY=true">>/data/.supersu
		fi
		KEEPFORCEENCRYPT=`cat $AROMA/encrypt.prop | grep "selected.2" | cut -f 2 -d '='`
		if [ "$KEEPFORCEENCRYPT" = "2" ]; then
			# Remove
			echo "KEEPFORCEENCRYPT=false">>/data/.supersu
		elif [ "$KEEPFORCEENCRYPT" = "3" ]; then
			# Keep
			echo "KEEPFORCEENCRYPT=true">>/data/.supersu
		fi
		REMOVEENCRYPTABLE=`cat $AROMA/encrypt.prop | grep "selected.3" | cut -f 2 -d '='`
		if [ "$REMOVEENCRYPTABLE" = "2" ]; then
			# Remove
			echo "REMOVEENCRYPTABLE=true">>/data/.supersu
		elif [ "$REMOVEENCRYPTABLE" = "3" ]; then
			# Keep
			echo "REMOVEENCRYPTABLE=false">>/data/.supersu
		fi
	fi
	if [ -f "$AROMA/misc.prop" ]; then
		FRP=`cat $AROMA/misc.prop | grep "selected.1" | cut -f 2 -d '='`
		if [ "$FRP" = "2" ]; then
			# Enable
			echo "FRP=true">>/data/.supersu
		elif [ "$FRP" = "3" ]; then
			# Disable
			echo "FRP=false">>/data/.supersu
		fi
		BINDSYSTEMXBIN=`cat $AROMA/misc.prop | grep "selected.2" | cut -f 2 -d '='`
		if [ "$BINDSYSTEMXBIN" = "2" ]; then
			# Enable
			echo "BINDSYSTEMXBIN=true">>/data/.supersu
		elif [ "$BINDSYSTEMXBIN" = "3" ]; then
			# Disable
			echo "BINDSYSTEMXBIN=false">>/data/.supersu
		fi
		PERMISSIVE=`cat $AROMA/misc.prop | grep "selected.3" | cut -f 2 -d '='`
		if [ "$PERMISSIVE" = "2" ]; then
			# Enforcing
			echo "PERMISSIVE=false">>/data/.supersu
		elif [ "$PERMISSIVE" = "3" ]; then
			# Permissive
			echo "PERMISSIVE=true">>/data/.supersu
		fi
	fi
	exit 10
fi

if [ $OPTION == "adb" ]; then
	# Install ADB
	rm -f /system/xbin/adb /system/xbin/adb.bin /system/xbin/fastboot
	cp -f $AROMA/adb /system/xbin/adb
	cp -f $AROMA/adb.bin /system/xbin/adb.bin
	cp -f $AROMA/fastboot /system/xbin/fastboot
	chown 0:0 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	chmod 755 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	exit 10
fi

if [ $OPTION == "busybox" ]; then
	## Install Busybox
	rm -f /system/bin/busybox /system/xbin/busybox
	mv $AROMA/busybox /system/xbin/busybox
	chmod 0755 /system/xbin/busybox
	ln -s /system/xbin/busybox /system/bin/busybox
	/system/xbin/busybox --install -s /system/xbin
	exit 10
fi

