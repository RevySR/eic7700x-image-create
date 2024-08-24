#!/usr/bin/make -f

.PHONY: new

# In update.yaml.in use {{PWD}}/relative-path to copy
# from or to the current directory.

PWD:=${shell pwd | sed -e 's/\//\\\//g'}
KERNEL:=${shell uname -r}
UID :=$(USER)

all:
	make new

noble-live-server-riscv64.img:
	wget https://cdimage.ubuntu.com/releases/noble/release/ubuntu-24.04-live-server-riscv64.img.gz
	pigz -d ubuntu-24.04-live-server-riscv64.img.gz
	mv ubuntu-24.04-live-server-riscv64.img noble-live-server-riscv64.img
	# get https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/noble-live-server-riscv64.img.gz || \
	# wget https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/pending/noble-live-server-riscv64.img.gz
	# pigz -d noble-live-server-riscv64.img.gz

new: noble-live-server-riscv64.img
	rm -f new.img
	sed -e 's/{{PWD}}/$(PWD)/g' update.yaml.in > update.yaml
	sudo livefs-edit noble-live-server-riscv64.img new.img \
	--action-yaml update.yaml
	sudo chown $(UID):$(UID) new.img
	mkdir -p mnt_installer
	mkdir -p mnt_from
	mkdir -p mnt_to
	sudo kpartx -a -v new.img | grep '\loop[0-9]\+p2' | \
	sed -e 's|.*\(loop[0-9]\+\)p2.*|\1|' | \
	awk '{ print "export part_to=\"/dev/mapper/" $$1 "p1\"\nexport part_from=\"/dev/mapper/" $$1 "p2\"\n"}' \
	> env.sh
	sleep 3
	. ./env.sh; sudo mount $$part_to mnt_to
	. ./env.sh; sudo mount $$part_from mnt_installer
	sudo rm -rf mnt_to/dtb/
	sudo mount mnt_installer/casper/ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs mnt_from
	sudo mkdir -p mnt_to/dtb/
	sudo cp -r mnt_from/usr/lib/firmware/*-eswin/device-tree/* mnt_to/dtb/
	find mnt_to
	sudo umount mnt_from
	sudo umount mnt_installer
	sudo umount mnt_to
	sleep 3
	sudo kpartx -d -v new.img
