+++
title = "nix run aliases"
date = 2019-01-26
tags = ["nixos"]
draft = true
creator = "Emacs 26.1 (Org mode 9.2 + ox-hugo)"
+++

I use [`NixOS`](https://nixos.org/) each and every day, everywhere. One really cool feature of `nix` is
`nix-shell` and more recently (with `nix` >= `2.0.0`), `nix run`.

```man
Usage: nix run <FLAGS>... <INSTALLABLES>...

Summary: run a shell in which the specified packages are available.

Flags:
      --arg <NAME> <EXPR>         argument to be passed to Nix functions
      --argstr <NAME> <STRING>    string-valued argument to be passed to Nix functions
  -c, --command <COMMAND> <ARGS>  command and arguments to be executed; defaults to 'bash'
  -f, --file <FILE>               evaluate FILE rather than the default
  -i, --ignore-environment        clear the entire environment (except those specified with --keep)
  -I, --include <PATH>            add a path to the list of locations used to look up <...> file names
  -k, --keep <NAME>               keep specified environment variable
  -u, --unset <NAME>              unset specified environment variable

Examples:

  To start a shell providing GNU Hello from NixOS 17.03:
  $ nix run -f channel:nixos-17.03 hello

  To start a shell providing youtube-dl from your 'nixpkgs' channel:
  $ nix run nixpkgs.youtube-dl

  To run GNU Hello:
  $ nix run nixpkgs.hello -c hello --greeting 'Hi everybody!'

  To run GNU Hello in a chroot store:
  $ nix run --store ~/my-nix nixpkgs.hello -c hello

Note: this program is EXPERIMENTAL and subject to change.
```

As you can see from the `-h` summary, it makes it really easy to run a shell or a command
with some packages that are not in your main configuration. It will download the
package(s) if there are not available in the Nix store (`/nix/store/`).

A few month ago I decided it would be a perfect use-case for command I do not run
often. My idea was, let's define `aliases` (in the shell) that would make a simple command
call, like `ncdu`, become `nix run nixpkgs.ncdu -c ndcu`. My _shell of choice_ is [fish](https://fishshell.com/), so
I decided to dig into the _language_ in order to implement that.

The use case is the following :

-   When I type `foo`, I want the command `foo` in package `bar` to be executed.
-   I want to be able to pin a channel for the package — I'm using [Matthew Bauer](https://matthewbauer.us/) [Channel
    Changing with Nix](https://matthewbauer.us/blog/channel-changing.html) setup for pin-pointing a given channel.


## Fish aliases experimentation {#fish-aliases-experimentation}

I had a feeling the built-in `alias` would not work so I ended up trying to define a
_dynamic_ function that would be the name of the command. That's the beauty of the shell,
everything is a command, even function appears as commands. If you define a function
`foo()`, you will be able to run `foo` in your shell, **and** it will take precedence over
the `foo` executable file that would be in your `PATH`.

I ended up with two main helper function that would create those _alias_ function.

```fish
function _nix_run_package
    set -l s $argv[1]
    set -l package (string split ":" $s)
    switch (count $package)
	case 1
	    _nix_run $s $s $argv[2] $argv[3]
	case 2
	    _nix_run $package[1] $package[2] $argv[2] $argv[3]
    end
end

function _nix_run
    set -l c $argv[1]
    set -l p $argv[2]
    set -l channel $argv[3]
    set -l channelsfile $argv[4]
    function $c --inherit-variable c --inherit-variable p --inherit-variable channel --inherit-variable channelsfile
	set -l cmd nix run
	if test -n "$channelsfile"
	    set cmd $cmd -f $channelsfile
	end
	eval $cmd $channel.$p -c $c $argv
    end
end
```

In a nutshell, `_nix_run` is the function that create the alias function. There is so
condition in there depending on whether we gave it a channel or not. So, a call like
`_nix_run foo bar unstable channels.nix` would, in the end generate a function `foo` with
the following call : `nix run -f channels.nix unstable.bar -c foo`.

The other function, `_nix_run_package` is there to make me write less when I define those
aliases — aka if the command and the package share the same name, I don't want to write it
twice. So, a call like `_nix_run_package foo nixpkgs` would result in a `_nix_run foo foo
nixpkgs`, whereas a call like `_nix_run_package foo:bar unstable channels.nix` would
result in a `_nix_run foo bar unstable channels.nix`.

An example is gonna be better than the above paragraphs. This is what I used to have in my
fish configuration.

```fish
function _def_nix_run_aliases
    set -l stable mr sshfs ncdu wakeonlan:python36Packages.wakeonlan lspci:pciutils lsusb:usbutils beet:beets gotop virt-manager:virtmanager pandoc nix-prefetch-git:nix-prefetch-scripts nix-prefetch-hg:nix-prefetch-scripts
    set -l unstable op:_1password update-desktop-database:desktop-file-utils lgogdownloader
    for s in $stable
	_nix_run_package $s nixpkgs
    end
    for s in $unstable
	_nix_run_package $s unstable ~/.config/nixpkgs/channels.nix
    end
end
# Call the function to create the aliases
_def_nix_run_aliases
```

This works like a charm, and for a while, I was happy. But I soon realized something : I'm
not always on my shell — like, I tend to spend more and more time in `eshell`. This also
doesn't work with graphic tools like [`rofi`](https://github.com/DaveDavenport/rofi). I needed actual command, so that external
tools would benefit from that. I ended up writing a small tool, [`nr`](https://github.com/vdemeester/nr) that integrates
nicely with `nix` and [`home-manager`](https://github.com/rycee/home-manager).


## A proper tool : `nr` {#a-proper-tool-nr}

The gist for this tool is simple :

-   create an executable script that will call `nix run ...` instead of the command
-   as for the above fish script, support different channels
-   make sure we don't have conflicts — if the command already exists, then don't create the
    command

The `nr` tool would have to be able to manage multiple _profile_, which really stands for
multiple file. The main reason is really about how I manage my configuration ; To make it
simple, depending on the computer my configurations are setup, I may not have `go`, thus I
don't want any `go`-related aliases for a computer that doesn't have `go` (using `go` here
but you can replace with anything).

```fish
$ nr default
> nr generate default
> virtmanager already exists
$ nr git
> nr generate git
```

`nr` generates a bash script that does the `nr run …` and mark it as executable. `nr`
needs to be able to clean files it has generated (in case we removed it from
aliases). Thus, I went for a really naive comment in the script. When generating a new set
of commands, `nr` will first remove previously generated script for this profile, and for
that, it uses the comment. Let's look at what a generated script looks like, for the
default profile.

```bash
#!/usr/bin/env bash
# Generated by nr default
nix run nixpkgs.nix-prefetch-scripts -c nix-prefetch-git $@
```

The format used in `nr` is `json`. I'm not a _huge fan_ of `json` but it really was the
best format to use for this tool. The reason to use `json` are simple :

-   Go has `encoding/json` built-in, so it's really easy to `Marshall` and `Unmarshall`
    structure.

    ```go
    type alias struct {
    	Command string `json:"cmd"`
    	Package string `json:"pkg"`
    	Channel string `json:"chan"`
    }
    ```
-   Nix also has built-in support for `json` : `builtins.toJSON` will marshall a _struct_
    into a json file.

Finally, to avoid conflicts at _build time_ (`home-manager switch`) I couldn't use/define
a nix package, but to execute command(s) at the end of the build. One way to achieve it is
to use `file.?.onChange` script, which is executed after [`home-manager`](https://github.com/rycee/home-manager) has updated the
environment, **if** the file has changed. That means it's possible to check for executable
files in `~/.nix-profile/bin/` for defined aliases and create those that are not there,
with `nr`. My configuration then looks like the following.

```nix
xdg.configFile."nr/default" = {
  text = builtins.toJSON [
    {cmd = "ncdu";} {cmd = "sshfs";} {cmd = "gotop";} {cmd = "pandoc";}
    {cmd = "wakeonlan"; pkg = "python36Packages.wakeonlan";}
    {cmd = "beet"; pkg = "beets";}
    {cmd = "virt-manager"; pkg = "virtmanager";}
    {cmd = "nix-prefetch-git"; pkg = "nix-prefetch-scripts";}
    {cmd = "nix-prefetch-hg"; pkg = "nix-prefetch-scripts";}
  ];
  onChange = "${pkgs.nur.repos.vdemeester.nr}/bin/nr default";
};
```

And there you are, now, each time I update my environment (`home-manager switch`), `nr`
will regenerate my `nix run` aliases.
