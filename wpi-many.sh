#!/bin/bash

# This script runs the Checker Framework's whole-program inference on each of a list of projects.

### Usage

# - Clone the wpi-many repository containing this script on the experimental
#   machine.
# - Make a file containing a list of git repositories and hashes. Each line of
#   the file should contain one repository and one hash, and may optionally
#   contain a third repository (see the -i argument description below).
#   run-queries.sh creates such a list of projects.
# - Ensure that your JAVA8_HOME variable points to a Java 8 JDK
# - Ensure that your JAVA11_HOME variable points to a Java 11 JDK
# - Ensure that your CHECKERFRAMEWORK variable points to a built copy of the Checker Framework
# - Other dependencies: perl, python2.7 (for dljc), awk, git, mvn, gradle, wget, curl
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
#             then each line owned by that user must contain a third element,
#             the original github repository.
#
# The meaning of each optional argument is:
#
# -u user : the GitHub owner for repositories that have
#           been forked and modified. These repositories must have a third entry
#           in the infile indicating their origin. Default is "$USER".
#
# -t timeout : the timeout to use, in seconds
#
# After these arguments, any remaining arguments are passed directly
# to DLJC without modification. See the documentation of DLJC for
# an explanation of these arguments: https://github.com/kelloggm/do-like-javac
# At least one such argument is required: --checker, which tells DLJC what
# typechecker to run.
#

while getopts "o:i:u:t:" opt; do
  case $opt in
    o) OUTDIR="$OPTARG"
       ;;
    i) INLIST="$OPTARG"
       ;;
    u) GITHUB_USER="$OPTARG"
       ;;
    t) TOUT="$OPTARG"
       ;;        
    \?) # the remainder of the arguments will be passed to DLJC directly
       ;;
  esac
done

# shift so that the other arguments (that should be passed to dljc) are all
# that's in $@
shift $(( OPTIND - 1 ))

# check required arguments and environment variables:

if [ "x${JAVA8_HOME}" = "x" ]; then
    echo "JAVA8_HOME must be set to a Java 8 JDK"
    exit 1
fi

if [ ! -d "${JAVA8_HOME}" ]; then
    echo "JAVA8_HOME is set to a non-existent directory ${JAVA8_HOME}"
    exit 1
fi

if [ "x${JAVA11_HOME}" = "x" ]; then
    echo "JAVA11_HOME must be set to a Java 11 JDK"
    exit 1
fi

if [ ! -d "${JAVA11_HOME}" ]; then
    echo "JAVA11_HOME is set to a non-existent directory ${JAVA11_HOME}"
    exit 1
fi

if [ "x${CHECKERFRAMEWORK}" = "x" ]; then
    echo "CHECKERFRAMEWORK is not set; it must be set to a locally-built Checker Framework. Please clone and build github.com/typetools/checker-framework"
    exit 2
fi

if [ ! -d "${CHECKERFRAMEWORK}" ]; then
    echo "CHECKERFRAMEWORK is set to a non-existent directory ${CHECKERFRAMEWORK}"
    exit 2
fi

if [ "x${OUTDIR}" = "x" ]; then
    echo "You must specify an output directory using the -o argument."
    exit 3
fi

if [ "x${INLIST}" = "x" ]; then
    echo "You must specify an input file using the -i argument."
    exit 4
fi

if [ "x${GITHUB_USER}" = "x" ]; then
    GITHUB_USER="${USER}"
fi

### Script

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# clone or update DLJC
if [ ! -d "${SCRIPTDIR}/../do-like-javac" ]; then
    git -C "${SCRIPTDIR}/.." clone https://github.com/kelloggm/do-like-javac
else
    git -C "${SCRIPTDIR}/../do-like-javac" pull
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

    # Use repo name and hash, but not owner.  We want
    # repos that are different but have the same name to be treated
    # as different repos, but forks with the same content to be skipped.
    # TODO: consider just using hash, to skip hard forks?
    mkdir -p "${REPO_NAME_HASH}"

    pushd "${REPO_NAME_HASH}" || exit 5
    
    if [ ! -d "${REPO_NAME}" ]; then
        # this environment variable prevents git from prompting for
	# username/password if the repository no longer exists
        GIT_TERMINAL_PROMPT=0 git clone "${REPO}"
        # skip the rest of the script if cloning isn't successful
        if [ -d "${REPO_NAME}" ]; then
           continue
        fi
    else
        rm -rf "${REPO_NAME}/dljc-out"
    fi

    pushd "${REPO_NAME}" || exit 5

    git checkout "${HASH}"

    OWNER=$(echo "${REPO}" | cut -d / -f 4)

    if [ "${OWNER}" = "${GITHUB_USER}" ]; then
        ORIGIN=$(echo "${REPOHASH}" | awk '{print $3}')
        git remote add unannotated "${ORIGIN}"
    fi

    REPO_FULLPATH=$(pwd)
    
    popd || exit 5

    RESULT_LOG="${OUTDIR}-results/${REPO_NAME_HASH}-wpi.log"
    touch "${RESULT_LOG}"

    "${SCRIPTDIR}/wpi.sh" -d "${REPO_FULLPATH}" -u "${GITHUB_USER}" -t "${TOUT}" "$@" &> "${RESULT_LOG}"

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

echo "${unaccounted_for}" > "${OUTDIR}-results/unaccounted_for.txt"

javafiles=$(grep -oh "\S*\.java " "${unaccounted_for}")

pushd "${SCRIPTDIR}/.." || exit 5
wget -nc "https://github.com/AlDanial/cloc/releases/download/1.80/cloc-1.80.pl"
popd || exit 5

perl "${SCRIPTDIR}/../cloc-1.80.pl" --report="${OUTDIR}-results/loc.txt" "${javafiles}"
