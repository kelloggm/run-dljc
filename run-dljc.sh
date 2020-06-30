#!/bin/bash

# This script runs the Checker Framework's whole-program inference on each of a list of projects.
# To create a list of projects, see run-queries.sh or create one by hand.

### Usage

# - Move this script to an experiment directory.
# - Make a file containing a list of git repositories, one per line. Repositories must be of the form: https://github.com/username/repository - the script is reliant on the number of slashes, so excluding https:// is an error.
# - Ensure that your JAVA8_HOME variable points to a Java 8 JDK
# - Ensure that your JAVA11_HOME variable points to a Java 11 JDK
# - Ensure that your JAVA_HOME variable points to the same place as JAVA11_HOME
# - Ensure that your CHECKERFRAMEWORK variable points to a built copy of the Checker Framework
# - Other dependencies: perl, python2.7, awk, git, mvn
# - Then run a command like the following (replacing the example arguments with your own):
#   > bash run-dljc.sh -o outdir -i describe-images-list -c org.checkerframework.checker.builder.TypesafeBuilderChecker -l /homes/gws/kelloggm/image-sniping-oss/typesafe-builder-checker/build/libs/typesafe-builder-checker.jar:/homes/gws/kelloggm/.m2/repository/org/springframework/spring-expression/5.1.7.RELEASE/spring-expression-5.1.7.RELEASE.jar:/homes/gws/kelloggm/.m2/repository/org/springframework/spring-core/5.1.7.RELEASE/spring-core-5.1.7.RELEASE.jar:/homes/gws/kelloggm/.m2/repository/org/springframework/spring-jcl/5.1.7.RELEASE/spring-jcl-5.1.7.RELEASE.jar: -s /homes/gws/kelloggm/image-sniping-oss/typesafe-builder-checker/stubs
#
# The meaning of each required argument is:
#
# -o outdir : run the experiment in the ./outdir directory, and place the
#             results in the ./outdir-results directory. Both will be created
#             if they do not exist.
#
# -i infile : read the list of repositories to use from the file $infile. Each
#             line should contain the (https) url of the git repository on
#             GitHub and the commit hash to use, separated by whitespace. If the
#             repository's owner is you (see -u flag), then each line owned by
#             you must be followed by the original github repository.
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

while getopts "c:l:s:o:i:q:w:t:" opt; do
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

# JAVA_HOME must point to a Java 8 JDK for this script to work
if [ "x${JAVA_HOME}" = "x" ]; then
    echo "JAVA_HOME must be set to a Java 8 JDK for this script to succeed"
    exit 1
fi


if [ "x${CHECKERFRAMEWORK}" = "x" ]; then
    echo "CHECKERFRAMEWORK must be set to the base directory of a pre-built Checker Framework for this script to succeed. Please checkout github.com/typetools/checker-framework and follow the build instructions there"
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

# clone DLJC if it's not present
if [ ! -d do-like-javac ]; then
    git clone https://github.com/kelloggm/do-like-javac
fi

ORIGIN_PWD=`pwd`

export DLJC=${ORIGIN_PWD}/do-like-javac/dljc
    
export PATH=${JAVA_HOME}/bin:${PATH}

mkdir ${OUTDIR} || true
mkdir ${OUTDIR}-results || true

pushd ${OUTDIR}

while IFS='' read -r line || [ "$line" ]
do    
    REPOHASH=${line}

    REPO=`echo ${REPOHASH} | awk '{print $1}'`
    HASH=`echo ${REPOHASH} | awk '{print $2}'`

    REPO_NAME=`echo ${REPO} | cut -d / -f 5`

    # need a layer in the file structure that prevents
    # two repos with the same name from colliding
    if [ ! -d ${REPO_NAME}-${HASH} ]; then
        mkdir ${REPO_NAME}-${HASH}
    fi

    pushd ${REPO_NAME}-${HASH}
    
    if [ ! -d ${REPO_NAME} ]; then
        # this environment variable prevents git from prompting for username/password
        # if the repository no longer exists
        GIT_TERMINAL_PROMPT=0 git clone ${REPO}
    else
        rm -rf ${REPO_NAME}/dljc-out
    fi

    # if the above clone command failed for whatever reason, create an
    # empty directory so that the rest of the commands fail gracefully
    # without messing with the directory structure
    if [ ! -d ${REPO_NAME} ]; then
        mkdir ${REPO_NAME}
    fi

    pushd ${REPO_NAME}

    git checkout ${HASH}

    OWNER=`echo ${REPO} | cut -d / -f 4`

    if [ "${OWNER}" = "${USER}" ]; then
        ORIGIN=`echo ${REPOHASH} | awk '{print $3}'`
        git remote add unannotated ${ORIGIN}
    fi

    REPO_FULLPATH=`pwd`
    
    popd

    RESULT_LOG="${ORIGIN_PWD}/${OUTDIR}-results/${REPO_NAME}-${HASH}-wpi.log"
    touch ${RESULT_LOG}

    ${ORIGIN_PWD}/configure-and-exec-dljc.sh -d ${REPO_FULLPATH} -c ${CHECKERS} -l ${CHECKER_LIB} -q ${QUALS} -s ${STUBS} -u ${USER} -t ${TOUT} &> ${RESULT_LOG}

    popd

    # if the result is unusable, we don't need it for data analysis and we can
    # delete it right away
    if [ -f ${REPO_FULLPATH}/.unusable ]; then
	rm -rf ${REPO_NAME}-${HASH} &
    else
        cat ${REPO_FULLPATH}/dljc-out/wpi.log >> ${RESULT_LOG}
    fi

    cd ${ORIGIN_PWD}
    
done <${INLIST}

popd

unaccounted_for=`grep -Zvl "no build file found for" ${OUTDIR}-results/*.log \
    | xargs -0 grep -Zvl "dljc could not run the Checker Framework" \
    | xargs -0 grep -Zvl "dljc could not run the build successfully" \
    | xargs -0 grep -Zvl "dljc timed out for" \
    | xargs -0 echo`

javafiles=`grep -oh "\S*\.java " ${unaccounted_for}`

# echo ${javafiles}

if [ ! -f cloc-1.80.pl ]; then
    wget "https://github.com/AlDanial/cloc/releases/download/1.80/cloc-1.80.pl"
fi

perl cloc-1.80.pl --report=${OUTDIR}-results/loc.txt ${javafiles}
