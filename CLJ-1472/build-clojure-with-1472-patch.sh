#!/usr/bin/env bash

# create a clj-1472 patched version of Clojure that overcomes locking issue so that we can compile GraalVM native-image

set -eou pipefail

# constants
JIRA_ISSUE="CLJ-1472"

status-line() {
    echo ""
    echo -e "\033[42m \033[30;46m $1 \033[42m \033[0m"
}

error-line() {
    echo ""
    echo -e "\033[30;43m*\033[41m error: $1 \033[43m*\033[0m"
}

trap 'error-line "Unexpected error at line $LINENO"' ERR

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

jira-patches() {
    set -eou pipefail

    local jira_issue="$1"
    curl -s -L "https://clojure.atlassian.net/rest/api/latest/issue/${jira_issue}" |
        jet --from json --keywordize |
        jet --query '[:fields :attachment]' |
        jet --query '(filter (re-find #jet/lit ".*\\.patch$" :filename))' |
        jet --query '(map (select-keys [:filename :content]))'
}

jira-patch-url-for-filename() {
    set -eou pipefail

    local jira_patches="$1"
    local jira_patch_filename="$2"

    echo "${jira_patches}" |
        jet --query "(first (filter (= :filename #jet/lit \"${jira_patch_filename}\")))" |
        jet --query ':content' |
        sed -e 's/^"//' -e 's/"$//'
}

jira-print-patch-filenames() {
    local jira_patches="$1"
    echo "${jira_patches}" | jet --query '(map :filename)' --pretty
}

patch-version-string() {
    # version string gets new qualifier that includes sha and a representation of patch file
    # Clojure build system uses ant which has some restrictions on versions, so we can't go
    # all willy nilly.
    set -eou pipefail

    local current_full_version="$1"
    local clojure_sha="$2"
    local patch_filename="$3"

    local version
    local snapshot
    local qualifier
    # regex created by looking at examples here: https://octopus.com/blog/maven-versioning-explained
    if [[ $current_full_version =~ ([.0-9]+)([.-]?[a-zA-Z][a-zA-Z0-9]*)?([.-]'SNAPSHOT')?$ ]]; then
        version="${BASH_REMATCH[1]}"
        qualifier="${BASH_REMATCH[2]}"
        snapshot="${BASH_REMATCH[3]}"
    fi

    local new_qualifier
    new_qualifier="patch_${clojure_sha}_$(basename "${patch_filename}" ".patch" |
                             tr - _ |
                             tr '[:upper:]' '[:lower:]')"

    if [ -n "${qualifier}" ]; then
        new_qualifier="${qualifier}_${new_qualifier}"
    else
        new_qualifier="-${new_qualifier}"
    fi

    echo "${version}${new_qualifier}${snapshot}"
}

maven() {
    # shellcheck disable=SC2068
    mvn --batch-mode $@
}

get-pom-version() {
    set -eou pipefail
    # shellcheck disable=SC2016
    maven -q \
          -Dexec.executable=echo \
          -Dexec.args='${project.version}' \
          --non-recursive \
          exec:exec
}

set-pom-version() {
    maven versions:set -DnewVersion="$1"
}

set-pom-property() {
    local name=$1
    local value=$2
    maven versions:set-property -Dproperty="${name}" -DnewVersion="${value}"
}

get-pom-dep-version() {
    set -eou pipefail

    # must be an easier way to do this
    local group_id=$1
    local artifact_id=$2

    local temp_file;temp_file=$(mktemp -t "clj-patcher-dep-version.XXXXXXXXXX")
    maven dependency:list -DincludeArtifactIds="${artifact_id}" \
        -DoutputFile="${temp_file}" -DexcludeTransitive=true -q
    local version;version=$(grep "${group_id}:${artifact_id}" "${temp_file}" | cut -d : -f 4)

    rm "${temp_file}"
    echo "${version}"
}

set-pom-dep-version() {
    local group_id=$1
    local artifact_id=$2
    local version=$3

    maven versions:use-dep-version -Dincludes="${group_id}:${artifact_id}" \
        -DdepVersion="${version}" -DforceVersion=true
}

mvn-clean-install() {
   rm -rf target && maven install -Dmaven.test.skip=true
}

usage() {
    echo "Usage: $(basename "$0") [options...]"
    echo ""
    echo " -h, --help"
    echo ""
    echo " -p, --patch-filename <filename>"
    echo "  name of patch file to download from CLJ-1472"
    echo "  defaults to the currently recommended clj-1472-5.patch"
    echo ""
    echo " -c, --clojure-commit <commit>"
    echo "  choose clojure commit to patch, can be sha or tag"
    echo "  specify HEAD for most recent commit"
    echo "  defaults to \"clojure-10.0.1\" tag"
    echo ""
    echo " -w, --work-dir <dir name>"
    echo "  temporary work directory"
    echo "  defaults to system generated temp dir"
    echo "  NOTE: for safety, this script will only delete what it creates under specified work dir"
}

