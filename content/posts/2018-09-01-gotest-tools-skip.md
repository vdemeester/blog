+++
title = "Golang testing — gotest.tools skip"
date = 2018-09-01
tags = ["testing", "golang"]
categories = ["developement"]
draft = false
creator = "Emacs 25.3.1 (Org mode 9.1.7 + ox-hugo)"
+++

Let's continue the [`gotest.tools`](https://gotest.tools) serie, this time with the `skip` package. This is a
really simple one so this should be quick.

> `skip` provides functions for skipping a test and printing the source code of the
> condition used to skip the test.

The package consists of only one function : `If`. The idea comes mainly from
[`docker/docker`](https://github.com/docker/docker) integration test suite, where we wanted to skip some test (or test suites)
given different context. By context I mean things like the system we are running on
(`Windows`, `Linux`, …) or the capabilities of the running kernel or node (is `apparmor`
available or not on the current machine).

This `If` method takes a `testing.T` pointer and either a boolean, a function that
returns a boolean, **or** an expression.

```go
// boolean
//   --- SKIP: TestName (0.00s)
//           skip.go:19: MissingFeature
var MissingFeature bool
skip.If(t, MissingFeature)

// function
//   --- SKIP: TestName (0.00s)
//           skip.go:19: !IsExperimentalDaemon(dockerClient): daemon is not experimental
skip.If(t, IsExperimentalDaemon(dockerClient), "daemon is not experimental")

// expression
//   --- SKIP: TestName (0.00s)
//           skip.go:19: apiVersion < version("v1.24")
skip.If(t, apiVersion < version("v1.24"))
```

There is few elements to note though :

-   This package (as other parts of the `gotest.tools` packages), will try to look at source
	files to display the expression used (same goes for `assert`). This is usually not a
	problem because you run tests where the source code is. **However**, in the cases you
	generate a test binary to be executed later (à-la `kubernetes` or other projects), this
	can display a weird error message if the sources are not available… You shouldn't be
	worried too much about it, but it's better if you know :)
-   The main reason to use `skip.If` is mainly for new contributors to get in quickly,
	**reducing potential friction of them running the tests on their environment**. The more
	the tests are written in a way they explicitely declare their requirements (and skipped
	if the environment does not meet those), the easier it makes contributors run your
	tests. **But**, this also means, you should try to measure the skipped tests on your
	continuous integration system to make sure you run all of them eventually… otherwise
	it's dead code. _But more on that in later posts 😉_.

That's all for today folks, told you that was going to be quick.
