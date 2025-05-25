#!/bin/bash


DEFAULT_PASS="SambaPass123"

for group in company accounting engineering leadership technology sales; do
    if ! getent group "$group" >/dev/null; then
        if ! groupadd "$group"; then
            echo "ERROR: Failed to create group $group"
            exit 1
        fi
        echo "Created group: $group"
    else
        echo "Group $group already exists"
    fi
done


create_user() {
    local username=$1
    local primary_group=$2
    local home_dir=$3
    local password=$4
    shift 4
    local secondary_groups="$*"
    
    secondary_groups=$(echo "$secondary_groups" | tr ' ' ',')

    echo "Creating user $username with primary group $primary_group and secondary groups: $secondary_groups"
    
    if ! getent group "$primary_group" >/dev/null; then
        echo "ERROR: Primary group $primary_group does not exist"
        exit 1
    fi

    local useradd_cmd="useradd -m -d '$home_dir' -s /bin/bash -g '$primary_group'"
    
    if [ -n "$secondary_groups" ]; then
        useradd_cmd="$useradd_cmd -G '$secondary_groups'"
    fi
    
    useradd_cmd="$useradd_cmd '$username'"
    
    if ! eval "$useradd_cmd"; then
        echo "ERROR: Failed to create user $username"
        exit 1
    fi

    if ! (echo "$password"; echo "$password") | smbpasswd -a -s "$username"; then
        echo "ERROR: Failed to set Samba password for $username"
        exit 1
    fi

    mkdir -p "$home_dir"
    if ! chown "$username:$primary_group" "$home_dir"; then
        echo "ERROR: Failed to chown $home_dir to $username:$primary_group"
        exit 1
    fi
    chmod 0700 "$home_dir"

}


create_user acct_user1 accounting /samba/departments/accounting/users/acct_user1 "$DEFAULT_PASS" company
create_user acct_user2 accounting /samba/departments/accounting/users/acct_user2 "$DEFAULT_PASS" company
create_user eng_user1 engineering /samba/departments/engineering/users/eng_user1 "$DEFAULT_PASS" company
create_user eng_user2 engineering /samba/departments/engineering/users/eng_user2 "$DEFAULT_PASS" company
create_user lead_user1 leadership /samba/departments/leadership/users/lead_user1 "$DEFAULT_PASS" company accounting engineering technology sales
create_user lead_user2 leadership /samba/departments/leadership/users/lead_user2 "$DEFAULT_PASS" company accounting engineering technology sales
create_user tech_user1 technology /samba/departments/technology/users/tech_user1 "$DEFAULT_PASS" company
create_user tech_user2 technology /samba/departments/technology/users/tech_user2 "$DEFAULT_PASS" company
create_user sales_user1 sales /samba/departments/sales/users/sales_user1 "$DEFAULT_PASS" company
create_user sales_user2 sales /samba/departments/sales/users/sales_user2 "$DEFAULT_PASS" company
