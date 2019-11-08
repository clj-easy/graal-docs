# clojure-graalifications

## Rationale

While clojure does not support graal, some developers are finding the quick
startup time it offers useful for command line tools.

This little repo's goal is to collect scripts and tips to graalify clojure code.

## TODO

* [incorporate @borkdude's gist](https://gist.github.com/borkdude/dd0857cf1958b25496fddbdbf359ca59) which
is the basis for the script herein

## Scripts

### build-clojure-with-1472-patch.sh

Clojure 1.10 introduced some locking code that causes graalvm's `native-image`
to fail.

[Clojure issue CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472) includes
some potential fixes for this issue.

This script builds and locally installs:

* `org.clojure/clojure` `1.10.1-patch1472`
* `org.clojure/spec.alpha` `0.2.176-patch1472`

This patched version of clojure should work with graal's `native-image`, reference
it via `{org.clojure/clojure {:mvn/version "1.10.1-patch1472"}}`

Prerequisites (installed via brew on macOS)

* clojure
* git
* git-extras
* maven

Tested on macOS Catalina.

## License

Distributed under the EPL License, same as Clojure. See LICENSE.
