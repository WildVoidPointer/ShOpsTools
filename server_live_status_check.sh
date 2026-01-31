#!/bin/bash


IP_ADDR_NET='192.168.170.'

IP_UP_LIST='ip_up_list.txt'

IP_DOWN_LIST='ip_down_list.txt'

UP_LIST_LOCK_FILE='up_list.lock'

DOWN_LIST_LOCK_FILE='down_list.lock'


# 初始化文件
> "$IP_UP_LIST"

> "$IP_DOWN_LIST"


# 创建锁文件
touch "$UP_LIST_LOCK_FILE" "$DOWN_LIST_LOCK_FILE"


for i in {1..254}; do 
    {
        if ping -c 1 -W 1 "${IP_ADDR_NET}${i}" &> /dev/null; then
            exec 100> "$UP_LIST_LOCK_FILE"
            flock -w 60 100
            printf 'The %s is Up\n' "${IP_ADDR_NET}${i}" >> "$IP_UP_LIST"
        else
            exec 200> "$DOWN_LIST_LOCK_FILE"
            flock -w 60 200
            printf 'The %s is Down\n' "${IP_ADDR_NET}${i}" >> "$IP_DOWN_LIST"
        fi
    } &
done

wait

# 注意 flock 可以主动创建锁文件
# 但是不会自动清理
rm -f "$UP_LIST_LOCK_FILE" "$DOWN_LIST_LOCK_FILE"

echo 'Complete!'
