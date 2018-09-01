+++
title = "Golang testing — gotest.tools introduction"
date = 2018-07-28
tags = ["testing", "golang"]
categories = ["developement"]
draft = false
creator = "Emacs 25.3.1 (Org mode 9.1.7 + ox-hugo)"
+++

I already wrote 2 previous posts about golang and testing. It's something I care deeply about and I wanted to continue
writing about it. It took me a bit more time than I thought, but getting back to it. Since the [last post](http://vincent.demeester.fr/posts/2017-04-22-golang-testing-golden-file/), Daniel Nephin
and I worked (but mainly Daniel 🤗) on bootstrapping a testing helper library.

Let me introduce it to you this library : [`gotest.tools`](https://gotest.tools). As described in the [godoc](https://godoc.org/gotest.tools) package comment, `gotest.tools` is a
collection of packages to augment `testing` and support common patterns. It's an enhanced and growing version of the
initial helpers we (the docker/moby maintainers) wrote initially in [`docker/docker`](https://github.com/docker/docker) repository. We are using in quite some
project here at [Docker](https://github.com).

There is a bunch of packages that will all have their own post (linked here when available) :

-   [`assert`](/posts/2018-08-16-gotest-tools-assertions/) (with `assert/cmp` and `assert/opt`) that provides assertions for comparing expected values to actual values.
-   `env` that provides functions to test code that read environment variable or the current working directory.
-   `fs` that provides tools for creating temporary files, and testing the contents and structure of a directory.
-   `golden` that provides tools for comparing large multi-line strings.
-   `icmd` that executes binaries and provides convenient assertions for testing the results.
-   `poll` that provides tools for testing asynchronous code.
-   [`skip`](/posts/2018-09-01-gotest-tools-skip/) that provides functions for skipping a test and printing the source code of the condition used to skip the test.

There is also experimental package, using the `x` notation (as the golang team uses, for example with `golang.org/x/sync`) :

-   `x/subtest` that provides a `TestContext` to subtests which handles cleanup and provides a `testing.TB` and `context.Context`.

There is already some good `testing` helpers in the Go ecosystem : [`testify`](https://github.com/stretchr/testify), [`gocheck`](http://labix.org/gocheck), [`ginkgo`](https://github.com/onsi/ginkgo) and a lot more — so
why create a new one ? There is multiple reason for it, most of them can be seen in the following [GitHub issue](https://github.com/gotestyourself/gotest.tools/issues/49#issuecomment-362436026).

[Daniel](https://github.com/dnephin/) also wrote a very useful converter if your code base is currently using `testify` : `gty-migrate-from-testify`.

```sh
$ go get -u gotest.tools/assert/cmd/gty-migrate-from-testify
# […]
$ go list \
	 -f '{{.ImportPath}} {{if .XTestGoFiles}}{{"\n"}}{{.ImportPath}}_test{{end}}' \
	 ./... | xargs gty-migrate-from-testify
```

In the next post, let's dig into the assertion part of the library, package `assert` 👼.
