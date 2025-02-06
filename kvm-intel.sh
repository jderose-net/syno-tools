#!/bin/sh
set -euo pipefail

# the purpose of this script is to enable nested kernel-based virtual machines.
#
# note: must be run as root (i.e., sudo); also, be sure to chmod +x the file.
#
# example:
#   sudo ./kvm-intel.sh

# check current value
val="$(cat /sys/module/kvm_intel/parameters/nested)"
if [ "$val" = "Y" ]; then
  echo "kvm_intel nested already enabled. exiting..."
  exit
fi

# unload module
echo "unloading kernel module..."
modprobe -r kvm_intel

# reload module with nested enabled
echo "reloading kernel module..."
modprobe kvm_intel nested=1

# confirm system parameter is set correctly
val="$(cat /sys/module/kvm_intel/parameters/nested)"
if [ $val != "Y" ]; then
  echo "unknown value: $val. exiting..."
  exit 1
else
  echo "success."
fi
