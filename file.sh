#!/usr/bin/env bash
# cat the most recent file in a folder

function clast
{
    local dir="./"
    if [[ $# -ge 1 ]]; then
        dir=$1
    fi
    find $dir -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" " | xargs cat
}

# cat the most recent file in log folder
function clog
{
    clast log
}
