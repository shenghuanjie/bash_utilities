#.bash_functions

BACK_CD_HISTORY=""
FORWARD_CD_HISTORY=""
KEEP_CD_HISTORY=10
OFFSET_CD_HISTORY=0

# override the builtin cd function so it can trace back history
# use cd n to move forwards
# use cd -n to move backwards
# use lcd to list stored history
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
                OFFSET_CD_HISTORY=$(( $OFFSET_CD_HISTORY - $1 ))
            fi
        elif [[ $1 -lt 0 ]]; then
            if [[ $(( -1 * $1 )) -gt $BACK_HISTORY_LENGTH ]]; then
                echo "Not enough backward history in the cache. Try 'lcd' to see the cache."
            else
                if [[ $FORWARD_HISTORY_LENGTH -eq 0 ]]; then
                    DIR=$PWD
                    FORWARD_HISTORY=$DIR:$FORWARD_HISTORY
                fi
                for iDir in $(seq 1 $(( -1 * $1 ))); do
                    DIR=${BACK_HISTORY%%:*}
                    BACK_HISTORY=${BACK_HISTORY#*:}
                    FORWARD_HISTORY=$DIR:$FORWARD_HISTORY
                done
                if [[ -d "$DIR" ]]; then
                    BACK_CD_HISTORY=$BACK_HISTORY
                    FORWARD_CD_HISTORY=$FORWARD_HISTORY
                    builtin cd "$DIR"
                fi
                OFFSET_CD_HISTORY=$(( $OFFSET_CD_HISTORY - $1 ))
            fi
        else
            echo "Stay right here."
        fi
    else
        if [[ $KEEP_CD_HISTORY -gt 0 ]]; then
            BACK_CD_HISTORY=$PWD:$BACK_CD_HISTORY
        else
            BACK_CD_HISTORY=$PWD:${BACK_CD_HISTORY%:*}
        fi

        if [[ $OFFSET_CD_HISTORY -eq 0 ]]; then
            if [[ $KEEP_CD_HISTORY -gt 0 ]]; then
                KEEP_CD_HISTORY=$(( $KEEP_CD_HISTORY - 1 ))
            fi
        else
            KEEP_CD_HISTORY=$(( $KEEP_CD_HISTORY + $OFFSET_CD_HISTORY ))
        fi

        OFFSET_CD_HISTORY=0
        FORWARD_CD_HISTORY=""
        builtin cd "$@"
    fi
}

# check the history in the stack
# only used for debugging
function checkcd
{
    echo "[BACK_CD_HISTORY]"
    echo $BACK_CD_HISTORY | tr ":" "\n"
    echo "[FORWARD_CD_HISTORY]"
    echo $FORWARD_CD_HISTORY | tr ":" "\n"
}

# list stored history
# calling cd after moving backwards will clear the future history
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

    local back_line_numbers=""
    if [[ $BACK_HISTORY_LENGTH -gt 0 ]]; then
        back_line_numbers=$(seq -s " " -t "\n" $((-$BACK_HISTORY_LENGTH)) 1 -1)
    fi

    local forward_line_numbers=""
    if [[ $FORWARD_HISTORY_LENGTH -gt 0 ]]; then
        forward_line_numbers=$(seq -s " " -t "\n" 0 1 $(($FORWARD_HISTORY_LENGTH-1)))
    fi

    # local line_numbers=$(echo -e "$(seq $((-$BACK_HISTORY_LENGTH)) -1)\n$(seq 0 $(($FORWARD_HISTORY_LENGTH-1)))")
    local line_numbers="$back_line_numbers$forward_line_numbers"
    line_numbers=$(echo $line_numbers | sed '/^$/d' | tr " " "\n")
    local filenames=$(echo ${history} | tr ":" "\n")
    if [[ $FORWARD_HISTORY_LENGTH -le 1 ]]; then
        filenames=$filenames" "
    fi
    if [[ $FORWARD_HISTORY_LENGTH -eq 0 ]]; then
        (paste  -d '\t' <(echo "$line_numbers")  <(echo "$filenames"))
    else
        (paste -d '\t' <(echo "$line_numbers")  <(echo "$filenames")) | grep "^.*\s$" -A $CD_HISTORY_LENGTH -B $CD_HISTORY_LENGTH
    fi
}

