#!/bin/bash

# Configuration
readonly SAMBA_SERVER_HOST="127.0.0.1"
readonly WORKSPACE_DOMAIN="MYCOMPANY"
readonly DEFAULT_USER_PASSWORD="SambaPass123"
readonly TMP_NEW_FILE_PATH="/tmp/new.txt"


# Users and departments
declare -A SAMBA_USERS=(
    [acct_user1]="accounting"
    [eng_user1]="engineering"
    [tech_user1]="technology"
    [sales_user1]="sales"
    [lead_user1]="leadership"
)


# Selected test users (one from each department)
readonly SELECTED_USERS=(
    "acct_user1"
    "eng_user1"
    "tech_user1"
    "sales_user1"
    "lead_user1"
)

# Shares and their paths
declare -A SAMBA_SHARE_PATHS=(
    ["company_public"]="/samba/public"
    ["company_exchange"]="/samba/company_exchange"
    ["accounting_department_share"]="/samba/departments/accounting/share"
    ["engineering_department_share"]="/samba/departments/engineering/share"
    ["technology_department_share"]="/samba/departments/technology/share"
    ["sales_department_share"]="/samba/departments/sales/share"
    ["leadership_department_share"]="/samba/departments/leadership/share"
)

# User directories
declare -A USER_DIRECTORIES=(
    ["acct_user1"]="/samba/departments/accounting/users/acct_user1"
    ["eng_user1"]="/samba/departments/engineering/users/eng_user1"
    ["tech_user1"]="/samba/departments/technology/users/tech_user1"
    ["sales_user1"]="/samba/departments/sales/users/sales_user1"
    ["lead_user1"]="/samba/departments/leadership/users/lead_user1"
)

