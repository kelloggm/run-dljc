#!/bin/bash

# This script actually executes WPI via dljc on a given project directory.
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

if [ "x${DLJC}" = "x" ]; then
    echo "DLJC must be set to the dljc executable for this script to succeed. Please checkout github.com/kelloggm/do-like-javac and point the DLJC environment variable to its dljc script"
    exit 3
fi

if [ ! -d "${DIR}" ]; then
    echo "configure-and-exec-dljc.sh called on invalid directory: ${DIR}. Please supply a valid directory's absolute path."
    exit 4
fi

function configure_and_exec_dljc {

  USABLE="yes"
  if [ -f build.gradle ]; then
      chmod +x gradlew
      BUILD_CMD="./gradlew clean compileJava -g .gradle -Dorg.gradle.java.home=${JAVA_HOME}"
      CLEAN_CMD="./gradlew clean -g .gradle -Dorg.gradle.java.home=${JAVA_HOME}"
  elif [ -f pom.xml ]; then
      # if running on java 8, you must add /jre to the end of this Maven command
      if [ "${JAVA_HOME}" = "${JAVA8_HOME}" ]; then
          BUILD_CMD="mvn clean compile -Djava.home=${JAVA_HOME}/jre"
          CLEAN_CMD="mvn clean -Djava.home=${JAVA_HOME}/jre"
      else
          BUILD_CMD="mvn clean compile -Djava.home=${JAVA_HOME}"
          CLEAN_CMD="mvn clean -Djava.home=${JAVA_HOME}"
      fi
  else
      BUILD_CMD="not found"
  fi
    
  if [ "${BUILD_CMD}" = "not found" ]; then
      echo "no build file found for ${REPO_NAME}; not calling DLJC"
      USABLE="no"
  else
      DLJC_CMD="${DLJC} -t wpi --cleanCmd \"${CLEAN_CMD}\""
      if [ ! "x${CHECKERS}" = "x" ]; then
	  TMP="${DLJC_CMD} --checker ${CHECKERS}"
          DLJC_CMD="${TMP}"
      fi
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
      
      if [ ! "x${TOUT}" = "x" ]; then
          TMP="${DLJC_CMD}"
          DLJC_CMD="timeout ${TOUT} ${TMP}"
          echo "setting timeout to ${TOUT}"
      fi
      
      TMP="${DLJC_CMD} -- ${BUILD_CMD}"
      DLJC_CMD="${TMP}"
      
      # ensure the project is clean before invoking DLJC
      eval ${CLEAN_CMD} < /dev/null

      echo ${DLJC_CMD}
      
      eval ${DLJC_CMD} < /dev/null
      
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
              else
                  echo "dljc could not run the build successfully"
		  USABLE="no"
              fi
          fi
      fi
  fi
  export JAVA_HOME="${JAVA11_HOME}"
}

#### Main script

pushd ${DIR}

configure_and_exec_dljc

# support run-dljc's ability to delete unusable projects automatically
if [ ${USABLE} = "no" ]; then
    touch .unusable
fi

popd
