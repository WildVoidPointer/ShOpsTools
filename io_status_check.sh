#!/bin/bash


device_num=`iostat -x | egrep "^sd[a-z]" | wc -l`
iostat -x 1 3 | egrep "^sd[a-z]" | tail -n +$((device_num+1)) | awk '{io_long[$1]+=$9} END {for (i in io_long) print io_long[i], i}'