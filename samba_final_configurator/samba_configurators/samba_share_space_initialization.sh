#!/bin/bash

SAMBA_REQUIRED_PACKAGES=("samba" "smbclient")

SAMBA_SHARE_SPACE_CSV_PATH="./samba_share_depts_space.csv"

SAMBA_USERS_HOME_CSV_PATH="./samba_share_users_space.csv"

SAMBA_USERGROUPS_DFEINE_FILE_PATH="./samba_company_usergroups.txt"

SAMBA_USERS_CSV_PATH="./samba_company_members.csv"

DEFAULT_USER_PASSWORD="SambaPass123"

DEFAULT_IFS="$IFS"


function samba_require_packages_check {
    for pkg in "$@"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            echo "Missing Samba dependencies: $pkg"
            exit 1
        fi
    done
    return 0
}


function samba_usergroup_create {

    local group="$1"

    if [ -z "$group" ]; then
        echo "Error: No group name provided."
        return 1
    fi

    if getent group "$group" > /dev/null; then
        echo "Group '$group' already exists."
        return 0
    fi

    if groupadd "$group"; then
        echo "Group '$group' created."
    else
        echo "Error: Failed to create group '$group'."
        return 2
    fi

    if getent group "$group" > /dev/null; then
        echo "Group '$group' creation verified."
        return 0
    else
        echo "Error: Group '$group' creation verification failed."
        return 3
    fi
}


function samba_user_initialization {

    local username="$1"
    local password="$2"
    shift
    local groups=("$@")

    if id "$username" &>/dev/null; then
        echo "User '$username' already exists, skipping creation."
    else
        useradd "$username"
        echo "User '$username' created."
    fi

    for group in "${groups[@]}"; do
        if getent group "$group" &>/dev/null; then
            if id -nG "$username" | grep -qw "$group"; then
                echo "User '$username' is already a member of group '$group'."
            else
                usermod -aG "$group" "$username"
                echo "Added user '$username' to group '$group'."
            fi
        else
            echo "Error: Group '$group' does not exist for user '$username'."
        fi
    done

    if pdbedit -L | grep -qw "^$username:"; then
        echo "Samba user '$username' already exists, skipping smbpasswd."
    else
        echo -e "$password\n$password" | smbpasswd -a -s "$username"
        echo "Samba user '$username' added with default password."
    fi
}


function samba_share_space_dir_create {

    local owner="$1"
    local group="$2"
    local perms="$3"
    local path="$4"

    if ! id "$owner" &>/dev/null; then
        echo "Error: User '$owner' does not exist."
        return 1
    fi

    if ! getent group "$group" &>/dev/null; then
        echo "Error: Group '$group' does not exist."
        return 1
    fi

    if [ ! -d "$path" ]; then
        mkdir -p "$path"
        echo "Directory created: $path"
    else
        echo "Directory already exists: $path"
    fi

    chown "$owner:$group" "$path"
    chmod "$perms" "$path"
}


function create_dirs_from_csv {

    while IFS=, read -r owner group perms path rest; do

        [[ -z "$owner" || "$owner" =~ ^# ]] && continue

        owner=$(echo "$owner" | xargs)
        group=$(echo "$group" | xargs)
        perms=$(echo "$perms" | xargs)
        path=$(echo "$path" | xargs)

        samba_share_space_dir_create "$owner" "$group" "$perms" "$path"
    done < "$1"

    IFS="$DEFAULT_IFS"
}


function create_users_from_csv {
    local csv_path="$1"
    local default_password="$2"

    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        IFS=',' read -ra fields <<< "$line"
        local username="${fields[0]}"
        local groups=("${fields[@]:1}")

        samba_user_initialization "$username" "$default_password" "${groups[@]}"
    done < "$csv_path"

    IFS="$DEFAULT_IFS"
}


function create_usergroups_from_define_file {

    while IFS=, read -r usergroup; do

        usergroup=$(echo "$usergroup" | xargs)

        samba_usergroup_create "$usergroup"
    done < "$1"

    IFS="$DEFAULT_IFS"
}


if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root!"
    exit 1
fi

create_usergroups_from_define_file "$SAMBA_USERGROUPS_DFEINE_FILE_PATH"

create_users_from_csv "$SAMBA_USERS_CSV_PATH" "$DEFAULT_USER_PASSWORD"

create_dirs_from_csv "$SAMBA_SHARE_SPACE_CSV_PATH"

create_dirs_from_csv "$SAMBA_USERS_HOME_CSV_PATH"
