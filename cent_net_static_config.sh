#!/bin/bash
#
# This script is used to configure a static network for a single Centos.

# Define the network configuration file that the script will execute.
DEFAULT_NET_CONF_PATH='/etc/sysconfig/network-scripts'
DEFAULT_NETWORK_CONFIG_FILE=$(find $DEFAULT_NET_CONF_PATH -name "ifcfg-ens*" ! -name "*bak")
CHANGED_LOGS_LIST=()

# Set your own DNS server information.
declare -A USER_DEF_DNS_ADDRS
USER_DEF_DNS_ADDRS['DNS1']='114.114.114.114'
USER_DEF_DNS_ADDRS['DNS2']='8.8.8.8'
USER_DEF_DNS_ADDRS['DNS3']='223.6.6.6'

# Set your own static network information.
declare -A USER_SETTING_CONF
USER_SETTING_CONF['IPADDR']='192.168.179.140'
USER_SETTING_CONF['NETMASK']='255.255.255.0'
USER_SETTING_CONF['GATEWAY']='192.168.179.2'

# Details of the script's return code.
declare -A EXIT_STATUS_CODE
EXIT_STATUS_CODE['PATH_ERROR']=1
EXIT_STATUS_CODE['LOG_ERROR']=2
EXIT_STATUS_CODE['BACKUP_ERROR']=3
EXIT_STATUS_CODE['MODE_CONF_ERROR']=4
EXIT_STATUS_CODE['STATIC_CONF_ERROR']=5
EXIT_STATUS_CODE['DNS_CONF_ERROR']=6
EXIT_STATUS_CODE['NET_LINK_ERROR']=7


############################################################
# Print the runtime error log, exit code and exit script.
# Globals:
#   None
# Arguments:
#   1: string, Run error location
#   2: int, Exit Code
# Returns:
#   int, Exit Code
############################################################
print_error_logs_and_exit() {
    echo "Error location:  $1, Exit code:  $2"
    exit "$2"
}


########################################################
# Verify that the configuration file path is correct.
# Globals:
#   DEFAULT_NETWORK_CONFIG_FILE
#   EXIT_STATUS_CODE[PATH_ERROR]
# Arguments:
#   None
# Returns:
#   0 or None
########################################################
check_config_path_correct() {
    if [ -f "$DEFAULT_NETWORK_CONFIG_FILE" ] && [ -w "$DEFAULT_NETWORK_CONFIG_FILE" ]; then
        if [ $(wc -l < "$DEFAULT_NETWORK_CONFIG_FILE") -eq 1 ]; then
            append_operate_log_to_list 'The path of Network-configuration file exists!'
            return 0
        fi
    else
        print_error_logs_and_exit 'check_config_path_correct' ${EXIT_STATUS_CODE[PATH_ERROR]}
    fi
}


###############################################################
# Append script runtime logs to the CHANGED_LOGS_LIST array.
# Globals:
#   CHANGED_LOGS_LIST
# Arguments:
#   1: string, Runtime log
# Returns:
#   0 or None
################################################################
append_operate_log_to_list() {
    echo "$1"
    CHANGED_LOGS_LIST+=("$1")
    [ $? -ne 0 ] && print_error_logs_and_exit 'append_operate_log_to_list' ${EXIT_STATUS_CODE['LOG_ERROR']} || return 0
}


###############################################
# Example Modify the NIC boot configuration.
# Globals:
#   DEFAULT_NET_CONF_PATH
#   DEFAULT_NETWORK_CONFIG_FILE
#   EXIT_STATUS_CODE[MODE_CONF_ERROR]
# Arguments:
#   None
# Returns:
#   0 or None
###############################################
modify_net_default_setting() {
    cd "$DEFAULT_NET_CONF_PATH" || exit ${EXIT_STATUS_CODE[MODE_CONF_ERROR]}
    sudo sed -i -e '/^ONBOOT/c ONBOOT=yes' \
            -e '/^BOOTPROTO/c BOOTPROTO=static' ${DEFAULT_NETWORK_CONFIG_FILE}
    [ $? -ne 0 ] && print_error_logs_and_exit 'modify_net_default_setting' ${EXIT_STATUS_CODE[MODE_CONF_ERROR]} || \
    append_operate_log_to_list "ONBOOT and BOOTPROTO status is changed!"
}


