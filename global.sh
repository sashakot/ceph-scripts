#!/bin/bash

function check_pdsh()
{
	if ! hash pdsh 2>/dev/null; then
		sudo yum -y install pdsh.x86_64 || echo >&2 "Error:pdsh is required"; exit 1
	fi
}

function up_network_interface()
{
	local hosts=$1
	local pdsh_hosts=${hosts// /,}

	check_pdsh
	sudo pdsh -w "$pdsh_hosts" 'ibdev2netdev | grep Up | head -1 | cut -d" " -f5 | xargs -I% ifconfig %  up  '
}


function discover_osds () {
	local hosts=$1
	local pdsh_hosts=${hosts// /,}

	for i in "${hosts[@]}"; do
		#determine what roots disk is on remote node in cluster
		rootdisk=$(ssh -q $i mount | grep "on \/ " | awk {'print $1'} | sed 's/.....//;s/.$//g')
		#determine all disks available to remote node in cluster
		alldisks=$(ssh -q $i sudo /usr/sbin/parted -l | grep "Disk \/" | awk {'print $2'} | sed 's/.....//;s/.$//g' | xargs)
		#expand all disks and strip roots disk and white space
		osds=$(echo "$alldisks" | sed 's/'$rootdisk'//g;s/^[ \t]*//')
		#Put the disk and node together in usable ceph-deploy format; result is $nosds
		for d in $osds; do
			#echo $rootdisk
			#echo $alldisks
			nosds=$(echo $i:$d)
			echo $nosds
		done
	done
}

function install_packages()
{
	local hosts=$1
	local packages=$2
	local pdsh_hosts=${hosts// /,}

	check_pdsh

	sudo pdsh -w ${pdsh_hosts} yum -y install "$packages"

}

dev_packages="pdsh.x86_64 environment-modules.x86_64 parted"

install_packages $(hostname -s) "${dev_packages}"
echo $(discover_osds $(hostname -s))
