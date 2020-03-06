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

This is a team effort. We heartily welcome, and greatly appreciate, tips, tricks, corrections and improvements from you.
Much thanks to all who have contributed.

The current curators of this repository are: [@borkdude](https://github.com/borkdude) and [@lread](https://github.com/lread).

## [Hello world](doc/hello-world.md)

## Tips and tricks

### Reflection

Make sure you put `(set! *warn-on-reflection* true)` at the top of every namespace in your project to get rid of all reflection.
There is a patch to make `clojure.stacktrace` work with GraalVM in [JIRA CLJ-2502](https://clojure.atlassian.net/browse/CLJ-2502),
which is currently available in the [Clojure 1.10.2 test release](https://clojure.org/community/devchangelog#_release_1_10_2).

To let Graal config the reflector for an array of Java objects, e.g. `Statement[]` you need to provide a rule
for `[Lfully.qualified.class` (e.g. `"[Ljava.sql.Statement"`).

### Report what is being analyzed

When you add GraalVM's `native-image`
[`-H:+PrintAnalysisCallTree`](https://github.com/oracle/graal/blob/master/substratevm/REPORTS.md#call-tree)
option, under `./reports` you will learn what packages, classes and methods are
being analyzed. Note that this option will likely slow down
compilation so it's better to turn it off in production builds.

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

:tada: Update: The recommended patch from [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472)
resolves this issue. This patch is included in the [Clojure 1.10.2 test release](https://clojure.org/community/devchangelog#_release_1_10_2).
We strongly encourage you to try it out with your projects and
[report back any issues to the Clojure core team](https://clojure.org/community/contributing#_reporting_problems_and_requesting_enhancements).

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

### Initialization

Unlike the early days the current `native-image` deffers the initialization of most classes to runtime.
For Clojure programs it is often actually feasible (unlike in a typical Java program) to change it back
via `--initialize-at-build-time` to achieve yet faster startup time. You can still defer some classes
to runtime initialization using `--initialize-at-run-time`.

### Static linking vs DNS lookup

If you happen to need a DNS lookup in your program you need to avoid statically linked images
(at least on Linux). If you are builing a minimal docker image it is sufficient
to add the linked libraries (like `libnss*`) to the resulting image.  But be sure that those
libraries have the same version as the ones used in the linking phase.

One way to achieve that is to compile  _within_ the docker image then scraping the intermediate files
using the `FROM scratch` directive and `COPY` the executable and shared libraries linked to it
into the target image.

See https://github.com/oracle/graal/issues/571

## JDK11 and clojure.lang.Reflector

JDK11 is supported since GraalVM 19.3.0. GraalVM can get confused about a
[conditional piece of
code](https://github.com/clojure/clojure/blob/653b8465845a78ef7543e0a250078eea2d56b659/src/jvm/clojure/lang/Reflector.java#L29-L57)
in `clojure.lang.Reflector` which dispatches on Java 8 or a later Java version.

Compiling your clojure code with JDK11 native image and then running it will result in the following exception being thrown apon first use of reflection:

```
Exception in thread "main" com.oracle.svm.core.jdk.UnsupportedFeatureError: Invoke with MethodHandle argument could not be reduced to at most a single call or single field access. The method handle must be a compile time constant, e.g., be loaded from a `static final` field. Method that contains the method handle invocation: java.lang.invoke.Invokers$Holder.invoke_MT(Object, Object, Object, Object)
    at com.oracle.svm.core.util.VMError.unsupportedFeature(VMError.java:101)
    at clojure.lang.Reflector.canAccess(Reflector.java:49)
    ...
```

Workarounds:

- Use a Java 8 version of GraalVM.
- Use the `--report-unsupported-elements-at-runtime` option.
- Patch `clojure.lang.Reflector` on the classpath with the conditional logic
  swapped out for non-conditional code which works on Java 11 (but not on
  Java 8). The patch can be found [here](resources/Reflector.java).
- If you require your project to support native image compilation on both Java 8
  and Java 11 versions of GraalVM then use the patch found [here](resources/Reflector2.java).
  This version does not respect any Java 11 module access rules and improper reflection
  access by your code may fail. The file will need to be renamed to `Reflector.java`.

## Interfacing with native libraries

For interfacing with native libraries you can use JNI. An example of a native
Clojure program calling a Rust library is documented
[here](https://github.com/borkdude/clojure-rust-graalvm). [Spire](https://github.com/borkdude/clojure-rust-graalvm)
is a real life project that combines GraalVM-compiled Clojure and C in a native
binary.

To interface with C code using JNI the following steps are taken:

- A java file is written defining a class. This class contains `public static native` methods
  defining the C functions you would like, their arguments and the return types. An example is
  [here](https://github.com/epiccastle/spire/blob/master/src/c/SpireUtils.java)
- A C header file with a `.h` extension is generated from this java file:
  - Java 8 uses a special tool `javah` which is called on the _class file_. You will need
    to first create the class file with `javac` and then generate the header file from that
    with `javah -o Library.h -cp directory_containing_class_file Library.class`
  - Java 11 bundled this tool into `javac`. You will javac on the `.java` _source file_ and
    specify a directory to store the header file in like
    `javac -h destination_dir Library.java`
- A C implementation file is now written with function definitions that match the prototypes
  created in the `.h` file. You will need to `#include` your generated header file. An example is
  [here](https://github.com/epiccastle/spire/blob/master/src/c/SpireUtils.c)
- The C code is compiled into a shared library as follows (specifying the correct path to the graal home instead of $GRAALVM):
  - On linux, the compilation will take the form `cc -I$GRAALVM/include -I$GRAALVM/include/linux -shared Library.c -o liblibrary.so -fPIC`
  - On MacOS, the compilation will take the form `cc -I$GRAALVM/Contents/Home/include -I$GRAALVM/Contents/Home/include/darwin -dynamiclib -undefined suppress -flat_namespace Library.c -o liblibrary.dylib -fPIC`
- Once the library is generated you can load it at clojure runtime with
  `(clojure.lang.RT/loadLibrary "library")`
- The JVM will need to be able to find the library on the standard library path. This can be
  set via `LD_LIBRARY_PATH` environment variable or via the `ld` linker config
  file (`/etc/ld.so.conf` on linux). Alternately you can set the library path by passing
  `-Djava.library.path="my_lib_dir"` to the java command line or by setting it at
  runtime with `(System/setProperty "java.library.path" "my_lib_dir")`
- Functions may be called via standard Java interop in clojure via the interface specified
  in your `Library.java` file: `(Library/method args)`

## JNI API bugs

JNI contains a suite of tools for transfering datatypes between Java and C. You can read
about this API [here for Java 8](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html)
and [here for Java 11](https://docs.oracle.com/en/java/javase/11/docs/specs/jni/functions.html).
There are a some bugs ([example](https://github.com/oracle/graal/issues/2152)) in the GraalVM
implementations of some of these functions in all versions up to and including GraalVM 20.0.0.
Some known bugs have been fixed in GraalVM 20.1.0-dev. If you encounter bugs with these API
calls try the latests development versions of GraalVM. If bugs persist please file them with
the Graal project.

## Startup performance on macOS

@borkdude noticed [slower startup times for babashka on macOS when using GraalVM v20](https://github.com/oracle/graal/issues/2136). He elaborated in the @graalvm channel on Clojurians Slack:

> The issue only happens with specific usages of certain classes that are somehow related to security, urls and whatnot. So not all projects will hit this issue.

> Maybe it's also related to enabling the SSL stuff. Likely, but I haven't tested that hypothesis.

The Graal team closed the issue with the following absolutely reasonable rationales:

- > I don't think we can do much on this issue. The problem is the inefficiency of the Apple dynamic linker/loader.
- > Yes, startup time is important, but correctness can of course never be compromised.
You are correct that a more precise static analysis could detect that, but our current context insensitive analysis it too limited.

Apple may fix this issue in macOS someday, who knows? If you:

- have measured a slowdown in startup time of your `native-iamge` produced app after moving to Graal v20
- want to restore startup app to what it was on macOS prior v20 of Graal
- are comfortable with a "caveat emptor" hack from the Graal team

then you may want to try incorporating [this Java code](https://github.com/oracle/graal/issues/2136#issuecomment-595688524)
with [@borkdude's tweaks](https://github.com/oracle/graal/issues/2136#issuecomment-595814343) into your project.

Here's how [@borkdude applied the fix to babashka](https://github.com/borkdude/babashka/commit/5723206ca2949a8e6443cdc38f8748159bcdce91).

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