###########################################
# Configuring the DNS Service.
# Globals:
#   DEFAULT_NET_CONF_PATH
#   DEFAULT_NETWORK_CONFIG_FILE
#   EXIT_STATUS_CODE[MODE_CONF_ERROR]
#   EXIT_STATUS_CODE[DNS_CONF_ERROR]
# Arguments:
#   None
# Returns:
#   0 or None
###########################################
configure_dns_server() {
    cd "$DEFAULT_NET_CONF_PATH" || exit ${EXIT_STATUS_CODE[MODE_CONF_ERROR]}
    for dns_name in "${!USER_DEF_DNS_ADDRS[@]}"
    do
        line_conf="${dns_name}=${USER_DEF_DNS_ADDRS[$dns_name]}"
        if cat "$DEFAULT_NETWORK_CONFIG_FILE" | grep "$dns_name" &> /dev/null
        then
            sudo sed -i -e "/^${dns_name}/c ${line_conf}" "$DEFAULT_NETWORK_CONFIG_FILE" || \
            print_error_logs_and_exit "configure_dns_server  =>  $dns_name" ${EXIT_STATUS_CODE[DNS_CONF_ERROR]} && \
            append_operate_log_to_list "${dns_name} is replaced successfully!"
        else
            echo "$line_conf" | sudo tee -a "$DEFAULT_NETWORK_CONFIG_FILE" || \
            print_error_logs_and_exit "configure_dns_server  =>  $dns_name" ${EXIT_STATUS_CODE[DNS_CONF_ERROR]} && \
            append_operate_log_to_list "${dns_name} is added successfully!"
        fi
    done
    return 0
}


###########################################
# Configuring the Static Network.
# Globals:
#   DEFAULT_NET_CONF_PATH
#   DEFAULT_NETWORK_CONFIG_FILE
#   EXIT_STATUS_CODE[MODE_CONF_ERROR]
#   EXIT_STATUS_CODE[STATIC_CONF_ERROR]
# Arguments:
#   None
# Returns:
#   0 or None
###########################################
configure_net_static() {
    cd "$DEFAULT_NET_CONF_PATH" || exit ${EXIT_STATUS_CODE[MODE_CONF_ERROR]}
    for setting_name in "${!USER_SETTING_CONF[@]}"
    do
        line_conf="${setting_name}=${USER_SETTING_CONF[$setting_name]}"
        if cat "$DEFAULT_NETWORK_CONFIG_FILE" | grep $setting_name &> /dev/null
        then
            sudo sed -i -e "/^${setting_name}/c ${line_conf}" ${DEFAULT_NETWORK_CONFIG_FILE} || \
            print_error_logs_and_exit "configure_net_static  =>  $setting_name" ${EXIT_STATUS_CODE[STATIC_CONF_ERROR]} && \
            append_operate_log_to_list "${setting_name} is replaced successfully!"
        else
            echo "$line_conf" | sudo tee -a "$DEFAULT_NETWORK_CONFIG_FILE" || \
            print_error_logs_and_exit "configure_net_static  =>  $setting_name" ${EXIT_STATUS_CODE[STATIC_CONF_ERROR]} && \
            append_operate_log_to_list "${setting_name} is added successfully!"
        fi
    done
    return 0
}


