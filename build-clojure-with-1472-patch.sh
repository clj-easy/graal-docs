#!/usr/bin/env bash

# create a clj-1472 patched version that overcomes locking issue so that we can compile graal native-image

set -eou pipefail

get-pom-version() {
  mvn -q \
      -Dexec.executable=echo \
      -Dexec.args='${project.version}' \
      --non-recursive \
      exec:exec
}

set-pom-version() {
    mvn versions:set -DnewVersion="$1"
}

mvn-clean-install() {
   rm -rf target && mvn install -Dmaven.test.skip=true
}

status-line() {
    echo ""
    echo -e "\033[42m \033[30;44m $1 \033[42m \033[0m"
}

rm -rf patch-work
mkdir patch-work
cd patch-work

status-line "cloning and building spec"
git clone git@github.com:clojure/spec.alpha.git
cd spec.alpha
git reset --hard spec.alpha-0.2.176
SPEC_VERSION="$(get-pom-version)-patch1472"
set-pom-version "${SPEC_VERSION}"
mvn-clean-install
cd ..

status-line "cloning, patching and building clojure"
git clone git@github.com:clojure/clojure.git
cd clojure
git reset --hard clojure-1.10.1
curl -L -O https://clojure.atlassian.net/secure/attachment/10782/clj-1472-3.patch
git rebase-patch clj-1472-3.patch
CLOJURE_VERSION="$(get-pom-version)-patch1472"
set-pom-version "${CLOJURE_VERSION}"
mvn-clean-install
cd ..

status-line "rebuilding spec with patched clojure"
cd spec.alpha
mvn versions:set-property -Dproperty=clojure.version -DnewVersion="${CLOJURE_VERSION}"
mvn-clean-install
cd ..

status-line "rebuilding clojure with rebuilt spec"
cd clojure
mvn versions:use-dep-version -Dincludes=org.clojure:spec.alpha \
    -DdepVersion="${SPEC_VERSION}" -DforceVersion=true
mvn-clean-install

echo ""
echo "Installed to local maven repo:"
echo "- org.clojure/clojure ${CLOJURE_VERSION}"
echo "- org.clojure/spec.alpha ${SPEC_VERSION}"
status-line "done"
