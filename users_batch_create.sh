#!/bin/bash


passwds=`mktemp passwds.XXX`
# for i in $(seq -s ' ' -w 1 20)
# do
#     useradd "user$i"
# done

# for i in $(seq 1 20)
# do
#     echo "$i" | md5sum | cut -c 1-6
# done


cat /dev/urandom | strings -6 | egrep '^[a-zA-Z0-9]{6}$' | head -20 > "$passwds"

for i in $(seq -s ' ' -w 1 20)
do
    passwd=$(head -n "$i" "$passwds" | tail -1)
    echo $passwd
    # echo "$passwd" | passwd --stdin "user$i"
    # echo -e "user$i \t $passwd" >> all_user_and_passwd.txt
done

rm -f "$passwds"
