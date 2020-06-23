#!/bin/sh

# This script collects a list of projects that match a query
# from GitHub. You must have a git personal access token in
# the file git-personal-access-token in the directory from which
# you run this script.

# inputs:
#
# the file git-personal-access-token must exist in the directory from which
# this script is run, and must be a valid github OAuth token
#
# $1 is the query file, which should contain the literal string to use
# as the github search. REQUIRED, no default
#
# $2 is the number of pages to search. default 1

query_file=$1

if [ -z ${query_file} ]; then
    echo "you must have provide a query file as the first argument"
    exit 2
fi

if [ -z "$2" ]; then
    page_count=1
else
    page_count=$2
fi

query=`cat ${query_file} | tr ' ' '+'`

## for storing the results before sorting and uniqing them
rm -f /tmp/github-query-results.txt
tempfile=$(mktemp /tmp/github-query-results.txt)
#trap "rm -f ${tempfile}" 0 2 3 15

rm -f /tmp/github-hash-results.txt
hashfile=$(mktemp /tmp/github-hash-results.txt)
#trap "rm -f ${hashfile}" 0 2 3 15

# find the repos
for i in `seq ${page_count}`; do
    full_query='https://api.github.com/search/code?q='${query}'&page='${i}
#    echo ${full_query}
    #    exit 1

    # this removes projects that are
    # 1. owned by me
    # 2. are hard-forks of android-libcore, because they're very big and
    #    we can't handle them anyway
    # 3. are hard-forks of apache harmony, for the same reason
    # 4. are owned by the user AndroidSDKSources, because those
    #    are all copies of (surprise!) the android SDK, which we
    #    don't care about for the same reasons.
    curl -sH "Authorization: token `cat git-personal-access-token`" \
     	     "Accept: application/vnd.github.v3+json" \
     	     ${full_query} \
    	| grep "        \"html_url" \
    	| grep -v "          " \
    	| sort | uniq \
    	| cut -d \" -f 4 \
    	| grep -v "kelloggm" \
        | grep -v "libcore" \
	| grep -v "apache-harmony" \
	| grep -v "AndroidSDKSources" >> ${tempfile}
done

sort -u -o ${tempfile} ${tempfile}

while IFS= read -r line
do
    repo=`echo ${line} | cut -d / -f 5`
    owner=`echo ${line} | cut -d / -f 4`
    hash_query='https://api.github.com/repos/'${owner}'/'${repo}'/commits?per_page=1'
#    echo ${hash_query}
    curl -sH "Authorization: token `cat git-personal-access-token`" \
    	     "Accept: application/vnd.github.v3+json" \
    	     ${hash_query} \
    	| grep '^    "sha":' \
    	| cut -d \" -f 4 >> ${hashfile}
    
done < ${tempfile}

paste ${tempfile} ${hashfile}
