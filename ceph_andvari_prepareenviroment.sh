#!/bin/bash

folder="/scrap"
repository="https://github.com/ceph/ceph.git"
branch=master

sudo mkdir -p $folder
sudo chown -R $USER $folder
chmod a+rw -R $folder

cd $folder
git clone --recursive ${repository}
cd ceph
git submodule update --force --init --recursive
git checkout master
./install-deps.sh
./do_cmake.sh
cd build
make -j
