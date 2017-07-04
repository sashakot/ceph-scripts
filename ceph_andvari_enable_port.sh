#!/bin/bash

echo $HOSTNAME
ibdev2netdev
base=${HOSTNAME%%.*}
echo $base
id=${base##*0}
echo $id

ifconfig ens8f0 down
ifconfig  ens8f0 1.1.1.${id}/24 up
ifconfig

