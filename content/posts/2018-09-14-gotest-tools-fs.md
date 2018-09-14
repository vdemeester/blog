+++
title = "Golang testing — gotest.tools fs"
date = 2018-09-14
tags = ["testing", "golang"]
categories = ["developement"]
draft = false
creator = "Emacs 25.3.1 (Org mode 9.1.7 + ox-hugo)"
+++

Let's continue the [`gotest.tools`](https://gotest.tools) serie, this time with the `fs` package.

> Package fs provides tools for creating temporary files, and testing the contents and structure of a directory.

This package is heavily using functional arguments (as we saw in [functional arguments for
wonderful builders](/posts/2017-01-01-go-testing-functionnal-builders/)). Functional arguments is, in a nutshell, a combinaison of two Go
features : _variadic_ functions (`...` operation in a function signature) and the fact
that `func` are _first class citizen_. This looks more or less like that.

```go
type Config struct {}

func MyFn(ops ...func(*Config)) *Config {
	c := &Config{} // with default values
	for _, op := range ops {
		op(c)
	}
	return c
}

// Calling it
conf := MyFn(withFoo, withBar("baz"))
```

The `fs` package has too **main** purpose :

1.  create folders and files required for testing in a simple manner
2.  compare two folders structure (and content)


## Create folder structures {#create-folder-structures}

Sometimes, you need to create folder structures (and files) in tests. Doing `i/o` work
takes time so try to limit the number of tests that needs to do that, especially in unit
tests. Doing it in tests adds a bit of boilerplate that could be avoid. As stated [before](/posts/2017-01-01-go-testing-functionnal-builders/) :

> One of the most important characteristic of a unit test (and any type of test really) is
> **readability**. This means it should be easy to read but most importantly it should **clearly
> show the intent** of the test. The setup (and cleanup) of the tests should be as small as
> possible to avoid the noise.

In a test you usually end up using `ioutil` function to create what you need. This looks
somewhat like the following.

```go
path, err := ioutil.TempDir("", "bar")
if err != nil { // or using `assert.Assert`
	t.Fatal(err)
}
if err := os.Mkdir(filepath.Join(path, "foo"), os.FileMode(0755)); err != nil {
	t.Fatal(err)
}
if err := ioutil.WriteFile(filepath.Join(path, "foo", "bar"), []byte("content"), os.FileMode(0777)); err != nil {
	t.Fatal(err)
}
defer os.RemoveAll(path) // to clean up at the end of the test
```

The `fs` package intends to help reduce the noise and comes with a bunch function to create
folder structure :

-   two main function `NewFile` and `NewDir`
-   a bunch of _operators_ : `WithFile`, `WithDir`, …

```go
func NewDir(t assert.TestingT, prefix string, ops ...PathOp) *Dir {
	// …
}

func NewFile(t assert.TestingT, prefix string, ops ...PathOp) *File {
	// …
}
```

The `With*` function are all satisfying the `PathOp` interface, making `NewFile` and
`NewDir` extremely composable. Let's first see how our above example would look like using
the `fs` package, and then, we'll look a bit more at the main `PathOp` function…

```go
dir := fs.NewDir(t, "bar", fs.WithDir("foo",
	fs.WithFile("bar", fs.WithContent("content"), fs.WithMode(os.FileMode(0777))),
))
defer dir.Remove()
```

It's clean and simple to read. The intent is well described and there is not that much of
noise. `fs` functions tends to have _sane_ and _safe_ defaults value (for `os.FileMode`
for example). Let's list the main, useful, `PathOp` provided by `gotest.tools/fs`.

-   `WithDir` creates a sub-directory in the directory at path.
-   `WithFile` creates a file in the directory at path with content.
-   `WithSymlink` creates a symlink in the directory which links to target. Target must be a
	path relative to the directory.
-   `WithHardlink` creates a link in the directory which links to target. Target must be a
	path relative to the directory.
-   `WithContent` and `WWithBytes` write content to a file at Path (from a `string` or a
	`[]byte` slice).
-   `WithMode` sets the file mode on the directory or file at path.
-   `WithTimestamps` sets the access and modification times of the file system object at
	path.
-   `FromDir` copies the directory tree from the source path into the new Dir. This is
	pretty useful when you have a huge folder structure already present in you `testdata`
	folder or elsewhere.
-   `AsUser` changes ownership of the file system object at Path.

Also, note that `PathOp` being an function type, you can provide your own implementation
for specific use-cases. Your function just has to satisfy `PathOp` signature.

```go
type PathOp func(path Path) error
```


## Compare folder structures {#compare-folder-structures}

Sometimes, the code you're testing is creating a folder structure, and you would like to
be able to tests that, with the given arguments, it creates the specified structure. `fs`
allows you to do that too.

The package provides a `Equal` function, which returns a `Comparison`, that the [`assert`](/posts/2018-08-16-gotest-tools-assertions/)
package understand. It works by comparing a `Manifest` type provided by the test and a
`Manifest` representation of the specified folder.

> Equal compares a directory to the expected structured described by a manifest and returns
> success if they match. If they do not match the failure message will contain all the
> differences between the directory structure and the expected structure defined by the
> Manifest.

A `Manifest` stores the expected structure and properties of files and directories in a
filesystem. You can create a `Manifest` using either the functions `Expected` or
`ManifestFromDir`.

We're going to focus on the `Expected` function, as `ManifestFromDir` does pretty much
what you would expected : it takes the specified path, and returns a `Manifest` that
represent this folder.

```go
func Expected(t assert.TestingT, ops ...PathOp) Manifest
```

`Expected` is close to `NewDir` function : it takes the same `PathOp` functional
arguments. This makes creating a `Manifest` straightforward, as it's working the same. Any
function that satisfy `PathOp` can be used for `Manifest` the exact same way you're using
them on `fs.NewDir`.

There is a few additional functions that are only useful with `Manifest` :

-   `MatchAnyFileContent` updates a Manifest so that the file at path may contain any content.
-   `MatchAnyFileMode` updates a Manifest so that the resource at path will match any file mode.
-   `MatchContentIgnoreCarriageReturn` ignores cariage return discrepancies.
-   `MatchExtraFiles` updates a Manifest to allow a directory to contain unspecified files.

```go
path := operationWhichCreatesFiles()
expected := fs.Expected(t,
	fs.WithFile("one", "",
	fs.WithBytes(golden.Get(t, "one.golden")),
	fs.WithMode(0600)),
	fs.WithDir("data",
		fs.WithFile("config", "", fs.MatchAnyFileContent)),
)

assert.Assert(t, fs.Equal(path, expected))
```

The following example compares the result of `operationWhichCreatesFiles` to the expected
`Manifest`. As you can see it also integrates well with other part of the `gotest.tools`
library, with the [`golden` package](/posts/2018-09-06-gotest-tools-golden/) in this example.


## Conclusion… {#conclusion}

… that's a wrap. In my opinion, this is one the most useful package provided by
`gotest.tools` after `assert`. It allows to create simple or complex folder structure
without the noise that usually comes with it.
