#!/bin/bash

# This script runs the Checker Framework's whole-program inference on each of a list of projects.
# To create a list of projects, see run-queries.sh or create one by hand.

### Usage

# - Clone the run-dljc repository containing this script on the experimental
#   machine.
# - Make a file containing a list of git repositories and hashes. Each line of
#   the file should contain one repository and one hash, and may optionally
#   contain a third repository (see the -i argument description below).
# - Ensure that your JAVA8_HOME variable points to a Java 8 JDK
# - Ensure that your JAVA11_HOME variable points to a Java 11 JDK
# - Ensure that your CHECKERFRAMEWORK variable points to a built copy of the Checker Framework
# - Other dependencies: perl, python2.7 (for dljc), awk, git, mvn, gradle
# - Run the script. There is an example invocation in
#   no-literal-securerandom-exact-dljc-cmd.sh
#
# The meaning of each required argument is:
#
# -o outdir : run the experiment in the ./outdir directory, and place the
#             results in the ./outdir-results directory. Both will be created
#             if they do not exist.
#
# -i infile : read the list of repositories to use from the file $infile. Each
#             line should contain the (https) url of the git repository on
#             GitHub and the commit hash to use, separated by whitespace.
#             Repositories must be of the form:
#             https://github.com/username/repository - the script is reliant
#             on the number of slashes, so excluding https:// is an error.
#             
#             If the repository's owner is the user specified by the -u flag,
#             then each line owned by that user must be followed by the
#             original github repository.
#
# -c checkers : a comma-separated list of typecheckers to run
#
# The meaning of each optional argument is:
#
# -l lib : a colon-separated list of jar files which should be added to the
#          java classpath when doing typechecking. Use this for the dependencies
#          of any custom typecheckers.
#
# -q quals : a colon-separated list of the jar files containing annotations used
#            by custom checkers
#
# -s stubs : a colon-separated list of stub files
#
# -u user : the GitHub user to consider the "owner" for repositories that have
#           been forked and modified. These repositories must have a third entry
#           in the infile indicating their origin. Default is "kelloggm".
#
# -t timeout : the timeout to use, in seconds
#

while getopts "c:l:s:o:i:q:u:t:" opt; do
  case $opt in
    c) CHECKERS="$OPTARG"
       ;;
    l) CHECKER_LIB="$OPTARG"
       ;;
    q) QUALS="$OPTARG"
       ;;
    s) STUBS="$OPTARG"
       ;;
    o) OUTDIR="$OPTARG"
       ;;
    i) INLIST="$OPTARG"
       ;;
    u) USER="$OPTARG"
       ;;
    t) TOUT="$OPTARG"
       ;;        
    \?) echo "Invalid option -$OPTARG" >&2
       ;;
  esac
done

# check required arguments and environment variables:

if [ "x${JAVA8_HOME}" = "x" ]; then
    echo "JAVA8_HOME must be set to a Java 8 JDK for this script to succeed"
    exit 1
fi

if [ ! -d "${JAVA8_HOME}" ]; then
    echo "JAVA8_HOME is set to a non-existant directory. Check that ${JAVA8_HOME} exists."
    exit 1
fi

if [ "x${JAVA11_HOME}" = "x" ]; then
    echo "JAVA11_HOME must be set to a Java 11 JDK for this script to succeed"
    exit 1
fi

if [ ! -d "${JAVA11_HOME}" ]; then
    echo "JAVA11_HOME is set to a non-existant directory. Check that ${JAVA11_HOME} exists."
    exit 1
fi

if [ "x${CHECKERFRAMEWORK}" = "x" ]; then
    echo "CHECKERFRAMEWORK is not set; it must be set to a locally-built Checker Framework. Please clone and build github.com/typetools/checker-framework"
    exit 2
fi

if [ ! -d "${CHECKERFRAMEWORK}" ]; then
    echo "CHECKERFRAMEWORK is set to a non-existant directory. Check that ${CHECKERFRAMEWORK} exists."
    exit 2
fi

if [ "x${CHECKERS}" = "x" ]; then
    echo "you must specify at least one checker using the -c argument"
    exit 2
fi

if [ "x${OUTDIR}" = "x" ]; then
    echo "you must specify an output directory using the -o argument"
    exit 3
fi

