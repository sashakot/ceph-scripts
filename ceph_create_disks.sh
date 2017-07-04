#!/bin/bash

DISKS=""
for CHOST in andvari0{1..8}; do
	for cdisk in {a..c}; do
		CDISK=sd$cdisk
		DISKS="$DISKS $CHOST:$CDISK"
	done
done

echo $DISKS
