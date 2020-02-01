# CLJ-1472

Clojure 1.10 introduced locking code into `clojure.spec.alpha` that often causes
GraalVM's `native-image` to fail with:

```
Error: unbalanced monitors: mismatch at monitorexit, 96|LoadField#lockee__5436__auto__ != 3|LoadField#lockee__5436__auto__
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
```

The reason for this is that the bytecode emitted by the Clojure locking macro fails
bytecode verification. The relevant issue on the Clojure JIRA for this is
[CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

If you are experiencing this symptom, a patch to Clojure from CLJ-1472 will likely solve your problem.

## Vote

Using a patched version of Clojure is not ideal. If you are interested in getting this issue fixed in a next release of Clojure, consider upvoting it on [ask.clojure.org](https://ask.clojure.org/index.php/740/locking-macro-fails-bytecode-verification-native-runtime).


## Scripts

### build-clojure-with-1472-patch.sh

Builds and locally installs Clojure with a patch from
[CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

**Audience**

We have identified 2 primary users of this script:

1. **Clojure tool developer** - wants to natively compile their app. This person will use a 1.10.1 patched version of Clojure and will get by without specifying any options to the script.
2. **Clojure core developer** - works on Clojure itself and wants to make progress on CLJ-1472.  This person will likely work off HEAD of Clojure master but may want also to select different commits and/or patches.

**Usage**

```
Usage: build-clojure-with-1472-patch.sh [options...]

 -h, --help

 -p, --patch-filename <filename>
  name of patch file to download from CLJ-1472
  defaults to the currently recommended clj-1472-4.patch

 -c, --clojure-commit <commit>
  choose clojure commit to patch, can be sha or tag
  specify HEAD for most recent commit
  defaults to "clojure-10.0.1" tag

 -w, --work-dir <dir name>
  temporary work directory
  defaults to system generated temp dir
  NOTE: for safety, this script will only delete what it creates under specified work dir
```

At the time of this writing, CLJ-1472 considered patches are:

* `clj-1472-4.patch` - Described in CLJ-1472 as approach #2 and recommended (and script default)
* `CLJ-1472-reentrant-finally2.patch` - Described in CLJ-1472 as approach #1 and not recommended

Note that the script will download the patch for you.

The built version contains the clojure git short sha and a modified form of the
patch filename in its version.

**Prerequisites**

The script will fail if any of the following are not found:

* clojure
* git
* git-extras
* maven - tested with v3.6.3, check that your maven version is recent
* jet - [see jet installation instructions](https://github.com/borkdude/jet#installation)
  (Interesting tidbit: jet is a Clojure program compiled to a native image with GraalVM)
* curl
* sed

If on macOS, any missing prerequisites can be installed via brew.

**Common Usage Example**

Most folks will run without options:
```
./build-clojure-with-1472-patch.sh
```

defaults to the recommended `clj-1472-4.patch` and clojure [clojure-1.10.1](https://github.com/clojure/clojure/commits/clojure-1.10.1) (which has a short sha of `38bafca9`) and installs the following to your local maven repo:
* <code>org.clojure/clojure 1.10.1-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_4</b></code>
* <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_4</b></code>

**Alternate Usage: Specifying a Patch**

```
./build-clojure-with-1472-patch.sh -p CLJ-1472-reentrant-finally2.patch
```

defaults to clojure tag [clojure-1.10.1](https://github.com/clojure/clojure/commits/clojure-1.10.1) and locally installs:
* <code>org.clojure/clojure 1.10.1-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_reentrant_finally2</b></code>
* <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_reentrant_finally2</b></code>

**Alternate Usage: Specifying a Commit**

```
./build-clojure-with-1472-patch.sh -c HEAD
```

defaults to `clj-1472-4.patch`, selects clojure [HEAD](https://github.com/clojure/clojure/tree/653b8465845a78ef7543e0a250078eea2d56b659) commit (which has a short sha of `653b8465` at the time of this writing) and installs:
* <code>org.clojure/clojure 1.11.0-master_patch\_<b><i>653b8465</i></b>\_<b>clj_1472_4</b>-SNAPSHOT</code>
* <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>653b8465</i></b>\_<b>clj_1472_4</b></code>

**Alternate Usage: Specifying a Patch and a Commit**
```
./build-clojure-with-1472-patch.sh \
  -p CLJ-1472-reentrant-finally2.patch \
  -c c9a45b5f8afc2c4dfcce7f2e23dadc8749b9fd0d
```

installs:
  * <code>org.clojure/clojure 1.10.0-beta8-patch\_<b><i>c9a45b5f</i></b>\_<b>clj_1472_reentrant_finally2</b></code>
  * <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>c9a45b5f</i></b>\_<b>clj_1472_reentrant_finally2</b></code>

**Referencing a Patched Clojure**

The patched version of Clojure should work with GraalVM's `native-image`, reference
the variant you want. Example dependencies for `deps.edn`:

```Clojure
{org.clojure/clojure {:mvn/version "1.10.1-patch_38bafca9_clj_1472_4"}}
```

```Clojure
{org.clojure/clojure {:mvn/version "1.10.1-patch_38bafca9_clj_1472_reentrant_finally2"}}
```

**Testing**

- Update `deps.edn` to reflect the Clojure patched version you want to test.
Verify that you are using a patched version of Clojure by running `clojure -Stree`.

- If the `native-image` binary is not on the `PATH`, set either:
  - the `GRAALVM_HOME` environment variable to the location of your GraalVM
    installation
  - the `NATIVE_IMAGE` environment variable to the location of GraalVM's
    `native-image` command.  then no environment variable has

- Run `./compile`. This should produce a `spec-test` executable.
- Run `./spec-test`. This should produce output like the following:

   ```Clojure
   {:major 1, :minor 10, :incremental 1, :qualifier patch_38bafca9_clj_1472_4}
   true
   ```

- Optionally rerun `./compile` against Clojure `1.10.1` unpatched. You should get `unbalanced monitors` errors.


## Performance

Here we look at the performance impact of CLJ-1472 patches on Clojure in absence
of GraalVM.

Locking test code matches code from **Perf test** section in [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

Run:

```
clojure -J-XX:-EliminateLocks -A:performance
```

We use `-J-XX:-EliminateLocks` to prevent the JVM from eliding locks.

This should output something like the following:

```
Java version: 11.0.6
Clojure version: 1.10.1
"Elapsed time: 23217.11897 msecs"
Success
```

The [babashka](https://github.com/borkdude/babashka) `perftest.clj` script runs the performance test
against Clojure `1.10.1` unpatched and CLJ-1472 candidate patches (which are assumed to be already installed).

Examples results from a Late 2013 iMac with Quad-Core Intel i7 running macOS 10.15.2.
`perftest.clj` was run twice against the Amazon Corretto JVM; once against v1.8 then once against v11.0.6.
Times are in milliseconds.

| Java Version | JVM Opt                                    |       1.10.1 | 1.10.1&#x2011;patch 38bafca9 clj 1472 4 | 1.10.1&#x2011;patch 38bafca9 clj 1472 reentrant finally2 |
|--------------|--------------------------------------------|--------------|-----------------------------------------|----------------------------------------------------------|
| 1.8.0_242    | &lt;none&gt;                               | 23579.025184 |                            23103.459166 |                                             22674.857614 |
| 1.8.0_242    | &#x2011;J&#x2011;XX:&#x2011;EliminateLocks | 23458.798344 |                            23110.255723 |                                             22743.683354 |
| 11.0.6       | &lt;none&gt;                               | 25526.012733 |                            23164.781265 |                                             22665.123933 |
| 11.0.6       | &#x2011;J&#x2011;XX:&#x2011;EliminateLocks | 22984.178757 |                            22521.638312 |                                             21779.119136 |

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

- revert to using Clojure 1.9.0

## Misc

- Comment by @eraserhd in the #graalvm channel on Slack:
> IMHO clj-1472-3.patch is simple and sufficient.  Ghadi's changes the clojure compiler to be able to generate the correct bytecode for locking, saving a method call and adding some code to the clojure compler.
I think locking is, by definition, not performant, and it's also not idiomatic in Clojure, so that's why my vote goes for 1472.
er, clj-1472-3.patch
(clj-1472-3.patch uses a native Java method which is passed a callable to lock an object)

- **Screener feedback** from @puredanger in [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472) recommends `clj-1472-4.patch` (which is `clj-1472-3.patch` rebased to Clojure master).


## TODO

* https://github.com/search?l=Clojure&o=desc&q=locking&s=indexed&type=Code might be worth a skim to see if anyone looks like they are using/abusing locking (Alex in #graalvm)
