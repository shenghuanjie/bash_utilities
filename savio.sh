#!/usr/bin/env bash
#.bash_savio

## slurm alisa
# search for a certain module in 'module avail'
alias smodule="module avail 2>/dev/stdout | grep"
# check your usage on all your projects
alias susage="check_usage.sh -E -u $USER"
# check the usage of fc_genomicdata project
alias sgenomic="check_usage.sh -a fc_genomicdata"
alias skaufer="check_usage.sh -a fc_kauferlab"
# check the available node and the corresponding project
alias savail="sacctmgr -p show associations user=$USER | tr '|' '\t'"
# check the starting time of your job
#alias sstart="squeue --start -j"
# show the CPU and memory usage of a job
alias sshow="wwall -j"
# show the dynamic CPU and memory usage of a job
alias stui="wwall -t -j"
# show a interactive version of CPU and memory usage of a job
alias sview="srun /bin/bash --pty --jobid"
# cancel all the jobs
alias sstop="scancel -u $USER"
# find all idle nodes
alias sidle="sinfo | grep idle"
# ask for an interactive CPU on savio2_htc for 30 minutes
alias shtc="srun --pty -A fc_genomicdata -p savio2_htc -c 1 -n 1 -t 00:30:00 bash -i"
# ask for an interactive node on savio3_bigmem for 30 minutes
alias scondo="srun --pty -A co_genomicdata -p savio3_bigmem -c 1 -n 1 -t 00:30:00 bash -i"

## slurm and savio functions
# list jobs in queue or check the status of a specific job
function scheck
{
   if [[ $# -eq 0 ]]; then
       squeue -u $USER
   else
       scontrol show jobs $1
   fi
}

# show the status of recent jobs
# use flag '-h' to set last x job to print
# use flag '-a' to print all the jobs after the start date
# use flag '-d' to set the start date in sacct search
function sstatus
{
    OPTIND=1
    local flag_all=0
    local history=1
    local start_date=$(date +%Y-%m-%d --date "3 days ago")
    while getopts "d:h:a" opt; do
        case "$opt" in
            a) flag_all=1;;
            d) start_date="${OPTARG}";;
            h) history="${OPTARG}";;
            *) echo 'Error in command line parsing. Flag not found' >&2
        esac
    done
    if [[ $flag_all -eq 1 ]]; then
        ids=$(sacct -b -S $start_date | awk '$1 ~ /^[0-9]*$/ {print $ 1}' | sort -n)
        for id in $ids
        do
            echo "Display job=$id"
            scontrol show jobid $id
        done
    else
        id=$(sacct -b  -S $start_date | awk '$1 ~ /^[0-9]*$/ {print $ 1}' | sort -rn | awk -v "history=$history" 'NR==history')
        if [[ $id -eq "" ]]; then
            id=$(sacct -b  -S "1900-01-1" | awk '$1 ~ /^[0-9]*$/ {print $ 1}' | sort -rn | awk -v "history=$history" 'NR==history')
            if [[ $id -eq "" ]]; then
                echo "No job is found in 'sacct' history. Please use 'scontrol show jobs [jobid]' to check the status"
            else
                scontrol show jobid $id
            fi
        else
            scontrol show jobid $id
        fi
    fi
}

# ask for a specified node for a given amount of time
function snode
{
    local node=""
    local time=""
    local project="co_genomicdata"
    if [[ $# -eq 0 ]]; then
        node="savio2_htc"
        time="00:30:00"
    elif [[ $# -eq 1 ]]; then
        if [[ $1 == *"savio"* ]]; then
            node=$1
            time="00:30:00"
        else
            node="savio2_htc"
            time=$1
        fi
    else
        node=$1
        time=$2
    fi
    if [[ $node == *"savio3"* ]]; then
        project="co_genomicdata"
    else
        project="fc_genomicdata"
    fi
    srun --pty -A $project -p $node -c 1 -n 1 -t $time bash -i
}

# check the latest log file in a given folder
# default directory is 'log'
# default log file is from the last job
function slog
{
    local dir="/global/home/users/shenghuanjie/log"
    local history=1
    case "$#" in
        1)
            if [[ $1 =~ ^[0-9]+$ ]]; then
                history=$1
            else
                dir=$1
            fi
            ;;
        2)
            if [[ $1 =~ ^[0-9]+$ ]]; then
                history=$1
                dir=$2
            else
                history=$2
                dir=$1
            fi
            ;;
        *);;
    esac
    id=$(sacct -b | awk '$1 ~ /^[0-9]*$/ {print $1}' | sort -rn | awk -v "history=$history" 'NR==history')
    if [[ $id -eq "" ]]; then
        id=$(sacct -b  -S "1900-01-1" | awk '$1 ~ /^[0-9]*$/ {print $ 1}' | sort -rn | awk -v "history=$history" 'NR==history')
    fi
    if [[ $id -eq "" ]]; then
        echo "No job is found in 'sacct' history. Please cat the log file manually"
    else
        if [[ -d $dir ]]; then
            local filename=$(find $dir -type f -name "*$id*")
            local hashes=''
            width=$(stty size | head -n1 | cut -d " " -f1)
            for i in $(seq 1 $width); do hashes="$hashes#"; done

            echo -e "\n$hashes"
            echo -e "log file of job $filename"
            echo -e "$hashes\n"
            if [[ -f $filename ]]; then
                cat $filename
            else
                echo -e "$filename file cannot be found"
            fi
            echo -e "\n$hashes"
            echo -e "log file of job $filename"
            echo -e "$hashes\n"
        else
            echo "$dir folder is not found. Please specify the path to the log file."
        fi
    fi
}
# print and find the error message in the most recent log file
function serror
{
    slog | grep "Error\|ERROR\|$" --color
}
