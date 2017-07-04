#!/bin/bash

function get_ip()
{
	local interface=$1

	local ip=$(/sbin/ip -o -4 addr list ${interface} | awk '{print $4}' | cut -d/ -f1)

	echo $ip
}

base_name=$(hostname -s)
interface=ens8f0
echo "|${base_name} | $(get_ip eno1) | ${interface} | mlx5_2 |  $(get_ip ${interface} ) | [${base_name}-ilo](http://${base_name}-ilo) |"