# Cleanup function
cleanup() {
    local share_path
    local user_dir
    
    echo "Cleaning up test files..."
    
    # Remove test files from shares
    for share_path in "${SAMBA_SHARE_PATHS[@]}"; do
        rm -f "${share_path}"/*_test.txt
    done
    
    # Remove test files from user directories
    for user_dir in "${USER_DIRECTORIES[@]}"; do
        rm -f "${user_dir}"/*_test.txt
    done
    
    # Remove company_public test file
    rm -f /samba/public/company_public_test.txt
    
    # Remove company_exchange test files
    rm -f /samba/company_exchange/exchange_test*.txt
    
    echo "Cleanup complete."
}


# Print test header
function samba_share_space_testing_header_printf {
    local user="$1"
    local share_name="$2"
    echo ""
    echo "=====> Testing user $user's CRUD operations on the $share_name path"
    echo ""
}


function samba_test_result_state_printf {
    local state="$1"
    local message="$2"

    local timestamp=`date +"%Y-%m-%d %H:%M:%S"`

    if state; then
        echo "\033[32m$timestamp SUCCESS - $message\033[0m"
    else
        echo "\033[31m$timestamp ERROR - $message\033[0m"
    fi
}

# Test public share
function samba_company_public_space_testing {
    local server_host="$1"
    local users=("${!2}")
    local password="$3"
    local temp_file="$4"
    
    # Create test file
    touch /samba/public/company_public_test.txt
    chmod 644 /samba/public/company_public_test.txt
    chown root:root /samba/public/company_public_test.txt
    
    for user in "${users[@]}"; do
        samba_share_space_testing_header_printf "$user" "company_public"
        
        # Try to create file (should fail)
        echo "Attempting to create file (should fail)..."
        if smbclient "//$server_host/company_public" -U "$user%$password" \
            -c "put $temp_file ${user}_public_test.txt" 2>/dev/null;
        then
            echo "        ERROR: $user was able to create file in company_public (should be read-only)"
        else
            echo "        SUCCESS: $user could not create file in company_public (as expected)"
        fi
        
        # Try to read file (should succeed)
        echo "Attempting to read file..."
        if smbclient "//$server_host/company_public" -U "$user%$password" \
            -c "get company_public_test.txt /dev/null" 2>/dev/null;
        then
            echo "        SUCCESS: $user could read file in company_public (as expected)"
        else
            echo "        ERROR: $user could not read file in company_public (should be allowed)"
        fi
        
        # Try to delete file (should fail)
        echo "Attempting to delete file (should fail)..."
        if ! smbclient "//$server_host/company_public" -U "$user%$password" \
            -c "del company_public_test.txt" 2>/dev/null\
                | grep "NT_STATUS_ACCESS_DENIED";
        then
            echo "        ERROR: $user was able to delete file in company_public (should be read-only)"
        else
            echo "        SUCCESS: $user could not delete file in company_public (as expected)"
        fi
    done
}


# Test company exchange share
function samba_company_exchange_space_testing {

    local server_host="$1"
    local users=("${!2}")
    local password="$3"
    local temp_file="$4"
    
    # Create initial test file with first user
    local first_user="${users[0]}"

    samba_share_space_testing_header_printf "$first_user" "company_exchange"

    echo "Creating test file with $first_user..."

    if ! smbclient "//$server_host/company_exchange" -U "$first_user%$password" \
        -c "put $temp_file exchange_test.txt" 2>/dev/null;
    then
        echo "        ERROR: $first_user failed to create file in company_exchange"
        return 1
    else
        echo "        SUCCESS: $first_user was able to create file in company_exchange"
    fi
    
    # Second user reads file
    local second_user="${users[1]}"
    samba_share_space_testing_header_printf "$second_user" "company_exchange"

    echo "Testing $second_user reading file..."

    if ! smbclient "//$server_host/company_exchange" -U "$second_user%$password" \
        -c "get exchange_test.txt /dev/null" 2>/dev/null;
    then
        echo "        ERROR: $second_user could not read file in company_exchange"
    else
        echo "        SUCCESS: $second_user could read file in company_exchange"
    fi
    
    # Third user renames file
    local third_user="${users[2]}"
    samba_share_space_testing_header_printf "$third_user" "company_exchange"

    echo "Testing $third_user renaming file..."

    if ! smbclient "//$server_host/company_exchange" -U "$third_user%$password" \
        -c "rename exchange_test.txt exchange_test_renamed.txt" 2>/dev/null;
    then
        echo "        ERROR: $third_user could not rename file in company_exchange"
    else
        echo "        SUCCESS: $third_user could rename file in company_exchange"
    fi
    
    # Fourth user modifies file
    local fourth_user="${users[3]}"
    samba_share_space_testing_header_printf "$fourth_user" "company_exchange"

    echo "Testing $fourth_user modifying file..."

    echo "Modified content" > "$temp_file"

    if ! smbclient "//$server_host/company_exchange" -U "$fourth_user%$password" \
        -c "put $temp_file exchange_test_renamed.txt" 2>/dev/null;
    then
        echo "        ERROR: $fourth_user could not modify file in company_exchange"
    else
        echo "        SUCCESS: $fourth_user could modify file in company_exchange"
    fi
    
    # Fifth user deletes file
    local fifth_user="${users[4]}"
    samba_share_space_testing_header_printf "$fifth_user" "company_exchange"

    echo "Testing $fifth_user deleting file..."

    if smbclient "//$server_host/company_exchange" -U "$fifth_user%$password" \
        -c "del exchange_test_renamed.txt" 2>/dev/null | grep "NT_STATUS_ACCESS_DENIED";
    then
        echo "        ERROR: $fifth_user could not delete file in company_exchange"
    else
        echo "        SUCCESS: $fifth_user could delete file in company_exchange"
    fi
    
}


# Test department shares
function samba_department_share_space_testing {
    
    local server_host="$1"
    local users=("${!2}")
    local password="$3"
    local temp_file="$4"
    local -n samba_users_ref="$5"
    local -n share_paths_ref="$6"
    
    for user in "${users[@]}"; do
        local department="${samba_users_ref[$user]}"
        local share_name="${department}_department_share"
        local share_path="${share_paths_ref[$share_name]}"
        
        # Create test file in department share
        touch "${share_path}/${user}_share_test.txt"
        chmod 660 "${share_path}/${user}_share_test.txt"
        chown "$user:$department" "${share_path}/${user}_share_test.txt"
        
        samba_share_space_testing_header_printf "$user" "$share_name"
        
        # Test CURD operations
        # Create (should succeed for department members)
        echo "Testing create operation..."

        if smbclient "//$server_host/$share_name" -U "$user%$password" \
            -c "put $temp_file ${user}_new_test.txt" 2>/dev/null;
        then
            echo "        SUCCESS: $user could create file in $share_name"
        else
            echo "        ERROR: $user could not create file in $share_name"
        fi
        
        # Read (should succeed)
        echo "Testing read operation..."

        if smbclient "//$server_host/$share_name" -U "$user%$password" \
            -c "get ${user}_share_test.txt /dev/null" 2>/dev/null;
        then
            echo "        SUCCESS: $user could read file in $share_name"
        else
            echo "        ERROR: $user could not read file in $share_name"
        fi
        
        # Update (should succeed)
        echo "Testing update operation..."

        echo "Updated content" > "$temp_file"

        if smbclient "//$server_host/$share_name" -U "$user%$password" \
            -c "put $temp_file ${user}_share_test.txt" 2>/dev/null;
        then
            echo "        SUCCESS: $user could update file in $share_name"
        else
            echo "        ERROR: $user could not update file in $share_name"
        fi
        
        # Delete (should succeed)
        echo "Testing delete operation..."

        if ! smbclient "//$server_host/$share_name" -U "$user%$password" \
            -c "del ${user}_new_test.txt" 2>/dev/null | grep "NT_STATUS_ACCESS_DENIED";
        then
            echo "        SUCCESS: $user could delete file in $share_name"
        else
            echo "        ERROR: $user could not delete file in $share_name"
        fi
    done
}

# Test user directories
function samba_department_users_space_testing {

    local server_host="$1"
    local users=("${!2}")
    local password="$3"
    local temp_file="$4"
    local -n samba_users_ref="$5"
    local -n user_dirs_ref="$6"
    
    for user in "${users[@]}"; do
        local user_dir="${user_dirs_ref[$user]}"
        local department="${samba_users_ref[$user]}"
        
        # Create test file in user directory
        touch "${user_dir}/${user}_dir_test.txt"
        chmod 600 "${user_dir}/${user}_dir_test.txt"
        chown "$user:$department" "${user_dir}/${user}_dir_test.txt"
        
        samba_share_space_testing_header_printf "$user" "${department}_department_users/$user"
        
        # Test CURD operations (should all succeed for owner)
        # Create
        echo "Testing create operation..."

        if smbclient "//$server_host/${department}_department_users" -U "$user%$password" \
            -c "cd $user; put $temp_file ${user}_new_test.txt" 2>/dev/null;
        then
            echo "        SUCCESS: $user could create file in their home directory"
        else
            echo "        ERROR: $user could not create file in their home directory"
        fi
        
        # Read
        echo "Testing read operation..."
        if smbclient "//$server_host/${department}_department_users" -U "$user%$password" \
            -c "cd $user; get ${user}_dir_test.txt /dev/null" 2>/dev/null;
        then
            echo "        SUCCESS: $user could read file in their home directory"
        else
            echo "        ERROR: $user could not read file in their home directory"
        fi
        
        # Update
        echo "Testing update operation..."
        echo "Updated content" > "$temp_file"
        
        if smbclient "//$server_host/${department}_department_users" -U "$user%$password" \
            -c "cd $user; put $temp_file ${user}_dir_test.txt" 2>/dev/null;
        then
            echo "        SUCCESS: $user could update file in their home directory"
        else
            echo "        ERROR: $user could not update file in their home directory"
        fi
        
        # Delete
        echo "Testing delete operation..."
        if ! smbclient "//$server_host/${department}_department_users" -U "$user%$password" \
            -c "cd $user; del ${user}_new_test.txt" 2>/dev/null | grep "NT_STATUS_ACCESS_DENIED";
        then
            echo "        SUCCESS: $user could delete file in their home directory"
        else
            echo "        ERROR: $user could not delete file in their home directory"
        fi
        
        # Test another user trying to access (should fail)
        local other_user
        for other_user in "${users[@]}"; do
            if [[ "$other_user" != "$user" ]]; then
                samba_share_space_testing_header_printf "$other_user" \
                    "${department}_department_users/$user (should fail)"

                echo "Testing $other_user trying to access $user's home directory (should fail)..."
                if smbclient "//$server_host/${department}_department_users" -U "$other_user%$password" \
                    -c "cd $user; ls" 2>/dev/null;
                then
                    echo "        ERROR: $other_user could access $user's home directory (should be denied)"
                else
                    echo "        SUCCESS: $other_user could not access $user's home directory (as expected)"
                fi
                break
            fi
        done
    done
    
}

# Main execution
main() {

    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root!"
        exit 1
    fi

    # Create a temporary file for testing
    echo "Test content" > "$TMP_NEW_FILE_PATH"
    
    # Run tests
    samba_company_public_space_testing "$SAMBA_SERVER_HOST" SELECTED_USERS[@] \
        "$DEFAULT_USER_PASSWORD" "$TMP_NEW_FILE_PATH"

    echo '=============================================================='

    samba_company_exchange_space_testing "$SAMBA_SERVER_HOST" SELECTED_USERS[@] \
        "$DEFAULT_USER_PASSWORD" "$TMP_NEW_FILE_PATH"
    
    echo '=============================================================='

    samba_department_share_space_testing "$SAMBA_SERVER_HOST" SELECTED_USERS[@] \
        "$DEFAULT_USER_PASSWORD" "$TMP_NEW_FILE_PATH" SAMBA_USERS SAMBA_SHARE_PATHS

    echo '=============================================================='

    samba_department_users_space_testing "$SAMBA_SERVER_HOST" SELECTED_USERS[@] \
        "$DEFAULT_USER_PASSWORD" "$TMP_NEW_FILE_PATH" SAMBA_USERS USER_DIRECTORIES

    echo '=============================================================='
    
    # Cleanup
    cleanup
    
    # Remove temporary file
    rm -f "$TMP_NEW_FILE_PATH"
    
    echo "All tests completed."
}

# Execute main function
main
