# External resources

## Projects

- [adorn](https://github.com/sogaiu/adorn). An exploration of editor micro helpers.
- [alc.enum-repls](https://github.com/sogaiu/alc.enum-repls). Find information about local networked Clojure REPLs, notably port numbers.
- [alc.x-as-tests](https://github.com/sogaiu/alc.x-as-tests). Use a variety of things (e.g. comment block content) as tests.
- [babashka](https://github.com/borkdude/babashka). A Clojure babushka for the grey areas of Bash.
- [brisk](https://github.com/justone/brisk). Freeze and thaw with Nippy at the command line
- [bootleg](https://github.com/retrogradeorbit/bootleg). Simple template processing command line tool to help build static websites.
- [clj-kondo](https://github.com/borkdude/clj-kondo). A linter for Clojure code that sparks joy.
- [cljfmt-graalvm](https://gitlab.com/konrad.mrozek/cljfmt-graalvm/). Clojure formatter using cljfmt built with GraalVM.
- [cljstyle](https://github.com/greglook/cljstyle). A tool for formatting Clojure code
- [cljtree-graalvm](https://github.com/borkdude/cljtree-graalvm). Tree version in Clojure built with GraalVM.
- [clojurl](https://github.com/taylorwood/clojurl). An example Clojure CLI HTTP/S client using GraalVM native image.
- [cotd](https://github.com/tomekw/cotd). Clojure docstring of the day.
- [dad](https://github.com/liquidz/dad). Small configuration management tool for Clojure.
- [deps.clj](https://github.com/borkdude/deps.clj). A port of the `clojure` bash script to Clojure and compiled with GraalVM to a binary.
- [eden](https://github.com/benzap/eden). Embedded and Extensible Scripting Language in Clojure.
- [Google Authenticator](https://github.com/ashwinbhaskar/Google-Authenticator). Compute your Google Authenticator One Time Password.
- [graal-native-image-jni](https://github.com/retrogradeorbit/graal-native-image-jni). Smallest JNI example with GraalVM native-image.
- [jet](https://github.com/borkdude/jet). CLI to transform between JSON, EDN and Transit.
- [optikon](https://github.com/stathissideris/optikon). Command-line wrapper for the powerful vega visualization JS libraries.
- [PGMig](https://github.com/leafclick/pgmig). Standalone PostgreSQL Migration Runner based on Migratus.
- [rep](https://github.com/eraserhd/rep). A single-shot nREPL client designed for shell invocation.
- [spire](https://github.com/epiccastle/spire). A Clojure domain specific language tailored to idempotently orchestrate machines in parallel over SSH.
- [tabl](https://github.com/justone/tabl). Make tables from data in your terminal
- [terminal-todo-mvc](https://github.com/phronmophobic/terminal-todo-mvc). An example terminal todo app (with mouse support!).
- [wernicke](https://github.com/latacora/wernicke). A redaction tool.
- [zprint](https://github.com/kkinnear/zprint). A fast zprint filter.


## Libraries compatible with GraalVM

- [cli-matic](https://github.com/l3nz/cli-matic). (Sub)command line parsing.
- [clj-http-lite](https://github.com/martinklepsch/clj-http-lite). A lite version of clj-http that uses the jre's `HttpURLConnection`.
- [cljstache](https://github.com/fotoetienne/cljstache). {{ mustache }} templates for Clojure[Script].
- [edamame](https://github.com/borkdude/edamame). Configurable EDN/code parser with location metadata.
- [enlive](https://github.com/cgrand/enlive). A selector-based (à la CSS) templating and transformation system for Clojure
- [fipp](https://github.com/brandonbloom/fipp). Fast idiomatic pretty-printe for Clojure.
- [graal.locking](https://github.com/borkdude/graal.locking). Historical workaround for CLJ-1472 with a library, Clojure 1.10.2-alpha1 is now recommended instead.
- [hickory](https://github.com/davidsantiago/hickory). HTML as data.
- [markdown-clj](https://github.com/yogthos/markdown-clj).  Markdown parser in Clojure.
- [lanterna](https://github.com/mabe02/lanterna). A java library for making Terminal User Interfaces.
- [puget](https://github.com/greglook/puget). Canonical Colorizing Clojure Printer
- [rewrite-clj](https://github.com/xsc/rewrite-clj). Rewrite Clojure Code and EDN!
- [selmer](https://github.com/yogthos/Selmer). A fast, Django inspired template system in Clojure.
- [Small Clojure Interpreter](https://github.com/borkdude/sci). Evaluation of Clojure expressions from user input a.k.a `read-string` + `eval` for GraalVM.
- [yaml](https://github.com/owainlewis/yaml). A fast, idiomatic and easy to use Clojure YAML library. Based on Snake YAML. *Note* requires :exclusion and seperate dependency of of snakeyaml: https://github.com/owainlewis/yaml/issues/35

Also see
[BrunoBonacci/graalvm-clojure](https://github.com/BrunoBonacci/graalvm-clojure)
for a list of libraries known to work with GraalVM `native-image`.


## Build tools / wrappers

- [clj.native-image](https://github.com/taylorwood/clj.native-image). Build GraalVM native images with Clojure Deps and CLI tools.
- [setup-graalvm](https://github.com/DeLaGuardo/setup-graalvm). GitHub action to set up GraalVM environment in hosted runners as a replacement for Java.

## Articles

- [Alex Miller, *Inside Clojure - Journal 2019.16*](http://insideclojure.org/2019/04/19/journal/#clojure-1101)
- [Alys Brooks, *Using Graal on a Small-But-Real Clojure Application*](http://www.alysbrooks.com/using-graal-on-a-small-but-real-clojure-application.html)
- [AstRecipes, *Command-line apps with Clojure and GraalVM: 300x better start-up times*](https://www.astrecipes.net/blog/2018/07/20/cmd-line-apps-with-clojure-and-graalvm/)
- [Bruno Bonacci, *An exploration of Clojure libraries that can produce native images under GraalVM*](https://github.com/BrunoBonacci/graalvm-clojure)
- [Dieter Komendera, *Clojure Berlin: ProseMirror Transforms with GraalVM and Clojure*](https://nextjournal.com/kommen/clojure-berlin-prosemirror-transforms-with-graalvm-and-clojure)
- [Jan Stępień, *Native Clojure with GraalVM*](https://www.innoq.com/en/blog/native-clojure-and-graalvm/)
- [Taylor Wood, *Building native Clojure images with GraalVM*](https://blog.taylorwood.io/2018/05/02/graalvm-clojure.html)

## Talks

- [Native Clojure with GraalVM by Jan Stępień](https://www.youtube.com/watch?v=topKYJgv6qA)


## Misc

- [Truffle/Clojure: An AST-Interpreter for Clojure, Master thesis for Thomas Feichtinger](http://ssw.jku.at/Teaching/MasterTheses/Graal/TruffleClojure.pdf) (PDF)
