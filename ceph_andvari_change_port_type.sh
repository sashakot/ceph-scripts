#!/bin/bash

mst start
ibv_devinfo  | grep vendor_part_id
mlxconfig --yes -d /dev/mst/mt4115_pciconf0 set LINK_TYPE_P1=2 LINK_TYPE_P2=1
reboot