# defaults for args
ARG_HELP=false
ARG_INVALID=false
ARG_PATCH_FILENAME="clj-1472-5.patch"
ARG_WORK_DIR_SET=false
ARG_CLOJURE_COMMIT="clojure-1.10.1"

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
        -c|--clojure-commit)
            ARG_CLOJURE_COMMIT="$2"
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
    WORK_DIR=$(mktemp -d -t "clj-patcher.XXXXXXXXXX")
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

JIRA_PATCHES=$(jira-patches "${JIRA_ISSUE}")
URL_FOR_PATCH=$(jira-patch-url-for-filename "${JIRA_PATCHES}" "${ARG_PATCH_FILENAME}")
if [ "${URL_FOR_PATCH}" == "nil" ]; then
    error-line "patch file \"${ARG_PATCH_FILENAME}\" not found in jira issue \"${JIRA_ISSUE}\""
    echo "- patches found for ${JIRA_ISSUE}:"
    jira-print-patch-filenames "${JIRA_PATCHES}"
    exit 1
fi

status-line "ok, let's do it"
echo "Apply issue ${JIRA_ISSUE} patch ${ARG_PATCH_FILENAME}"
echo "Temporary work dir: ${WORK_DIR}"
echo "Patch url: ${URL_FOR_PATCH}"
cd "${WORK_DIR}"

#
# clojure clone and patch
#

status-line "clojure - cloning"
git clone https://github.com/clojure/clojure.git
cd clojure

status-line "clojure - resetting to: ${ARG_CLOJURE_COMMIT}"
git reset --hard "${ARG_CLOJURE_COMMIT}"

status-line "clojure - finding versions"
CLOJURE_SHORT_SHA=$(git rev-parse --short=8 HEAD)
CLOJURE_SPEC_VERSION=$(get-pom-dep-version "org.clojure" "spec.alpha")
SPEC_ALPHA_COMMIT="spec.alpha-${CLOJURE_SPEC_VERSION}"
echo "spec alpha commit: ${SPEC_ALPHA_COMMIT}"
# The clojure build system uses ant which is fussy about what goes into a version
# Converting dashes to underscores seems to do the trick
# Also converting to lowercase to normalize a bit
CLOJURE_VERSION="$(patch-version-string "$(get-pom-version)" "${CLOJURE_SHORT_SHA}" "${ARG_PATCH_FILENAME}")"
echo "clojure patch version: ${CLOJURE_VERSION}"
SPEC_VERSION="$(patch-version-string "${CLOJURE_SPEC_VERSION}" "${CLOJURE_SHORT_SHA}" "${ARG_PATCH_FILENAME}")"
echo "spec patch version: ${SPEC_VERSION}"

status-line "clojure - patching with: ${ARG_PATCH_FILENAME}"
curl -L -O "${URL_FOR_PATCH}"
git rebase-patch "${ARG_PATCH_FILENAME}"

status-line "clojure - setting version: ${CLOJURE_VERSION}"
set-pom-version "${CLOJURE_VERSION}"
cd ..

#
# spec build
#
status-line "spec - cloning"
git clone https://github.com/clojure/spec.alpha.git
cd spec.alpha

status-line "spec - resetting to: ${SPEC_ALPHA_COMMIT}"
git reset --hard "${SPEC_ALPHA_COMMIT}"

status-line "spec - setting version: ${SPEC_VERSION}"
set-pom-version "${SPEC_VERSION}"

status-line "spec - building"
mvn-clean-install
cd ..

#
# clojure build
#

status-line "clojure - building"
cd clojure
mvn-clean-install
cd ..

#
# spec rebuild
#

status-line "spec - rebuilding with patched clojure"
cd spec.alpha
set-pom-property "clojure.version" "${CLOJURE_VERSION}"
mvn-clean-install
cd ..

#
# cloure rebuild
#
status-line "clojure - rebuilding with rebuilt spec"
cd clojure
set-pom-dep-version "org.clojure" "spec.alpha" "${SPEC_VERSION}"
mvn-clean-install

echo ""
echo "Installed to local maven repo:"
echo "- org.clojure/clojure ${CLOJURE_VERSION}"
echo "- org.clojure/spec.alpha ${SPEC_VERSION}"
status-line "done"
