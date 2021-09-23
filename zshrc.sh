# .BASHRC
setopt interactivecomments
# DO NOT echo anything, otherwise scp won't work
# echo ".bashrc is sourced"

# Source global definitions
# if [ -f /etc/bashrc ]; then
#     . /etc/bashrc
# fi

# Source global aliases
if [ -f ~/.zaliases ]; then
    . ~/.zaliases
fi

# Source global aliases
if [ -f ~/.zfunctions ]; then
    . ~/.zfunctions
fi

# # Source slurm utilities
# if [ -f ~/.bash_savio ] & [[ $HOSTNAME != dtn* ]]; then
#     . ~/.bash_savio
# fi

# Store some useful path to data, code, and misc
if [ -f ~/.zpath ]; then
    . ~/.zpath
fi

# Source global environment variables and modules
if [ -f ~/.profile ]; then
    . ~/.profile
fi

# ssh keys
eval "$(ssh-agent -s)" > /dev/null
for keypath in $(ls ~/.ssh); do
    if [[ ${keypath} == *.pub ]]; then
        ssh-add -K ~/.ssh/${keypath%%.pub} 2>/dev/null
    fi
done

ssh-add -K ~/.ssh/id_rsa_sc1 2>/dev/null
ssh-add -K ~/.ssh/id_rsa_public_github 2>/dev/null
ssh-add -K ~/.ssh/id_rsa_simc2 2>/dev/null

# export environment variables
# export TMPDIR=~/tmp

# Google Cloud SDK
export IS_CLOUD_PROCESSING=1
export GOOGLE_APPLICATION_CREDENTIALS=/Users/shengh4/.keys/rsc-general-computing-0e8ffaa7ddf1_allaccess.json
gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" 2>/dev/null
gcloud config set project rsc-general-computing 2>/dev/null

if [[ -z $TMUX ]]; then
	export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH:/Users/shengh4/Applications/"
fi

export PATH="/Library/TeX/texbin:"$PATH

# Do not ask for confirmation to remove path with *
setopt rmstarsilent
# export GREP_OPTIONS='--color=always'
# export GREP_COLOR='1;35;40'
# export PS1="\W $ "
export PS1="%1~ \$ "
export CPATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk/usr/include"
export ML_MODEL="gs://ac-analysis/ml-models/base-caller/dev"
export ACAP_GENOME="gs://ac-analysis/genomes/dev"
export TMUX_TMPDIR="/Users/shengh4/.tmux_tmp"
# on demand instance
export ON_DEMAND_INSTANCE=10.159.230.92

# load global modules
# module load git
# module load gcc/6.3.0
# module load java
# # module load gsl
# module load rclone

# Don't activate conda upon openning, otherwise activating conda in tmux will be Python 2
if [[ ! -z $TMUX ]]; then
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/Users/shengh4/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/Users/shengh4/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/Users/shengh4/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/Users/shengh4/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<

    # activate acap_dev
    if [[ $(conda env list | grep acap_dev | wc -l) -ge 1 ]]; then
        conda activate acap_dev
    fi
    # stop anti-virus while logging in
    # sep stop
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Applications/google-cloud-sdk/path.zsh.inc' ]; then . '/Applications/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Applications/google-cloud-sdk/completion.zsh.inc' ]; then . '/Applications/google-cloud-sdk/completion.zsh.inc'; fi
