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

# Global configuration constants
readonly MYSQL_PKG_PATH='./mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz'
readonly MYSQL_INSTALL_PATH='/www/services/mysql57'
readonly MYSQL_DEFAULT_CONF='./my.cnf'
readonly MYSQL_GLOBAL_CONF='/etc/my.cnf'
readonly MYSQL_FHS_LINK_PATH='/usr/local/mysql'
readonly MYSQL_INIT_LOG='/mysql_init.log'
readonly MYSQL_LOG_DIR='/var/log/mysqld/'
readonly MYSQL_DATA_DIR='/var/lib/mysqld/data'
readonly MYSQL_BINLOG_DIR='/var/lib/mysqld/binlog'
readonly MYSQL_LOG_FILE='/var/log/mysqld/mysqld.log'

readonly MULTI_USER_ENV_CONF='/etc/profile'
# Use systemd service file located in the same directory as this script
readonly SYSTEMD_SERVICE_SRC='./mysql.service'
readonly SYSTEMD_SERVICE_DST='/etc/systemd/system/mysql.service'

# Dependencies to install via apt
readonly DEPENDENCIES=("libncurses5" "libaio1" "libnuma1")

# Runtime directories that need to be owned by mysql:mysql
readonly MYSQL_DIRS=("$MYSQL_DATA_DIR" "$MYSQL_BINLOG_DIR" "$MYSQL_LOG_DIR")


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
# Check whether a file or directory exists.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Path to check
#
# Returns:
#   0 if exists, otherwise exits with error
####################################
is_exist() {
    local path="$1"
    if [[ -e "$path" ]]; then
        log_info "${path} is found"
        return 0
    else
        log_error "${path} is not found"
    fi
}


####################################
# Check whether a user exists.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Username
#
# Returns:
#   0 if exists, otherwise exits with error
####################################
is_user_exist() {
    local user_name="$1"
    if id "$1" &>/dev/null; then
        log_info "User ${user_name} exists"
        return 0
    else
        log_error "User ${user_name} does not exist"
    fi
}


####################################
# Check whether a group exists.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Group name
#
# Returns:
#   0 if exists, otherwise exits with error
####################################
is_group_exist() {
    local user_group="$1"
    if getent group "${user_group}" &>/dev/null; then
        log_info "Group ${user_group} exists"
        return 0
    else
        log_error "Group ${user_group} does not exist"
    fi
}


####################################
# Install required system dependencies.
# Uses the global DEPENDENCIES array.
#
# Globals:
#   DEPENDENCIES (readonly array)
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
install_dependencies() {
    log_info "Installing dependencies..."
    local to_install=()

    for pkg in "${DEPENDENCIES[@]}"; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            log_info "$pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        apt-get update
        apt-get install -y "${to_install[@]}" || log_error "Failed to install dependencies: ${to_install[*]}"
        for pkg in "${to_install[@]}"; do
            log_info "$pkg installed successfully"
        done
    else
        log_info "All dependencies already installed."
    fi
}


####################################
# Extract the MySQL binary tarball to the installation directory.
# Also copies the configuration file and systemd service file.
#
# Globals:
#   MYSQL_PKG_PATH
#   MYSQL_INSTALL_PATH
#   MYSQL_DEFAULT_CONF
#   MYSQL_GLOBAL_CONF
#   SYSTEMD_SERVICE_SRC
#   SYSTEMD_SERVICE_DST
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
install_mysql_binary() {
    log_info "Installing MySQL binary package..."
    is_exist "$MYSQL_PKG_PATH"
    is_exist "$MYSQL_DEFAULT_CONF"
    is_exist "$SYSTEMD_SERVICE_SRC"

    mkdir -p "$MYSQL_INSTALL_PATH"
    
    tar -zxvf "$MYSQL_PKG_PATH" \
        -C "$MYSQL_INSTALL_PATH" \
        --strip-components=1 &>/dev/null \
    || log_error "Failed to extract MySQL package"

    is_exist "$MYSQL_INSTALL_PATH"

    mkdir -p "${MYSQL_INSTALL_PATH}/conf"
    cp "$MYSQL_DEFAULT_CONF" "${MYSQL_INSTALL_PATH}/conf/my.cnf"

    chown -R root:root "$MYSQL_INSTALL_PATH"

    chown root:mysql "${MYSQL_INSTALL_PATH}/conf/my.cnf"
    chmod 644 "${MYSQL_INSTALL_PATH}/conf/my.cnf"

    cat > "$MYSQL_GLOBAL_CONF" <<EOF

!includedir ${MYSQL_INSTALL_PATH}/conf

EOF

    # Copy systemd service file
    log_info "Installing systemd service file..."
    cp "$SYSTEMD_SERVICE_SRC" "$SYSTEMD_SERVICE_DST" \
        || log_error "Failed to copy systemd service file"
    chown root:root "$SYSTEMD_SERVICE_DST"
    chmod 644 "$SYSTEMD_SERVICE_DST"
    log_info "Systemd service file installed to $SYSTEMD_SERVICE_DST"

    log_info "MySQL binary installed to $MYSQL_INSTALL_PATH"
}


