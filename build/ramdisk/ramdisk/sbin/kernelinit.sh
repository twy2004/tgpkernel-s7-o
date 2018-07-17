#!/system/bin/sh
#
# Created by @djb77. Code snippets from @Tkkg1994, and @Morogoku
#

# Set Variables
BB="/sbin/busybox"
RESETPROP="/sbin/magisk resetprop -v -n"

# Mount
$BB mount -t rootfs -o remount,rw rootfs
$BB mount -o remount,rw /system
$BB mount -o remount,rw /data
$BB mount -o remount,rw /

# Set KNOX to 0x0 on running /system
$RESETPROP ro.boot.warranty_bit "0"
$RESETPROP ro.warranty_bit "0"

# Fix Safetynet flags
$RESETPROP ro.build.fingerprint "samsung/hero2ltexx/hero2lte:8.0.0/R16NW/G935FXXU2ERG2:user/release-keys"

# Fix Samsung Related Flags
$RESETPROP ro.fmp_config "1"
$RESETPROP ro.boot.fmp_config "1"

# SELinux (0 / 640 = Permissive, 1 / 644 = Enforcing)
echo "0" > /sys/fs/selinux/enforce
chmod 640 /sys/fs/selinux/enforce

# PWMFix (0 = Disabled, 1 = Enabled)
echo "0" > /sys/class/lcd/panel/smart_on

# Stock CPU / GPU Settings
echo "2288000" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo "208000" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
echo "1586000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo "130000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo "650" > /sys/devices/14ac0000.mali/max_clock
echo "260" > /sys/devices/14ac0000.mali/min_clock

# Tweaks: SD-Card Readhead
echo "2048" > /sys/devices/virtual/bdi/179:0/read_ahead_kb

# Tweaks: Internet Speed
echo "0" > /proc/sys/net/ipv4/tcp_timestamps
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse
echo "1" > /proc/sys/net/ipv4/tcp_sack
echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes
echo "30" > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout
echo "404480" > /proc/sys/net/core/wmem_max
echo "404480" > /proc/sys/net/core/rmem_max
echo "256960" > /proc/sys/net/core/rmem_default
echo "256960" > /proc/sys/net/core/wmem_default
echo "4096,16384,404480" > /proc/sys/net/ipv4/tcp_wmem
echo "4096,87380,404480" > /proc/sys/net/ipv4/tcp_rmem

# Customisations


# Unmount
$BB mount -t rootfs -o remount,ro rootfs
$BB mount -o remount,ro /system
$BB mount -o remount,rw /data
$BB mount -o remount,ro /