if [ "x${INLIST}" = "x" ]; then
    echo "you must specify an input file using the -i argument"
    exit 4
fi

if [ "x${USER}" = "x" ]; then
    USER=kelloggm
fi

### Script

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# clone\update DLJC
if [ ! -d "${SCRIPTDIR}/../do-like-javac" ]; then
    pushd "${SCRIPTDIR}/.." || exit 5
    git clone https://github.com/kelloggm/do-like-javac
    popd || exit 5
else
    pushd "${SCRIPTDIR}/../do-like-javac" || exit 5
    git pull
    popd || exit 5 
fi

export DLJC="${SCRIPTDIR}/../do-like-javac/dljc"
    
export PATH="${JAVA_HOME}/bin:${PATH}"

mkdir -p "${OUTDIR}"
mkdir -p "${OUTDIR}-results"

pushd "${OUTDIR}" || exit 5

while IFS='' read -r line || [ "$line" ]
do    
    REPOHASH=${line}

    REPO=$(echo "${REPOHASH}" | awk '{print $1}')
    HASH=$(echo "${REPOHASH}" | awk '{print $2}')

    REPO_NAME=$(echo "${REPO}" | cut -d / -f 5)
    REPO_NAME_HASH="${REPO_NAME}-${HASH}"

    # Use repo name and hash, but not e.g. owner because we want
    # repos that are different but have the same name to be treated
    # as different repos, but forks with the same content to be skipped
    # TODO: consider just using hash, to skip hard forks?
    mkdir -p "${REPO_NAME_HASH}"

    pushd "${REPO_NAME_HASH}" || exit 5
    
    if [ ! -d "${REPO_NAME}" ]; then
        # this environment variable prevents git from prompting for
	# username/password if the repository no longer exists
        GIT_TERMINAL_PROMPT=0 git clone "${REPO}"
    else
        rm -rf "${REPO_NAME}/dljc-out"
    fi

    # if the above clone command failed for whatever reason, create an
    # empty directory so that the rest of the commands fail gracefully
    # without messing with the directory structure
    mkdir -p "${REPO_NAME}"

    pushd "${REPO_NAME}" || exit 5

    git checkout "${HASH}"

    OWNER=$(echo "${REPO}" | cut -d / -f 4)

    if [ "${OWNER}" = "${USER}" ]; then
        ORIGIN=$(echo "${REPOHASH}" | awk '{print $3}')
        git remote add unannotated "${ORIGIN}"
    fi

    REPO_FULLPATH=$(pwd)
    
    popd || exit 5

    RESULT_LOG="${OUTDIR}-results/${REPO_NAME_HASH}-wpi.log"
    touch "${RESULT_LOG}"

    "${SCRIPTDIR}/configure-and-exec-dljc.sh" -d "${REPO_FULLPATH}" -c "${CHECKERS}" -l "${CHECKER_LIB}" -q "${QUALS}" -s "${STUBS}" -u "${USER}" -t "${TOUT}" &> "${RESULT_LOG}"

    popd || exit 5

    # if the result is unusable, we don't need it for data analysis and we can
    # delete it right away
    if [ -f "${REPO_FULLPATH}/.unusable" ]; then
        rm -rf "${REPO_NAME_HASH}" &
    else
        cat "${REPO_FULLPATH}/dljc-out/wpi.log" >> "${RESULT_LOG}"
    fi

    cd "${OUTDIR}" || exit 5
    
done <"${INLIST}"

popd || exit 5

unaccounted_for=$(grep -Zvl "no build file found for" "${OUTDIR}-results/*.log" \
    | xargs -0 grep -Zvl "dljc could not run the Checker Framework" \
    | xargs -0 grep -Zvl "dljc could not run the build successfully" \
    | xargs -0 grep -Zvl "dljc timed out for" \
    | xargs -0 echo)

javafiles=$(grep -oh "\S*\.java " "${unaccounted_for}")

if [ ! -f "${SCRIPTDIR}/../cloc-1.80.pl" ]; then
    pushd "${SCRIPTDIR}/.." || exit 5
    wget "https://github.com/AlDanial/cloc/releases/download/1.80/cloc-1.80.pl"
    popd || exit 5
fi

perl "${SCRIPTDIR}/../cloc-1.80.pl" --report="${OUTDIR}-results/loc.txt" "${javafiles}"
