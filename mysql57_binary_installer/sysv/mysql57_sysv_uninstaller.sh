#!/bin/bash
set -euo pipefail


####################################
# Check if the script is executed by root.
#
# Globals:
#   EUID
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
if [[ $EUID -ne 0 ]]; then
    printf "ERROR: This script must be run as root.\n" >&2
    exit 1
fi


# Global configuration constants (same as install script)
readonly MYSQL_INSTALL_PATH='/www/services/mysql57'
readonly MYSQL_GLOBAL_CONF='/etc/my.cnf'
readonly MYSQL_FHS_LINK_PATH='/usr/local/mysql'
readonly SYSV_INIT_SCRIPTS_PATH='/etc/init.d'
readonly MYSQL_LOG_DIR='/var/log/mysqld/'
readonly MYSQL_DATA_DIR='/var/lib/mysqld/data'
readonly MYSQL_BINLOG_DIR='/var/lib/mysqld/binlog'
readonly MYSQL_LOG_FILE='/var/log/mysqld/mysqld.log'
readonly MULTI_USER_ENV_CONF='/etc/profile'
readonly BACKUP_TAR='/mysql_data.bak.tar'

# MySQL user and group
readonly MYSQL_USER='mysql'
readonly MYSQL_GROUP='mysql'


####################################
# Log an error message and exit.
#
# Globals:
#   None
#
# Arguments:
#   $* - Error message to log
#
# Returns:
#   None (exits with status 1)
####################################
log_error() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "\033[31m%s - ERROR - %s\n\033[0m" "$timestamp" "$*" >&2
    exit 1
}


####################################
# Log an informational message.
#
# Globals:
#   None
#
# Arguments:
#   $* - Info message to log
#
# Returns:
#   None
####################################
log_info() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "\033[32m%s - INFO - %s\n\033[0m" "$timestamp" "$*"
}


####################################
# Log a warning message (yellow).
#
# Globals:
#   None
#
# Arguments:
#   $* - Warning message to log
#
# Returns:
#   None
####################################
log_warn() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "\033[33m%s - WARN - %s\n\033[0m" "$timestamp" "$*"
}


####################################
# Stop the MySQL service gracefully.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
stop_mysql_service() {
    log_info "Stopping MySQL service..."
    if service mysql status &>/dev/null; then
        service mysql stop || log_error "Failed to stop MySQL service"
        log_info "MySQL service stopped"
    else
        log_info "MySQL service is not running"
    fi
}


