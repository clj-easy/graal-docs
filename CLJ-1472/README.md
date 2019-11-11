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

* include tradeoffs between clj-1472-3.patch and CLJ-1472-reentrant-finally2.patch
* https://github.com/search?l=Clojure&o=desc&q=locking&s=indexed&type=Code might be worth a skim to see if anyone looks like they are using/abusing locking (Alex in #graalvm)
* cleaning all this info up and making a really readable ticket would be really helpful. this is basically what I would do on this ticket (https://clojure.org/dev/creating_tickets) and is a huge boost to getting it ready to screen (Alex in #graalvm)

## Scripts

### build-clojure-with-1472-patch.sh

Builds and locally installs clojure with a specified patch from
[CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

**Audience**

We have identified 2 primary users of this script:

1. **clojure tool developer** - wants to natively compile their app. This person will use a 1.10.1 patched version of clojure and will get by without specifying any options to the script.
2. **clojure core developer** - works on clojure itself and wants to make progress on CLJ-1472.  This person will likely work off HEAD of master but may want also to select different commits and/or patches.

**Usage**

```Shell
Usage: build-clojure-with-1472-patch.sh [options...]

 -h, --help

 -p, --patch-filename <filename>
  name of patch file to download from CLJ-1472
  defaults to clj-1472-3.patch

 -c, --clojure-commit <commit>
  choose clojure commit to patch, can be sha or tag
  specify HEAD for most recent commit
  defaults to "clojure-10.0.1" tag

 -w, --work-dir <dir name>
  temporary work directory
  defaults to system generated temp dir
  NOTE: for safety, this script will only delete what it creates under specified work dir
```

At the time of this writing, current candidate patches filenames are:

* `clj-1472-3.patch` (default)
* `CLJ-1472-reentrant-finally2.patch`

Note that the script will download the patch for you.

The built version contains the clojure git short sha and a modified form of the
patch filename in its version, examples:

* patch **clj-1472-3.patch** at clojure tag
  [***clojure-1.10.1***](https://github.com/clojure/clojure/commits/clojure-1.10.1)
  (the default when specifying no options) installs:
    * <code>org.clojure/clojure 1.10.1-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_3</b></code>
    * <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_3</b></code>
* patch **CLJ-1472-reentrant-finally2.patch** at clojure tag
  [***clojure-1.10.1***](https://github.com/clojure/clojure/commits/clojure-1.10.1)
  installs:
    * <code>org.clojure/clojure 1.10.1-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_reentrant_finally2</b></code>
    * <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_reentrant_finally2</b></code>
* patch **clj-1472-3.patch** at clojure
  [***HEAD***](https://github.com/clojure/clojure/tree/653b8465845a78ef7543e0a250078eea2d56b659)
  (at the time of this writing) installs:
    * <code>org.clojure/clojure 1.11.0-master_patch\_<b><i>653b8465</i></b>\_<b>clj_1472_3</b>-SNAPSHOT</code>
    * <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>653b8465</i></b>\_<b>clj_1472_3</b></code>
* patch **CLJ-1472-reentrant-finally2.patch** at clojure commit
  [***c9a45b5f***](https://github.com/clojure/clojure/commits/c9a45b5f8afc2c4dfcce7f2e23dadc8749b9fd0d)
  installs:
    * <code>org.clojure/clojure 1.10.0-beta8-patch\_<b><i>c9a45b5f</i></b>\_<b>clj_1472_reentrant_finally2</b></code>
    * <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>c9a45b5f</i></b>\_<b>clj_1472_reentrant_finally2</b></code>

The patched version of clojure should work with graal's `native-image`, reference
the variant you want. Example dependencies for `deps.edn`:

```Clojure
{org.clojure/clojure {:mvn/version "1.10.1-patch_38bafca9_clj_1472_3"}}
```

```Clojure
{org.clojure/clojure {:mvn/version "1.10.1-patch_38bafca9_clj_1472_reentrant_finally2"}}
```

**Prerequisites**

The script will fail if any of the following are not found:

* clojure
* git
* git-extras
* maven
* jet - [see jet installation instructions](https://github.com/borkdude/jet#installation)
  (Interesting tidbit: jet is a clojure program compiled to a native image with graal)
* curl
* sed

If on macOS, any missing prerequisites can be installed via brew.

**Testing**

- Update `deps.edn` to reflect the Clojure version you want to test.
Verify that you are using the patched version of spec using `clojure -Stree`.

- If the `native-image` binary is not on the `PATH`, set either:
  - the `GRAALVM_HOME` environment variable to the location of your GraalVM
    installation
  - the `NATIVE_IMAGE` environment variable to the location of GraalVM's
    `native-image` command.  then no environment variable has

- Run `./compile`. This should produce a `spec-test` executable.
- Run `./spec-test`. This should produce output like the following:

``` clojure
{:major 1, :minor 10, :incremental 1, :qualifier patch_38bafca9_clj_1472_3}
true
```

## Performance

Here we look at the performance impact of CLJ-1472 patches on clojure in absence
of graal.

Run:

``` shellsession
clojure -J-XX:-EliminateLocks -A:performance
```

We use `-J-XX:-EliminateLocks` to prevent the JVM from eliding locks.

This should output something like the following:

```
Java version: 11.0.3
Clojure version: 1.10.1-patch_clj_1472_3
"Elapsed time: 14955.486811 msecs"
10000000
```

Reports:

CLJ-1472-reentrant-finally2:

```
Java version: 1.8.0_212
Clojure version: 1.11.0-master-SNAPSHOT
"Elapsed time: 20173.415374 msecs"
10000000
```

clj-1472-3.patch:
```
Java version: 1.8.0_212
Clojure version: 1.11.0-master-SNAPSHOT
"Elapsed time: 19793.283815 msecs"
10000000
```

It seems neither patch cause a performance regression.

## Other Workarounds

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

- revert to using clojure 1.9.0

## Misc

Comment by @eraserhd in the #graalvm channel on Slack:

> IMHO clj-1472-3.patch is simple and sufficient.  Ghadi's changes the clojure compiler to be able to generate the correct bytecode for locking, saving a method call and adding some code to the clojure compler.
I think locking is, by definition, not performant, and it's also not idiomatic in Clojure, so that's why my vote goes for 1472.
er, clj-1472-3.patch
(clj-1472-3.patch uses a native Java method which is passed a callable to lock an object)