#######################################
# Back up network configuration file.
# Globals:
#   DEFAULT_NET_CONF_PATH
#   DEFAULT_NETWORK_CONFIG_FILE
#   EXIT_STATUS_CODE[MODE_CONF_ERROR]
#   EXIT_STATUS_CODE[BACKUP_ERROR]
# Arguments:
#   None
# Returns:
#   0 or None
#######################################
backup_net_conf_file() {
    cd "$DEFAULT_NET_CONF_PATH" || exit ${EXIT_STATUS_CODE[MODE_CONF_ERROR]}
    if ! [ -e "${DEFAULT_NETWORK_CONFIG_FILE}.bak" ]
    then
        sudo cp -ar "$DEFAULT_NETWORK_CONFIG_FILE" "${DEFAULT_NETWORK_CONFIG_FILE}.bak"
        echo 'Network interface configuration file is backed up successfully!'
        echo "The path of Network-Configuration backup file is: $(readlink -f ${DEFAULT_NETWORK_CONFIG_FILE}.bak)"
    else
        read -p 'Whether to continue overwriting backup files that have been saved, [yes/no]  ' overwrite_flag
        shopt -s nocasematch

        case "$overwrite_flag" in 
            "yes")
                sudo cp -ar "$DEFAULT_NETWORK_CONFIG_FILE" "${DEFAULT_NETWORK_CONFIG_FILE}.bak"
                [ $? -ne 0 ] && print_error_logs_and_exit "overwriting backup files" ${EXIT_STATUS_CODE[BACKUP_ERROR]} || \
                append_operate_log_to_list "${DEFAULT_NETWORK_CONFIG_FILE}.bak that have been overwriting!"
                ;;

            "no")
                read -p 'Whether to create a new file to save the current configuration file, [yes/no] ' set_new_flag
                
                if [[ "$set_new_flag" = "yes" ]]; then
                    echo 'The new backup file name formate is: {new_back_name}_network_config.bak, you just need enter new_back_name'
                    read -p 'Enter a new file name for new Network-Configuration backup file' new_back_name
                    sudo cp -ar "$DEFAULT_NETWORK_CONFIG_FILE" "${new_back_name}_network_config.bak"
                    [ $? -ne 0 ] && print_error_logs_and_exit "set new backup files" ${EXIT_STATUS_CODE[BACKUP_ERROR]} || \
                    append_operate_log_to_list "${new_back_name}_network_config.bak is added!"
                
                elif [[ "$set_new_flag" = "no" ]]; then
                    echo 'The current configuration file is not backed up !'
                fi
                ;;

            *)
                append_operate_log_to_list 'No backup operation is performed !!!'
        esac
        shopt -u nocasematch
    fi
    return 0
}


#########################################################
# Check run logs and service configuration results.
# Globals:
#   DEFAULT_NET_CONF_PATH
#   DEFAULT_NETWORK_CONFIG_FILE
#   EXIT_STATUS_CODE[MODE_CONF_ERROR]
#   EXIT_STATUS_CODE[NET_LINK_ERROR]
# Arguments:
#   None
# Returns:
#   0 or None
#########################################################
print_runtime_logs_and_check_server() {
    for ((i=0; i<50; i++)); do printf "="; done
    echo ''
    sudo service network restart
    ip a
    ping -c 4 -w 5 baidu.com
    [ $? -ne 0 ] && \
    print_error_logs_and_exit 'Test failed' ${EXIT_STATUS_CODE[NET_LINK_ERROR]} || \
    append_operate_log_to_list 'Test succeeded!'
    echo ''
    for ((i=0; i<50; i++)); do printf "="; done
    echo '' 
    for log in "${CHANGED_LOGS_LIST[@]}"; do echo "$log"; done
    for ((i=0; i<50; i++)); do printf "="; done
    echo ''
    echo 'Complete!'
    echo ''
}


# At the beginning of the operative part.
check_config_path_correct
backup_net_conf_file
modify_net_default_setting
configure_net_static
configure_dns_server
print_runtime_logs_and_check_server
# At the end of the operative part.
