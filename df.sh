#!/usr/bin/env bash
# data frame manipulation

function dcsv
{
    cat $1 | perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' | column -t -s, | less -S
}

function dtsv
{
    perl -pe 's/((?<=\t)|(?<=^))\t/ \t/g;' "$@" | column -t -s $'\t' | exec less  -F -S -X -K
}

function transpose
{
    if [[ $# -eq 1 && -f $1 ]]; then
        awk '
        {
            for (i=1; i<=NF; i++)  {
                        a[NR,i] = $i
            }
        }
        NF>p { p = NF }
        END {
           for(j=1; j<=p; j++) {
                str=a[1,j]
                for(i=2; i<=NR; i++){
                    str=str"\t"a[i,j];
                }
                print str
            }
        }' $1
    fi
}

function dsort
{
    local column=1
    if [[ $# -ge 1 ]]; then
        if [[ $# -eq 1 ]]; then
            column=1
        else
            column=$2
        fi
        (head -n 1 $1 && (tail -n +2 $1 | sort -k${column}g)) | cat
    fi
}
