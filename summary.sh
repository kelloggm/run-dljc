#!/bin/sh

# This script takes a directory of .log files as input, and produces a summary of the results.
# Use its output to guide your analysis of the results of running ./run-dljc.sh: you must manually
# examine the results of any project that appears in the "unaccounted for" list.

targetdir=$1

total=$(find "${targetdir}" -name "*.log" | wc -l)

timed_out=$(grep -cl "dljc timed out for" "${targetdir}/*.log")
timed_out_percent=$(((timed_out*100)/total))
timed_out_list=$(grep -l "dljc timed out for" "${targetdir}/*.log")

no_build_file=$(grep -cl "no build file found for" "${targetdir}/*.log")
no_build_file_percent=$(((no_build_file*100)/total))

no_cf_old=$(grep -cl "dljc could not run the Checker Framework" "${targetdir}/*.log")
no_cf_new=$(grep -cl "dljc could not run the build successfully" "${targetdir}/*.log")
no_cf=$((no_cf_old+no_cf_new))
no_cf_percent=$(((no_cf*100)/total))

echo "total repositories: ${total} (100%)"
echo "no maven or gradle build file: ${no_build_file} (~${no_build_file_percent}%)"
echo "build failed: ${no_cf} (~${no_cf_percent}%)"
echo "timed out: ${timed_out} (~${timed_out_percent}%)"
echo ""
echo "timeouts:"
echo ""
echo "${timed_out_list}" | tr ' ' '\n'
echo ""

unaccounted_for=$(grep -Zvl "no build file found for" "${targetdir}/*.log" \
    | xargs -0 grep -Zvl "dljc could not run the Checker Framework" \
    | xargs -0 grep -Zvl "dljc could not run the build successfully" \
    | xargs -0 grep -Zvl "dljc timed out for" \
    | xargs -0 echo)

echo "unaccounted for: "
echo ""
echo "${unaccounted_for}" | tr ' ' '\n'
echo ""

echo "unaccounted for LoC:"

cat "${targetdir}/loc.txt"
