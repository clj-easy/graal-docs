# clj-graal-docs

## Rationale

GraalVM offers the ability to compile Java classes to native binaries.  This is
possible to some extent with Clojure programs as well. This approach works well
for command line tools that require fast startup so they can be used for
scripting and editor integration.

This little repo's goal is to collect scripts and tips to graalify clojure code.

## [CLJ-1472](CLJ-1472/README.md)

Clojure 1.10 introduced locking code into clojure.spec.alpha that often causes
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

## [External resources](doc/external-resources.md)

## License

Distributed under the EPL License, same as Clojure. See LICENSE.
