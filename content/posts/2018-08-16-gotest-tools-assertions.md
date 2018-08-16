+++
title = "Golang testing : gotest.tools assertions"
date = 2018-08-16
tags = ["testing", "golang"]
categories = ["developement"]
draft = true
creator = "Emacs 25.3.1 (Org mode 9.1.7 + ox-hugo)"
+++

Let's take a closer look at [`gotest.tools`](https://gotest.tools) assertions packages. This is mainly about `assert`, `assert/cmp` and
`assert/opt`.

> Package assert provides assertions for comparing expected values to actual values. When assertion fails a helpful error
> message is printed.

There is two main function (`Assert` and `Check`) and some helpers (like `NilError`, …), They all take a `*testing.T` as
a first argument, pretty common across testing Go libraries. Let's dive into those !


## `Assert` and `Check` {#assert-and-check}

Both those function accept a `Comparaison` (we'll check what it is later on) and fail the test when that comparaison
fails. The one difference is that `Assert` will end the test execution at immediately whereas `Check` will fail the test
and proceed with the rest of the test case. This is similar to `FailNow` and `Fail` from the standard library
`testing`. Both have their use cases.

We'll Use `Assert` for the rest of the section but any example here would work with `Check` too. When we said
`Comparaison` above, it's mainly the [BoolOrComparaison](https://godoc.org/gotest.tools/assert#BoolOrComparison) interface — it can either be a boolean expression, or a
[cmp.Comparaison](https://godoc.org/gotest.tools/assert/cmp#Comparison) type. `Assert` and `Check` code will be _smart_ enough to detect which one it is.

```go
assert.Assert(t, ok)
assert.Assert(t, err != nil)
assert.Assert(t, foo.IsBar())
```

So far not anything extra-ordinary. Let's first look at some more _helper_ functions in the `assert` package and quickly
dive a bit deeper with `Comparaison`.


## More `assert` helpers {#more-assert-helpers}

The additional helper functions are the following

-   `Equal` that uses the `==` operator to assert two values are equal.
-   `DeepEqual` that uses `google/go-cmp` to assert two values are equal (it's _close_ to `reflect.DeepEqual` but not
	quite). We'll detail a bit more the _options_ part of this function with `cmp.DeepEqual`.
-   `Error` that fails if the error is `nil` **or** the error message is not the expected one.
-   `ErrorContains` that fails if the error is `nil` **or** the error message does not contain the expected substring.
-   `ErrorType` that fails if the error is `nil` **or** the error type is not the expected type.
-   `NilError` that fails if the error is not `nil`.

All those helper functions, have a equivalent function in the `cmp` package that returns a `Comparaison`.I, personally,
prefer to use `assert.Check` or `assert.Assert` in combination with `cmp.Comparison` as it allows me to write all my
assertions the same way, with built-ins comparison or with my owen — i.e. `assert.Assert(t, is.Equal(…), "message"` or
`assert.Assert(t, stackIsUp(c, time…), "another message")`.


## `cmp.Comparison` {#cmp-dot-comparison}

This is where it get really interesting, `gotest.tools` tries to make it as easy as possible for you to create
appropriate comparison — making you test readable as much as possible.

Let's look a bit at the `cmp.Comparaison` type.

```go
type Comparison func() Result
```

It's just a function that returns a `cmp.Result`, so let's look at `cmp.Result` definition.

```go
type Result interface {
	Success() bool
}
```

Result is an `interface`, thus any struct that provide a function `Success` that returns a `bool` can be used as a
comparaison result, making it really easy to use in your code. There is also existing type of result to make it even
quicker to write your own comparaison.

-   `ResultSuccess` that is a constant which is returned to indicate success.
-   `ResultFailure` and `ResultFailureTemplate` that returns a failed Result with a failure message.
-   `ResultFromError` returns `ResultSuccess` if `err` is nil. Otherwise `ResultFailure` is returned with the error
	message as the failure message. It works a bit like the `errors.Wrap` function of the [`github.com/pkgs/errors`](https://github.com/pkg/errors)
	package.

The `cmp` package comes with a few defined comparaison that, we think, should cover a high number of use-cases. Let's
look at them.


### Equality with `Equal` and `DeepEqual` {#equality-with-equal-and-deepequal}

> Equal uses the == operator to assert two values are equal and fails the test if they are not equal.
>
> If the comparison fails Equal will use the variable names for x and y as part of the failure message to identify the
> actual and expected values.
>
> If either x or y are a multi-line string the failure message will include a unified diff of the two values. If the
> values only differ by whitespace the unified diff will be augmented by replacing whitespace characters with visible
> characters to identify the whitespace difference.

On the other hand…

> DeepEqual uses google/go-cmp (<http://bit.do/go-cmp>) to assert two values are equal and fails the test if they are not
> equal.
>
> Package <https://godoc.org/gotest.tools/assert/opt> provides some additional commonly used Options.

Using one or the other is as simple as : if you wrote your `if` with `==` then use `Equal`, otherwise use `DeepEqual`.
`DeepEqual` (and usually `reflect.DeepEqual`) is used when you want to compare anything more complex than primitive
types. One advantage of using `cmp.DeepEqual` over `reflect.DeepEqual` (in an if), is that you get a well crafted
message that shows the diff between the expected and the actual structs compared.

```go
assert.Assert(t, cmp.DeepEqual([]string{"a", "b"}, []string{"b", "a"}))
// Will print something like
// --- result
// +++ exp
// {[]string}[0]:
//         -: "a"
//         +: "b"
// {[]string}[1]:
//         -: "b"
//         +: "a"
foo := &someType(a: "with", b: "value")
bar := &someType(a: "with", b: "value")
// the following will succeed as foo and bar are _DeepEqual_
assert.Assert(t, cmp.DeepEqual(foo, bar))
```

When using `DeepEqual`, you may end up with really weird behavior sometimes. You may want to ignore some fields, or
consider `nil` slice or map the same as empty ones ; or more common, your `struct` contains some unexported fields that
you cannot use when comparing (as they are not exported 👼). In those case, you can use `go-cmp` options.

Some existings one are :

-   [`EquateEmpty`](https://godoc.org/github.com/google/go-cmp/cmp/cmpopts#EquateEmpty) returns a Comparer option that determines all maps and slices with a length of zero to be equal,
	regardless of whether they are nil.
-   [`IgnoreFields`](https://godoc.org/github.com/google/go-cmp/cmp/cmpopts#IgnoreFields) returns an Option that ignores exported fields of the given names on a single struct type. The struct
	type is specified by passing in a value of that type.
-   [`IgnoreUnexported`](https://godoc.org/github.com/google/go-cmp/cmp/cmpopts#IgnoreUnexported) returns an Option that only ignores the immediate unexported fields of a struct, including anonymous
	fields of unexported types.
-   [`SortSlices`](https://godoc.org/github.com/google/go-cmp/cmp/cmpopts#SortSlices) returns a Transformer option that sorts all `[]V`
-   … and [more](https://godoc.org/github.com/google/go-cmp/cmp/cmpopts) 👼

`gotest.tools` also defines some… **and** you can define yours ! For example, `gotest.tools` defines `TimeWithThreshold`
and `DurationWithThreshold` that allows to not fails if the time (or duration) is not exactly the same but in the
specified threshold we specified. Here is the code for `DurationWithThreshold` as an example.

```go
// DurationWithThreshold returns a gocmp.Comparer for comparing time.Duration. The
// Comparer returns true if the difference between the two Duration values is
// within the threshold and neither value is zero.
func DurationWithThreshold(threshold time.Duration) gocmp.Option {
	return gocmp.Comparer(cmpDuration(threshold))
}

func cmpDuration(threshold time.Duration) func(x, y time.Duration) bool {
	return func(x, y time.Duration) bool {
		if x == 0 || y == 0 {
			return false
		}
		delta := x - y
		return delta <= threshold && delta >= -threshold
	}
}
```

Another good example for those options is when you want to skip some field. In [`docker/docker`](https://github.com/docker/docker) we want to be able to
easily check for equality between two service specs, but those might have different `CreatedAt` and `UpdatedAt` values
that we usually don't care about – what we want is to make sure it happens in the past 20 seconds. You can easily define
an option for that.

```go
func cmpServiceOpts() cmp.Option {
	const threshold = 20 * time.Second

	// Apply withinThreshold only for the following fields
	metaTimeFields := func(path cmp.Path) bool {
		switch path.String() {
		case "Meta.CreatedAt", "Meta.UpdatedAt":
			return true
		}
		return false
	}
	// have a 20s threshold for the time value that will be passed
	withinThreshold := cmp.Comparer(func(x, y time.Time) bool {
		delta := x.Sub(y)
		return delta < threshold && delta > -threshold
	})

	return cmp.FilterPath(metaTimeFields, withinThreshold)
}
```

I recommend you look at the [gotest.tools/assert/opt](https://godoc.org/gotest.tools/assert/opt) documentation to see which one are defined and how to use them.


### Errors with `Error`, `ErrorContains` and `ErrorType` {#errors-with-error-errorcontains-and-errortype}

Checking for errors is **very common** in Go, having `Comparison` function for it was a requirement.

-   `Error` that fails if the error is `nil` **or** the error message is not the expected one.
-   `ErrorContains` that fails if the error is `nil` **or** the error message does not contain the expected substring.
-   `ErrorType` that fails if the error is `nil` **or** the error type is not the expected type.

Let's first look at the most used : `Error` and `ErrorContains`.

```go
var err error
// will fail with : expected an error, got nil
assert.Check(t, cmp.Error(err, "message in a bottle"))
err = errors.Wrap(errors.New("other"), "wrapped")
// will fail with : expected error "other", got "wrapped: other"
assert.Check(t, cmp.Error(err, "other"))
// will succeed
assert.Check(t, cmp.ErrorContains(err, "other"))
```

As you can see `ErrorContains` is especially useful when working with _wrapped_ errors.
Now let's look at `ErrorType`.

```go
var err error
// will fail with : error is nil, not StubError
assert.Check(t, cmp.ErrorType(err, StubError{}))

err := StubError{"foo"}
// will succeed
assert.Check(t, cmp.ErrorType(err, StubError{}))

// Note that it also work with a function returning an error
func foo() error {}
assert.Check(t, cmp.ErrorType(foo, StubError{}))
```


### Bonus with `Panics` {#bonus-with-panics}

Sometimes, a code is supposed to _panic_, see [Effective Go (#Panic)](https://golang.org/doc/effective_go.html#panic) for more information about that. And thus, you may
want to make sure you're code panics in such cases. It's always a bit tricky to test a code that panic as you have to
use a deferred function to recover the panic — but then if the panic doesn't happen how do you fail the test ?

This is where `Panics` comes handy.

```go
func foo(shouldPanic bool) {
	if shouldPanic {
		panic("booooooooooh")
	}
	// don't worry, be happy
}
// will fail with : did not panic
assert.Check(t, cmp.Panics(foo(false)))
// will succeed
assert.Check(t, cmp.Panics(foo(true)))
```


### Miscellaneous with `Contains`, `Len` and `Nil` {#miscellaneous-with-contains-len-and-nil}

Those last three _built-in_ `Comparison` are pretty straightforward.

-   `Contains` succeeds if item is in collection. Collection may be a string, map, slice, or array.

	If collection is a string, item must also be a string, and is compared using strings.Contains(). If collection is a Map,
	contains will succeed if item is a key in the map. If collection is a slice or array, item is compared to each item in
	the sequence using reflect.DeepEqual().
-   `Len` succeeds if the sequence has the expected length.
-   `Nil` succeeds if obj is a nil interface, pointer, or function.

```go
// Contains works on string, map, slice or arrays
assert.Check(t, cmp.Contains("foobar", "foo"))
assert.Check(t, cmp.Contains([]string{"a", "b", "c"}, "b"))
assert.Check(t, cmp.Contains(map[string]int{"a": 1, "b": 2, "c": 4}, "b"))

// Len also works on string, map, slice or arrays
assert.Check(t, cmp.Len("foobar", 6))
assert.Check(t, cmp.Len([]string{"a", "b", "c"}, 3))
assert.Check(t, cmp.Len(map[string]int{"a": 1, "b": 2, "c": 4}, 3))

// Nil
var foo *MyStruc
assert.Check(t, cmp.Nil(foo))
assert.Check(t, cmp.Nil(bar()))
```

But let's not waste more time and let's see how to write our own `Comparison` !


### Write your own `Comparison` {#write-your-own-comparison}

One of the main aspect of `gotest.tools/assert` is to make it easy for developer to write as less boilerplate code as
possible while writing tests. Writing your own `Comparison` allows you to write a well named function that will be easy
to read and that can be re-used across your tests.

Let's look back at the `cmp.Comparaison` and `cmp.Result` types.

```go
type Comparison func() Result

type Result interface {
	Success() bool
}
```

A `Comparison` for `assert.Check` or `assert.Check` is a function that return a `Result`, it's pretty straightforward to
implement, especially with `cmp.ResultSuccess` and `cmp.ResultFailure(…)`.

```go
func regexPattern(value string, pattern string) cmp.Comparison {
	return func() cmp.Result {
		re := regexp.MustCompile(pattern)
		if re.MatchString(value) {
			return cmp.ResultSuccess
		}
		return cmp.ResultFailure(
			fmt.Sprintf("%q did not match pattern %q", value, pattern))
	}
}

// To use it
assert.Check(t, regexPattern("12345.34", `\d+.\d\d`))
```

As you can see, it's pretty easy to implement, and you can do quite a lot in there easily. If a function call returns an
error inside of your `Comparison` function, you can use `cmp.ResultFromError` for example. Having something like
`assert.Check(t, isMyServerUp(":8080"))` is way more readable than a 30-line of code to check it.


## Conclusion… {#conclusion}

… and that's a wrap. We only looked at the `assert` package of [`gotest.tools`](https://gotest.tools) so far, but it's already quite a bit to process.

We've seen :

-   the main functions provided by this package : `assert.Assert` and `assert.Check`
-   some helper functions like `assert.NilError`, …
-   the `assert/cmp`, and `assert/opt` sub-package that allows you to write more custom `Comparison`

Next time, we'll look at the `skip` package, that is a really simple wrapper on top of `testing.Skip` function.
