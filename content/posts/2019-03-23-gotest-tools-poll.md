+++
title = "Golang testing — gotest.tools poll"
date = 2019-03-23
tags = ["testing", "golang", "poll"]
categories = ["developement"]
draft = false
creator = "Emacs 26.1 (Org mode 9.2 + ox-hugo)"
+++

Let's continue the [`gotest.tools`](https://gotest.tools) serie, this time with the `poll` package.

> Package poll provides tools for testing asynchronous code.

When you write test, you may test a piece of code that work asynchronously, where the
state you're expecting is gonna take a bit of time to be achieved. This is especially true
when you work on networking or file-system code. And this happens a lot when you write
integration (or end-to-end) test, less for unit-tests.

The package `poll` is trying to tackle those use cases. We'll first take a look at the
main function, `WaitOn`, then how to write a `Check`, using the `Result` type.


## `WaitOn` {#waiton}

Let's look into the main `poll` function : \`WaitOn\`.

> WaitOn a condition or until a timeout. Poll by calling check and exit when check returns
> a done Result. To fail a test and exit polling with an error return a error result.

In a gist, `WaitOn` will run a _condition_ function until it either times out or
succeed. It wait for a given time/delay between each run.

```go
func WaitOn(t TestingT, check Check, pollOps ...SettingOp) {
	// […]
}
```

As any _testing helper_ function, the first argument is `*testing.T` (or, in this case,
any thing that look like it, thanks to the `TestingT` interace). The two other arguments
are way more interesting :

-   The `Check` is the condition that will run multiple times until it either timeout, or succeed.
-   The `SettingOp(s)` which are options to configure the function, things like the timeout,
    or the _delay_ between each run.

The settings are pretty straightforward :

-   `WithDelay` : sets the delay to wait between polls. The default delay is 100ms.
-   `WithTimeout` : sets the timeout. The default timeout is 10s.

There is existing `Check` for common case:

-   `Connection` : try to open a connection to the address on the named network.

    ```go
    poll.WaitOn(t, poll.Connection("tcp", "foo.bar:55555"), poll.WithTimeout("5s"))
    ```

-   `FileExists` : looks on filesystem and check that path exists.

    ```go
    poll.WaitOn(t, poll.FileExists("/should/be/created"), poll.WithDelay("1s"))
    ```


## `Check` and `Result` {#check-and-result}

`Connection` and `FileExists` are the only two _built-in_ `Check` provided by
`gotest.tools`. They are useful, but as usual, where `gotest.tools` shines is
extensiblity. It is really easy to define your own `Check`.

```go
type Check func(t LogT) Result
```

A `Check` is, thus, only a function that takes `LogT` — which is anything that can log
something, like `*testing.T` — and return a `Result`. Let's look at this intersting
`Result` type.

```go
type Result interface {
    // Error indicates that the check failed and polling should stop, and the
    // the has failed
    Error() error
    // Done indicates that polling should stop, and the test should proceed
    Done() bool
    // Message provides the most recent state when polling has not completed
    Message() string
}
```

Although it's an interface, the `poll` package defines built-in `Result` so that it's easy
to write `Check` without having to define you `Result` type.

-   `Continue` returns a Result that indicates to WaitOn that it should continue
    polling. The message text will be used as the failure message if the timeout is reached.
-   `Success` returns a Result where Done() returns true, which indicates to WaitOn that it
    should stop polling and exit without an error.
-   `Error` returns a Result that indicates to WaitOn that it should fail the test and stop
    polling.

The basic just to write a `Check` is then :

-   if the state is not there yet, return `Continue`,
-   if there is an error, unrelated to validating the state, return an `Error`,
-   if the state is there, return `Success`.

Let's look at an example taken from the `moby/moby` source code.

```go
poll.WaitOn(t, container.IsInState(ctx, client, cID, "running"), poll.WithDelay(100*time.Millisecond))

func IsInState(ctx context.Context, client client.APIClient, containerID string, state ...string) func(log poll.LogT) poll.Result {
	return func(log poll.LogT) poll.Result {
		inspect, err := client.ContainerInspect(ctx, containerID)
		if err != nil {
			return poll.Error(err)
		}
		for _, v := range state {
			if inspect.State.Status == v {
				return poll.Success()
			}
		}
		return poll.Continue("waiting for container to be one of (%s), currently %s", strings.Join(state, ", "), inspect.State.Status)
	}
}
```


## Conclusion {#conclusion}

… that's a wrap. The `poll` package allows to easily wait for a condition to happen in a
given time-frame — with sane defaults. As for most of the `gotest.tools` package, we use
this package heavily in `docker/*` projects too…
