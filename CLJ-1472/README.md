# CLJ-1472

Clojure 1.10 introduced locking code into clojure.spec.alpha that often causes
GraalVM's `native-image` to fail with:

```
Error: unbalanced monitors: mismatch at monitorexit, 96|LoadField#lockee__5436__auto__ != 3|LoadField#lockee__5436__auto__
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
```

The reason for this is that the bytecode emitted by the locking macro fails
bytecode verification. The relevant issue on the Clojure JIRA for this is
[CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

## TODO

* [incorporate @borkdude's gist](https://gist.github.com/borkdude/dd0857cf1958b25496fddbdbf359ca59) which
is the basis for the script herein
* include tradeoffs between clj-1472-3.patch and CLJ-1472-reentrant-finally2.patch
* include performance tests of clj-1472-3.patch vs CLJ-1472-reentrant-finally2.patch

## Scripts

### build-clojure-with-1472-patch.sh

This script builds and locally installs:

* `org.clojure/clojure` `1.10.1-patch1472`
* `org.clojure/spec.alpha` `0.2.176-patch1472`

with patches from JIRA issue [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

TODO: there are multiple patches in CLJ-1472. Make explicit which patch the script is using or configure via a parameter? The relevant patches so far are: clj-1472-3.patch and CLJ-1472-reentrant-finally2.patch.

The patched version of clojure should work with graal's `native-image`, reference
it via, for example from deps.edn, via:
```
{org.clojure/clojure {:mvn/version "1.10.1-patch1472"}}
```

Prerequisites (installed via brew on macOS)

* clojure
* git
* git-extras
* maven

Tested on macOS Catalina.

## Workarounds

- clojurl introduces a Java-level special form and patches selections of Clojure
code at run-time:
[link](https://github.com/taylorwood/clojurl/commit/12b96b5e9a722b372f153436b1f6827709d0f2ab)

- rep builds GraalVM binaries using an automated patched Clojure build:
  [link](https://github.com/eraserhd/rep/blob/1951df780fdd2781644f934dfc36ee394460effb/.circleci/images/primary/build.sh#L1)

It keeps pre-built jars of clojure and spec
[here](https://github.com/eraserhd/rep/tree/develop/deps)

- babashka vendors code from Clojure and works around the locking issues
  manually. [This](https://github.com/borkdude/babashka/blob/070220da70c894ad7b282ce2747607c0bee68613/src/babashka/impl/clojure/core/server.clj#L1)
  is a patched version of `clojure.core.server`.
