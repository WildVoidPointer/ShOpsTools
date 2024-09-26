#!/bin/bash


# Define network profile and runtime information.
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
# NET_PROFILE_PATH='./test.yaml'
NET_PROFILE_PATH='/etc/netplan/00-installer-config.yaml'

declare -A ETHERNETS_INFO
ETHERNETS_INFO["ETHERNET_NAME"]='ens33'

ETHERNETS_INFO["DHCP4_STATUS"]='no'

ETHERNETS_INFO["GATEWAY4"]='192.168.179.2'

ETHERNETS_INFO["IP_ADDRESSES"]="192.168.179.140/24"

ETHERNETS_INFO["DNS_ADDRESSES"]="8.8.8.8, 114.114.114.114, 223.6.6.6"


# Splits associative array keys into ordinary arrays.
declare -a IP_ADDRESSES
declare -a DNS_ADDRESSES

DEFAULT_IFS="$IFS"
IFS=', ' read -r -a IP_ADDRESSES <<< "${ETHERNETS_INFO["IP_ADDRESSES"]}"
IFS=', ' read -r -a DNS_ADDRESSES <<< "${ETHERNETS_INFO["DNS_ADDRESSES"]}"
IFS="$DEFAULT_IFS"


####################################
# Backup the target network profile.
#
# Globals:
#   NET_PROFILE_PATH
#   TIMESTAMP
#
# Arguments:
#   None
#
# Returns:
#   None
####################################
target_netplan_config_backup() {
    if [ -z "$NET_PROFILE_PATH" ]; then
        echo "      ERROR: NET_PROFILE_PATH is not defined or empty."
        exit 1
    fi

    if [ -f "$NET_PROFILE_PATH" ]; then
        new_f_name="${NET_PROFILE_PATH}-${TIMESTAMP}.npconf.bak"
        if [ ! -f "$new_f_name" ]; then
            sudo cp -ar "$NET_PROFILE_PATH" "$new_f_name"
        else
            read -p "      Whether to overwrite duplicate files? [y/n]: " overwrite_flag
            overwrite_flag=$(echo "$overwrite_flag" | tr '[:upper:]' '[:lower:]')
            case "$overwrite_flag" in
                y)
                    echo "      The overwrite operation will be performed !!!"
                    sudo cp -ar "$NET_PROFILE_PATH" "$new_f_name"
                ;;
                n)
                    read -p "      Please enter a new file name: " new_f_name
                    if [ -z "$new_f_name" ]; then
                        echo "ERROR: New file name cannot be empty."
                        exit 1
                    fi
                    f_path=$(dirname $NET_PROFILE_PATH)
                    sudo cp -ar "$NET_PROFILE_PATH" "${f_path}/${new_f_name}"
                ;;
                *)
                    echo "      ERROR: To exit the configuration process !!!"
                    exit 1
                ;;
            esac
        fi
    else
        echo "      WARNING: $NET_PROFILE_PATH does not exist."
    fi
}


####################################
# Generate the new configuration file content line by line.
#
# Globals:
#   NET_PROFILE_PATH
#
# Arguments:
#   ConfigLine: $1
#
# Returns:
#   None
####################################
current_config_generator() {
    echo "$1" | sudo tee -a "$NET_PROFILE_PATH" &> /dev/null
}


####################################
# The IP address is generated repeatedly to enter the configuration file.
#
# Globals:
#   NET_PROFILE_PATH
#   IP_ADDRESSES
#
# Arguments:
#   None
#
# Returns:
#   None
####################################
ethernets_ip_address_append() {
    current_config_generator "      addresses:"
    for ip in "${IP_ADDRESSES[@]}"
    do
        current_config_generator "        - $ip"
    done
}


####################################
# The DNS address is generated repeatedly to enter the configuration file.
#
# Globals:
#   NET_PROFILE_PATH
#   DNS_ADDRESSES
#
# Arguments:
#   None
#
# Returns:
#   None
####################################
ethernets_dns_address_append() {
    current_config_generator "      nameservers:"
    current_config_generator "        addresses:"
    for ip in "${DNS_ADDRESSES[@]}"
    do
        current_config_generator "          - $ip"
    done
}


####################################
# Generate a new network profile.
#
# Globals:
#   ETHERNETS_INFO
#   NET_PROFILE_PATH
#
# Arguments:
#   None
#
# Returns:
#   None
####################################
netplan_profile_generator() {

    printf "# Change time: $TIMESTAMP\n# \
Modifier: $SUDO_USER\n# \
Detail: $(id -u $SUDO_USER) $(id -g $SUDO_USER)\n" \
    > "$NET_PROFILE_PATH"

    cat <<EOF >> "$NET_PROFILE_PATH"
network:
  version: 2
  ethernets:
EOF

    current_config_generator "    ${ETHERNETS_INFO["ETHERNET_NAME"]}:"
    current_config_generator "      dhcp4: ${ETHERNETS_INFO["DHCP4_STATUS"]}"
    current_config_generator "      gateway4: ${ETHERNETS_INFO["GATEWAY4"]}"

    ethernets_ip_address_append
    ethernets_dns_address_append

}


####################################
# Output change result.
#
# Globals:
#   NET_PROFILE_PATH
#
# Arguments:
#   None
#
# Returns:
#   None
####################################
printf_changed_net_profile_result() {
    echo '      Output change result'
    DEFAULT_IFS="$IFS"
    echo '=================================================='
    while IFS= read -r line; do
        echo "      |$line      "
    done < "$NET_PROFILE_PATH"
    echo '=================================================='
    IFS="$DEFAULT_IFS"
    sudo netplan apply
}


target_netplan_config_backup
netplan_profile_generator
printf_changed_net_profile_result
