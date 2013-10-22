#!/bin/bash

PATH_SDK=/Users/ankita/Desktop/RemiEclipse/Android/adt-bundle-mac/sdk
PATH_ANDROID_BIN="${PATH_SDK}/tools/android"
PATH_ANT=$(which ant)
PATH_PROJECT=/Users/ankita/Documents/TestApp
NAME_PROJECT=TestApp

API_TOKEN=3afe2aac8655ec73f6b3495d4ab42ff5_MTExMTM0OTIwMTMtMDYtMTQgMDY6MDU6NTMuNzMzNzI3
TEAM_TOKEN=94cd09572b29a973f20ac0dbaad361db_MjM2NTY2MjAxMy0wNi0xNCAwNjoxNjoxMC42NzIwMjU 
SIGNING_IDENTITY="Android Distribution: Extentia Information Technology"

if [[ -z $PATH_SDK ]]
then
    PATH_SDK=$(find $HOME -name sdk | head -1)
fi

if [[ ! -e $PATH_ANDROID_BIN ]] || [[ ! -e $PATH_PROJECT ]]
then
    echo "path don't exist" 1>&2
fi

#create build.xml
$PATH_ANDROID_BIN update project --path "${PATH_PROJECT}" 2> /tmp/error_create_build

RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    echo "creation build.xml failed" 1>&2
fi

cd $PATH_PROJECT

$PATH_ANT clean debug 2> /tmp/error_android_build | grep "BUILD SUCCESSFUL"

RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    echo "build FAIL" 1>&2
fi

PATH_APK=$(find "${PATH_PROJECT}" -name *-debug.apk | head -1)

echo "PATH PROJECT = ${PATH_PROJECT}"
echo "PATH PWD current = ${PWD}"
echo "PATH APK = ${PATH_APK}"

if [[ -z $PATH_APK ]]
then
    echo "APK not found" 1>&2
fi

cd -
echo "done"

/usr/bin/curl "http://testflightapp.com/api/builds.json" \
-F file=@"${PATH_APK}" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build ${BUILD_NUMBER} uploaded automatically from script shell on in jenkins." \
-F notify=True \
-F distribution_lists='all'
