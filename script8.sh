#!/bin/bash
a="Hello World"
length=${#a}
echo "The length is $length"
upper="${a^^}"
echo "upper is $upper"
lower=${a,,}
replace="${a/World/Buddy}"
echo $replace
echo $lower
slice=${a:2:4}
echo $slice




