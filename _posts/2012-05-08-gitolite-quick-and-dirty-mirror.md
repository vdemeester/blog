---
layout: post
category : developement
tags : [gitolite, git, linux, mirror, github]
bodyClass : gray
---
{% include setup %}

I'm running a gitolite _instance_ on my personal server to manage my repositories
(personnal, private or public) ; and I am quickly going to share with you how I
setup a _quick and dirty_ mirror feature.

First, I am using **gitolite 3**. The mirroring we are going to setup is not the
_supported_ [mirroring **built-in**](http://sitaramc.github.com/gitolite/mirroring.html).
We are going to implement a simplier way to set mirror thing :

1. Write a custom gitolite command ; the idea is to be able to write `git-config`
   stuff.
2. Write a hook that take a specific `git-config` (let say `mirror.url`) and do
   a simple mirroring.

# Gitolite commands

Gitolite 3 has been rewritten to be more flexible : [Why a completely new version](http://sitaramc.github.com/gitolite/g3why.html).
The rewrite made it really easy to extend gitolite. <del>I've fork [gitolite](https://github.com/vdemeester/gitolite) on github</del>
I've created a [repository git](http://github.com/vdemeester/vdemeester-gitolite-local-code)
to easily add commands to my gitolite instance via _local code_. The gitolite command I wrote is
a quick and dirty script in shell to add `git config`. The source should speek
for itself ; It _should_ include some way to check if the given config is not 
already present in the `gitolite-admin` configuration file — and so might be
rewritten in `Perl`.

The command is `write-git-config` because a `git-config` command already exists
in the built-in commands.

{% highlight bash %}
#!/bin/sh

# Usage:    ssh git@host write-git-config <repo> <key> <value>
#
# Set git-config value for user-created ("wild") repo.

die() { echo "$@" >&2; exit 1; }
usage() { perl -lne 'print substr($_, 2) if /^# Usage/../^$/' < $0; exit 1; }
[ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ] && usage
[ "$1" = "-h" ] && usage
[ -z "$GL_USER" ] && die GL_USER not set

# ----------------------------------------------------------------------
repo=$1; shift
key=$1; shift
value=$1; shift

# this shell script takes arguments that are completely under the user's
# control, so make sure you quote those suckers!

if gitolite query-rc -q WRITER_CAN_UPDATE_DESC
then
    gitolite access -q "$repo" $GL_USER W any || die You are not authorised
else
    gitolite creator "$repo" $GL_USER || die You are not authorised
fi

# if it passes, $repo is a valid repo name so it is known to contain only sane
# characters.  This is because 'gitolite creator' return true only if there
# *is* a repo of that name and it has a gl-creator file that contains the same
# text as $GL_USER.

configfile=`gitolite query-rc GL_REPO_BASE`/"$repo".git/config

git config --file "$configfile" "$key" "$value"
{% endhighlight %}

# Gitolite hooks

The next step is to write a quick `post-receive` hook that check if there is a
certain `git-config` entry and run `git push --mirror`. The file is in 
`$HOME/.gitolite/hooks/common/post-receive` ; you could add a better system to
hooks (to be able to add "dynamic" hooks, …).

{% highlight bash %}
#!/bin/sh

# Simple gitolite mirroring

# flush STDIN coming from git, because gitolite's own post-receive.mirrorpush
# script does the same thing
[ -t 0 ] || cat >/dev/null

[ -z "$GL_REPO" ] && die GL_REPO not set

target=`git config --get mirror.url`
[ -z "$target" ] && exit 0

# Support a REPO variable for wildcard mirrors
gl_repo_escaped=$(echo $GL_REPO | sed 's/\//\\\//g')
target=$(echo $target | sed -e "s/REPO/$gl_repo_escaped/g")

# Do the mirror push
git push --mirror $target
{% endhighlight %}

The next, and final step is to run `gitolite compile` to update links to hooks
for every repositories.

# For real

And finaly, this is the final step you'll do.

    $ ssh git@host write-git-config vincent/vcsh-home mirror.url git@github.com:vdemeester/vcsh-home.git
    $ git push
    Counting objects: 5, done.
    Delta compression using up to 2 threads.
    Compressing objects: 100% (3/3), done.
    Writing objects: 100% (3/3), 294 bytes, done.
    Total 3 (delta 2), reused 0 (delta 0)
    remote: To git@github.com:vdemeester/vcsh-home.git
    remote:    65681a8..701c990  master -> master
    To git@host:vincent/vcsh-home.git
       65681a8..701c990  master -> master

And that should be it !

__Update 2012/10/04__ : Moved from gitolite fork to _gitolite local code_
repository.
