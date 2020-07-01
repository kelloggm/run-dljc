#!/bin/bash

# This script performs WPI via dljc on a given project directory.
# The inputs are similar to run-dljc.sh, which uses this script internally.
# The only difference is that run-dljc.sh takes a list of projects, while
# this script operates on a single project at a time.
# See the documentation of run-dljc.sh for information on the inputs to this
# script.
#
# Input differences compared to run-dljc.sh:
# -i and -o are not valid options
# new option -d: the directory containing the target project

while getopts "c:l:q:s:d:u:t:" opt; do
  case $opt in
    c) CHECKERS="$OPTARG"
       ;;
    l) CHECKER_LIB="$OPTARG"
       ;;
    q) QUALS="$OPTARG"
       ;;
    s) STUBS="$OPTARG"
       ;;
    d) DIR="$OPTARG"
       ;;
    u) USER="$OPTARG"
       ;;
    t) TIMEOUT="$OPTARG"
       ;;        
    \?) echo "Invalid option -$OPTARG" >&2
       ;;
  esac
done

# check required arguments and environment variables:

# testing for JAVA8_HOME, not an unintentional reference to JAVA_HOME
# shellcheck disable=SC2153
if [ "x${JAVA8_HOME}" = "x" ]; then
    echo "JAVA8_HOME must be set to a Java 8 JDK for this script to succeed"
    exit 1
fi

if [ ! -d "${JAVA8_HOME}" ]; then
    echo "JAVA8_HOME is set to a non-existant directory. Check that ${JAVA8_HOME} exists."
    exit 1
fi

# testing for JAVA11_HOME, not an unintentional reference to JAVA_HOME
# shellcheck disable=SC2153
if [ "x${JAVA11_HOME}" = "x" ]; then
    echo "JAVA11_HOME must be set to a Java 11 JDK for this script to succeed"
    exit 1
fi

if [ ! -d "${JAVA11_HOME}" ]; then
    echo "JAVA11_HOME is set to a non-existant directory. Check that ${JAVA11_HOME} exists."
    exit 1
fi

JAVA_HOME="${JAVA11_HOME}"

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

if [ "x${DLJC}" = "x" ]; then
    echo "DLJC is not set; it must be set to the dljc executable. Please checkout github.com/kelloggm/do-like-javac and point the DLJC environment variable to its dljc script"
    exit 3
fi

if [ ! -d "${DIR}" ]; then
    echo "configure-and-exec-dljc.sh called on invalid directory: ${DIR}. Please supply an existing directory's absolute path."
    exit 4
fi

function configure_and_exec_dljc {

  if [ -f build.gradle ]; then
      if [ -f gradlew ]; then
	  chmod +x gradlew
	  GRADLE_EXEC="./gradlew"
      else
	  GRADLE_EXEC="gradle"
      fi
      BUILD_CMD="${GRADLE_EXEC} clean compileJava -g .gradle -Dorg.gradle.java.home=${JAVA_HOME}"
      CLEAN_CMD="${GRADLE_EXEC} clean -g .gradle -Dorg.gradle.java.home=${JAVA_HOME}"
  elif [ -f pom.xml ]; then
      if [ -f mvnw ]; then
	  MVN_EXEC="./mvnw"
      else
	  MVN_EXEC="mvn"
      fi
      # if running on java 8, you must add /jre to the end of this Maven command
      if [ "${JAVA_HOME}" = "${JAVA8_HOME}" ]; then
          BUILD_CMD="${MVN_EXEC} clean compile -Djava.home=${JAVA_HOME}/jre"
          CLEAN_CMD="${MVN_EXEC} clean -Djava.home=${JAVA_HOME}/jre"
      else
          BUILD_CMD="${MVN_EXEC} clean compile -Djava.home=${JAVA_HOME}"
          CLEAN_CMD="${MVN_EXEC} clean -Djava.home=${JAVA_HOME}"
      fi
  else
      echo "no build file found for ${REPO_NAME}; not calling DLJC"
      USABLE="no"
      return
  fi
    
  DLJC_CMD="${DLJC} -t wpi --checker ${CHECKERS}"

  if [ ! "x${CHECKER_LIB}" = "x" ]; then
      TMP="${DLJC_CMD} --lib ${CHECKER_LIB}"
      DLJC_CMD="${TMP}"
  fi

  if [ ! "x${STUBS}" = "x" ]; then
      TMP="${DLJC_CMD} --stubs ${STUBS}"
      DLJC_CMD="${TMP}"
  fi

  if [ ! "x${QUALS}" = "x" ]; then
      TMP="${DLJC_CMD} --quals ${QUALS}"
      DLJC_CMD="${TMP}"
  fi

  if [ ! "x${TIMEOUT}" = "x" ]; then
      TMP="${DLJC_CMD}"
      DLJC_CMD="timeout ${TIMEOUT} ${TMP}"
  fi

  TMP="${DLJC_CMD} -- ${BUILD_CMD}"
  DLJC_CMD="${TMP}"

  # ensure the project is clean before invoking DLJC
  eval "${CLEAN_CMD}" < /dev/null

  echo "${DLJC_CMD}"

  eval "${DLJC_CMD}" < /dev/null

  if [[ $? -eq 124 ]]; then
      echo "dljc timed out for ${DIR}"
      USABLE="no"
  else 
      if [ -f dljc-out/wpi.log ]; then
          USABLE="yes"
      else
          # if this last run was under Java 11, try to run
          # under Java 8 instead
          if [ "${JAVA_HOME}" = "${JAVA11_HOME}" ]; then
              export JAVA_HOME="${JAVA8_HOME}"
              echo "couldn't build using Java 11; trying Java 8"
              configure_and_exec_dljc
              export JAVA_HOME="${JAVA11_HOME}"
          else
              echo "dljc could not run the build successfully"
              USABLE="no"
          fi
      fi
  fi
}

#### Main script

pushd "${DIR}" || exit 1

configure_and_exec_dljc

# support run-dljc.sh's ability to delete unusable projects automatically
if [ "${USABLE}" = "no" ]; then
    touch .unusable
fi

popd || exit 1
