#!/bin/bash

. $(dirname $0)/global.sh

all_hosts=${all_hosts:-"andvari01 andvari02 andvari03 andvari04 andvari05 andvari06 andvari07 andvari08"}
monitors=${monitors:-"andvari01 andvari02 andvari03"}
osds=${osds:-$all_hosts}
selected_network=${selected_network:-"1.1.1.1/16"}

pdsh_hosts=${all_hosts// /,}

function clean_ceph()
{
	local hosts=$1
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
	local hosts=$1
	local pdsh_hosts=${hosts// /,}

	ceph-deploy --overwrite-conf install --no-adjust-repos  $hosts
	ceph-deploy mon create-initial
	ceph-deploy admin $hosts
	sudo pdsh -w $pdsh_hosts  chmod +rx /etc/ceph/ceph.client.admin.keyring # Mellanox wiki
#	ceph-deploy gatherkeys
}

function create_osd()
{
	local hosts=$1
	# Nodes and discovered OSD's Array format: node1:sdb
	local list=(`discover_osds "${hosts}" | xargs`)

	# clean disks
	for i in "${list[@]}"; do
		ceph-deploy disk zap $i
	done

	# ceph-deploy prepare disks
	for i in "${list[@]}"; do
		ceph-deploy --overwrite-conf osd prepare $i
	done

	# ceph-deploy activate disks
	for i in "${list[@]}"; do
		#strip trailing white space from $i
		osd=$(echo "$i" | sed 's/\s*$//g')
		ceph-deploy osd activate "$osd"1
	done
}

#while getopts "h:" flag_arg; do
#	case $flag_arg in
#		d) hosts="$OPTARG"         ;;
#	esac
#done

echo "List of hosts: $all_hosts"
echo "Monitors: $monitors"
echo "OSDs: $osds"

clean_ceph $all_hosts
install_ceph $all_hosts
create_new_cluster $monitors $selected_network
create_osd $osds

ceph -s
