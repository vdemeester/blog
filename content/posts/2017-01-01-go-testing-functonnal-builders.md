+++
title = "Golang testing — functional arguments for wonderful builders"
date = 2017-01-01
tags = ["testing", "golang", "functionnal", "java", "builder"]
categories = ["developement"]
draft = true
creator = "Emacs 25.3.1 (Org mode 9.1.7 + ox-hugo)"
+++

> Programming is not easy; even the best programmers are incapable of
> writing programs that work exactly as intended every time. Therefore
> an important part of the software development process is
> testing. Writing tests for our code is a good way to ensure quality
> and improve reliability.

Go programs, when properly implemented, are fairly simple to test
programatically. The `testing` built-in library and the features of
the language itself offer plenty of ways to write good tests. As this
is a subject I particularly like, I'm gonna write a bunch of articles
about it, that, _hopefully_ do not get old or boring.

I'm not going to start by introducing how `testing` works, it's
already widely described in [the `testing` godoc](https://golang.org/pkg/testing/), [some](https://blog.golang.org/examples) [articles](https://www.golang-book.com/books/intro/12) and
[blogs](https://jonathanmh.com/golang-unit-testing-for-absolute-beginners/). I'm going to jump ahead on a more advanced techinque to write
tests, the `builders` for tests.

One of the most important characteristic of a **unit test** (and any
type of test really) is **readability**. This means it should be _easy
to read_ but most importantly it should **clearly show the intent of
the test**. The setup (and cleanup) of the tests should be as small as
possible to avoid the noise. And as we are going to see below, `go`
makes it pretty easy to do so.


## Builders in tests {#builders-in-tests}

Sometimes, your need to create data structure for your test that
might take a lot of line and introduce noise. In `golang` we don't
have method overload or even _constructors_ as some other language
have. This means most of the time, we end up building our data using
directly the struct expression, as below.

{{< highlight go "hl_lines=1 3-5">}}
node := &Node{
	Name: "carthage",
	Hostname: "carthage.sbr.pm",
	Platform: Platform{
		Architecture: "x86_64",
		OS:           "linux",
	},
}
{{< /highlight >}}

Let's imagine we have a `Validate` function that make sure the
specified `Node` is supported on our structure. We would write some
tests that ensure that.

```go
func TestValidateLinuxIsSupported(t *testing.T) {
	valid := Validate(&Node{
		Name: "carthage",
		Hostname: "carthage.sbr.pm",
		Platform: &Platform{
			Architecture: "x86_64",
			OS:           "linux",
		},
	})
	if !valid {
		t.Fatal("linux should be supported, it was not")
	}
}

func TestValidateDarwinIsNotSupported(t *testing.T) {
	valid := Validate(&Node{
		Name: "babylon",
		Hostname: "babylon.sbr.pm",
		Platform: &Platform{
			Architecture: "x86_64",
			OS:           "darwin",
		},
	})
	if valid {
		t.Fatal("darwin should not be supported, it was")
	}
}
```

This is quickly hard to read, there is too much noise on that
test. We setup a whole `Node` struct, but the only thing we really
intend to test is the `Platform.OS` part. The rest is just required
fields for the function to correctly compile and run.

This is where test builders (and builders in general) comes into
play. In [Growing Object-Oriented Software Guided by Tests](http://www.growing-object-oriented-software.com/), the
Chapter 22 "Constructing Complex Test Data" is exactly about that
and guide us through the why and the how of these builders. The
examples in the book are in `java` and uses wisely the
object-oriented nature of the language. Here is an example from the
book.

```java
// I just want an order from a customer that has no post code
Order order = anOrder()
	.from(aCustomer().with(anAddress().withNotPostCode()))
	.build()
```

These builders helps **keep tests expressive**, as it's pretty obvious
when reading it, what we want to test. They remove the **visual
noise** you have when building an object (or a `struct{}` in Go) and
allows you to put sane default. They also make **tests resilient to
change**. If the structure changes, only the builder has to be
updated, not the tests depending on it. They also make default case
really simple to write, and special cases not much more complicated.


## Builder in Go {#builder-in-go}

The naive way to create builders in `go` could be to create a
`builder` struct that have methods to construct the final struct and
a `build` method. Let's see how it looks.

```go
func ANode() *NodeBuilder {
	return &NodeBuilder{
		node: &Node{
			Name: "node",
			// Other defaults
		},
	}
}

type NodeBuilder struct {
	node *Node
}

func (b *NodeBuilder) Build() *Node {
	return b.node
}

func (b *NodeBuilder) Hostname(hostname string) *NodeBuilder {
	b.node.Hostname = hostname
	return b
}

func (b *NodeBuilder) Name(name string) *NodeBuilder {
	b.node.Name = name
	return b
}

func (b *NodeBuilder) Platform(platform *Platform) *NodeBuilder {
	b.node.Platform = platform
	return b
}
```

This looks decent, and using it is pretty straightforward. At least
it make building the `struct` more expressive, less noisy and
resilient to change. We can update the previous test as follow.

```go
func TestValidateLinuxIsSupported(t *testing.T) {
	valid := Validate(ANode().Platform(&Platform{
		Architecture: "x86_64",
		OS:           "linux",
	}).Build())
	if !valid {
		t.Fatal("linux should be supported, it was not")
	}
}

func TestValidateDarwinIsNotSupported(t *testing.T) {
	valid := Validate(ANode().Platform(&Platform{
		Architecture: "x86_64",
		OS:           "darwin",
	}).Build())
	if valid {
		t.Fatal("darwin should not be supported, it was")
	}
}
```

There is room for improvement :

-   There is still some noise, mainly `build()` and the platform
	`struct`, as it still shows too much.
-   It's not that extensible yet. If you want to update the `Node` a
	certain way that the builder is not written for, you have to
	update the builder.
-   The `NodeBuilder` struct feels a little empty, it's just there to
	hold on the `Node` being constructed until it is `build`.

One improvement we could make is to have a `Platform` builder, even
if it's a small struct here. Let's do that in the same way we did
with `Node`.

```go
func APlatform() *PlatformBuilder {
	return &PlatformBuilder{
		platform: &Platform{
			Architecture: "x64_86",
			OS: "linux",
		},
	}
}

type PlatformBuilder struct{
	platform *Platform
}

func (b *PlatformBuilder) Build() *Platform {
	return b.platform
}

func (b *PlatformBuilder) OS(os string) *PlatformBuilder {
	b.platform.OS = os
	return b
}
```

And our tests becomes 🐻.

```go
func TestValidateLinuxIsSupported(t *testing.T) {
	valid := Validate(ANode().Platform(
		APlatform().OS("linux").Build()
	).Build())
	if !valid {
		t.Fatal("linux should be supported, it was not")
	}
}

func TestValidateDarwinIsNotSupported(t *testing.T) {
	valid := Validate(ANode().Platform(
		APlatform().OS("darwin").Build()
	).Build())
	if valid {
		t.Fatal("darwin should not be supported, it was")
	}
}
```

It does not really improve the visual noise as there is now quite a
few duplication : several `build`, `APlatform` inside `Platform`, …
It is a small improvement on readability but not that much compared
to the previous one. This is were the Go language features comes
into play.


## Functional arguments to the rescue {#functional-arguments-to-the-rescue}

Go has two interesting feature that are going to be useful here.

First, a function in Go is a type on its own and thus is considered
a _first class citizen_. It means it's possible to pass a function
as argument, or define a variable that holds it.

```go
func ApplyTo(s string, fn func(string) string) string {
	return fn(s)
}

func world(s string) string {
	return fmt.Sprintf("%s, world!", s)
}

// Usage
a := ApplyTo("hello", world)
// a == "hello, world!"
```

The second feature that comes into play here, is the possiblity to
have _variadic_ functions. A variadic function is a function that
takes a variable number of arguments (from `0` to any number of
argument).

```go
func Print(strs ...string) string {
	for _, s := range strs {
		fmt.Println(s)
	}
}
```

As we are going to see below, combining these two feature makes our
builders pretty easy to write and to use with simple case, while
staying very customizable, even outside of the builder. This is
really well described in a talk from Dave Cheney : [Functional
options for friendly APIs](https://www.youtube.com/watch?v%3D24lFtGHWxAQ&index%3D15&list%3DPLMW8Xq7bXrG58Qk-9QSy2HRh2WVeIrs7e) ([transcription](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis)).

Let's apply that to our new builders.

```go
func ANode(nodeBuilders ...func(*Node)) *Node {
	node := &Node{
		Name: "node",
		// Other defaults
	}

	for _, build := range nodeBuilders {
		build(node)
	}

	return node
}

func APlatform(platformBuilders ...func(*Platform)) *Platform {
	platform := &Platform{
		Architecture: "x64_86",
		OS: "linux",
	}

	for _, build := range platformBuilders {
		build(platform)
	}

	return platform
}
```

And that is it for the actual builder code. It is **small** and
simple, there is **no more `NodeBuilder`** struct, and this is highly
extensible. Let's see how to use it.

```go
// a default node
node1 := ANode()
// a node with a specific Hostname
node2 := ANode(func(n *Node) {
	n.Hostname = "custom-hostname"
})
// a node with a specific name and platform
node3 := ANode(func(n *Node) {
	n.Name = "custom-name"
}, func (n *Node) {
	n.Platform = APlatform(func (p *Platform) {
		p.OS = "darwin"
	})
})
```

The last step is to define some _function builder_ for common or
widely used customization, to make this **expressive**. And let
complex, _one-time_ function builder in the end of the user. Now our
tests looks like.

```go
func TestValidateLinuxIsSupported(t *testing.T) {
	valid := Validate(ANode(WithAPlatform(Linux)))
	if !valid {
		t.Fatal("linux should be supported, it was not")
	}
}

func TestValidateDarwinIsNotSupported(t *testing.T) {
	valid := Validate(ANode(WithAPlatform(Darwin)))
	if valid {
		t.Fatal("darwin should not be supported, it was")
	}
}

// Function builders
func WithAPlatform(builders ...func(*Platform)) func (n *Node) {
	return func(n *Node) {
		n.Platform = Platform(builders...)
	}
}

func Linux(p *Platform) {
	p.OS = "linux"
}

func Darwin(p *Platform) {
	p.OS = "darwin"
}
```

The intent is now clear. It's readable and still resilient to
change. The code `Node(WithPlatform(Linux))` is easy to understand
for a human. It makes what are the _tested_ characteristics of
`struct` pretty clear. It's easy to combine multiple builders as the
`WithPlatform` function shows 👼. It's also easy to create a
_function builder_, even in a different package (as long as the ways
to modify the struct are exported) and complex or _on-off_ builder
can be embedded in the function call (`Node(func(n *Node) { // …
  })`).

In summary, using these types of builder have several advantages :

-   tests are **easy to read**, and reduce the visual noise
-   tests are **resilient to change**
-   builders are **easy to compose** and very extensible
-   builders could even be **shared** with production code as there is
	nothing tied to `testing`.
