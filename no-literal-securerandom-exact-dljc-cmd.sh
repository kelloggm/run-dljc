#!/bin/sh

## This is an example "one-command with no arguments" script that controls run-dljc.sh. It is copied
## directly from the experiments for the Continuous Compliance paper. If you want to re-use this
## script, you'll have to change environment variables and paths below.

# Change these if you are running on a non-CSE machine.
export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk/
export JAVA8_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Everyone must change these.
export PARENTDIR=${HOME}/compliance-experiments/fse20
export CHECKERFRAMEWORK=${PARENTDIR}/checker-framework
checkername=no-literal
export CHECKERDIR=${PARENTDIR}/${checkername}-checker
repolist=securerandom.list

# Optionally change these.
export ANDROID_HOME=${PARENTDIR}/android_home
timeout=3600 # 60 minutes

# There is no need to make changes below this point.
export JAVA_HOME=${JAVA11_HOME}
repolistbase=$(basename "$repolist")

# Code starts here.

rm -rf "${checkername}-${repolistbase}-results"

bash run-dljc.sh -o "${checkername}-${repolistbase}" \
 -i "${PARENTDIR}/${repolist}" \
 -c org.checkerframework.checker.noliteral.NoLiteralChecker \
 -q "${CHECKERDIR}/${checkername}-qual/build/libs/${checkername}-qual.jar:${HOME}/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/3.1.1/361404eff7f971a296020d47c928905b3b9c5b5f/checker-qual-3.1.1.jar" \
 -l "${CHECKERDIR}/${checkername}-checker/build/classes/java/main:${CHECKERDIR}/${checkername}-checker/build/resources/main:${CHECKERFRAMEWORK}/checker/dist/checker.jar:${CHECKERDIR}/${checkername}-qual/build/libs/${checkername}-qual.jar:${HOME}/.gradle/caches/modules-2/files-2.1/com.google.errorprone/javac/9+181-r4173-1/bdf4c0aa7d540ee1f7bf14d47447aea4bbf450c5/javac-9+181-r4173-1.jar:${HOME}/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/3.1.1/361404eff7f971a296020d47c928905b3b9c5b5f/checker-qual-3.1.1.jar" \
 -s "${CHECKERDIR}/${checkername}-checker/stubs" \
 -t ${timeout}
