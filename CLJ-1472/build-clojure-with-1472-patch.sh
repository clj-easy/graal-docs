#!/usr/bin/env bash

# create a clj-1472 patched version that overcomes locking issue so that we can compile graal native-image

set -eou pipefail

# constants
JIRA_ISSUE="CLJ-1472"

status-line() {
    echo ""
    echo -e "\033[42m \033[30;44m $1 \033[42m \033[0m"
}

error-line() {
    echo ""
    echo -e "\033[30;43m*\033[41m error: $1 \033[43m*\033[0m"
}

check-cmd-prerequisites() {
    local is_error=false
    for cmd in git jet mvn clojure curl sed; do
        if ! [ -x "$(command -v ${cmd})" ]; then
            is_error=true
            >&2 echo "! ${cmd} not found"
        fi
    done

    set +e
    if ! git extras --version &>/dev/null; then
        is_error=true
        >&2 echo "! git-extras not found"
    fi
    set -e

    if [ "$is_error" = true ]; then
        >&2 error-line "prerequisites check failed"
        exit 1
    fi
}

url-for-jira-patch() {
    local jira_issue=$1
    local jira_patch_filename=$2

    local patches
    patches=$(curl -s -L "https://clojure.atlassian.net/rest/api/latest/issue/${jira_issue}" |
                  jet --from json --keywordize |
                  jet --query '[:fields :attachment]' |
                  jet --query '(filter (re-find #jet/lit ".*\\.patch$" :filename))' |
                  jet --query '(map (select-keys [:filename :content]))')

    local patch_url
    patch_url=$(echo "${patches}" |
                    jet --query "(first (filter (= :filename #jet/lit \"${jira_patch_filename}\")))" |
                    jet --query ':content')

    if [ "${patch_url}" == "nil" ]; then
        >&2 error-line "patch file \"${jira_patch_filename}\" not found in jira issue \"${jira_issue}\""
        >&2 echo "- patches found for ${jira_issue}:"
        echo "${patches}" | jet --query '(map :filename)' --pretty >&2
        exit 1
    fi
    # turf leading and trailing quotes
    sed -e 's/^"//' -e 's/"$//' <<<"$patch_url"
}

get-pom-version() {
    # shellcheck disable=SC2016
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

usage() {
    echo "Usage: $(basename "$0") [options...]"
    echo ""
    echo " -h, --help"
    echo ""
    echo " -p, --patch-filename <filename>"
    echo "  name of patch file to download from CLJ-1472"
    echo "  defaults to clj-1472-3.patch"
    echo ""
    echo " -w, --work-dir <dir name>"
    echo "  temporary work directory"
    echo "  defaults to system generated temp dir"
    echo "  NOTE: for safety, this script will only delete what it creates under specified work dir"
}

# defaults for args
ARG_HELP=false
ARG_INVALID=false
ARG_PATCH_FILENAME="clj-1472-3.patch"
ARG_WORK_DIR_SET=false

while [[ $# -gt 0 ]]
do
    ARG="$1"
    case $ARG in
        -h|--help)
            ARG_HELP=true
            shift
            ;;
        -p|--patch-filename)
            ARG_PATCH_FILENAME="$2"
            shift
            shift
            ;;
        -w|--work-dir)
            ARG_WORK_DIR="$2"
            ARG_WORK_DIR_SET=true
            shift
            shift
            ;;
        *)
            ARG_INVALID=true
            shift
            ;;
    esac
done

if [ ${ARG_HELP} == true ]; then
    usage
    exit 0
fi

if [ ${ARG_INVALID} == true ]; then
    error-line "invalid usage"
    echo ""
    usage
    exit 1
fi

if [ ${ARG_WORK_DIR_SET} == false ]; then
    # some versions of osx require -t?
    WORK_DIR=$(mktemp -d -t "clj-patcher")
else
    # add patch-work dir, I am comfortable creating and deleting patch-work
    # under provided dir but not provide work dir itself - too dangerous.
    WORK_DIR="${ARG_WORK_DIR}/patch-work"
    rm -rf "${WORK_DIR}"
    mkdir -p "${WORK_DIR}"
    # a fully qualified path will be turfable work regardless of current working dir
    WORK_DIR=$(cd "${WORK_DIR}";pwd)
fi
trap 'rm -rf ${WORK_DIR}' EXIT

check-cmd-prerequisites

# The clojure build system uses ant which is fussy about what goes into a version
# Converting dashes to underscores seems to do the trick
# Also converting to lowercase to normalize a bit
VERSION_SUFFIX=-patch_$(basename "${ARG_PATCH_FILENAME}" ".patch" |
                            tr - _ |
                            tr '[:upper:]' '[:lower:]')

URL_FOR_PATCH=$(url-for-jira-patch "${JIRA_ISSUE}" "${ARG_PATCH_FILENAME}")

status-line "run variables"
echo "Apply issue ${JIRA_ISSUE} patch ${ARG_PATCH_FILENAME}"
echo "Temporary work dir: ${WORK_DIR}"
cd "${WORK_DIR}"

status-line "cloning and building spec"
git clone https://github.com/clojure/spec.alpha.git
cd spec.alpha
git reset --hard spec.alpha-0.2.176
SPEC_VERSION="$(get-pom-version)${VERSION_SUFFIX}"
set-pom-version "${SPEC_VERSION}"
mvn-clean-install
cd ..

status-line "cloning, patching and building clojure"
git clone https://github.com/clojure/clojure.git
cd clojure
git reset --hard clojure-1.10.1
echo "applying patch: ${URL_FOR_PATCH}"
curl -L -O "${URL_FOR_PATCH}"
git rebase-patch "${ARG_PATCH_FILENAME}"
CLOJURE_VERSION="$(get-pom-version)${VERSION_SUFFIX}"
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
