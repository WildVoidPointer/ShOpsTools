#!/bin/bash


# free-cached-buffer-swap
head -2 /proc/meminfo | awk 'NR==1{t=$2}NR==2{f=$2;print (t-f)*100/t}'
head -5 /proc/meminfo | awk 'NR==1{t=$2}NR==5{c=$2;print c*100/t}'
head -4 /proc/meminfo | awk 'NR==1{t=$2}NR==4{b=$2;print b*100/t}'
