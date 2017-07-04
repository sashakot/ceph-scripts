#!/bin/bash

all_hosts=${all_hosts:-"andvari01 andvari02 andvari03 andvari04 andvari05 andvari06 andvari07 andvari08"}
monitors=${monitors:-"andvari01 andvari02 andvari03"}
osds=${osds:-$all_hosts}
selected_network=${selected_network:-"1.1.1.1/16"}

pdsh_hosts=${all_hosts// /,}

function clean_ceph()
{
	local hosts =$1
	local pdsh_hosts=${hosts// /,}

	echo "*********** Clean ceph **********************"

	ceph-deploy purge $hosts
	ceph-deploy purgedata $hosts
	ceph-deploy forgetkeys

	sudo pdsh -w $pdsh_hosts  mv /usr/local/bin/ceph{-orig,} 2> /dev/null # Mellanox wiki
}

function create_new_cluster()
{
	local monitors=$1
	local selected_network=$2

	ceph-deploy new  --cluster-network=$selected_network --public-network=$selected_network $monitors
}

function install_ceph()
{
	local hosts =$1
	local pdsh_hosts=${hosts// /,}

	ceph-deploy --overwrite-conf install --no-adjust-repos  $hosts
	ceph-deploy mon create-initial
	ceph-deploy admin $hosts
	sudo pdsh -w $pdsh_hosts  chmod +rx /etc/ceph/ceph.client.admin.keyring # Mellanox wiki
}

function create_osd()
{
	local hosts=$1
	local disks=$2

	local list
	local 

	for host in ${hosts}; do
		for disk in ${disks}; do
			list="${list} ${host}:${disk}"

		done
	done

	echo list

	ceph-deploy --overwrite-conf disk zap $list
	ceph-deploy --overwrite-conf osd prepare $list
}

while getopts "d:" flag_arg; do
	case $flag_arg in
		d) disks="$OPTARG"         ;;
	esac
done

if [ -z "$disks" ];
	"Error: Provide a list of disks"
	exit
fi

echo "List of hosts: $all_hosts"
echo "Monitors: $monitors"
echo "OSDs: $osds"

clean_ceph $all_hosts

create_new_cluster $monitors $selected_network


ceph -s
