# CLJ-1472

:tada: Update: The recommended patch from [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472) resolves this issue. This patch is included in the current Clojure release.

```
Error: unbalanced monitors: mismatch at monitorexit, 96|LoadField#lockee__5436__auto__ != 3|LoadField#lockee__5436__auto__
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
```

See [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472) for a detailed explanation of the cause of this failure and the Clojure core team's approach to addressing it.

Although no longer necessary nor recommended, you can create a local patched version of Clojure by following the instructions below under [Scripts](#scripts).

## Vote

:tada: Update: Thanks for voting! The Clojure core team has has addressed this issue and the fix is available in the current Clojure release.

Using a patched version of Clojure is not ideal.
If you are interested in getting this issue fixed in a next release of Clojure, consider upvoting it on [ask.clojure.org](https://ask.clojure.org/index.php/740/locking-macro-fails-bytecode-verification-native-runtime).

## [Steps to Reproduce](steps-to-reproduce.md)

## Scripts

### build-clojure-with-1472-patch.sh

Builds and locally installs Clojure with a patch from [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

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
  defaults to the currently recommended clj-1472-5.patch

 -c, --clojure-commit <commit>
  choose clojure commit to patch, can be sha or tag
  specify HEAD for most recent commit
  defaults to "clojure-10.0.1" tag

 -w, --work-dir <dir name>
  temporary work directory
  defaults to system generated temp dir
  NOTE: for safety, this script will only delete what it creates under specified work dir
```

CLJ-1472 considered patches are:

* `clj-1472-5.patch` - At the time of this writing, there are no other candidates under consideration.

Note that the script will download the patch for you.

The built version contains the clojure git short sha and a modified form of the patch filename in its version.

**Prerequisites**

The script will fail if any of the following are not found:

* clojure
* git
* git-extras
* maven - tested with v3.6.3, check that your maven version is recent
* jet - [see jet installation instructions](https://github.com/borkdude/jet#installation) (Interesting tidbit: jet is a Clojure program compiled to a native image with GraalVM)
* curl
* sed

If on macOS, any missing prerequisites can be installed via brew.

**Common Usage Example**

Most folks will run without options:
```
./build-clojure-with-1472-patch.sh
```

defaults to the recommended `clj-1472-5.patch` and clojure [clojure-1.10.1](https://github.com/clojure/clojure/commits/clojure-1.10.1) (which has a short sha of `38bafca9`) and installs the following to your local maven repo:
* <code>org.clojure/clojure 1.10.1-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_5</b></code>
* <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>38bafca9</i></b>\_<b>clj_1472_5</b></code>

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

defaults to `clj-1472-5.patch`, selects clojure [HEAD](https://github.com/clojure/clojure/tree/653b8465845a78ef7543e0a250078eea2d56b659) commit (which has a short sha of `653b8465` at the time of this writing) and installs:
* <code>org.clojure/clojure 1.11.0-master_patch\_<b><i>653b8465</i></b>\_<b>clj_1472_5</b>-SNAPSHOT</code>
* <code>org.clojure/spec.alpha 0.2.176-patch\_<b><i>653b8465</i></b>\_<b>clj_1472_5</b></code>

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

The patched version of Clojure should work with GraalVM's `native-image`, reference the variant you want. Example dependencies for `deps.edn`:

```Clojure
{org.clojure/clojure {:mvn/version "1.10.1-patch_38bafca9_clj_1472_5"}}
```

```Clojure
{org.clojure/clojure {:mvn/version "1.10.1-patch_38bafca9_clj_1472_reentrant_finally2"}}
```

## Testing

- Update `deps.edn` to reflect the version of Clojure you want to test.
Verify the Clojure version by running `clojure -Stree`.

- If the `native-image` binary is not on the `PATH`, set either:
  - the `GRAALVM_HOME` environment variable to the location of your GraalVM installation
  - the `NATIVE_IMAGE` environment variable to the location of GraalVM's `native-image` command.

- Run `./compile`, after some output that looks similar to this:
     ```
     spec-test.core
     [spec-test:46447]    classlist:   3,710.61 ms,  1.15 GB
     [spec-test:46447]        (cap):   2,793.84 ms,  1.15 GB
     [spec-test:46447]        setup:   4,119.13 ms,  1.15 GB
     [spec-test:46447]   (typeflow):  13,646.25 ms,  3.01 GB
     [spec-test:46447]    (objects):   6,452.33 ms,  3.01 GB
     [spec-test:46447]   (features):     497.04 ms,  3.01 GB
     [spec-test:46447]     analysis:  21,187.40 ms,  3.01 GB
     [spec-test:46447]     (clinit):     360.62 ms,  3.26 GB
     [spec-test:46447]     universe:   1,068.79 ms,  3.26 GB
     [spec-test:46447]      (parse):   1,660.49 ms,  3.26 GB
     [spec-test:46447]     (inline):   1,942.10 ms,  3.31 GB
     [spec-test:46447]    (compile):  12,632.50 ms,  4.28 GB
     [spec-test:46447]      compile:  17,143.04 ms,  4.28 GB
     [spec-test:46447]        image:   2,310.31 ms,  4.28 GB
     [spec-test:46447]        write:     743.65 ms,  4.28 GB
     [spec-test:46447]      [total]:  50,826.31 ms,  4.28 GB
     ```
     you should now have a `spec-test` executable.
- Run `./spec-test`. This should produce output like the following:

   ```Clojure
   {:major 1, :minor 10, :incremental 2, :qualifier alpha1}
   true
   ```

- Optionally rerun `./compile` against Clojure `1.10.1` unpatched. You should get `unbalanced monitors` errors.


## Performance

Here we look at the performance impact of CLJ-1472 patches on Clojure in absence of GraalVM.

### Run a Performance Test

To run an individual performance test against Clojure patched with current recommended CLJ-1472 patch.
Patched Clojure must already be installed, see [Scripts](#scripts) above:

```
clojure -J-XX:-EliminateLocks -A:performance
```

(We use `-J-XX:-EliminateLocks` to prevent the JVM from eliding locks.)

This should output something like the following:

```
Java version: 11.0.6
Clojure version: 1.10.1
"Elapsed time: 23217.11897 msecs"
Success
```

### Run Performance Tests via perftest.clj

The [babashka](https://github.com/borkdude/babashka) `perftest.clj` script runs the performance test against Clojure `1.10.1` unpatched and Clojure `1.10.1` with CLJ-1472 current and previous candidate patches.
Patches are assumed to be already installed, see [Scripts](#scripts) above.

Examples results from a Late 2013 iMac with Quad-Core Intel i7 running macOS 10.15.3.
`perftest.clj` was run twice against the Amazon Corretto JVM; once against v1.8 then once against v11.0.6.
Times are in milliseconds.

| Java Version | JVM Opt                                    |       1.10.1 | 1.10.1&#x2011;patch 38bafca9 clj 1472 4 | 1.10.1&#x2011;patch 38bafca9 clj 1472 5 | 1.10.1&#x2011;patch 38bafca9 clj 1472 reentrant finally2 |
|--------------|--------------------------------------------|--------------|-----------------------------------------|-----------------------------------------|----------------------------------------------------------|
| 1.8.0_242    | &lt;none&gt;                               | 23868.683118 |                            23235.997299 |                            23686.511219 |                                             23720.294582 |
| 1.8.0_242    | &#x2011;J&#x2011;XX:&#x2011;EliminateLocks | 23495.019667 |                            23461.609831 |                            22877.822631 |                                             23050.786466 |
| 11.0.6       | &lt;none&gt;                               | 22563.156409 |                             22601.63469 |                            23592.760502 |                                             22018.846114 |
| 11.0.6       | &#x2011;J&#x2011;XX:&#x2011;EliminateLocks | 22569.031807 |                            23240.028719 |                            23122.333266 |                                             24844.203457 |

## Other Workarounds

If you cannot, for whatever reason, use the current Clojure v1.10 release, here are some other workarounds:

- create your own patched version of Clojure by following instructions under [Scripts](#scripts) above.

- clojurl introduces a Java-level special form and patches selections of Clojure code at run-time:
[link](https://github.com/taylorwood/clojurl/commit/12b96b5e9a722b372f153436b1f6827709d0f2ab)

- rep builds GraalVM binaries using an automated patched Clojure build:
  [link](https://github.com/eraserhd/rep/blob/1951df780fdd2781644f934dfc36ee394460effb/.circleci/images/primary/build.sh#L1)

    It keeps pre-built jars of clojure and spec
    [here](https://github.com/eraserhd/rep/tree/develop/deps)

- babashka vendors code from Clojure and works around the locking issues manually.
  [This](https://github.com/borkdude/babashka/blob/070220da70c894ad7b282ce2747607c0bee68613/src/babashka/impl/clojure/core/server.clj#L1) is a patched version of `clojure.core.server`.

- revert to using Clojure 1.9.0
