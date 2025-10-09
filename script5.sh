#!/bin/bash

read choice
case $choice in
a) echo "a selected";;
b) echo "b selected";;
c)
echo "c selected"
date
echo "c deselected"
;;
esac
