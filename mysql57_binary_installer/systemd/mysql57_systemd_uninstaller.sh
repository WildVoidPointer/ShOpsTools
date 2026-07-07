#!/bin/bash
set -euo pipefail

####################################
# Check if script is executed by root.
####################################
if [[ $EUID -ne 0 ]]; then
    printf "ERROR: This script must be run as root.\n" >&2
    exit 1
fi

# Configuration constants (same as install script)
readonly MYSQL_INSTALL_PATH='/www/services/mysql57'
readonly MYSQL_GLOBAL_CONF='/etc/my.cnf'
readonly MYSQL_FHS_LINK_PATH='/usr/local/mysql'
readonly MYSQL_DATA_DIR='/var/lib/mysqld/data'
readonly MYSQL_BINLOG_DIR='/var/lib/mysqld/binlog'
readonly MYSQL_LIB_DIR='/var/lib/mysqld'
readonly MYSQL_LOG_DIR='/var/log/mysqld/'
readonly MYSQL_INIT_LOG='/mysql_init.log'
readonly SYSTEMD_SERVICE_DST='/etc/systemd/system/mysql.service'
readonly MULTI_USER_ENV_CONF='/etc/profile'

# MySQL user and group
readonly MYSQL_USER='mysql'
readonly MYSQL_GROUP='mysql'


####################################
# Logging functions
####################################
log_info() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "\033[32m%s - INFO - %s\n\033[0m" "$timestamp" "$*"
}


log_warn() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "\033[33m%s - WARN - %s\n\033[0m" "$timestamp" "$*" >&2
}


log_error() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "\033[31m%s - ERROR - %s\n\033[0m" "$timestamp" "$*" >&2
    exit 1
}


####################################
# Stop and disable MySQL service
####################################
stop_disable_mysql() {
    log_info "Stopping MySQL service..."
    
    systemctl stop mysql 2>/dev/null && log_info "MySQL service stopped" \
        || log_warn "MySQL service not running or already stopped"

    log_info "Disabling MySQL service..."

    systemctl disable mysql 2>/dev/null && log_info "MySQL service disabled" \
        || log_warn "MySQL service not enabled or already disabled"
}


####################################
# Remove systemd service file and reload daemon
####################################
remove_systemd_service() {
    if [[ -f "$SYSTEMD_SERVICE_DST" ]]; then
        log_info "Removing systemd service file: $SYSTEMD_SERVICE_DST"
        rm -f "$SYSTEMD_SERVICE_DST" || log_error "Failed to remove $SYSTEMD_SERVICE_DST"
        systemctl daemon-reload
        log_info "Systemd daemon reloaded"
    else
        log_warn "Systemd service file $SYSTEMD_SERVICE_DST not found, skipping"
    fi
}


####################################
# Remove MySQL installation directory
####################################
remove_installation() {
    if [[ -d "$MYSQL_INSTALL_PATH" ]]; then
        log_info "Removing MySQL installation directory: $MYSQL_INSTALL_PATH"
        rm -rf "$MYSQL_INSTALL_PATH" || log_error "Failed to remove $MYSQL_INSTALL_PATH"
    else
        log_warn "Installation directory $MYSQL_INSTALL_PATH not found, skipping"
    fi
}


####################################
# Remove global configuration file (if it was created by install script)
# WARNING: This removes /etc/my.cnf entirely.
# If you have other MySQL configs, you may want to keep/restore it.
####################################
remove_global_config() {
    if [[ -f "$MYSQL_GLOBAL_CONF" ]]; then
        log_info "Removing global configuration file: $MYSQL_GLOBAL_CONF"
        rm -f "$MYSQL_GLOBAL_CONF" || log_error "Failed to remove $MYSQL_GLOBAL_CONF"
    else
        log_warn "Global config $MYSQL_GLOBAL_CONF not found, skipping"
    fi
}


####################################
# Remove symbolic link /usr/local/mysql
####################################
remove_symlink() {
    if [[ -L "$MYSQL_FHS_LINK_PATH" ]] || [[ -e "$MYSQL_FHS_LINK_PATH" ]]; then
        log_info "Removing symbolic link: $MYSQL_FHS_LINK_PATH"
        rm -rf "$MYSQL_FHS_LINK_PATH" || log_error "Failed to remove $MYSQL_FHS_LINK_PATH"
    else
        log_warn "Symbolic link $MYSQL_FHS_LINK_PATH not found, skipping"
    fi
}


