#!/bin/bash

if [[ "${#}" != "1" ]]
then
    echo "Bad arguement, you must pass a file"
    exit 1
fi

if [[ ! -e $1 ]]
then
    echo "file don't exist"
    exit 2
fi

NUMBER_LINE=$(sed -e "/^$/d" $1 | wc -l)
echo "number line = ${NUMBER_LINE}"

exit 0
