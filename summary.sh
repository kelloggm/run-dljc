#!/bin/sh

# This script takes a directory of .log files as input, and produces a summary of the results.
# Use its output to guide your analysis of the results of running ./run-dljc.sh: you must manually
# examine the results of any project that appears in the "unaccounted for" list.

target=$1

total=`ls -l ${target}/*.log | wc -l`

timed_out=`grep -l "dljc timed out for" ${target}/*.log | wc -l`
timed_out_percent=$(((${timed_out}*100)/${total}))
timed_out_list=`grep -l "dljc timed out for" ${target}/*.log`

no_build=`grep -l "no build file found for" ${target}/*.log | wc -l`
no_build_percent=$(((${no_build}*100)/${total}))

## These checks are no longer necessary, because DLJC now handles both cases
## automatically and is therefore able to process such projects.

# lombok=`grep -lZ 'cannot find symbol' ${target}/*.log | xargs -0 grep -l 'lombok' | wc -l`
# lombok_percent=$(((${lombok}*100)/${total}))

# no_java_under_8=`grep -l "error: Source option" ${target}/*.log | wc -l`
# no_java_under_8_percent=$(((${no_java_under_8}*100)/${total}))

no_cf_old=`grep -l "dljc could not run the Checker Framework" ${target}/*.log | wc -l`
no_cf_new=`grep -l "dljc could not run the build successfully" ${target}/*.log | wc -l`
no_cf=$((${no_cf_old}+${no_cf_new}))
no_cf_percent=$(((${no_cf}*100)/${total}))

echo "total repositories: ${total} (100%)"
echo "no maven or gradle build file: ${no_build} (~${no_build_percent}%)"
echo "build failed: ${no_cf} (~${no_cf_percent})"
echo "timed out: ${timed_out} (~${timed_out_percent}%)"
echo ""
echo "timeouts:"
echo ""
echo ${timed_out_list} | tr ' ' '\n'
echo ""
# echo "build failed due to lombok: ${lombok} (~${lombok_percent}%)"
# echo "Java 7 or earlier: ${no_java_under_8} (~${no_java_under_8_percent}%)"

unaccounted_for=`grep -Zvl "no build file found for" ${target}/*.log \
    | xargs -0 grep -Zvl "dljc could not run the Checker Framework" \
    | xargs -0 grep -Zvl "dljc could not run the build successfully" \
    | xargs -0 grep -Zvl "dljc timed out for" \
    | xargs -0 echo`

unaccounted_for_count=`echo ${unaccounted_for} | tr ' ' '\n' | wc -l`
unaccounted_for_count_percent=$(((${unaccounted_for_count}*100)/${total}))

echo "unaccounted for: "
echo ""
echo ${unaccounted_for} | tr ' ' '\n'
echo ""

echo "unaccounted for LoC:"

cat ${target}/loc.txt
