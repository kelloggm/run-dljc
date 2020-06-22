#!/bin/sh

export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk/
export JAVA8_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JAVA_HOME=${JAVA11_HOME}
export CHECKERFRAMEWORK=/homes/gws/kelloggm/compliance-experiments/fse20/checker-framework/
export ANDROID_HOME=/homes/gws/kelloggm/compliance-experiments/fse20/android_home

tout=3600 # 60 minutes

rm -rf no-literal-securerandom-results

bash run-dljc.sh -o no-literal-securerandom \
 -i /homes/gws/kelloggm/compliance-experiments/fse20/securerandom100.list \
 -c org.checkerframework.checker.noliteral.NoLiteralChecker \
 -q '/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-qual/build/libs/no-literal-qual.jar:/homes/gws/kelloggm/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/3.1.1/361404eff7f971a296020d47c928905b3b9c5b5f/checker-qual-3.1.1.jar' \
 -l '/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-checker/build/classes/java/main:/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-checker/build/resources/main:/homes/gws/kelloggm/compliance-experiments/fse20/checker-framework/checker/dist/checker.jar:/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-qual/build/libs/no-literal-qual.jar:/homes/gws/kelloggm/.gradle/caches/modules-2/files-2.1/com.google.errorprone/javac/9+181-r4173-1/bdf4c0aa7d540ee1f7bf14d47447aea4bbf450c5/javac-9+181-r4173-1.jar:/homes/gws/kelloggm/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/3.1.1/361404eff7f971a296020d47c928905b3b9c5b5f/checker-qual-3.1.1.jar' \
 -s '/homes/gws/kelloggm/compliance-experiments/fse20/no-literal-checker/no-literal-checker/stubs' \
 -t ${tout}
