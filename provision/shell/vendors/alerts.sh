#!/bin/bash
#
# alerts.sh
#


# Colors
# ---------------------------------------
C_RED='\033[0;31m'
C_YELLOW='\033[1;33m'
C_NC='\033[0m'              # No Color
C_GREEN='\033[0;32m'
C_BRN='\033[0;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[0;97m'

export C_RED C_YELLOW C_NC C_GREEN C_BRN C_BLUE C_MAGENTA C_CYAN C_WHITE

# Alerts
# $1 : --warning, --info, --success, --error
# $2 : message
function alert() {
    level=$1
    msg=$2
    if [[ "$level" == '--warning' ]]; then 
        alert_warning "${msg}"
    elif [[ $level == '--info' ]]; then
        alert_info "${msg}"
    elif [[ $level == '--success' ]]; then
        alert_success "${msg}"
    elif [[ $level == '--error' ]]; then
        alert_error "${msg}"
    else
        alert_info "${msg}"
    fi
}

function alert_warning() {
    MSG=$1
    echo -e "${C_YELLOW} ${MSG} ${C_NC}"
}

function alert_error() {
    MSG=$1
    echo -e "${C_RED} ${MSG} ${C_NC}"
}

function alert_info() {
    MSG=$1
    echo -e "${C_BLUE} ${MSG} ${C_NC}"
}

function alert_success() {
    MSG=$1
    echo -e "${C_GREEN} ${MSG} ${C_NC}"
}

function alert_line(){
    echo "==============================="
}