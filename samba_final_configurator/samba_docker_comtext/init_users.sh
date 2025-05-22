#!/bin/bash


DEFAULT_PASS="SambaPass123"


for group in company accounting engineering leadership technology sales; do
    groupadd "$group"
done


create_user() {
    username=$1
    primary_group=$2
    home_dir=$3
    password=$4
    shift 4
    secondary_groups=$*

    useradd -m -d "$home_dir" -s /bin/bash -g "$primary_group" -G "$secondary_groups" "$username"
    echo -e "$password\n$password" | smbpasswd -s -a "$username"
    mkdir -p "$home_dir"
    chown "$username:$primary_group" "$home_dir"
    chmod 0700 "$home_dir"
}


create_user acct_user1 accounting /samba/departments/accounting/users/acct_user1 "$DEFAULT_PASS" company
create_user acct_user2 accounting /samba/departments/accounting/users/acct_user2 "$DEFAULT_PASS" company
create_user eng_user1 engineering /samba/departments/engineering/users/eng_user1 "$DEFAULT_PASS" company
create_user eng_user2 engineering /samba/departments/engineering/users/eng_user2 "$DEFAULT_PASS" company
create_user lead_user1 leadership /samba/departments/leadership/users/lead_user1 "$DEFAULT_PASS" company accounting leadership engineering technology sales
create_user lead_user2 leadership /samba/departments/leadership/users/lead_user2 "$DEFAULT_PASS" company accounting leadership engineering technology sales
create_user tech_user1 technology /samba/departments/technology/users/tech_user1 "$DEFAULT_PASS" company
create_user tech_user2 technology /samba/departments/technology/users/tech_user2 "$DEFAULT_PASS" company
create_user sales_user1 sales /samba/departments/sales/users/sales_user1 "$DEFAULT_PASS" company
create_user sales_user2 sales /samba/departments/sales/users/sales_user2 "$DEFAULT_PASS" company
