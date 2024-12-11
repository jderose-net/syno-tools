#!/bin/sh

# the purpose of this script is to create a Vlan interface via an Open vSwitch
# bridge, assign it an address, and test connectivity to the router.
#
# note: must be run as root (i.e., sudo); also, be sure to chmod +x the file.

if [ "$#" -ne 5 ]; then
    echo "usage: `basename $0` <PARENT> <BRIDGE> <VLANID> <CIDRIP> <ROUTER>"
    exit 1
fi

# example:
#   sudo ./ovs-vlans.sh ovs_eth5 eth5-br11 11 10.0.11.1/24 10.0.11.1
# 
# program will create a bridge interface (eth5-br11) off parent (ovs_eth5),
# assigned address (10.0.11.51) with broadcast (10.0.11.255; calculated).
# it will then attempt to ping a gateway (10.0.11.1) to test the interface.

PARENT="$1"		# existing interface
BRIDGE="$2"		# vlan bridge interface (to be created)
VLANID="$3"
CIDRIP="$4"
ROUTER="$5"
BRDCST=$(ipcalc -b $CIDRIP | grep BROADCAST | cut -d '=' -f 2)

echo "## deleting bridge interface"
ovs-vsctl --if-exists del-br $BRIDGE

echo "## creating bridge interface"
ovs-vsctl add-br $BRIDGE $PARENT $VLANID

echo "## setting ip addr on bridge interface"
ip addr flush dev $BRIDGE
ip addr add $CIDRIP brd $BRDCST dev $BRIDGE

echo "## bringing up interface"
ip link set $BRIDGE up

echo "## pinging the router"
ping -c 1 -w 1 -q $ROUTER

if [ $? -eq 0 ]; then
    echo "## passed"
	exit 0
else
    echo "## failed"
	exit 1
fi


#!/bin/bash

# Rest of the script logic
echo "## Deleting existing bridge interface ($BRIDGE)..."
ovs-vsctl --if-exists del-br $BRIDGE || { echo "Failed to delete existing bridge"; exit 1; }

echo "## Creating new bridge interface ($BRIDGE) with VLAN ID $VLANID..."
ovs-vsctl add-br $BRIDGE $PARENT $VLANID || { echo "Failed to create bridge interface"; exit 1; }

echo "## Configuring IP address ($CIDRIP) on $BRIDGE..."
ip addr flush dev $BRIDGE
ip addr add $CIDRIP brd $BRDCST dev $BRIDGE || { echo "Failed to set IP address"; exit 1; }

echo "## Bringing up interface ($BRIDGE)..."
ip link set $BRIDGE up || { echo "Failed to bring up interface"; exit 1; }

echo "## Testing connectivity to router ($ROUTER)..."
ping -c 1 -w 1 -q $ROUTER
if [ $? -eq 0 ]; then
    echo "## Connectivity test passed"
    exit 0
else
    echo "## Connectivity test failed"
    exit 1
fi