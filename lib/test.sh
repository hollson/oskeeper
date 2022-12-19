#!/bin/bash


my_array=(A B "C" D)

for i in $my_array ; do
    echo $i
done

for element in ${array[*]};do
    echo $element
done