####################################
# Backup MySQL data and binlog directories into a tarball.
# If the backup file already exists, it is moved to .old.
#
# Globals:
#   MYSQL_DATA_DIR
#   MYSQL_BINLOG_DIR
#   BACKUP_TAR
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
backup_data_and_binlog() {
    log_info "Backing up data and binlog directories to $BACKUP_TAR"

    # Check if directories exist; if not, warn but continue
    local dirs_to_backup=()
    if [[ -d "$MYSQL_DATA_DIR" ]]; then
        dirs_to_backup+=("$MYSQL_DATA_DIR")
    else
        log_info "Data directory $MYSQL_DATA_DIR does not exist, skipping"
    fi
    if [[ -d "$MYSQL_BINLOG_DIR" ]]; then
        dirs_to_backup+=("$MYSQL_BINLOG_DIR")
    else
        log_info "Binlog directory $MYSQL_BINLOG_DIR does not exist, skipping"
    fi

    if [[ ${#dirs_to_backup[@]} -eq 0 ]]; then
        log_info "No data or binlog directories to back up"
        return 0
    fi

    # Handle existing backup file
    if [[ -f "$BACKUP_TAR" ]]; then
        local bak_old="${BACKUP_TAR}.old"
        log_info "Backup file $BACKUP_TAR already exists, moving to $bak_old"
        mv "$BACKUP_TAR" "$bak_old" || log_error "Failed to move old backup"
    fi

    # Create tarball with absolute paths but preserve directory structure
    tar -cf "$BACKUP_TAR" -C / "${dirs_to_backup[@]#/}" \
        || log_error "Failed to create backup tarball"

    log_info "Backup created successfully: $BACKUP_TAR"
}


####################################
# Remove the MySQL installation directory.
#
# Globals:
#   MYSQL_INSTALL_PATH
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
remove_mysql_binary() {
    log_info "Removing MySQL installation directory..."
    if [[ -d "$MYSQL_INSTALL_PATH" ]]; then

        rm -rf "$MYSQL_INSTALL_PATH" \
            || log_error "Failed to remove $MYSQL_INSTALL_PATH"

        log_info "Removed $MYSQL_INSTALL_PATH"
    else
        log_info "$MYSQL_INSTALL_PATH does not exist, skipping"
    fi
}


####################################
# Remove the global MySQL configuration file.
#
# Globals:
#   MYSQL_GLOBAL_CONF
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
remove_global_conf() {
    log_info "Removing global MySQL configuration..."
    if [[ -f "$MYSQL_GLOBAL_CONF" ]]; then

        rm -f "$MYSQL_GLOBAL_CONF" \
            || log_error "Failed to remove $MYSQL_GLOBAL_CONF"

        log_info "Removed $MYSQL_GLOBAL_CONF"
    else
        log_info "$MYSQL_GLOBAL_CONF does not exist, skipping"
    fi
}


####################################
# Remove symbolic links created during installation.
#
# Globals:
#   MYSQL_FHS_LINK_PATH
#   SYSV_INIT_SCRIPTS_PATH
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
remove_symlinks() {
    log_info "Removing symbolic links..."

    if [[ -L "$MYSQL_FHS_LINK_PATH" ]] || [[ -e "$MYSQL_FHS_LINK_PATH" ]]; then
        rm -rf "$MYSQL_FHS_LINK_PATH" || log_error "Failed to remove $MYSQL_FHS_LINK_PATH"
        log_info "Removed $MYSQL_FHS_LINK_PATH"
    else
        log_info "$MYSQL_FHS_LINK_PATH does not exist, skipping"
    fi

    local init_script="${SYSV_INIT_SCRIPTS_PATH}/mysql"
    if [[ -L "$init_script" ]] || [[ -e "$init_script" ]]; then
        rm -rf "$init_script" || log_error "Failed to remove $init_script"
        log_info "Removed $init_script"
    else
        log_info "$init_script does not exist, skipping"
    fi
}


####################################
# Remove the MySQL bin directory entry from /etc/profile.
#
# Globals:
#   MYSQL_INSTALL_PATH
#   MULTI_USER_ENV_CONF
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
remove_path_entry() {
    log_info "Removing MySQL bin directory from PATH in $MULTI_USER_ENV_CONF"

    local path_entry="export PATH=\$PATH:${MYSQL_INSTALL_PATH}/bin"

    if grep -Fq "$path_entry" "$MULTI_USER_ENV_CONF" 2>/dev/null; then
        # Use sed to delete the line containing the exact entry
        sed -i "\|$path_entry|d" "$MULTI_USER_ENV_CONF" \
            || log_error "Failed to remove PATH entry"

        log_info "PATH entry removed from $MULTI_USER_ENV_CONF"
    else
        log_info "PATH entry not found in $MULTI_USER_ENV_CONF, skipping"
    fi
}


####################################
# Remove runtime directories (data, binlog, log) after backup.
#
# Globals:
#   MYSQL_DATA_DIR
#   MYSQL_BINLOG_DIR
#   MYSQL_LOG_DIR
#   MYSQL_LOG_FILE
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
remove_runtime_directories() {
    log_info "Removing MySQL runtime directories and log files..."

    for dir in "$MYSQL_DATA_DIR" "$MYSQL_BINLOG_DIR" "$MYSQL_LOG_DIR"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir" || log_error "Failed to remove $dir"
            log_info "Removed $dir"
        else
            log_info "$dir does not exist, skipping"
        fi
    done

    if [[ -f "$MYSQL_LOG_FILE" ]]; then
        rm -f "$MYSQL_LOG_FILE" || log_error "Failed to remove $MYSQL_LOG_FILE"
        log_info "Removed $MYSQL_LOG_FILE"
    else
        log_info "$MYSQL_LOG_FILE does not exist, skipping"
    fi
}


####################################
# Remove MySQL user and group.
# If the user or group does not exist, log a warning (yellow).
#
# Globals:
#   MYSQL_USER
#   MYSQL_GROUP
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
remove_mysql_user_and_group() {
    log_info "Removing MySQL user and group..."

    # Remove user
    if id "$MYSQL_USER" &>/dev/null; then
        userdel "$MYSQL_USER" || log_error "Failed to remove user $MYSQL_USER"
        log_info "Removed user $MYSQL_USER"
    else
        log_warn "User $MYSQL_USER does not exist, skipping"
    fi

    # Remove group
    if getent group "$MYSQL_GROUP" &>/dev/null; then
        groupdel "$MYSQL_GROUP" || log_error "Failed to remove group $MYSQL_GROUP"
        log_info "Removed group $MYSQL_GROUP"
    else
        log_warn "Group $MYSQL_GROUP does not exist, skipping"
    fi
}


####################################
# Main orchestration function for uninstallation.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
main() {
    log_info "Starting MySQL 5.7 uninstallation process"
    stop_mysql_service
    backup_data_and_binlog
    remove_mysql_binary
    remove_global_conf
    remove_symlinks
    remove_path_entry
    remove_runtime_directories
    remove_mysql_user_and_group
    log_info "MySQL 5.7 uninstallation completed!"
}


main
