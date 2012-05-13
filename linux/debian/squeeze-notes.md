---
title: Notes on Debian 6.0 aka Squeeze
layout: page
bodyClass: red
group: navigation
tags: [linux,debian,squeeze,installation,configuration]
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