####################################
# Create the mysql user and group.
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
create_mysql_user_and_group() {
    log_info "Creating MySQL user and group..."

    if ! getent group mysql &>/dev/null; then
        groupadd mysql || log_error "Failed to create group mysql"
        log_info "Group mysql created"
    else
        log_info "Group mysql already exists"
    fi

    if ! id mysql &>/dev/null; then
        useradd -r -g mysql -s /bin/false mysql \
            || log_error "Failed to create user mysql"
        log_info "User mysql created"
    else
        log_info "User mysql already exists"
    fi

    log_info "MySQL user and group configured"
}


####################################
# Create runtime directories for MySQL data, binlog, and logs.
# Uses the global MYSQL_DIRS array.
#
# Globals:
#   MYSQL_DIRS (readonly array)
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
create_mysql_runtime_directories() {
    log_info "Creating MySQL runtime directories..."

    for dir in "${MYSQL_DIRS[@]}"; do
        mkdir -p "$dir" || log_error "Failed to create directory: $dir"
        is_exist "$dir"
        chown mysql:mysql "$dir" || log_error "Failed to chown $dir"
        chmod 750 "$dir" || log_error "Failed to chmod $dir"
        log_info "Directory $dir created and permissions set"
    done

    log_info "MySQL runtime directories configured"
}


####################################
# Create symbolic links required for FHS compliance.
#
# Globals:
#   MYSQL_INSTALL_PATH
#   MYSQL_FHS_LINK_PATH
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
create_symlinks() {
    log_info "Creating symbolic links..."

    # Create /usr/local/mysql -> /www/services/mysql57
    if [[ -L "$MYSQL_FHS_LINK_PATH" ]] || [[ -e "$MYSQL_FHS_LINK_PATH" ]]; then
        rm -rf "$MYSQL_FHS_LINK_PATH" \
            || log_error "Failed to remove existing $MYSQL_FHS_LINK_PATH"
    fi

    ln -s "$MYSQL_INSTALL_PATH" "$MYSQL_FHS_LINK_PATH" \
        || log_error "Failed to create symlink $MYSQL_FHS_LINK_PATH"

    log_info "Symlink $MYSQL_FHS_LINK_PATH -> $MYSQL_INSTALL_PATH created"
}


####################################
# Initialize the MySQL database and start the service using systemd.
#
# Globals:
#   MYSQL_INSTALL_PATH
#   MYSQL_GLOBAL_CONF
#   MYSQL_INIT_LOG
#   MYSQL_LOG_FILE
#
# Arguments:
#   None
#
# Returns:
#   None (exits on failure)
####################################
initialize_and_start_mysql() {
    log_info "Initializing MySQL database..."

    cd "$MYSQL_INSTALL_PATH" || log_error "Cannot enter $MYSQL_INSTALL_PATH"

    # Initialize database
    ./bin/mysqld \
        --defaults-file="$MYSQL_GLOBAL_CONF" \
        --user=mysql \
        --initialize \
        || log_error "MySQL initialization failed. Check log: $MYSQL_INIT_LOG"

    cp "$MYSQL_LOG_FILE" "$MYSQL_INIT_LOG"

    > "$MYSQL_LOG_FILE"

    # Reload systemd to pick up the new service file
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload || log_error "Failed to reload systemd"

    # Enable MySQL service to start on boot
    log_info "Enabling MySQL service..."
    systemctl enable mysql || log_error "Failed to enable MySQL service"

    # Start MySQL via systemd
    log_info "Starting MySQL service via systemctl..."
    systemctl start mysql || log_error "Failed to start MySQL service"
    sleep 2

    # Check service status
    log_info "Checking MySQL service status..."
    systemctl status mysql --no-pager || log_error "MySQL service status check failed"

    log_info "MySQL service started successfully"
}


####################################
# Append the MySQL binary directory to the system PATH in /etc/profile.
# Avoids duplicate entries by checking if already present.
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
append_mysql_bin_to_path() {
    log_info "Adding MySQL bin directory to PATH permanently..."
    local path_entry="export PATH=\$PATH:${MYSQL_INSTALL_PATH}/bin"
    if grep -Fq "$path_entry" "$MULTI_USER_ENV_CONF" 2>/dev/null; then
        log_info "PATH entry already exists in $MULTI_USER_ENV_CONF"
    else
        echo "$path_entry" >> "$MULTI_USER_ENV_CONF" \
            || log_error "Failed to append PATH to $MULTI_USER_ENV_CONF"
        log_info "PATH updated in $MULTI_USER_ENV_CONF"
    fi
}


####################################
# Main orchestration function for the entire installation.
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
    log_info "Starting MySQL 5.7 installation process"

    install_dependencies
    create_mysql_user_and_group
    create_mysql_runtime_directories

    install_mysql_binary

    create_symlinks
    initialize_and_start_mysql
    append_mysql_bin_to_path
    
    log_info "MySQL 5.7 installation completed!"
}

main
