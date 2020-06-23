#!/bin/sh

## This is an example "one-command with no arguments" script that controls run-dljc.sh. It is copied directly
## from the experiments for the Continuous Compliance paper. If you want to re-use this script, you'll have to change
## different things depending on what you're doing differently:
# * If you are running on a non-CSE machine, change the definitions of JAVA11_HOME and JAVA8_HOME.
# * EVERYONE must change the definitions of CHECKERFRAMEWORK and ANDROID_HOME. Setting ANDROID_HOME is optional.
# * EVERYONE must change all instances of "securerandom" in this file to the name of the .list file containing your target repositories.
# * If you are running a checker other than the no-literal checker, change the -c, -q, -l, and -s arguments to run-dljc.sh to make sense
#   for the checker you are running.
# * Make sure that all the absolute paths in this file match your machine/experimental directory.

export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk/
export JAVA8_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JAVA_HOME=${JAVA11_HOME}
export CHECKERFRAMEWORK=/homes/gws/kelloggm/compliance-experiments/fse20/checker-framework/
export ANDROID_HOME=/homes/gws/kelloggm/compliance-experiments/fse20/android_home

tout=3600 # 60 minutes

rm -rf no-literal-securerandom-results

bash run-dljc.sh -o no-literal-securerandom \
 -i /homes/gws/kelloggm/compliance-experiments/fse20/securerandom.list \
 -c org.checkerframework.checker.noliteral.NoLiteralChecker \
 -q '/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-qual/build/libs/no-literal-qual.jar:/homes/gws/kelloggm/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/3.1.1/361404eff7f971a296020d47c928905b3b9c5b5f/checker-qual-3.1.1.jar' \
 -l '/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-checker/build/classes/java/main:/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-checker/build/resources/main:/homes/gws/kelloggm/compliance-experiments/fse20/checker-framework/checker/dist/checker.jar:/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-qual/build/libs/no-literal-qual.jar:/homes/gws/kelloggm/.gradle/caches/modules-2/files-2.1/com.google.errorprone/javac/9+181-r4173-1/bdf4c0aa7d540ee1f7bf14d47447aea4bbf450c5/javac-9+181-r4173-1.jar:/homes/gws/kelloggm/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/3.1.1/361404eff7f971a296020d47c928905b3b9c5b5f/checker-qual-3.1.1.jar' \
 -s '/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-checker/stubs' \
 -t ${tout}
