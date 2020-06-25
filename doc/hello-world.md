# Hello world

This tutorial guides you through the first steps of creating a native binary using GraalVM. It assumes you have the [`clojure` CLI](https://clojure.org/guides/getting_started) installed.

1. Download [GraalVM](https://github.com/oracle/graal/releases).

2. Create a project

    ``` shellsession
    $ mkdir -p hello-world/src/hello_world
    $ cd hello-world
    ```

    In `src/hello_world/core.clj` put the following code:

    ``` clojure
    (ns hello-world.core
      (:gen-class))

    (defn -main [& _args]
      (println "Hello world!"))
    ```

3. Compile project sources to class files.

    Create a `classes` folder which will contain `.class` files:

    ```
    $ mkdir classes
    ```

    Then run:

    ```
    $ clojure -e "(compile 'hello-world.core)"
    ```

    to compile the main namespace (and transitively everything it requires).

    Verify that the program works on the JVM:

    ```
    $ java -cp $(clojure -Spath):classes hello_world.core
    Hello world!
    ```

4. Compile native.

    Create a `compile` script:

    ``` bash
    #!/usr/bin/env bash

    if [ -z "$NATIVE_IMAGE" ]; then
        echo 'Please set $NATIVE_IMAGE'
        exit 1
    fi

    $NATIVE_IMAGE \
        -cp $(clojure -Spath):classes \
        -H:Name=hello-world \
        -H:+ReportExceptionStackTraces \
        --initialize-at-build-time  \
        --verbose \
        --no-fallback \
        --no-server \
        "-J-Xmx3g" \
        hello_world.core
    ```

    This script requires that you set the `NATIVE_IMAGE` environment variable to the GraalVM `native-image` command, e.g.:

    ``` shellsession
    export NATIVE_IMAGE=/Users/borkdude/Downloads/graalvm-ce-19.2.1/Contents/Home/bin/native-image
    ```

    Don't forget to make the script executable:

    ``` shellsession
    $ chmod +x compile
    ```

    And then compile:

    ``` shellsession
    $ ./compile
    ```

5. Run!

    ``` shellsession
    $ ./hello-world
    Hello world!
    ```

That's it.

## Leiningen

One other approach is to build an uberjar with [`leiningen`](https://leiningen.org/) first. We assume you have completed the previous tutorial.

1. Create a `project.clj`:

    ``` clojure
    (defproject hello-world "0.1.0-SNAPSHOT"
      ;; clojure version "1.10.2-alpha1" includes fixes for some graalvm specific issues
      :dependencies [[org.clojure/clojure "1.10.2-alpha1"]]
      :main hello-world.core
      :aot :all)
    ```

2. Create uberjar.

    ``` shellsession
    $ lein uberjar
    ```

    Verify that the program works on the JVM:

    ``` shellsession
    $ java -jar target/hello-world-0.1.0-SNAPSHOT-standalone.jar
    Hello world!
    ```

3. Compile to native.

    Create a `compile` script:

    ``` bash
    #!/usr/bin/env bash

    if [ -z "$NATIVE_IMAGE" ]; then
        echo 'Please set $NATIVE_IMAGE'
        exit 1
    fi

    $NATIVE_IMAGE \
        -jar target/hello-world-0.1.0-SNAPSHOT-standalone.jar \
        -H:Name=hello-world \
        -H:+ReportExceptionStackTraces \
        --initialize-at-build-time  \
        --verbose \
        --no-fallback \
        --no-server \
        "-J-Xmx3g"
    ```

    Note that we now use `-jar` instead of `-cp`.

    Run `./compile`.

4. Run!

    ``` shellsession
    $ ./hello-world
    Hello world!
    ```
