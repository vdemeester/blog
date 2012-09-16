---
title: Notes on installing Debian Squeeze with XEN on a ssd disk
layout: page
bodyClass: red
group: navigation
tags: [linux, debian, squeeze, installation, configuration, ssd, xen]
---

These notes are taken from the installation I've done by installaing Debian
+ XEN on a Thinkpad x61s with a SSD hard drive using SystemRescueCD.

# SSD Hard drive initialization

- Réinitialize + verification : badlocks
    badblocks -vw /dev/sda

- Partitionning alignment with fdisk -c -u /dev/sda

    /dev/sda1   /boot   100M  ext2
    /dev/sda2   /       20G   ext4
    /dev/sda3   swap    5G
    /dev/sda4   lvm

- Formatting the filesystem with options : mkfs.ext4 -b 4096 -E stride=32

- Init lvm and create the home lv

    pvcreate /dev/sda4
    vgcreate kyushu /dev/sda4
    lvcreate -L26G -nhomes kyushu
    mkfs.ext4 -b 4096 -E stride=32 /dev/kyushu/homes

# Installation using deboostrap

- Mount partions

    mkdir /mnt/debian
    mount -orw,noatime,nodiratime,commit=100,discard /dev/sda2 /mnt/debian
    mkdir /mnt/debian/{home,boot}
    mount -orw,noatime,nodiratime,commit=100,discard /dev/kyushu/homes /mnt/debian/home
    mount /dev/sda1 /mnt/debian/boot

- Run initial deboostrap

    debootstrap --arch=amd64 --include=locales,udev,ssh,vim,sudo,less,openssh-server,zsh,guessnet,resolvconf,console-data,lvm2 stable /mnt/debian http://ftp.fr.debian.org/debian

- Prepare the chroot

    mount -o bind /dev /mnt/debian/dev
    mount -t proc none /proc
    mount -t sysfs none /sys

- Creating files

    vim /mnt/debian/etc/fstab
    vim /mnt/debian/etc/network/interface

- Entering chroot

    LANG=en_US.UTF-8 chroot /mnt/debian /bin/bash

- Reconfiguring locales: dpkg-reconfigure locales

- Update debian repository

    apt-get update
    cat > /etc/apt/source.list.d/backports.list << EOF
    deb http://backports.debian.org/debian-backports squeeze-backports main
    EOF
    apt-get update

- Kernel and bootloader

    apt-get install -t squeeze-backports xen-linux-system-amd64 xen-hypervisor xen-utils xen-tools xen-qemu-dm xenstore-utils
    apt-get install grub
    dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen

- Few stuff

    apt-get -t squeeze-backports install vcsh git mr

Sources :

* http://doc.ubuntu-fr.org/ssd_solid_state_drive
* http://forums.gentoo.org/viewtopic-t-825933-postdays-0-postorder-asc-start-25.html
* http://libre-ouvert.toile-libre.org/index.php?article72/ssd-crucial-m4-64-go-linux-trim-ext4-noatime
* https://sites.google.com/site/lightrush/random-1/checkiftrimonext4isenabledandworking
* http://wiki.debian.org/Xen