####################################
# Remove runtime directories (data, binlog, logs)
# Before deletion, backup data and binlog to /mysql_data.bak.tar
####################################
remove_runtime_dirs() {
    # Backup data and binlog directories before removal
    log_info "Backing up data and binlog directories to /mysql_data.bak.tar"
    local tar_args=""
    if [[ -d "$MYSQL_DATA_DIR" ]]; then
        tar_args="$tar_args $MYSQL_DATA_DIR"
    fi

    if [[ -d "$MYSQL_BINLOG_DIR" ]]; then
        tar_args="$tar_args $MYSQL_BINLOG_DIR"
    fi

    if [[ -z "$tar_args" ]]; then
        log_warn "No data or binlog directories found to backup. Skipping backup."
    else
        if ! tar -cf /mysql_data.bak.tar $tar_args; then
            log_error "Failed to create backup tarball /mysql_data.bak.tar"
        fi
        log_info "Backup created at /mysql_data.bak.tar"
    fi

    # Now delete the runtime directories
    local dirs=("$MYSQL_DATA_DIR" "$MYSQL_BINLOG_DIR" "$MYSQL_LOG_DIR")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Removing runtime directory: $dir"
            rm -rf "$dir" || log_error "Failed to remove $dir"
        else
            log_warn "Directory $dir not found, skipping"
        fi
    done

    # Also remove parent directories if empty (optional)
    # /var/lib/mysqld and /var/log/mysqld may be empty now; remove if empty
    local parent_dirs=("$MYSQL_LIB_DIR" "$MYSQL_LOG_DIR")
    for pdir in "${parent_dirs[@]}"; do
        if [[ -d "$pdir" ]] && [[ -z "$(ls -A "$pdir" 2>/dev/null)" ]]; then
            log_info "Removing empty parent directory: $pdir"
            rmdir "$pdir" 2>/dev/null || log_warn "Could not remove $pdir (may not be empty)"
        fi
    done
}


####################################
# Remove initialization log file
####################################
remove_init_log() {
    if [[ -f "$MYSQL_INIT_LOG" ]]; then
        log_info "Removing initialization log: $MYSQL_INIT_LOG"
        rm -f "$MYSQL_INIT_LOG" || log_warn "Failed to remove $MYSQL_INIT_LOG"
    else
        log_warn "Init log $MYSQL_INIT_LOG not found, skipping"
    fi
}


####################################
# Remove PATH entry from /etc/profile
####################################
remove_path_entry() {
    local path_entry="export PATH=\$PATH:${MYSQL_INSTALL_PATH}/bin"
    if grep -Fq "$path_entry" "$MULTI_USER_ENV_CONF" 2>/dev/null; then
        log_info "Removing PATH entry from $MULTI_USER_ENV_CONF"
        # Use sed to delete the exact line
        sed -i "\|${path_entry}|d" "$MULTI_USER_ENV_CONF" || log_error "Failed to remove PATH entry"
        log_info "PATH entry removed"
    else
        log_warn "PATH entry not found in $MULTI_USER_ENV_CONF, skipping"
    fi
}


####################################
# Remove mysql user and group (optional, be cautious)
# The script creates them, so we remove them if they exist and no other processes use them.
####################################
remove_mysql_user_group() {
    # Check if user '$MYSQL_USER' exists
    if id "$MYSQL_USER" &>/dev/null; then
        log_info "Removing user 'mysql'..."
        # Kill any remaining processes? Usually not needed since service is stopped.
        userdel "$MYSQL_USER" 2>/dev/null && log_info "User '$MYSQL_USER' removed" \
            || log_warn "Failed to remove user '$MYSQL_USER' (maybe still in use)"
    else
        log_warn "User '$MYSQL_USER' does not exist, skipping"
    fi

    if getent group "$MYSQL_GROUP" &>/dev/null; then
        log_info "Removing group '$MYSQL_GROUP'..."
        groupdel "$MYSQL_GROUP" 2>/dev/null && log_info "Group '$MYSQL_GROUP' removed" \
            || log_warn "Failed to remove group '$MYSQL_GROUP' (maybe still in use)"
    else
        log_warn "Group '$MYSQL_GROUP' does not exist, skipping"
    fi
}


####################################
# Main uninstall function
####################################
main() {
    log_info "Starting MySQL 5.7 uninstallation process"

    # Stop and disable service first
    stop_disable_mysql

    # Remove systemd service
    remove_systemd_service

    # Remove installation and configuration
    remove_installation
    remove_global_config
    remove_symlink
    remove_runtime_dirs
    remove_init_log
    remove_path_entry

    # Remove user/group (optional; comment out if you prefer to keep them)
    remove_mysql_user_group

    log_info "MySQL 5.7 uninstallation completed successfully!"
    log_info "Please verify that all files have been removed as expected."
}

main