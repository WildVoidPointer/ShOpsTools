#!/bin/bash

# 测试函数：测试指定用户对某个共享目录的 CRUD 权限
test_smb_crud() {
    local SERVER="$1"
    local SHARE="$2"
    local DOMAIN="$3"
    local USER="$4"
    local PASSWORD="$5"
    local EXIST_FILE_NAME="$6"
    local NEW_FILE_PATH="$7"
    local TMP_DIR="/tmp/samba_test_${USER}_${SHARE}"
    mkdir -p "$TMP_DIR"

    echo "=====> Testing user $USER's CRUD operations on the $SHARE path."

    # 尝试列目录
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "ls" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] List directory"
    else
        echo "    [failed]  List directory"
    fi

    # 上传新文件（Create）
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "put ${NEW_FILE_PATH} new_${USER}.txt" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Create file (put new_${USER}.txt)"
    else
        echo "    [failed]  Create file (put new_${USER}.txt)"
    fi

    # 下载测试文件（Read）
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "get ${EXIST_FILE_NAME} ${TMP_DIR}/read_${USER}.txt" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Read file (${EXIST_FILE_NAME})"
    else
        echo "    [failed]  Read file (${EXIST_FILE_NAME})"
    fi

    # 重命名测试文件（Update）
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "rename ${EXIST_FILE_NAME} updated_${USER}.txt" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Update file (rename ${EXIST_FILE_NAME})"
    else
        echo "    [failed]  Update file (rename ${EXIST_FILE_NAME})"
    fi

    # 删除测试文件（Delete）
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "del ${EXIST_FILE_NAME}" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    [succeed] Delete file (${EXIST_FILE_NAME})"
    else
        echo "    [failed]  Delete file (${EXIST_FILE_NAME})"
    fi

    # 清理现场
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "del new_${USER}.txt" > /dev/null 2>&1
    smbclient "//$SERVER/$SHARE" -U "${USER}%${PASSWORD}" -W "$DOMAIN" -c "del updated_${USER}.txt" > /dev/null 2>&1
    rm -rf "$TMP_DIR"
}


# 全局配置
SERVER="127.0.0.1"
DOMAIN="MYCOMPANY"
PASSWORD="SambaPass123"
NEW_FILE_PATH="/tmp/new.txt"
echo "new file content" > "$NEW_FILE_PATH"

declare -A USERS=(
    [acct_user1]=accounting
    [eng_user1]=engineering
    [tech_user1]=technology
    [sales_user1]=sales
    [lead_user1]=leadership
)

SHARES=(
    "company_public:/samba/public"
    "company_exchange:/samba/company_exchange"
    "accounting_department_share:/samba/departments/accounting/share"
    "engineering_department_share:/samba/departments/engineering"
    "leadership_department_share:/samba/departments/leadership/share"
    "technology_department_share:/samba/departments/technology/share"
    "sales_department_share:/samba/departments/sales/share"
)

# 为每个共享目录预生成存在文件
for entry in "${SHARES[@]}"; do
    IFS=":" read SHARE SHARE_PATH <<< "$entry"
    for USER in "${!USERS[@]}"; do
        echo "This is ${USER}'s test file for ${SHARE}" > "${SHARE_PATH}/${USER}_exist.txt"
    done
done

# 测试每个用户对每个共享目录的访问权限
for entry in "${SHARES[@]}"; do
    IFS=":" read SHARE SHARE_PATH <<< "$entry"
    for USER in "${!USERS[@]}"; do
        EXIST_FILE_NAME="${USER}_exist.txt"
        test_smb_crud "$SERVER" "$SHARE" "$DOMAIN" "$USER" "$PASSWORD" "$EXIST_FILE_NAME" "$NEW_FILE_PATH"
    done
done

rm -f "$NEW_FILE_PATH"
echo "=====> Test Complete."
