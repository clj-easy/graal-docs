# Steps to Reproduce CLJ-1472

Instructions to reproduce the `unbalanced monitors` error when compiling Clojure source that makes use of locking with GraalVM's `native-image`.

See [CLJ-1472](https://clojure.atlassian.net/browse/CLJ-1472).

These steps were verified on macOS 10.15.3 and Linux Mint 19.3. GraalVM was installed via [SDKMAN!](https://sdkman.io/).
Clojure version used was 1.10.1.510.

## Setup

1. This error occurs for all know versions of [GraalVM](https://www.graalvm.org/docs/getting-started/), but to keep us all on the same page, **verify you are running GraalVM v19.3.1 on JDK8**
     ```
     java -version
     ```
     Should return something like:
     ```
     openjdk version "1.8.0_242"
     OpenJDK Runtime Environment (build 1.8.0_242-b06)
     OpenJDK 64-Bit GraalVM CE 19.3.1 (build 25.242-b06-jvmci-19.3-b07, mixed mode)
     ```
     Note: A thorough tester will repeat all tests for GraalVM 19.3.1 on **JDK11**.
2. Ensure GraalVM's `native-image` is installed via GraalVM's Component Updater:
     ```
     gu install native-image
     ```
2. Verify you are running Clojure v1.10.1
     ```
     clojure -Sdescribe
     ```

## Witness the Issue for Clojure 1.10.1

1. From a new empty directory
2. Create `core.clj` under `src/spec_test/`:
    ```Clojure
    (ns spec-test.core
    (:gen-class)
    (:require [clojure.spec.alpha :as s]))

    (s/def ::g int?)

    (defn -main [& _args]
      (println *clojure-version*)
      (println (s/valid? ::g 1)))
    ```
3. AOT compile clojure source:
    ```
    mkdir classes
    clojure -e "(compile 'spec-test.core)"
    ```
4. Compile with GraalVM:
    ```
    native-image \
      -H:Name=spec-test \
      --no-server \
      --no-fallback \
      -cp $(clojure -Spath):classes \
      --initialize-at-build-time \
      --report-unsupported-elements-at-runtime \
      -H:+ReportExceptionStackTraces \
      spec_test.core
    ```
5. GraalVM `native-image` will fail with output like:
```
[spec-test:18154]    classlist:   3,720.13 ms
[spec-test:18154]        (cap):   1,851.05 ms
[spec-test:18154]        setup:   3,122.64 ms
[spec-test:18154]   (typeflow):  15,242.32 ms
[spec-test:18154]    (objects):   6,715.40 ms
[spec-test:18154]   (features):     609.79 ms
[spec-test:18154]     analysis:  23,204.47 ms
Error: unbalanced monitors: mismatch at monitorexit, 3|LoadField#lockee__5436__auto__ != 96|LoadField#lockee__5436__auto__
Detailed message:
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
	at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
	at clojure.lang.AFn.run(AFn.java:22)
	at java.lang.Thread.run(Thread.java:748)
	at com.oracle.svm.core.thread.JavaThreads.threadStartRoutine(JavaThreads.java:497)
	at com.oracle.svm.core.posix.thread.PosixJavaThreads.pthreadStartRoutine(PosixJavaThreads.java:193)
	at com.oracle.svm.core.code.IsolateEnterStub.PosixJavaThreads_pthreadStartRoutine_e1f4a8c0039f8337338252cd8734f63a79b5e3df(generated:0)

com.oracle.svm.core.util.UserError$UserException: unbalanced monitors: mismatch at monitorexit, 3|LoadField#lockee__5436__auto__ != 96|LoadField#lockee__5436__auto__
Detailed message:
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
	at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
	at clojure.lang.AFn.run(AFn.java:22)
	at java.lang.Thread.run(Thread.java:748)
	at com.oracle.svm.core.thread.JavaThreads.threadStartRoutine(JavaThreads.java:497)
	at com.oracle.svm.core.posix.thread.PosixJavaThreads.pthreadStartRoutine(PosixJavaThreads.java:193)
	at com.oracle.svm.core.code.IsolateEnterStub.PosixJavaThreads_pthreadStartRoutine_e1f4a8c0039f8337338252cd8734f63a79b5e3df(generated:0)

	at com.oracle.svm.core.util.UserError.abort(UserError.java:75)
	at com.oracle.svm.hosted.FallbackFeature.reportAsFallback(FallbackFeature.java:221)
	at com.oracle.svm.hosted.NativeImageGenerator.runPointsToAnalysis(NativeImageGenerator.java:736)
	at com.oracle.svm.hosted.NativeImageGenerator.doRun(NativeImageGenerator.java:530)
	at com.oracle.svm.hosted.NativeImageGenerator.lambda$run$0(NativeImageGenerator.java:445)
	at java.util.concurrent.ForkJoinTask$AdaptedRunnableAction.exec(ForkJoinTask.java:1386)
	at java.util.concurrent.ForkJoinTask.doExec(ForkJoinTask.java:289)
	at java.util.concurrent.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1056)
	at java.util.concurrent.ForkJoinPool.runWorker(ForkJoinPool.java:1692)
	at java.util.concurrent.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:157)
Caused by: com.oracle.graal.pointsto.constraints.UnsupportedFeatureException: unbalanced monitors: mismatch at monitorexit, 3|LoadField#lockee__5436__auto__ != 96|LoadField#lockee__5436__auto__
Detailed message:
Call path from entry point to clojure.spec.gen.alpha$dynaload$fn__2628.invoke():
	at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:21)
	at clojure.lang.AFn.run(AFn.java:22)
	at java.lang.Thread.run(Thread.java:748)
	at com.oracle.svm.core.thread.JavaThreads.threadStartRoutine(JavaThreads.java:497)
	at com.oracle.svm.core.posix.thread.PosixJavaThreads.pthreadStartRoutine(PosixJavaThreads.java:193)
	at com.oracle.svm.core.code.IsolateEnterStub.PosixJavaThreads_pthreadStartRoutine_e1f4a8c0039f8337338252cd8734f63a79b5e3df(generated:0)

	at com.oracle.graal.pointsto.constraints.UnsupportedFeatures.report(UnsupportedFeatures.java:126)
	at com.oracle.svm.hosted.NativeImageGenerator.runPointsToAnalysis(NativeImageGenerator.java:733)
	... 7 more
Caused by: org.graalvm.compiler.code.SourceStackTraceBailoutException$1: unbalanced monitors: mismatch at monitorexit, 3|LoadField#lockee__5436__auto__ != 96|LoadField#lockee__5436__auto__
	at clojure.spec.gen.alpha$dynaload$fn__2628.invoke(alpha.clj:22)
Caused by: org.graalvm.compiler.core.common.PermanentBailoutException: unbalanced monitors: mismatch at monitorexit, 3|LoadField#lockee__5436__auto__ != 96|LoadField#lockee__5436__auto__
	at org.graalvm.compiler.java.BytecodeParser.bailout(BytecodeParser.java:3800)
	at org.graalvm.compiler.java.BytecodeParser.genMonitorExit(BytecodeParser.java:2711)
	at org.graalvm.compiler.java.BytecodeParser.processBytecode(BytecodeParser.java:5181)
	at org.graalvm.compiler.java.BytecodeParser.iterateBytecodesForBlock(BytecodeParser.java:3286)
	at org.graalvm.compiler.java.BytecodeParser.processBlock(BytecodeParser.java:3093)
	at org.graalvm.compiler.java.BytecodeParser.build(BytecodeParser.java:977)
	at org.graalvm.compiler.java.BytecodeParser.buildRootMethod(BytecodeParser.java:871)
	at org.graalvm.compiler.java.GraphBuilderPhase$Instance.run(GraphBuilderPhase.java:84)
	at org.graalvm.compiler.phases.Phase.run(Phase.java:49)
	at org.graalvm.compiler.phases.BasePhase.apply(BasePhase.java:197)
	at org.graalvm.compiler.phases.Phase.apply(Phase.java:42)
	at org.graalvm.compiler.phases.Phase.apply(Phase.java:38)
	at com.oracle.graal.pointsto.flow.MethodTypeFlowBuilder.parse(MethodTypeFlowBuilder.java:221)
	at com.oracle.graal.pointsto.flow.MethodTypeFlowBuilder.apply(MethodTypeFlowBuilder.java:340)
	at com.oracle.graal.pointsto.flow.MethodTypeFlow.doParse(MethodTypeFlow.java:310)
	at com.oracle.graal.pointsto.flow.MethodTypeFlow.ensureParsed(MethodTypeFlow.java:300)
	at com.oracle.graal.pointsto.flow.MethodTypeFlow.addContext(MethodTypeFlow.java:107)
	at com.oracle.graal.pointsto.flow.SpecialInvokeTypeFlow.onObservedUpdate(InvokeTypeFlow.java:421)
	at com.oracle.graal.pointsto.flow.TypeFlow.notifyObservers(TypeFlow.java:343)
	at com.oracle.graal.pointsto.flow.TypeFlow.update(TypeFlow.java:385)
	at com.oracle.graal.pointsto.flow.SourceTypeFlowBase.update(SourceTypeFlowBase.java:121)
	at com.oracle.graal.pointsto.BigBang$2.run(BigBang.java:511)
	at com.oracle.graal.pointsto.util.CompletionExecutor.lambda$execute$0(CompletionExecutor.java:171)
	at java.util.concurrent.ForkJoinTask$RunnableExecuteAction.exec(ForkJoinTask.java:1402)
	at java.util.concurrent.ForkJoinTask.doExec(ForkJoinTask.java:289)
	at java.util.concurrent.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1056)
	at java.util.concurrent.ForkJoinPool.runWorker(ForkJoinPool.java:1692)
	at java.util.concurrent.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:157)
Error: Image build request failed with exit status 1
```

## Witness Success for Clojure 1.9.0

1. From a new empty directory
2. Create a `deps.edn` file:
    ```
    {:deps {org.clojure/clojure {:mvn/version "1.9.0"}}}
    ```
3. Follow steps 2 through 4 inclusive from "Witness the Issue for Clojure 1.10.1".
4. You should see output like the following from `native-image`:
```
[spec-test:13799]    classlist:   2,870.04 ms,  1.68 GB
[spec-test:13799]        (cap):   1,869.00 ms,  1.68 GB
[spec-test:13799]        setup:   3,061.62 ms,  1.68 GB
[spec-test:13799]   (typeflow):  12,340.96 ms,  2.81 GB
[spec-test:13799]    (objects):   7,523.11 ms,  2.81 GB
[spec-test:13799]   (features):     490.74 ms,  2.81 GB
[spec-test:13799]     analysis:  20,955.78 ms,  2.81 GB
[spec-test:13799]     (clinit):     380.87 ms,  2.81 GB
[spec-test:13799]     universe:     979.86 ms,  2.81 GB
[spec-test:13799]      (parse):   1,656.69 ms,  2.85 GB
[spec-test:13799]     (inline):   1,770.50 ms,  3.12 GB
[spec-test:13799]    (compile):  12,297.82 ms,  3.76 GB
[spec-test:13799]      compile:  16,672.40 ms,  3.76 GB
[spec-test:13799]        image:   2,297.69 ms,  3.79 GB
[spec-test:13799]        write:     676.13 ms,  3.79 GB
[spec-test:13799]      [total]:  48,045.29 ms,  3.79 GB
```
5. And you should be able to run the created native image:
    ```
    ./spec-test
    ```
   Should output:
   ```
   {:major 1, :minor 9, :incremental 0, :qualifier nil}
   true
   ```
