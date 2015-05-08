---
title: "Jekyll Forman Guard Bundler"
date: "2012-05-13"
categories :
    - developement
tags :
    - jekyll
    - ruby
    - bundler
    - guard
    - foreman
bodyClass : gray
aliases:
    - /2012/05/jekyll-foreman-guard-bundler/
---

This post is a quick "How did I setup my Jekyll environnement ?". We are going
all the tools that are quite awesome in Ruby.

# Goal

The goal is simple :

1. I want to be able to install any dependent [Gem](http://rubygems.org) with a
   _on-liner_ command
2. I want to be able to run a _Jekyll server_ that auto updates.

We are going to play with : [Bundler](http://gembundler.com/), 
[Guard](https://github.com/guard/guard) and [foreman](https://github.com/ddollar/foreman).

## Bundler

Bundler let us run `bundle install` to get all Ruby Gems we will need ; It use
a file name `Gemfile`. The gems we need are simple : `jekyll`, `guard` and some
Guard extensions.

{{< highlight ruby >}}
source "http://rubygems.org"

gem 'jekyll'
gem 'guard'
gem 'guard-jekyll2'
gem 'guard-shell'
gem 'guard-bundler'
{{< /highlight >}}

## Guard

> Guard is a command line tool to easily handle events on file system modifications.

Guard will be watching file we told him and run action in consequence ; The file
is name `Guardfile`.

{{< highlight ruby >}}
guard 'jekyll2' do
  watch %r{.*}
end

guard :bundler do
  watch('Gemfile')
end
# vim:filetype=ruby
{{< /highlight >}}

## Foreman

Finally, foreman will let us declare our processes and will handle the start,
forward the output and handle the shutdown. It can then export its configuration
into more _production-ready_ file (`init`, `upstard`, …) ; It uses a file named
`Procfile`.

We will tell foreman to run :

* The jekyll build-in server : `jekyll --server`
* Guard, to handle file changes _in background_.

{{< highlight bash >}}
web: bundle exec jekyll --server
guard: bundle exec guard
{{< /highlight >}}

And that's all folk. Now, you just need to run foreman in the Jekyll-powered
directory and edit your files.
