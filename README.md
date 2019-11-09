# clj-graal-docs

## Rationale

GraalVM offers the ability to compile Java classes to native binaries.
This is possible to some extent with Clojure programs as well.

This little repo's goal is to collect scripts and tips to graalify clojure code.

## [CLJ-1472](CLJ-1472/README.md)

Clojure 1.10 introduced locking code into clojure.spec.alpha that often causes
GraalVM's `native-image` to fail. The reason for this is that the bytecode emitted by the locking macro fails bytecode verification. The relevant issue on the Clojure JIRA for this is [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472). We document how to apply patches from this issue and several other workarounds [here](doc/README.md).

See [CLJ-1472](README.md).

## [External resources](doc/external-resources.md)

## License

Distributed under the EPL License, same as Clojure. See LICENSE.
