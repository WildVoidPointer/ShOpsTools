#!/bin/bash

# Global variables
SERVER="127.0.0.1"
SHARE="company_public"
DOMAIN="company"
PASSWORD="SambaPass123"
EXIST_FILE_NAME="exist.txt"
EXIST_FILE_PATH="/samba/public/exist.txt"
NEW_FILE_NAME="new.txt"
NEW_FILE_PATH="/tmp/new.txt"



# Users (one per department)
declare -A USERS=(
    ["acct_user1"]="accounting"
    ["eng_user1"]="engineering"
    ["tech_user1"]="technology"
    ["sales_user1"]="sales"
    ["lead_user1"]="leadership"
)

# Create test files
echo "This is the new file." > "$NEW_FILE_PATH"
echo "This is the exist file." > "$EXIST_FILE_PATH"


# Loop through users and test CRUD
for USER in "${!USERS[@]}"; do
    echo "=====> Testing user $USER's CRUD operations on the $SHARE path."

    # Create new file
    smbclient "//$SERVER/$SHARE" -U "$USER%$PASSWORD" -W "$DOMAIN" -c "put $NEW_FILE_PATH new_$USER.txt" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Create file (put new_$USER.txt)"
    else
        echo "    [failed]  Create file (put new_$USER.txt)"
    fi

    # Read exist.txt
    smbclient "//$SERVER/$SHARE" -U "$USER%$PASSWORD" -W "$DOMAIN" -c "get $EXIST_FILE_NAME /tmp/get_${USER}.txt" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Read file ($EXIST_FILE_NAME)"
    else
        echo "    [failed]  Read file ($EXIST_FILE_NAME)"
    fi

    # Delete exist.txt
    if smbclient "//$SERVER/$SHARE" -U "$USER%$PASSWORD" -W "$DOMAIN" -c "del $EXIST_FILE_NAME" > /dev/null 2>&1 | grep -q "NT_STATUS_ACCESS_DENIED"; then
        echo "    [succeed] Delete file ($EXIST_FILE_NAME)"
    else
        echo "    [failed]  Delete file ($EXIST_FILE_NAME)"
    fi

    # Update (rename)
    smbclient "//$SERVER/$SHARE" -U "$USER%$PASSWORD" -W "$DOMAIN" -c "put $NEW_FILE_PATH $EXIST_FILE_NAME" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Update file (update $EXIST_FILE_NAME)"
    else
        echo "    [failed]  Update file (update $EXIST_FILE_NAME)"
    fi

    smbclient "//$SERVER/$SHARE" -U "$USER%$PASSWORD" -W "$DOMAIN" -c "rename $EXIST_FILE_NAME updated_${USER}.txt" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Update file (rename $EXIST_FILE_NAME)"
    else
        echo "    [failed]  Update file (rename $EXIST_FILE_NAME)"
    fi

    # Cleanup user-created files
    smbclient "//$SERVER/$SHARE" -U "$USER%$PASSWORD" -W "$DOMAIN" -c "del updated_${USER}.txt" > /dev/null 2>&1
    rm -f "/tmp/get_${USER}.txt"
done

# Delete exist.txt again in case it survived
rm -f "$EXIST_FILE_PATH"
# Cleanup local files
rm -f "$NEW_FILE_PATH"

echo "=====> Test Complete."
