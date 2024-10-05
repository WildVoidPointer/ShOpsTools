#!/bin/bash


t_file=`mktemp memory.XXX`

top -n 1 > "$t_file"

tail -n +8 "$t_file" | awk '{array[$13]+=$6} END {for (i in array) print i, array[i]}' | sort -k 2 -n -r | head -10

rm -f "$t_file"