+++
title = "Golang testing — gotest.tools icmd"
date = 2018-09-18
tags = ["testing", "golang", "exec", "command"]
categories = ["developement"]
draft = true
creator = "Emacs 26.1 (Org mode 9.1.14 + ox-hugo)"
+++

Let's continue the [`gotest.tools`](https://gotest.tools) serie, this time with the `icmd` package.

> Package icmd executes binaries and provides convenient assertions for testing the results.

After filesystem operations (seen in [`fs`](/posts/2018-09-14-gotest-tools-fs/)), antoher common use-case in tests is to
**execute a command**. The reasons can be you're testing the `cli` you're currently writing
or you need to setup something using a command line. A classic execution in a test might
lookup like the following.

```go
cmd := exec.Command("echo", "foo")
cmd.Stout = &stdout
cmd.Env = env
if err := cmd.Run(); err != nil {
	t.Fatal(err)
}
if string(stdout) != "foo" {
	t.Fatalf("expected: foo, got %s", string(stdout))
}
```

The package `icmd` is there to ease your pain (as usual 😉) — we used _the name `icmd`_
instead of `cmd` because it's a pretty common identifier in Go source code, thus would be
really easy to _shadow_ — and have some really weird problems going on.

The usual `icmd` workflow is the following:

1.  Describe the command you want to execute using : type `Cmd`, function `Command` and
	`CmdOp` operators.
2.  Run it using : function `RunCmd` or `RunCommand` (that does 1. for you). You can also
	use `StartCmd` and `WaitOnCmd` if you want more control on the execution workflow.
3.  Check the result using the `Assert`, `Equal` or `Compare` methods attached to the
	`Result` struct that the command execution return.


## Create and run a command {#create-and-run-a-command}

Let's first dig how to create commands. In this part, the assumption here is that the
command is successful, so we'll have `.Assert(t, icmd.Success)` for now — we'll learn more
about `Assert` in the next section 👼.

The simplest way to create and run a command is using `RunCommand`, it has the same
signature as `os/exec.Command`. A simple command execution goes as below.

```go
icmd.RunCommand("echo", "foo").Assert(t, icmd.Sucess)
```

Sometimes, you need to customize the command a bit more, like adding some environment
variable. In those case, you are going to use `RunCmd`, it takes a `Cmd` and operators.
Let's look at those functions.

```go
func RunCmd(cmd Cmd, cmdOperators ...CmdOp) *Result

func Command(command string, args ...string) Cmd

type Cmd struct {
	Command []string
	Timeout time.Duration
	Stdin   io.Reader
	Stdout  io.Writer
	Dir     string
	Env     []string
}
```

As we've seen [multiple](/posts/2017-01-01-go-testing-functionnal-builders/) [times](/posts/2018-08-16-gotest-tools-assertions/) [before](/posts/2018-09-14-gotest-tools-fs/), it uses the _powerful_ functional arguments. At the
time I wrote this post, the `icmd` package doesn't contains too much `CmdOp`&nbsp;[^fn:1], so I'll
propose two version for each example : one with `CmdOpt` present in [this PR](https://github.com/gotestyourself/gotest.tools/pull/122) and one
without them.

```go
// With
icmd.RunCmd(icmd.Command("sh", "-c", "echo $FOO"),
	icmd.WithEnv("FOO=bar", "BAR=baz"), icmd.Dir("/tmp"),
	icmd.WithTimeout(10*time.Second),
).Assert(t, icmd.Success)

// Without
icmd.RunCmd(icmd.Cmd{
	Command: []string{"sh", "-c", "echo $FOO"},
	Env: []string{"FOO=bar", "BAR=baz"},
	Dir: "/tmp",
	Timeout: 10*time.Second,
}).Assert(t, icmd.Success)
```

As usual, the intent is clear, it's simple to read and composable (with `CmdOp`'s).


## Assertions {#assertions}

