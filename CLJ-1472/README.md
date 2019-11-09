# CLJ-1472

## Scripts

### build-clojure-with-1472-patch.sh

Clojure 1.10 introduced locking code into clojure.spec.alpha that often causes
GraalVM's `native-image` to fail.

[Clojure issue CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472) includes
potential fixes for this issue.

This script builds and locally installs:

* `org.clojure/clojure` `1.10.1-patch1472`
* `org.clojure/spec.alpha` `0.2.176-patch1472`

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

