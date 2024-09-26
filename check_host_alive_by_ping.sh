#!/bin/bash


TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
IP_ADDR_MAX_RANGE_C=255
IP_ADDR_FIELD_C='192.168.179.'
IP_DOWN_LOG_FILE="down_log_${TIMESTAMP}.log"
IP_UP_LOG_FILE="up_log_${TIMESTAMP}.log"

PING_COUNT=3
PING_INTERVAL=3
PING_INTERVAL_TIMEOUT=5

: > "$IP_DOWN_LOG_FILE"
: > "$IP_UP_LOG_FILE"


##############################################
# Run the ping command to check the online status of the host
# The ping command will initiate $PING_COUNT requests 
# with an interval of $PING_INTERVAL and a timeout period of $PING_INTERVAL_TIMEOUT.
# If all requests fail at $PING_COUNT, a log is generated and an online log is kept
#
# Globals:
#   PING_COUNT
#   PING_INTERVAL
#   PING_INTERVAL_TIMEOUT
#
# Arguments:
#   IP_ADDRESS: $1
#
# Returns:
#   None
##############################################
check_alive_by_ping() {
    let cont=0
    for ((i=1; i<4; i++)); do  
        if ping -c "$PING_COUNT" -i "$PING_INTERVAL" -W "$PING_INTERVAL_TIMEOUT" "$1" &> /dev/null; then
           let cont++
        fi
        sleep 1
    done
    
    if [ $cont -eq 3 ]; then
        echo "      $1 is Down !" | tee -a "$IP_DOWN_LOG_FILE"
    else
        echo "      $1 is Up !" >> "$IP_UP_LOG_FILE"
    fi
    return 0
}


for i in $(seq 1 "$IP_ADDR_MAX_RANGE_C");do
    check_alive_by_ping "${IP_ADDR_BODY}${i}"
done &
