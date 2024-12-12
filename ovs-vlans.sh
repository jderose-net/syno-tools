#!/bin/sh

# the purpose of this script is to create a Vlan interface via an Open vSwitch
# bridge; optionally, assign it an address and test connectivity to the router.
#
# note: must be run as root (i.e., sudo); also, be sure to chmod +x the file.

if [ "$#" -ne 3 ] && [ "$#" -ne 5 ]; then
    echo "usage: $(basename $0) <PARENT> <BRIDGE> <VLANID> [<CIDRIP> <ROUTER>]"
    echo "# <PARENT> is the name of the trunk interface (e.g., ovs_eth0)."
    echo "# <BRIDGE> is the name of the bridge interface that will be created."
    echo "# <VLANID> is the vlan that will be assigned to the bridge interface."
    echo "# optional:"
    echo "# <CIDRIP> is the address to assign to the bridge interface."
    echo "# <ROUTER> is the address to ping to test the bridge interface."
    exit 1
fi

# example:
#   sudo ./ovs-vlans.sh ovs_eth5 eth5-br11 11 10.0.11.99/24 10.0.11.1
# 
# program will create a bridge interface (eth5-br11) off parent (ovs_eth5),
# assigned address (10.0.11.99) with broadcast (10.0.11.255; calculated);
# it will then attempt to ping a gateway (10.0.11.1) to test the interface.
#
# note: if you do not pass a CIDRIP and ROUTER, you can specify these values
# using the Synology Network control panel (which might be more intuitive for
# some); however, do not select "Enable VLAN (802.1Q)", as the interface is
# already bound to the vlan you specified when creating the interface and
# will not pass traffic if "double-tagged". importantly, addresses set in the
# UI are not automatically brought up on reboot (#bug).
#
# 2024-12-11: tested on DSM 7.2.2-72806 Update 2 (hw: RS1619xs+ w/10GbE)

PARENT="$1"		# name of the trunk interface (e.g., eth0)
BRIDGE="$2"		# vlan bridge interface (to be created)
VLANID="$3"		# vlan to be assigned to the bridge interface

if [ "$#" -eq 5 ]; then
    CIDRIP="$4"
    ROUTER="$5"
    BRDCST=$(ipcalc -b $CIDRIP | grep BROADCAST | cut -d '=' -f 2)
fi

error() {
    echo "## $2 failed"
    exit 2
}

trap 'error $LINENO $BASH_COMMAND' ERR

# https://www.openvswitch.org/support/dist-docs/ovs-vsctl.8.html

echo "## deleting bridge interface"
ovs-vsctl --if-exists del-br $BRIDGE

echo "## creating bridge interface"
ovs-vsctl add-br $BRIDGE $PARENT $VLANID

echo "## bringing up interface"
ip link set $BRIDGE up || error_exit

if [ -n "$CIDRIP" ] && [ -n "$ROUTER" ]; then
    echo "## setting ip addr on bridge interface"
    ip addr flush dev $BRIDGE
    ip addr add $CIDRIP brd $BRDCST dev $BRIDGE

    echo "## pinging the router"
    ping -c 1 -w 1 -q -I $BRIDGE $ROUTER
    [ $? -eq 0 ] && echo "## passed"
fi

