#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2020, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`

function start_hbtp()
{
        # Start the Host based Touch processing but not in the power off mode.
        bootmode=`getprop ro.bootmode`
        if [ "charger" != $bootmode ]; then
                start vendor.hbtp
        fi
}

function enable_memory_features()
{
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    if [ $MemTotal -le 2097152 ]; then
        # Enable B service adj transition for 2GB or less memory
        setprop ro.vendor.qti.sys.fw.bservice_enable true
        setprop ro.vendor.qti.sys.fw.bservice_limit 5
        setprop ro.vendor.qti.sys.fw.bservice_age 5000

        # Enable Delay Service Restart
        setprop ro.vendor.qti.am.reschedule_service true
    fi
}

case "$target" in
    "sm6115")

        # Apply settings for sm6115
        # Set the default IRQ affinity to the silver cluster. When a
        # CPU is isolated/hotplugged, the IRQ affinity is adjusted
        # to one of the CPU from the default IRQ affinity mask.

        echo f > /proc/irq/default_smp_affinity

#        if [ -f /sys/devices/soc0/hw_platform ]; then
#            hw_platform=`cat /sys/devices/soc0/hw_platform`
#        else
#            hw_platform=`cat /sys/devices/system/soc/soc0/hw_platform`
#        fi

#        case "$hw_platform" in
#            "MTP" | "QRD" | "IDP" )
#            start_hbtp
#            ;;
#        esac

        if [ -f /sys/devices/soc0/soc_id ]; then
                soc_id=`cat /sys/devices/soc0/soc_id`
        else
                soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi

        case "$soc_id" in
            "365" | "366" )

        #
        # Setting b.L scheduler parameters
        #

        # Disable sched_boost in post-boot :
		# [cpu_boost is already enabled]
        echo 0 > /proc/sys/kernel/sched_boost

        # Default sched up and down migrate
        echo 65 > /proc/sys/kernel/sched_downmigrate
        echo 95 > /proc/sys/kernel/sched_upmigrate

        # Default sched up and down migrate
        echo 65 > /proc/sys/kernel/sched_group_downmigrate
        echo 95 > /proc/sys/kernel/sched_group_upmigrate

        echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

        # Colocation v3 settings
        echo 1000000 > /proc/sys/kernel/sched_little_cluster_coloc_fmin_khz


        #
        # Setting b.L governor parameters
        #

        # Little Cluster
        echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

        echo 0 /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
        echo 1612800 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
        echo 85 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_load
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/pl
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us

        # Big Cluster
        echo "schedutil" > /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor

        echo 0 /sys/devices/system/cpu/cpu6/cpufreq/schedutil/down_rate_limit_us
        echo 2169600 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq
        echo 85 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_load
        echo 0 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/pl
        echo 0 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/up_rate_limit_us

        # Turn ON sleep mode
        echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled


        #
        # Set Memory parameters
		#
        configure_memory_parameters

        # Enable bus-dcvs
        for device in /sys/devices/platform/soc
        do

        for cpubw in $device/*cpu-cpu-llcc-bw/devfreq/*cpu-cpu-llcc-bw
        do
	      echo "bw_hwmon" > $cpubw/governor
	      echo 50 > $cpubw/polling_interval
	      echo 45 > $cpubw/bw_hwmon/down_thres
	      echo 0 > $cpubw/bw_hwmon/guard_band_mbps
	      echo 20 > $cpubw/bw_hwmon/hist_memory
	      echo 0 > $cpubw/bw_hwmon/hyst_length
	      echo 1600 > $cpubw/bw_hwmon/idle_mbps
	      echo 65 > $cpubw/bw_hwmon/io_percent
	      echo "2288 4577 7110 9155 12298 14236" > $cpubw/bw_hwmon/mbps_zones
	      echo 4 > $cpubw/bw_hwmon/sample_ms
	      echo 250 > $cpubw/bw_hwmon/up_scale
          echo 85 > $cpubw/bw_hwmon/up_thres
	    done

	    for llccbw in $device/*cpu-llcc-ddr-bw/devfreq/*cpu-llcc-ddr-bw
	    do
	      echo "bw_hwmon" > $llccbw/governor
	      echo 50 > $llccbw/polling_interval
	      echo 45 > $llccbw/bw_hwmon/down_thres
	      echo 0 > $llccbw/bw_hwmon/guard_band_mbps
	      echo 20 > $llccbw/bw_hwmon/hist_memory
	      echo 0 > $llccbw/bw_hwmon/hyst_length
	      echo 1600 > $llccbw/bw_hwmon/idle_mbps
	      echo 65 > $llccbw/bw_hwmon/io_percent
	      echo "1144 1720 2086 2929 3879 5931 6881" > $llccbw/bw_hwmon/mbps_zones
	      echo 4 > $llccbw/bw_hwmon/sample_ms
	      echo 250 > $llccbw/bw_hwmon/up_scale
          echo 85 > $llccbw/bw_hwmon/up_thres
	    done

	    # Enable mem_latency governor for L3, LLCC, and DDR scaling
	    for memlat in $device/*cpu*-lat/devfreq/*cpu*-lat
	    do
	      echo "mem_latency" > $memlat/governor
	      echo 10 > $memlat/polling_interval
	      echo 400 > $memlat/mem_latency/ratio_ceil
        done

        # Gold L3 ratio ceil
          echo 4000 > /sys/class/devfreq/soc:qcom,cpu6-cpu-l3-lat/mem_latency/ratio_ceil

        # Enable cdspl3 governor for L3 cdsp nodes
        for l3cdsp in $device/*cdsp-cdsp-l3-lat/devfreq/*cdsp-cdsp-l3-lat
        do
          echo "cdspl3" > $l3cdsp/governor
        done

	    # Enable compute governor for gold latfloor
	    for latfloor in $device/*cpu*-ddr-latfloor*/devfreq/*cpu-ddr-latfloor*
	    do
	      echo "compute" > $latfloor/governor
	      echo 10 > $latfloor/polling_interval
	    done

        # Enable compute governor for npu
        for npubw in $device/*npu-npu-ddr-bw/devfreq/*npu-npu-ddr-bw
        do
          echo "bw_hwmon" > $npubw/governor
          echo 50 > $npubw/polling_interval
          echo 45 > $npubw/bw_hwmon/down_thres
          echo 0 > $npubw/bw_hwmon/guard_band_mbps
          echo 20 > $npubw/bw_hwmon/hist_memory
          echo 10 > $npubw/bw_hwmon/hyst_length
          echo 0 > $npubw/bw_hwmon/idle_mbps
          echo 65 > $npubw/bw_hwmon/io_percent
          echo "1144 1720 2086 2929 3879 5931 6881" > $npubw/bw_hwmon/mbps_zones
          echo 4 > $npubw/bw_hwmon/sample_ms
          echo 250 > $npubw/bw_hwmon/up_scale
          echo 85 > $npubw/bw_hwmon/up_thres
        done

          echo 0 > /sys/devices/virtual/npu/msm_npu/pwr

        done

            ;;
        esac
    ;;
esac

# Post-setup services
case "$target" in
    "sm6150")

        setprop vendor.post_boot.parsed 1
    ;;
esac

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Parse misc partition path and set property
misc_link=$(ls -l /dev/block/bootdevice/by-name/misc)
real_path=${misc_link##*>}
setprop persist.vendor.mmi.misc_dev_path $real_path

# Change console log level as per console config property
console_config=`getprop persist.console.silent.config`
case "$console_config" in
    "1")
        echo "Enable console config to $console_config"
        echo 0 > /proc/sys/kernel/printk
        ;;
    *)
        echo "Enable console config to $console_config"
        ;;
esac
