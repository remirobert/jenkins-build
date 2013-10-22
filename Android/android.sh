#!/bin/bash

PATH_SDK=/Users/ankita/Desktop/RemiEclipse/Android/adt-bundle-mac/sdk
PATH_ANDROID_BIN="${PATH_SDK}/tools/android"
PATH_ANT=$(which ant)

if [[ -z $PATH_SDK ]]
then
    PATH_SDK=$(find $HOME -name sdk | head -1)
fi

if [[ ! -e $PATH_ANDROID_BIN ]]
then
    2> echo "android bin don't exist"
fi



echo "done"
