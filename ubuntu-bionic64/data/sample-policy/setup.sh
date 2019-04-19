#!/bin/bash

ovs-vsctl add-br br-int
ovs-vsctl add-br br-fabric
ovs-vsctl add-br br-ex

ip tuntap add tap1ba834ab-50 mode tap
ip link set tap1ba834ab-50 up

ovs-vsctl add-port br-int tap1ba834ab-50
ovs-vsctl add-port br-int qpf1ba834ab-50 -- set interface qpf1ba834ab-50 type=patch options:peer=qpi1ba834ab-50
ovs-vsctl add-port br-fabric qpi1ba834ab-50 -- set interface qpi1ba834ab-50 type=patch options:peer=qpf1ba834ab-50

ovs-vsctl add-port br-ex patch-ex-fabric -- set interface patch-ex-fabric type=patch options:peer=patch-fabric-ex
ovs-vsctl add-port br-fabric patch-fabric-ex -- set interface patch-fabric-ex type=patch options:peer=patch-ex-fabric
ovs-vsctl add-port br-fabric br-fab_vxlan0 -- set interface br-fab_vxlan0 type=vxlan options:remote_ip=flow options:key=flow options:dst_port=8472
