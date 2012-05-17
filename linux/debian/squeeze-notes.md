---
title: Notes on Debian 6.0 aka Squeeze
layout: page
bodyClass: red
group: navigation
tags: [linux, debian, squeeze, installation, configuration]
---

Here is a few notes I took when installing and using [Debian](http://debian.org)
GNU/Linux distrutions in its `6.0` version, named Squeeze.

# First step after installation

First thing first, I want to keep history of changes in my `/etc` folder using
a distributed version controle, like [Git](http://git-scm.com). And there is a
wonderful piece of software for that : [etckeeper](http://joeyh.name/code/etckeeper/).

    # apt-get install etckeeper

On Debian it depends on `git` so it will automatically install `git` and `git-core`
package. At the end of the installation, a git repository is initialized and
everything in `/etc` is added and commited. The next thing I do is to disable the
_daily autocommit_ by uncomment the line `AVOID_DAILY_AUTOCOMMITS=1`. Finally, I
do setup remotes that point to my personal(s) git repository and push to it, just
in case ; It could serve as backup __and__ I might want to checkout it for future
references, etc.

# APT/Dpkg configuration

The next step I usually took is to add additionnal source repository for apt and
add default preferences.

## Sources

We are going to add a few sources : backports, mozilla specific and testing sources.

A quick presentation on backports and mozilla source.list (using quotation).

> Backports are recompiled packages from testing (mostly) and unstable (in a few cases only, e.g. security updates) in a stable environment so that they will run without new libraries (whenever it is possible) on a Debian stable distribution
>
> Backports cannot be tested as extensively as Debian stable, and backports are provided on an as-is basis, with risk of incompatibilities with other components in Debian stable. Use with care!

    # cat /etc/apt/source.list.d/backports.list
    deb http://backports.debian.org/debian-backports squeeze-backports main

For mozilla we will be using the release version for Iceweasel (Firefox) and
esr (entreprise supported release [right ?]) for Icedove.

    # cat /etc/apt/source.list.d/mozilla.list
    deb http://mozilla.debian.net/ squeeze-backports iceweasel-release
    deb http://mozilla.debian.net/ squeeze-backports icedove-esr

Finally, we will use the testing repository to be able to play around with 
_APT-Pinning_. Mainly I, somehow, need it for using a decent version of `mr` and
`pandoc` that are not available in `squeeze-backports`.

## APT Preferences

[Dpkg](http://wiki.debian.org/dpkg) and [APT](http://wiki.debian.org/Apt) are tools that always kept me on debian (and derived) ; I just can't
leave without them. I tend to play a lot with the preferences, located in `/etc/apt/preferences`
and `/etc/apt/preferences.d/`. I put some _sane_ defaults in the main configuration
file (`/etc/apt/preferences`) and I group other configuration in several files
in the `/etc/apt/preferences.d/` folder.

    # cat /etc/apt/preferences
    Package: *
    Pin: release n=squeeze
    Pin-Priority: 700

    Package: *
    Pin: release n=wheezy
    Pin-Priority: 50

    Package: *
    Pin: release n=sid
    Pin-Priority: 50

Next, a file for the backports `squeeze-backports`. We want to be able to install
package from backports that won't be downgrade by the stable version, **but** we
don't want all package from `squeeze-backports` to be installed by default.

    # cat /etc/apt/preferences.d/backports
    Package: *
    Pin: release a=squeeze-backports
    Pin-Priority: 650

And there is a fow other file, currently only for `mr` and `pandoc`.

    # cat /etc/apt/preferences.d/mr
    Package: mr
    Pin: release n=wheezy
    Pin-Priority: 1001
    # cat /etc/apt/preferences.d/pandoc
    Packge: pandoc libpcre3 libpcre3-dev
    Pin: release n=wheezy
    Pin-Priority: 1001

# Network

The network configuration depends a lot on the computer I'm installing Debian (
server, desktop, laptop…). I'll just present here the tools I use and the simplest
configuration I tend to do on my laptops.

I want to have almost the same experience that using `NetworkManager` but without
it, without event need to have a Window system and such. By default, on laptop
the wifi is on and unless I'm going to use a ethernet cable, I want it to be
enabled ; If I want to disable it, I'll use the *killing switch* or a command line.
I also want autodetection of the known network. To have all of this in place, we
are going to need the following softwares : `ifplugd`, `guessnet` and wifi tools
(`wireless-tools` and `wpa_supplicant`).

The `/etc/network/interfaces` will speek by itself :

    # cat /etc/network/interfaces
    auto lo
    iface lo net loopback

    mapping eth0
        script /usr/sbin/guessnet-ifupdown
        map default: default_eth0
        map timeout: 3
        map verbose: true

    iface home-bdx inet dhcp # My home \o/
        test-peer address 192.168.1.… mac …:…:…:…:…:…
        dns-search  ….…
        dns-nameservers 192.168.1.…

    iface default_eth0 inet dhcp

    auto wlan0 # wlan0 will be up by default
    mapping wlan0
        script /usr/sbin/guessnet-ifupdown
        map timeout: 3
        map verbose: true
        map wifi-livebox-… wifi-work-… wifi-home-…
        map default: wifi-…

    iface wifi-livebox-… inet dhcp
        dns-search ….…
        dns-nameservers ….….….…
        wpa-driver wext
        wpa-ssid Livebox-…
        wpa-conf /etc/wpa_supplicant/wifi-livebox-….conf
        test wireless essid Livebox-…

    # […]
    # Like this for each known networks

Next, we'll tell `ifplugd` to detect cable connection on `eth0` (I wish I could
do better with wifi but…).

    # cat /etc/default/ifplugd
    # […] blabla
    INTERFACES="auto"
    HOTPLUG_INTERFACES="eth0"
    ARGS="-q -f -u0 -d10 -w -I"
    SUSPEND_ACTION="stop"

The best way to edit this file is to run `dpkg-reconfigure ifplugd` as you'll
be guide by the Debian dialog.

<!--
# Laptop

laptop-mode-tools, unburden-home, optim boot & co

# Xorg

xorg, urxvt, …

# Development & sysadmin

lxc, schroot, …

## Debian

pbuilder, …
-->
