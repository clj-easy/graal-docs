# clj-graal-docs

## Rationale

GraalVM offers the ability to compile Java classes to native binaries.  This is
possible to some extent with Clojure programs as well. This approach works well
for command line tools that require fast startup so they can be used for
scripting and editor integration.

This little repo's goal is to collect scripts and tips to GraalVM-ify Clojure code.

When we refer to GraalVM in this repository, we mean SubstrateVM, the native
compiler, unless otherwise indicated.

## Community

> :wave: Need help or want to chat? Say hi on [Clojurians Slack](http://clojurians.net/) in [#graalvm](https://clojurians.slack.com/app_redirect?channel=graalvm).

We heartily welcome, and greatly appreciate, tips, tricks, corrections and improvements from you.

## [Hello world](doc/hello-world.md)

## Tips and tricks

### Reflection

Make sure you put `(set! *warn-on-reflection* true)` at the top of every namespace in your project to get rid of all reflection.
There is a patch to make `clojure.stacktrace` work with GraalVM in [JIRA](https://clojure.atlassian.net/browse/CLJ-2502).

### Learn What's Being Included

When you add GraalVM's `native-image`
[`-H:+PrintAnalysisCallTree`](https://github.com/oracle/graal/blob/master/substratevm/REPORTS.md#call-tree)
option, under `./reports` you will learn what packages, classes and methods are
being included in your native image.

### native-image RAM usage

GraalVM's `native-image` can consume more RAM than is available on free tiers of
services such as CircleCI. To limit how much RAM `native-image` uses, include
the `--no-server` option and set max heap usage via the `"-J-Xmx"` option
(for example `"-J-Xmx3g"` limits the heap to 3 gigabytes).

If you are suffering out of memory errors, experiment on your development
computer with higher `-J-Xmx` values. To learn actual memory usage, prefix the
`native-image` command with:

* on macOS `command time -l `
* on Linux `command time -v `

These `time` commands report useful stats in addition to "maximum resident set size".

Actual memory usage is an ideal. Once you have a successful build, you can experiment
with lowering `-J-Xmx` below the ideal. The cost will be longer build times, and when
`-J-Xmx` is too low, out of memory errors.

## [CLJ-1472](CLJ-1472/README.md)

Clojure 1.10 introduced locking code into `clojure.spec.alpha` that often causes
GraalVM's `native-image` to fail with:

```
Error: unbalanced monitors: mismatch at monitorexit, 96|LoadField#lockee__5436__auto__ != 3|LoadField#lockee__5436__auto__
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
	at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
```

The reason for this is that the bytecode emitted by the locking macro fails
bytecode verification. The relevant issue on the Clojure JIRA for this is
[CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472). We document how to
apply patches from this issue and several other workarounds
[here](CLJ-1472/README.md).

## JDK11 and clojure.lang.Reflector

JDK11 is supported since GraalVM 19.3.0. GraalVM can get confused about a
[conditional piece of
code](https://github.com/clojure/clojure/blob/653b8465845a78ef7543e0a250078eea2d56b659/src/jvm/clojure/lang/Reflector.java#L29-L57)
in `clojure.lang.Reflector` which dispatches on Java 8 or a later Java version.

Workarounds:

- Using a Java 8 version of GraalVM
- Patch `clojure.lang.Reflector` on the classpath with the conditional logic
  swapped out for non-conditional code which works on JDK11 (but not on
  JDK8). The patch can be found [here](resources/Reflector.java).

## GraalVM development builds

Development builds of GraalVM can be found
[here](https://github.com/graalvm/graalvm-ce-dev-builds/releases). Note that
these builds are intended for early testing feedback, but can disappear after a
proper release has been made, so don't link to them from production CI builds.

## [Testing Strategies](doc/testing-strategies.md)

## [External resources](doc/external-resources.md)

Curated collection of [projects, articles, etc.](doc/external-resources.md)

## License

Distributed under the EPL License, same as Clojure. See LICENSE.
