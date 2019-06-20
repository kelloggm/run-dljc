#!/bin/bash

# usage: bash run-dljc.sh OUTDIR INLIST

DLJC=/homes/gws/kelloggm/auto-cf-2/do-like-javac/dljc
export CHECKERFRAMEWORK=/homes/gws/kelloggm/checker-framework
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
PATH=${JAVA_HOME}/bin:${PATH}

mkdir $1 || true
mkdir $1-results || true

pushd $1

for repo in `cat ../$2`; do
    
    REPO_NAME=`echo ${repo} | cut -d / -f 5`
    
    if [ ! -d ${REPO_NAME} ]; then
        git clone ${repo}
    fi

    pushd ${REPO_NAME}

    if [ -f build.gradle ]; then
	BUILD_CMD="./gradlew clean compileJava -Dorg.gradle.java.home=${JAVA_HOME}"
    elif [ -f pom.xml ]; then
	BUILD_CMD="mvn clean compile -Djava.home=${JAVA_HOME}/jre"
    else
        BUILD_CMD="not found"
    fi
    
    if [ "${BUILD_CMD}" = "not found" ]; then
        echo "no build file found for ${REPO_NAME}; not calling DLJC" > ../../$1-results/${REPO_NAME}-check.log 
    else
        ${DLJC} --lib /homes/gws/kelloggm/image-sniping-oss/typesafe-builder-checker/build/libs/typesafe-builder-checker.jar:/homes/gws/kelloggm/.m2/repository/org/springframework/spring-expression/5.1.7.RELEASE/spring-expression-5.1.7.RELEASE.jar:/homes/gws/kelloggm/.m2/repository/org/springframework/spring-core/5.1.7.RELEASE/spring-core-5.1.7.RELEASE.jar:/homes/gws/kelloggm/.m2/repository/org/springframework/spring-jcl/5.1.7.RELEASE/spring-jcl-5.1.7.RELEASE.jar: -t checker --checker org.checkerframework.checker.builder.TypesafeBuilderChecker --stubs /homes/gws/kelloggm/image-sniping-oss/typesafe-builder-checker/stubs -- ${BUILD_CMD}

        cp dljc-out/check.log ../../$1-results/${REPO_NAME}-check.log
    fi
 
    popd
done

popd
