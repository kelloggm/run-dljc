#!/bin/sh

# This script takes a directory of .log files as input, and produces a summary of the results.
# Use its output to guide your analysis of the results of running ./wpi-many.sh: you must manually
# examine the results of any project that appears in the "unaccounted for" list.

targetdir=$1

total=$(find "${targetdir}" -name "*.log" | wc -l)

no_build_file=$(grep -cl "no build file found for" "${targetdir}/"*.log)
no_build_file_percent=$(((no_build_file*100)/total))

# "old" and "new" in the below refer to the two different messages that
# dljc's wpi tool can emit for this kind of failure. At some point while
# running an early set of these experiments, I realized that the original
# message wasn't correct, and fixed it. But, for backwards compatibility,
# this script looks for both messages and combines the counts.
build_failed_old=$(grep -cl "dljc could not run the Checker Framework" "${targetdir}/"*.log)
build_failed_new=$(grep -cl "dljc could not run the build successfully" "${targetdir}/"*.log)
build_failed=$((build_failed_old+build_failed_new))
build_failed_percent=$(((build_failed*100)/total))

timed_out=$(grep -cl "dljc timed out for" "${targetdir}/"*.log)
timed_out_percent=$(((timed_out*100)/total))

echo "total repositories: ${total} (100%)"
echo "no maven or gradle build file: ${no_build_file} (~${no_build_file_percent}%)"
echo "build failed: ${build_failed} (~${build_failed_percent}%)"
echo "timed out: ${timed_out} (~${timed_out_percent}%)"
echo ""
echo "timeouts:"
echo ""
grep -l "dljc timed out for" "${targetdir}/"*.log
echo ""

for_manual_inspection=$(cat "${targetdir}/for_manual_inspection.txt")

echo "these need to be manually inspected: "
echo ""
echo "${for_manual_inspection}" | tr ' ' '\n'
echo ""

if [ -f "${targetdir}/loc.txt" ]; then
    echo "LoC of projects to be manually inspected:"

    cat "${targetdir}/loc.txt"
else
    echo "No LoC count found for projects to be manuall inspected"
fi
