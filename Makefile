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
	wget https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/noble-live-server-riscv64.img.gz || \
	wget https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/pending/noble-live-server-riscv64.img.gz
	pigz -d noble-live-server-riscv64.img.gz

new: noble-live-server-riscv64.img
	rm -f new.img
	sed -e 's/{{PWD}}/$(PWD)/g' update.yaml.in > update.yaml
	sudo livefs-edit noble-live-server-riscv64.img new.img \
	--action-yaml update.yaml
	sudo chown $(UID):$(UID) new.img
