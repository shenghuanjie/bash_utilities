#.bash_aliases

# initialize gitlog
source ~/.git-prompt.sh

# initialize gitlog
alias gitlog='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'

# setup alias
# alias scratch="cd /global/scratch/$USER"
# alias psudmant="cd /global/home/users/psudmant"
# alias pscratch="cd /global/scratch/psudmant"
# Unix alias
# list all hidden files
alias ls="ls -G"
alias lh="ls -d .?*"
# list more information including size in MB
alias la="ls -lash"
# always use absolute path tracing down symbolic link
alias pwd="pwd -P"
# always use color when grep
alias grep="grep --color=always"

# git alias, lazy functions
alias gadd="git add -A"
alias gcommit="git commit -m 'lazy commit'"
alias gpush="git push origin master"
alias gpull="git pull origin master"
alias gstatus="git status"
# remove added files
alias grm="git rm --cached"
# sync to the remote
alias gsync="
git fetch --all
git reset --hard origin/mast
git pull origin master
"
# download remote
alias gdown="
git stash
git pull origin master
git stash pop
"
# upload everything to remote
alias gup="
git add .
git commit -m 'lazy commit'
git push origin master
"

# google cloud
alias gcstart="gcloud auth activate-service-account --key-file=/Applications/google-cloud-sdk/credential/rsc-general-computing-fdc599384065.json"
alias gcinit="gcloud init"
alias gclist="gcloud auth list"
# ai-platform
alias gcjobs="gcloud ai-platform jobs list --filter $USER"
alias gcstream="gcloud ai-platform jobs stream-logs"
alias gcdescribe="gcloud ai-platform jobs describe"

# simc2 node
alias simc2="ssh shengh4@simc2.rscc.science.roche.com"

# mount different drives
alias mtrain="
mkdir -p $HOME/data/training_runs_data
umount -f $HOME/data/training_runs_data
gcsfuse training_runs_data $HOME/data/training_runs_data
"

alias mrnn="
mkdir -p $HOME/data/rnn_training
umount -f $HOME/data/rnn_training
gcsfuse rnn_training $HOME/data/rnn_training
"

alias mgenia="
mkdir -p $HOME/data/genia-runs
umount -f $HOME/data/genia-runs
gcsfuse --implicit-dirs genia-runs $HOME/data/genia-runs
"

alias msimc2="
mkdir -p $HOME/data/simc2
umount -f $HOME/data/simc2
sshfs -o allow_other,defer_permissions shengh4@simc2.rscc.science.roche.com:/nfshome/us-central1-b/shengh4 $HOME/data/simc2
"

alias msc1="
mkdir -p $HOME/data/sc1
umount -f $HOME/data/sc1
sshfs -o allow_other,defer_permissions shengh4@lb093login.eth.rsshpc1.sc1.science.roche.com:/home/shengh4 $HOME/data/sc1
"

alias gdm_conda='conda run -n gdm_env gdm'
alias test-ac-pipeline='run-ac-pipeline --skip-calibration --skip-single-pore-detection'
alias develop_acap='
cd ~/projects/acap_src/ac-analysis
python setup.py develop
cd ~/projects/acap_src/data-handling
python setup.py develop
cd ~/projects/acap_src/rnn-base-caller
python setup.py develop
cd ~/projects/acap_src/desktop-dvt
python setup.py develop
sleep 0.1
cd -4
'
alias develop_rnn='
cd ~/projects/dl-training-data
python setup.py develop
sleep 0.1
cd -1
'
alias lsh5='python ~/.pyscript gsutil_ls_h5'

# tmux
alias tmux_history='tmux capture-pane -pS -1000000000'

# reload tmux
alias tmux_restore='tmux source-file ~/.tmux.conf'

# monitor cpu temperature
alias cpu_temp='sudo powermetrics --samplers smc |grep -i "CPU die temperature"'

# alias docker_run='docker run -i -t [IMAGE_ID] /bin/bash'

alias demand='ssh shengh@$ON_DEMAND_INSTANCE'

# get run model name or commit id
alias runinfo='python ~/projects/shengh4-playground/utils/print_model_name.py'

# command finished with email notification
alias notify='echo "Job completed on machine at $(hostname)@$(ifconfig | grep -E "(inet.*netmask.*broadcast.*|inet addr.*Bcast.*Mask.*)")" | mail -s "Remote Job Completed" huanjie.sheng@roche.com'
# alias notify='echo "Job completed on machine at $(hostname)@$(ip a | grep -E "inet .* brd (.*) scope global dynamic")" | mail -s "Remote Job Completed" huanjie.sheng@roche.com'
