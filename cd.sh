#!/usr/bin/env bash

BACK_CD_HISTORY=""
FORWARD_CD_HISTORY=""
KEEP_CD_HISTORY=100

# cd with tracking history
# cd 1 to move forward
# cd -1 to move backward
# cd [directory] to move to a path
function cd {
    local DIR="."
    local BACK_HISTORY=$BACK_CD_HISTORY
    local FORWARD_HISTORY=$FORWARD_CD_HISTORY
    if [[ $# -eq 1 ]] && [[ $1 =~ ^[0-9-]+$ ]]; then
        local FORWARD_HISTORY_LENGTH=$(echo $FORWARD_CD_HISTORY | grep -o ":" | wc -l)
        local BACK_HISTORY_LENGTH=$(echo $BACK_CD_HISTORY | grep -o ":" | wc -l)
        if [[ $1 -gt 0 ]]; then
            # go forward
            if [[ $FORWARD_CD_HISTORY == "" ]]; then
                echo "You are at the frontier! Cannot move forward. Try 'lcd' to see the cache."
            else
                if [[ $1 -ge $FORWARD_HISTORY_LENGTH ]]; then
                    echo "Not enough forward history in the cache. Try 'lcd' to see the cache."
                else
                    for iDir in $( seq 1 $1 ); do
                        DIR=${FORWARD_HISTORY%%:*}
                        FORWARD_HISTORY=${FORWARD_HISTORY#*:}
                        BACK_HISTORY=$DIR:$BACK_HISTORY
                    done
                    DIR=${FORWARD_HISTORY%%:*}
                    if [[ -d "$DIR" ]]; then
                        FORWARD_CD_HISTORY=$FORWARD_HISTORY
                        BACK_CD_HISTORY=$BACK_HISTORY
                        builtin cd "$DIR"
                    fi
                fi
            fi
        elif [[ $1 -lt 0 ]]; then
            if [[ $(( -$1 )) -gt $BACK_HISTORY_LENGTH ]]; then
                echo "Not enough backward history in the cache. Try 'lcd' to see the cache."
            else
                if [[ $FORWARD_HISTORY_LENGTH -eq 0 ]]; then
                    DIR=$PWD
                    FORWARD_HISTORY=$DIR:$FORWARD_HISTORY
                fi
                for iDir in $(seq 1 $(( -$1 ))); do
                    DIR=${BACK_HISTORY%%:*}
                    BACK_HISTORY=${BACK_HISTORY#*:}
                    FORWARD_HISTORY=$DIR:$FORWARD_HISTORY
                done
                if [[ -d "$DIR" ]]; then
                    BACK_CD_HISTORY=$BACK_HISTORY
                    FORWARD_CD_HISTORY=$FORWARD_HISTORY
                    builtin cd "$DIR"
                fi
            fi
        else
            echo "Stay right here."
        fi
    else
        if [[ $KEEP_CD_HISTORY -gt 0 ]]; then
            BACK_CD_HISTORY=$PWD:$BACK_CD_HISTORY
            KEEP_CD_HISTORY=$(( $KEEP_CD_HISTORY - 1 ))
        else
            BACK_CD_HISTORY=$PWD:${BACK_CD_HISTORY%:*}
        fi
        FORWARD_CD_HISTORY=""
        builtin cd "$@"
    fi
}

#
function checkcd
{
    echo "[BACK_CD_HISTORY]"
    echo $BACK_CD_HISTORY | tr ":" "\n"
    echo "[FORWARD_CD_HISTORY]"
    echo $FORWARD_CD_HISTORY | tr ":" "\n"
}

# list the tracked history of cd
# lcd 1 to show history one line before and after the current position
function lcd
{
    local CD_HISTORY_LENGTH=100
    if [[ $# -ge 1 ]]; then
        CD_HISTORY_LENGTH=$1
    fi
    local FORWARD_HISTORY_LENGTH=$(echo $FORWARD_CD_HISTORY | grep -o ":" | wc -l)
    local BACK_HISTORY_LENGTH=$(echo $BACK_CD_HISTORY | grep -o ":" | wc -l)
    local BACK_HISTORY=${BACK_CD_HISTORY%:*}
    local FORWARD_HISTORY=${FORWARD_CD_HISTORY%:*}
    local history=""
    if [[ $FORWARD_HISTORY_LENGTH -eq 0 ]]; then
        history=$(echo ${BACK_HISTORY} | tr ":" "\n" | tac | tr "\n" ":")
    else
        if [[ $BACK_HISTORY_LENGTH -gt 0 ]]; then
            history=$history$(echo ${BACK_HISTORY} | tr ":" "\n" | tac | tr "\n" ":")
        fi
        history=$history$(echo "${FORWARD_HISTORY%%:*} ")
        if [[ $FORWARD_HISTORY_LENGTH -gt 1 ]]; then
            history=$history:$(echo "${FORWARD_HISTORY#*:}")
        fi
    fi
    local line_numbers=$(echo -e "$(seq -$BACK_HISTORY_LENGTH -1)\n$(seq 0 $(($FORWARD_HISTORY_LENGTH-1)))")
    line_numbers=$(echo $line_numbers | sed '/^$/d' | tr " " "\n")
    local filenames=$(echo ${history} | tr ":" "\n")
    if [[ $FORWARD_HISTORY_LENGTH -le 1 ]]; then
        filenames=$filenames" "
    fi
    if [[ $FORWARD_HISTORY_LENGTH -eq 0 ]]; then
        (paste <(echo "$line_numbers")  <(echo "$filenames") --delimiters '\t')
    else
        (paste <(echo "$line_numbers")  <(echo "$filenames") --delimiters '\t') | grep "^.*\s$" -A $CD_HISTORY_LENGTH -B $CD_HISTORY_LENGTH
    fi
}
