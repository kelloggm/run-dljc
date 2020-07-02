#!/bin/sh

# This script collects a list of projects that match a query from GitHub.

# inputs:
#
# The file git-personal-access-token must exist in the directory from which
# this script is run, and must be a valid github OAuth token.
#
# $1 is the query file, which should contain the literal string to use
# as the github search. REQUIRED, no default
#
# $2 is the number of pages to search. default 1

query_file=$1
# Number of times to retry a GitHub search query.
query_tries=5

if [ -z "${query_file}" ]; then
    echo "you must provide a query file as the first argument"
    exit 2
fi

if [ -z "$2" ]; then
    page_count=1
else
    page_count=$2
fi

query=$(tr ' ' '+' < "${query_file}")

## for storing the results before sorting and uniqing them
rm -f /tmp/github-query-results-*.txt
tempfile=$(mktemp /tmp/github-query-results-XXX.txt)
#trap "rm -f ${tempfile}" 0 2 3 15

rm -f /tmp/github-hash-results-*.txt
hashfile=$(mktemp /tmp/github-hash-results-XXX.txt)
#trap "rm -f ${hashfile}" 0 2 3 15

curl_output_file=$(mktemp curl-output-XXX.txt --tmpdir)

# find the repos
for i in $(seq "${page_count}"); do
    # GitHub only allows 30 searches per minute, so add a delay to each request.
    if [ "${i}" -gt 1 ]; then
        sleep 5
    fi

    full_query='https://api.github.com/search/code?q='${query}'&page='${i}
    for tries in $(seq ${query_tries}); do
        status_code=$(curl -s \
            -H "Authorization: token $(cat git-personal-access-token)" \
            -H "Accept: application/vnd.github.v3+json" \
            -w "%{http_code}" \
            -o "${curl_output_file}" \
            "${full_query}")

        # 200 and 422 are both non-error codes. Failures are usually due to
        # triggering the abuse detection mechanism for sending too many
        # requests, so we add a delay when this happens.
        if [ "${status_code}" -eq 200 ] || [ "${status_code}" -eq 422 ]; then
            break
        elif [ "${tries}" -lt $((query_tries - 1)) ]; then
            sleep 20
        fi
    done

    # GitHub only returns the first 1000 results. Requests pass this limit
    # return 422 so stop making requests in this case.
    if [ "${status_code}" -eq 422 ]; then
        break;
    elif [ "${status_code}" -ne 200 ]; then
        echo "GitHub query failed, last response:"
        cat "${curl_output_file}"
        rm -f "${curl_output_file}"
        exit 1
    fi
    # this removes projects that are
    # 1. owned by me
    # 2. are hard-forks of android-libcore, because they're very big and
    #    we can't handle them anyway
    # 3. are hard-forks of apache harmony, for the same reason
    # 4. are owned by the user AndroidSDKSources, because those
    #    are all copies of (surprise!) the android SDK, which we
    #    don't care about for the same reasons.
    grep "        \"html_url" < "${curl_output_file}" \
        | grep -v "          " \
        | sort -u \
        | cut -d \" -f 4 \
        | grep -v "kelloggm" \
        | grep -v "libcore" \
        | grep -v "apache-harmony" \
        | grep -v "AndroidSDKSources" >> "${tempfile}"
done

rm -f "${curl_output_file}"

sort -u -o "${tempfile}" "${tempfile}"

while IFS= read -r line
do
    repo=$(echo "${line}" | cut -d / -f 5)
    owner=$(echo "${line}" | cut -d / -f 4)
    hash_query='https://api.github.com/repos/'${owner}'/'${repo}'/commits?per_page=1'
    curl -sH "Authorization: token $(cat git-personal-access-token)" \
             "Accept: application/vnd.github.v3+json" \
             "${hash_query}" \
        | grep '^    "sha":' \
        | cut -d \" -f 4 >> "${hashfile}"
    
done < "${tempfile}"

paste "${tempfile}" "${hashfile}"
