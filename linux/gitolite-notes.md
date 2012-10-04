---
title: Notes on Gitolite on Debian
layout: page
bodyClass: red
group: navigation
tags: [linux, debian, git, gitolite]
---

Here is a few notes I'm taking when installing, managing, upgrading or simply
using [gitolite](http://github.com/sitaramc/gitolite) on Debian.

# Installatoion

The idea is to install gitolite from source because debian package are not
always up to date. We could create an up-to-date package but… meh… this will
come later.

The user will be ``git`` so url to clone will be ``git@mydomain.com:…``. We
are going to use ``/var/git`` folder for __home__ (because ``/var`` is, on the
server I used, the data partition with a lots of space).

Be sure to get the dependencies you'll need for gitolite :

    apt-get install git perl

Note: You might want to have an up-to-date git installation. On squeeze, the
best idea would be to use [squeeze-backports](http://backports.debian.org) 
and install git from it.

## Create users & groups

We are going to create a user ``git`` and a group with the same name (for
unix access purpose).

    addgroup --system git
    adduser --system --home /var/git --ingroup git git

You will have to change the shell of the user _git_. When creating a system
user, the default shell is ``/bin`false``, which does nothing. The idea is to
change it to ``/bin/bash``, or any posix compatible "sh", for now.

    # edit /etc/passwd
    vim /etc/passwd
    # ex
    # git:x:103:105:/var/git:/bin/sh

It might be a good idea to add the user _git_ in the group _www-data_. It
might be needed for application runned by _www-data_ (in apache for example)
that want to access to the repositories ([redmine](http://redmine.org), …).
Or to add the _www-data_ user to the _git_ group… It depends (``\o/``).

    adduser git www-data
    # or
    adduser www-data git

## Get gitolite

We are going to use git to get [gitolite]().

    su - git
    pwd # → /var/git
    git clone git://github.com/sitaramc/gitolite.git
    cd gitolite

We want to use a stable version. The ``master`` branche might be stable enough
but we are going to use a tagged version.

    git checkout v3.04

## Install gitolite

As the document state it, there is several options. We are going to use the
number 2 :

> Keep the sources anywhere and symlink just the gitolite program to some directory on your $PATH.

First thing first, be sure to have ``$HOME/bin`` in your ``PATH`` environement
variable. The simplest way to be sure of it is the following

    env | grep PATH
    # assuming it is not in PATH
    # assuming your shell is bash
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> $HOME/.profile

That way, when updating the checked tag in the source folder of gitolite, it
will be automatically up-to-date.

    mkdir $HOME/bin # → /var/git/bin
    ./install -ln
    # refer to the documentation if you want it elsewhere than $HOME/bin

## Setup gitolite

The real stuff happens here. The first thing to do, is to send the ssh public
key of the admin to the server you're installing gitolite to. Feel free to
proceed as you want (scp, rsync, usb key, pigeon, …).

    # assuming the public key is here : /tmp/admin.pub
    gitolite setup -pk /tmp/admin.pub

And that should be it. Test it by cloning the ``gitolite-admin.git``
repository.

    git clone git@yourhost.tld:gitolite-admin.git

# Migration notes

If your migrating your repositories from an existing gitolite installation
(source) to a new one (destination), there is a few step to take, based on the
[documentation](http://sitaramc.github.com/gitolite/rare.html#existing).

First things first, __change the source rules to set all repositories to
read-only for everybody__. This way, no need to worry for concurrent access
when moving repositories.

    ssh git@source writable @all off << EOF
    Maintenance action (migration), repositories are set to read-only.
    Please wait for the end of the migration please ;)
    EOF

Then, move the repositories from the _source_ to the _destination_. I tend to
use rsync for that task and I am note syncing ``/var/git/repositories``
up-front on destination.

    # on source
    rsync -ave ssh --progress /var/git/repositories root@destination:/var/tmp/repositories --dry-run
    # if it seems ok, run it for real
    rsync -ave ssh --progress /var/git/repositories root@destination:/var/tmp/repositories

Then set the right user on destination and copy them to the
``/var/git/repositories``. Don't copy the ``gitolite-admin`` repository, it's
better to modify it via git _push_.

    chown -R git:git /var/tmp/repositories
    mv /var/tmp/repositories/gitolite-admin.git /tmp # or remove it
    su - git
    mv /var/tmp/repositories/* /var/git/repositories/

Next, copy or modify the gitolite.rc to your needs.

Finally, you can run ``gitolite setup`` and re-push the ``gitolite-admin``
from your workstation.


