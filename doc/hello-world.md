# Hello world

This tutorial guides you through the first steps of creating a native binary of a Clojure program using GraalVM.

- [Common Setup](#common-setup)
- [Clojure Deps CLI](#clojure-deps-cli)
- [Leiningen](#leiningen)
- [Compile Scripts From The Wild](#compile-scripts-from-the-wild)

## Common Setup

Download and install [GraalVM](https://github.com/graalvm/graalvm-ce-builds/releases) for your operating system.
There are Java 8 and Java 11 versions.
It doesn't matter which one you pick for this tutorial.

## Clojure Deps CLI

You may be interested in watching @borkdude's [*GraalVM native Clojure: hello world* video](https://youtu.be/G9Xp2zlEmos), it not only walks you through this process but includes many interesting observations and tips.

We assume you have the current [`clojure` CLI](https://clojure.org/guides/getting_started) installed.

1. Create a Clojure Deps CLI project.

    ``` shellsession
    $ mkdir -p hello-world/src/hello_world
    $ cd hello-world
    ```

    Optionally create a `deps.edn`.
    While not required for this hello world app, the current Clojure release contains some important fixes for GraalVM so it is best to select it explictly:

    ``` clojure
    {:deps {org.clojure/clojure {:mvn/version "1.10.3"}}}
    ```

    Paste the following code into a `src/hello_world/main.clj` file:

    ``` clojure
    (ns hello-world.main
      (:gen-class))

    (defn -main [& _args]
      (println "Hello world!"))
    ```

    Run your hello world program using `clojure` to prove to yourself that it works:

    ``` shellsession
    $ clojure -M -m hello-world.main
    Hello world!
    ```

2. Compile project sources to class files

    Create a `classes` folder.
    This is where Clojure compiles source files to `.class` files:

    ```
    $ mkdir classes
    ```

    Then run:

    ```
    $ clojure -M -e "(compile 'hello-world.main)"
    ```

    to compile the main namespace (and transitively everything it requires).

    Verify that the program works when run from the JVM:

    ```
    $ java -cp $(clojure -Spath):classes hello_world.main
    Hello world!
    ```

3. Compile to native

    Create a `compile` script:

    ``` bash
    #!/usr/bin/env bash

    if [ -z "$GRAALVM_HOME" ]; then
        echo 'Please set GRAALVM_HOME'
        exit 1
    fi

    # Ensure Graal native-image program is installed
    "$GRAALVM_HOME/bin/gu" install native-image

    "$GRAALVM_HOME/bin/native-image" \
        -cp "$(clojure -Spath):classes" \
        -H:Name=hello-world \
        -H:+ReportExceptionStackTraces \
        --initialize-at-build-time  \
        --verbose \
        --no-fallback \
        --no-server \
        "-J-Xmx3g" \
        hello_world.main
    ```

    This script requires the `GRAALVM_HOME` environment variable points to your GraalVM home dir.

    Don't forget to make the script executable:

    ``` shellsession
    $ chmod +x compile
    ```

    And then run it:

    ``` shellsession
    $ ./compile
    ```

    This will create `hello-world`, a native image version of hello world program.

5. Run your native image!

    ``` shellsession
    $ ./hello-world
    Hello world!
    ```

That's it.

## Leiningen

Another approach is to build an uberjar with [`leiningen`](https://leiningen.org/) first.

1. Create a lein project.

   ``` shellsession
    $ mkdir -p hello-world/src/hello_world
    $ cd hello-world
    ```

   Create a `project.clj`:

    ``` clojure
    (defproject hello-world "0.1.0-SNAPSHOT"
      ;; the current Clojure version includes fixes for some GraalVM specific issues
      :dependencies [[org.clojure/clojure "1.10.3"]]
      :main hello-world.main
      :aot :all)
    ```

   Paste the following code into a `src/hello_world/main.clj` file:

    ``` clojure
    (ns hello-world.main
      (:gen-class))

    (defn -main [& _args]
      (println "Hello world!"))
    ```

    Run your hello world program using `lein` to prove to yourself that it works:

    ```shellsession
    $ lein run
    Hello world!
    ```

2. Create an uberjar.

    ``` shellsession
    $ lein uberjar
    ```

    Verify that the uberjar works when run from the JVM:

    ``` shellsession
    $ java -jar target/hello-world-0.1.0-SNAPSHOT-standalone.jar
    Hello world!
    ```

3. Compile to native.

    Create a `compile` script:

    ``` bash
    #!/usr/bin/env bash

    if [ -z "$GRAALVM_HOME" ]; then
        echo 'Please set GRAALVM_HOME'
        exit 1
    fi

    # Ensure Graal native-image program is installed
    "$GRAALVM_HOME/bin/gu" install native-image

    "$GRAALVM_HOME/bin/native-image" \
        -jar target/hello-world-0.1.0-SNAPSHOT-standalone.jar \
        -H:Name=hello-world \
        -H:+ReportExceptionStackTraces \
        --initialize-at-build-time  \
        --verbose \
        --no-fallback \
        --no-server \
        "-J-Xmx3g"
    ```

    Note that we use `-jar` instead of `-cp`.

    This script requires the `GRAALVM_HOME` environment variable points to your GraalVM home dir.

    Don't forget to make the script executable:

    ``` shellsession
    $ chmod +x compile
    ```

    And then run it:

    ``` shellsession
    $ ./compile
    ```

    This will create `hello-world`, a native image for your program.

5. Run your native image!

    ``` shellsession
    $ ./hello-world
    Hello world!
    ```

That's it.

## Compile Scripts From the Wild

Our hello world examples are designed to get you started.
Here are some real world compile script examples from the wild:

- [Babashka macOS and Linux compile](https://github.com/babashka/babashka/blob/master/script/compile)
- [Babashka Windows compile](https://github.com/babashka/babashka/blob/master/script/compile.bat)
- [Rewrite-clj v1 cross platform compile via Babashka scripting](https://github.com/clj-commons/rewrite-clj/blob/1259d10413dbe73924164b14a1d2dc33aaee0f31/script/pure_native_test.clj)

And be sure to read our [tips and tricks](/README.adoc) and share back your discoveries!