Let's dig into the assertion part of `icmd`. Running a command returns a struct
`Result`. It has the following methods :

-   `Assert` compares the Result against the Expected struct, and fails the test if any of
	the expectations are not met.
-   `Compare` compares the result to Expected and return an error if they do not match.
-   `Equal` compares the result to Expected. If the result doesn't match expected
	returns a formatted failure message with the command, stdout, stderr, exit code, and any
	failed expectations. It returns an `assert.Comparison` struct, that can be used by other
	`gotest.tools`.
-   `Combined` returns the stdout and stderr combined into a single string.
-   `Stderr` returns the stderr of the process as a string.
-   `Stdout` returns the stdout of the process as a string.

When you have a result, you, most likely want to do two things :

-   _assert_ that the command succeed or failed with some specific values (exit code,
	stderr, stdout)
-   use the output — most likely `stdout` but maybe `stderr` — in the rest of the test.

As seen above, _asserting_ the command result is using the `Expected` struct.

```go
type Expected struct {
	ExitCode int    // the exit code the command returned
	Timeout  bool   // did it timeout ?
	Error    string // error returned by the execution (os/exe)
	Out      string // content of stdout
	Err      string // content of stderr
}
```

`Success` is a constant that defines a success — it's an exit code of `0`, didn't timeout,
no error. There is also the `None` constant, that should be used for `Out` or `Err`, to
specify that we don't want any content for those standard outputs.

```go
icmd.RunCmd(icmd.Command("cat", "/does/not/exist")).Assert(t, icmd.Expected{
	ExitCode: 1,
	Err:      "cat: /does/not/exist: No such file or directory",
})

// In case of success, we may want to do something with the result
result := icmd.RunCommand("cat", "/does/exist")
result.Assert(t, icmd.Success)
// Read the output line by line
scanner := bufio.NewScanner(strings.NewReader(result.Stdout()))
for scanner.Scan() {
	// Do something with it
}
```

If the `Result` doesn't map the `Expected`, a test failure will happen with a useful
message that will contains the executed command and what differs between the result and
the expectation.

```go
result := icmd.RunCommand(…)
result.Assert(t, icmd.Expected{
		ExitCode: 101,
		Out:      "Something else",
		Err:      None,
})
// Command:  binary arg1
// ExitCode: 99 (timeout)
// Error:    exit code 99
// Stdout:   the output
// Stderr:   the stderr
//
// Failures:
// ExitCode was 99 expected 101
// Expected command to finish, but it hit the timeout
// Expected stdout to contain "Something else"
// Expected stderr to contain "[NOTHING]"
```

Finally, we listed `Equal` above, that returns a `Comparison` struct. This means we can
use it easily with the `assert` package. As written in a [previous post (about the `assert`
package)](/posts/2018-08-16-gotest-tools-assertions/), I tend prefer to use `cmp.Comparison`. Let's convert the above examples using
`assert`.

```go
result := icmd.RunCmd(icmd.Command("cat", "/does/not/exist"))
assert.Check(t, result.Equal(icmd.Expected{
	ExitCode: 1,
	Err:      "cat: /does/not/exist: No such file or directory",
}))

// In case of success, we may want to do something with the result
result := icmd.RunCommand("cat", "/does/exist")
assert.Assert(t, result.Equal(icmd.Success))
// Read the output line by line
scanner := bufio.NewScanner(strings.NewReader(result.Stdout()))
for scanner.Scan() {
	// Do something with it
}
```


## Conclusion… {#conclusion}

… that's a wrap. The `icmd` package allows to easily run command and describe what result
are expected of the execution, with the least noise possible. We **use this package heavily**
on several `docker/*` projects (the engine, the cli)…

[^fn:1]: The `icmd` package is one of the oldest `gotest.tools` package, that comes from the [`docker/docker`](https://github.com/docker/docker) initialy. We introduced these `CmdOp` but implementations were in `docker/docker` at first and we never really updated them.