# fast advance to a directory containing a pattern
# not very fast in reality
function fcd
{
    if [[ $# -ge 1 ]]; then
        if [[ $1 == */* ]]; then
            cd "$(find . -path '*$1' -print -quit)"
        else
            cd "$(find . -type d -name $1 -print -quit)"
        fi
    fi
}

# up n levels
function up
{
    for i in $(seq 1 $1)
    do
        cd ..
    done
}

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
    clast ~/log
}

# data frame manipulation

function djson
{
    python -m json.tool $1
}

# print csv file in tidy format
function dcsv
{
    # local max_length=2048
    # local code_length=$(cat $1 | head -n100 | tr ',' '\n' | awk '{print length}' | sort -nr | head -n1)
    # local ncols=$(($max_length / $code_length))
    # local ccols=$(cat $1 | head -n 100 | awk '{print length}' | sort -nr | head -n1)

    local ncol=20
    local nrow=100
    OPTIND=1
    while getopts ":c:r:" opt; do
        case "$opt" in
            c) ncol="${OPTARG}";;
            r) nrow="${OPTARG}";;
            *) ;;
        esac
    done
    shift $((OPTIND-1))
    # only display the first $ncols columns
    cat $1 | head -n ${nrow} | cut -d',' -f1-${ncol} | perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' | column -t -s, | less -S
}

# print tsv file in tidy format
function dtsv
{
    local ncol=20
    local nrow=100
    OPTIND=1
    while getopts ":c:r:" opt; do
        case "$opt" in
            c) ncol="${OPTARG}";;
            r) nrow="${OPTARG}";;
            *) ;;
        esac
    done
    shift $((OPTIND-1))
    cat $1 | head -n ${nrow} | cut -d$'\t' -f1-${ncol} | perl -npe 's/((?<=\t)|(?<=^))\t/\t/g;' | column -t -s $'\t' | less  -F -S -X -K
}

# transpose a matrix
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

# sort a data table by the given column
# inputs: $1: filename, $2: column index to sort (start from 1)
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

# transfer the file to google shared drive
# you have to setup rclone first
# go to lab wiki to check how to do that
# function tfdrive
# {
#     local drive="sudmantlab"
#     OPTIND=1
#     while getopts ":d:" opt; do
#         case "$opt" in
#             d) drive="${OPTARG}";;
#             *) ;;
#         esac
#     done
#     shift $((OPTIND-1))
#     if [[ $# -ge 1 ]]; then
#         local file=$1
#         shift
#         if [[ -f $file ]]; then
#             rclone copy $@ $file ${drive}:projects/agingGeneRegulation/savio/$(date +'%Y%m%d')
#         elif [[ -d $file ]]; then
#             rclone copy $@ $file ${drive}:projects/agingGeneRegulation/savio/$(date +'%Y%m%d')/$(basename $file)
#         else
#             echo "$file: File/Folder not Found"
#         fi
#     else
#         echo "No file/folder to be transferred"
#     fi
# }

# # transfer files (obsolete but still in use)
# function tfsudmant
# {
#     if [[ $# -eq 1 ]]; then
#         rclone copy $1 sudmantlab:projects/agingGeneRegulation/savio/$(date +'%Y%m%d')
#     fi
# }
# function tfberkeley
# {
#     if [[ $# -eq 1 ]]; then
#         rclone copy $1 berkeley:sudmant/agingGeneRegulation/savio/$(date +'%Y%m%d')
#     fi
# }

function gcmount
{
      if [[ $# -lt 1 ]]; then
        echo "Error!" 1>&2
      else
        mkdir -p $HOME/data/$1
        gcsfuse $@ $HOME/data/$1
      fi
}

function gcdownload
{
    mkdir -p $HOME/data/genia_runs/$@
    gsutil -m rsync -r gs://genia-runs/$@ $HOME/data/downloaded_genia_runs/$@
}

export SC1_NODE="lb070dev"
function sc1
{
    local node=$SC1_NODE
    local nodes="lb021login lb045login lb069login lb093login lb022dev lb046dev lb070dev lb094dev"

    OPTIND=1
    while getopts ":lh" opt; do
        case "$opt" in
            l) echo $nodes | tr " " "\n"
               return;;
            h) echo
            "Use -l to show available nodes.
            By default $SC1_NODE is used.
            Change \$SC1_NODE to change to default node"
               return;;
            *) ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ $# -ge 1 ]]; then
        node=$1
    fi

    if [[ ${nodes[*]} =~ $node ]]; then
        ssh shengh4@$node.eth.rsshpc1.sc1.science.roche.com
    else
        echo "Requested node $node is not available."
    fi
}

function simc2scp()
{
    scp ${@:3} shengh4@simc2.rscc.science.roche.com:$1 $2
}

function scpsimc2()
{
    scp ${@:3} $1 shengh4@simc2.rscc.science.roche.com:$2
}

function sc1scp()
{
    scp ${@:3} shengh4@lb045login.eth.rsshpc1.sc1.science.roche.com:$1 $2
}

function scpsc1()
{
    scp ${@:3} $1 shengh4@lb045login.eth.rsshpc1.sc1.science.roche.com:$2
}

function demandscp()
{
    scp ${@:3} -i ~/.ssh/on_demand_instance shengh@${ON_DEMAND_INSTANCE}:$1 $2
}

function scpdemand()
{
    scp ${@:3} -i ~/.ssh/on_demand_instance $1 shengh@${ON_DEMAND_INSTANCE}:$2
}


# google could ai-platform
function gclast()
{
    local describe=1
    OPTIND=1
    while getopts ":s" opt; do
        case "$opt" in
            s) describe=0;;
            *) ;;
        esac
    done
    shift $((OPTIND-1))
    local hist=1
    if [[ $# -ge 1 ]]; then
        hist=$1
    fi
    jobid=$(gcloud ai-platform jobs list --filter $USER | awk -v n=$((hist+1)) 'NR==n {print $1}')
    if [[ $describe -eq 0 ]]; then
        gcloud ai-platform jobs stream-logs $jobid
    else
        gcloud ai-platform jobs describe $jobid
    fi
}

function dlfile()
{
    local gcpath="$1"
    local save_file=''
    if [[ $gcpath = *cycle* ]]; then
        if [[ $gcpath = *P_* ]]; then
            save_file="$(echo "$gcpath" | sed 's/^gs:\/\/.*\/\(.*\)\/\([0-9]*\)_.*_cycle\([0-9]*\)\/P_\([0-9]*\).*\/\(.*\)\.\(.*\)$/\5_\2-\1-\3-p\4\.\6/')"
        else
            save_file="$(echo "$gcpath" | sed 's/^gs:\/\/.*\/\(.*\)\/\([0-9]*\)_.*_cycle\([0-9]*\)\/\(.*\)\.\(.*\)$/\4_\2-\1-\3\.\5/')"
        fi
    else
        # support for SBX runs
        if [[ $gcpath = *P_* ]]; then
            save_file="$(echo "$gcpath" | sed 's/^gs:\/\/.*\/\(.*\)\/\([0-9]*\)_.*\/P_\([0-9]*\).*\/\(.*\)\.\(.*\)$/\4_\2-\1-p\3\.\5/')"
        else
            save_file="$(echo "$gcpath" | sed 's/^gs:\/\/.*\/\(.*\)\/\([0-9]*\)_.*\/\(.*\)\.\(.*\)$/\3_\2-\1\.\4/')"
        fi
    fi

    if [[ -f "${save_file}" ]]; then
        local idx=1
        local save_name=$(echo "$save_file" | sed 's/^\(.*\)\.\(.*\)$/\1/')
        local save_extension=$(echo "$save_file" | sed 's/^\(.*\)\.\(.*\)$/\2/')
        while true; do
            if [[ -f "${save_name}_${idx}.${save_extension}" ]]; then
                idx=$(( $idx + 1 ))
                continue
            fi
            gsutil -m cp "$gcpath" "${save_name}_${idx}.${save_extension}"
            break
        done

    else
        gsutil -m cp "$gcpath" "${save_file}"
    fi
}

function run_path()
{
    if [[ $# -le 0 ]]; then
        echo "At least one run id needed" >&2
        return 1
    fi
    run_id="$1"
    local station_id=""
    if [[ $run_id = *cycle* ]]; then
        station_id=$(echo $run_id | sed 's/^[0-9]*_[^_]*_.*_\(.*\)_.*_cycle[0-9]*$/\1/')
    else
        # support SBX
        station_id=$(echo $run_id | sed 's/^[0-9]*_[^_]*_.*_\(.*\)_.*$/\1/')
    fi
    local gcpath="gs://genia-runs/${station_id}/${run_id}/"
    echo "$gcpath"
}

function h5chunk()
{
    if [[ -z "$(command -v h5ls)" ]]; then
        echo "h5ls is required but not found."
        return -1
    fi
    local run_id=""
    local chunk_type=""
    local verbose=0
    local gcpath=""
    OPTIND=1
    while getopts ":r:c:vh" opt; do
        case "$opt" in
            r) run_id="${OPTARG}";;
            c) chunk_type="${OPTARG}";;
            h)
echo "h5chunk -r [run_id]  -c (1K|0.5p) [cell_ids...]
By default, it will search chunked_raw_data
Example:
h5chunk -r 200220_PEG-POL-HTP_01_mayall_WVD04R02C09_cycle09 b05r0253c0052 b05r0252c1486
Only search in chunked_raw_data_1K:
h5chunk -r 200220_PEG-POL-HTP_01_mayall_WVD04R02C09_cycle09 -c 1K b05r0253c0052 b05r0252c1486
"; return 0;;
            v) verbose=1;;
            *) ;;
        esac
    done
    shift $((OPTIND-1))
    if [[ $# -le 0 ]]; then
        echo "At least one cell id needed" >&2
        return 1
    fi
    local cell_ids=$@
    # run_id example: 200109_PEG-POL-HTP_02_callisto_WVL12R01C03_cycle01
    local station_id=""
    if [[ $run_id = *cycle* ]]; then
        station_id=$(echo $run_id | sed 's/^[0-9]*_[^_]*_.*_\(.*\)_.*_cycle[0-9]*$/\1/')
    else
        # support SBX
        station_id=$(echo $run_id | sed 's/^[0-9]*_[^_]*_.*_\(.*\)_.*$/\1/')
    fi
    if [[ -z $chunk_type ]]; then
        gcpath="gs://genia-runs/$station_id/$run_id/chunked_raw_data"
    else
        gcpath="gs://genia-runs/$station_id/$run_id/chunked_raw_data_$chunk_type"
    fi
    if [[ $(gsutil -q stat "$gcpath/**"; echo $?) -eq 1 ]]; then
        echo "Cannot find raw data: $gcpath" >&2
        return 2
    fi

    local tmp_dir=$(mktemp -d)
    if [[ $verbose -eq 1 ]]; then
        echo "Downloding h5 files to $tmp_dir"
    fi
    local smallest_h5=""
    local filename=""
    local chunkname=""
    local chunk_to_download=""
    local cellfound=0
    local chunk_folders=$(gsutil ls $gcpath)
    local nchunk=$(echo "$chunk_folders" | wc -l)
    local ntotal=$(( $nchunk * $# ))

    if [[ $verbose -eq 1 ]]; then
        echo "Number of cells to search: $#"
        echo "Number of chunks: $nchunk"
    fi

    local ichunk=0
    local icell=0
    local msg=""
    local errmsg=""

    clean_up(){
        echo -e "Cells found:$msg"
        echo -e "Cells not found:$errmsg"
        chunk_to_download=$(echo -e $chunk_to_download | uniq)
        echo -e "Chunks to download: $chunk_to_download"
        rm -rf $tmp_dir
        trap - SIGINT
        return -1
    }
    trap clean_up SIGINT
    for cellid in $(echo ${cell_ids}); do
        cellfound=0
        for chunkfolder in $(echo $chunk_folders); do
            if [[ $cellfound -eq 1 ]]; then
                break
            fi
            ichunk=$(( $ichunk + 1 ))
            chunkname="$(basename $chunkfolder)"
            mkdir -p "$tmp_dir/$chunkname"
            if [[ -f "$tmp_dir/$chunkname/*.h5" ]]; then
                # already downloaded
                filename=$(find "$tmp_dir/$chunkname/*.h5" | head -n 1)
            else
                # download data
                # gsutil ls has / at the end
                smallest_h5=$(gsutil ls -l "${chunkfolder}raw/" | sort -k 1 | awk 'NR==1 {print $NF}')
                gsutil -m cp "$smallest_h5" "$tmp_dir/$chunkname" >&/dev/null
                filename="$tmp_dir/$chunkname/$(basename $smallest_h5)"
            fi
            # show progress
            if [[ $verbose -eq 1 ]]; then
                echo -ne "Searching... $(( ( $ichunk + $nchunk * $icell ) * 100 / ${ntotal} ))%"'\r'
            fi
            if [[ -f $filename ]]; then
                if [[ $(h5ls "$filename/cells" | awk '{print $1}' | grep "$cellid") ]]; then
                    msg="$msg\n$cellid is found in $chunkname"
                    chunk_to_download="$chunk_to_download\n$chunkfolder"
                    cellfound=1
                fi
            else
                echo "Error! Downloaded h5 cannot be found: $filename from $smallest_h5"
                rm -rf $tmp_dir
                return 3
            fi
        done
        ichunk=0
        icell=$(( $icell + 1 ))
        if [[ $cellfound -eq 0 ]]; then
            errmsg="$errmsg\n$cellid cannot be found in $run_id"
        fi
    done
    chunk_to_download=$(echo -e $chunk_to_download | uniq)
    if [[ $verbose -eq 1 ]]; then
        echo "Searching... 100%"
        echo -e "Cells found:$msg"
        echo -e "Cells not found:$errmsg"
        echo -e "Chunks to download: $chunk_to_download"
    fi
    rm -rf $tmp_dir
    echo -e "$chunk_to_download"
}

function dlchunk()
{
    # gs://genia-runs/mayall/200220_PEG-POL-HTP_01_mayall_WVD04R02C09_cycle09/chunked_raw_data/chunk0000/
    local chunks=''
    if [[ $1 = gs://* ]]; then
        chunks=$1
    else
        chunks=$(cat $1)
    fi
    for chunk in $(echo $chunks); do
        local run_id=$(echo $chunk | sed 's/^gs:\/\/genia-runs\/[^\/]*\/\(.*\)\/chunked_raw_data.*$/\1/')
        local station_id=""
        if [[ $run_id = *cycle* ]]; then
            station_id=$(echo $run_id | sed 's/^[0-9]*_[^_]*_.*_\(.*\)_.*_cycle[0-9]*$/\1/')
        else
            # support SBX
            station_id=$(echo $run_id | sed 's/^[0-9]*_[^_]*_.*_\(.*\)_.*$/\1/')
        fi
        local chunk_id=$(echo $chunk | sed 's/^gs:\/\/genia-runs\/.*\/chunked_raw_data[^\/]*\/\([^\/]*\)\/*.*$/\1/')
        mkdir -p "$run_id/chunked_raw_data/$chunk_id"
        gsutil -m rsync -r "$chunk" "$run_id/chunked_raw_data/$chunk_id"
        gsutil -m cp "gs://genia-runs/$station_id/$run_id/ExpState.json" "$run_id"
    done
}

function upmodel()
{
    if [[ $# -ge 1 ]]; then
        local thisdir=${1%/}
    else
        local thisdir='.'
    fi

    cd ${thisdir}
    if [ -f git_commit_info_ckpt*.yml ]; then
        mv git_commit_info_ckpt*.yml git_commit_info.yml
    fi
    if [ -f run_config_ckpt*.yml ]; then
        mv run_config_ckpt*.yml run_config.yml
    fi
    if [[ ${thisdir} == "." ]]; then
        thisdir="${PWD##*/}"
    fi
    cd ..
    zip -vr "${thisdir}.zip" "$thisdir"
    gsutil -m cp "${thisdir}.zip" "gs://ac-analysis/ml-models/base-caller/dev"
}

function dlmodel(){
    local localdir=${1##*/}
    mkdir -p $localdir
    gsutil -m rsync -r $1 $localdir
}

function get_cell_chunk_id(){
    local data_path='./chunked_raw_data'
    local output_file='./cell_list.txt'
    if [[ $# -ge 1 ]]; then
        data_path="$1/chunked_raw_data"
    fi
    if [[ $# -ge 2 ]]; then
        output_file="$2"
    fi
    echo -e "cell_id\tchunk_id" > "$output_file"

    result=""
    for folder in $(ls $data_path); do
        if [[ -d "$data_path/$folder" ]]; then
            h5ls "$data_path/$folder/raw/multi_ubf.h5/cells" | awk -v chunk="$folder" '{print $1"\t"chunk}' >> "$output_file"
        fi
    done
}


# pull all
function gdmpull()
{
    for folder in $(ls -d */); do
        cd $folder
        git pull
        cd -1
    done
}

function h5cells()
{
    local data_path=""
    local output_file=""
    local chunk_index_file=""
    if [[ $# -ge 1 ]]; then
        local current_folder = $(realpath "$1")
        data_path="${current_folder}/chunked_raw_data"
        output_file="${current_folder}/cell_list.txt"
        chunk_index_file="${current_folder}/cell_chunk_index.txt"
    else
        data_path="$PWD/chunked_raw_data"
        output_file="$PWD/cell_list.txt"
        chunk_index_file="$PWD/cell_chunk_index.txt"
    fi

    # refresh current cell_list.txt
    echo "" > "${output_file}"
    echo "" > "${chunk_index_file}"

    for chunk_folder in $(ls "$data_path"); do
        h5ls "${data_path}/${chunk_folder}/raw/multi_ubf.h5/cells" | awk -v chunk='${chunk_folder}' '{print $1}' >> "${output_file}"
        h5ls "${data_path}/${chunk_folder}/raw/multi_ubf.h5/cells" | awk -v chunk='${chunk_folder}' '{print $1"\t"chunk}' >> "${chunk_index_file}"
    done
}

function dlcells()
{
    local bookmarks=""
    local cell_ids=""
    local run_id=""
    local output_dir="chunked_raw_data_test";
    local allow_missing=0
    local miss_cell=0
    local subsampling=""

    OPTIND=1
    while getopts ":b:c:o:r:mvh" opt; do
        case "$opt" in
            b) bookmarks="${OPTARG}";;
            c) subsampling="${OPTARG}";;
            o) output_dir="${OPTARG}";;
            r) run_id="${OPTARG}";;
            h)
echo "dlcells -r [run_id] -b [cell_list.txt] [cell_ids...]
By default, it will search chunked_raw_data
Example:
h5chunk -r 200220_PEG-POL-HTP_01_mayall_WVD04R02C09_cycle09 b05r0253c0052 b05r0252c1486
"; return 0;;
            m) allow_missing=1;;
            v) verbose=1;;
            *) ;;
        esac
    done
    shift $((OPTIND-1))
    if [[ $# -le 0 ]] && [[ -z $bookmarks ]]; then
        echo "At least one cell id needed" >&2
        return 1
    fi
    if [[ $# -le 0 ]] && ! [[ -z $bookmarks ]]; then
        echo "Cannot use bookmarks and cell ids at the same time" >&2
        return 2
    fi

    if [[ -z $bookmarks ]]; then
        cell_ids="$@"
    else
        cell_ids="$(cat '$bookmarks' | tr '\n' ' ')"
    fi

    # check existing data to see if cells already exist in current dataset
    for cell_id in "${cell_ids}"; do

    done

    for chunk_path in $(h5chunk -r "$run_id" -c "${subsampling}" "$cell_ids"); do
        echo "Downloading chunk: $chunk_path."
        dlchunk "$chunk_path" || miss_cell=1
        if [[ $miss_cell -eq 1 ]]; then
            echo "$chunk_path cannot be found."
            if [[ $allow_missing -eq 0 ]]; then
                return 1
            fi
        fi
    done


    if [[ "$output_dir" == */ ]]; then
        output_dir=${output_dir::-1}
    fi

    if [[ "$output_dir" != /* ]]; then
        output_dir="$PWD/${run_id}/${output_dir}"
    fi
    rm -rf "${output_dir}"
    mkdir -p "${output_dir}"
    extract-h5-dataset --src ${run_id}/chunked_raw_data/chunk*/raw/*.h5 --cells ${cell_ids} --allow-missing -o ${output_dir}

    # set up raw data structure like ACAP
    mkdir -p "${output_dir}/chunk99/raw"
    mv ${output_dir}/*.h5 ${output_dir}/chunk99/raw

    echo ${output_dir}

}


function dlink()
{
    if [[ $# -eq 0 ]]; then
        echo "No input link is found." >&2
        return 1
    fi

    local filename="annotations.h5"

    OPTIND=1
    while getopts ":n:" opt; do
        case "$opt" in
            n) filename="${OPTARG}";;
            *) ;;
        esac
    done
    shift $((OPTIND-1))

    local link="$1"
    local buck_link=$(echo "${link%%/}/$filename" | sed 's/^.*\(genia-runs\/.*\)$/gs:\/\/\1/')
    dlfile "$buck_link"
}

function lsize()
{
    # list actual file size of the directory
    local directiory='./'
    if [[ $# -ge 1 ]]; then
        directiory=$1
    fi
    du -h --max-depth=1 ${directiory} | sort -hr
}
