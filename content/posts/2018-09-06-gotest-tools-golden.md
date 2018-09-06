+++
title = "Golang testing — gotest.tools golden"
date = 2018-09-06
tags = ["testing", "golang"]
categories = ["developement"]
draft = true
creator = "Emacs 25.3.1 (Org mode 9.1.7 + ox-hugo)"
+++

Let's continue the [`gotest.tools`](https://gotest.tools) serie, this time with the `golden` package. This is a
[_quick follow-up_ on a previous `golden` post](/posts/2017-04-22-golang-testing-golden-file/), but focused on the `gotest.tools`
implementation. I'm gonna be quicker, please read that one if `golden` files is a new
concept for you.

> Package `golden` provides tools for comparing large mutli-line strings.
>
> Golden files are files in the `./testdata/` subdirectory of the package under test.

In the previous article, we described the problem, and how to fix it by writing a small
helper. Well, that small helper is in `gotest.tools/golden` now, and it has a tiny bit
more features.

One of the difference between the `gotest.tools` implementation and the previous post is
the flag name. In `gotest.tools/golden`, the flag is `-test.update-golden` (was just
`-test.update` before). Just as before, if the `-test.update-golden` flag is set then the
actual content is written to the golden file, before reading it and comparing.

There is two ways to use the `golden` package:

-   on it's own, using `golden.Assert` or `golden.AssertBytes`
-   as a `cmp.Comparison`, with `golden.String` or `golden.Bytes`


## `Assert` and `AssertBytes` {#assert-and-assertbytes}

Using `Assert` functions should be straightforward. Both `Assert` function compares the
actual content to the expected content in the golden file and returns whether the
assertion was successful (true) or not (false).

-   `Assert` uses string. Note that this one **removes carriage return** before comparing to
	depend as less as possible of the system (`\n` vs `\r\n` 😅)
-   `AssertBytes` uses raw data (in the form of `[]byte`)

```go
golden.Assert(t, "foo", "foo-content.golden")
// Could also be used to check some binary format
golden.AssertBytes(t, []byte("foo"), "foo-content.golden")
```


## `Bytes` and `String` {#bytes-and-string}

As written in a [previous post (about the `assert` package)](/posts/2018-08-16-gotest-tools-assertions/), I prefer to use `cmp.Comparison`.

> All those helper functions have a equivalent function in the `cmp` package that returns a
> `Comparison`. I, personally, prefer to use `assert.Check` or `assert.Assert` in
> combination with `cmp.Comparison` as it allows me to write all my assertions the same way,
> with built-ins comparison or with my own — i.e. `assert.Assert(t, is.Equal(…), "message"`
> or `assert.Assert(t, stackIsUp(c, time…), "another message")`.

The `golden` package gives us that too, in the form of `Bytes` and `String`. Using the
`assert.Check` or `assert.Assert` functions with those is equivalent to their _helper_
counter-part `golden.Assert` and `golden.AssertBytes`.

```go
assert.Assert(t, golden.String("foo", "foo-content.golden"))
// Could also be used to check some binary format
assert.Assert(t, golden.Bytes([]byte("foo"), "foo-content.golden"))
```


## Conclusion… {#conclusion}

… that's a wrap. As for [`skip`](/posts/2018-09-01-gotest-tools-skip/), this is a small package, so the post was going to be
quick. `golden` package just solve a specific problem (read [Golang testing — golden file](/posts/2017-04-22-golang-testing-golden-file/))
in a simple way.
