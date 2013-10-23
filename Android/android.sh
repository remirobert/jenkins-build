#!/bin/bash

PATH_SDK="/Users/ankita/Desktop/RemiEclipse/Android/adt-bundle-mac/sdk"
PATH_ANDROID_BIN="${PATH_SDK}/tools/android"
PATH_ANT=$(which ant)
PATH_PROJECT=/Users/ankita/Documents/TestApp
PROJECT=TestApp

API_TOKEN=3afe2aac8655ec73f6b3495d4ab42ff5_MTExMTM0OTIwMTMtMDYtMTQgMDY6MDU6NTMuNzMzNzI3
TEAM_TOKEN=94cd09572b29a973f20ac0dbaad361db_MjM2NTY2MjAxMy0wNi0xNCAwNjoxNjoxMC42NzIwMjU 
SIGNING_IDENTITY="Android Distribution: Extentia Information Technology"

#
#configuration mail
#
MAIL_SMTP_SERVER="mail.extentia.com"
MAIL_SMTP_PORT="587"
MAIL_SENDER="jenkins@extentia.com"
MAIL_SUBJECT="Jenkins error build ${PROJECT}"
#separate adress with space : ' '
MAIL_RECIPIENT="remirobert33530 remi.robert@extentia.com"

send_mail()
{
    if [[ "${#}" != "1" ]]
    then
	echo "Bad arguement"
	return
    fi
    MESSAGE=$1
    python <<EOF
from email.MIMEText import MIMEText
import smtplib
import sys

list_recipient = str.split("${MAIL_RECIPIENT}", " ")
try:
    server = smtplib.SMTP("${MAIL_SMTP_SERVER}", int("${MAIL_SMTP_PORT}")) 
    msg = MIMEText("\n${MESSAGE}")
    msg['Subject'] = "${MAIL_SUBJECT}"
    server.sendmail("${MAIL_SENDER}", list_recipient, msg.as_string())
except:
    sys.stderr.write("error send mail")
EOF
}

if [[ -z $PATH_SDK ]]
then
    PATH_SDK=$(find $HOME -name sdk | head -1)
fi

if [[ ! -e $PATH_ANDROID_BIN ]] || [[ ! -e $PATH_PROJECT ]]
then
    send_mail "Error build ${PROJECT} fail :\nPath SDK not found"
    echo "path don't exist" 1>&2
fi

#create build.xml
$PATH_ANDROID_BIN update project --path "${PATH_PROJECT}" 2> /tmp/error_create_build

RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    send_mail "Error build ${PROJECT} fail :\nCreation build.xml failed"
    echo "creation build.xml failed" 1>&2
fi

cd $PATH_PROJECT

$PATH_ANT clean debug 2> /tmp/error_android_build | grep "BUILD SUCCESSFUL"

RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    send_mail "Error build ${PROJECT} fail :\nBuild failed"
    echo "build FAIL" 1>&2
fi

PATH_APK=$(find "${PATH_PROJECT}" -name *-debug.apk | head -1)

echo "PATH APK = ${PATH_APK}"

if [[ -z $PATH_APK ]]
then
    send_mail "Error build ${PROJECT} fail :\nAPK not found"
    echo "APK not found" 1>&2
fi

cd -

/usr/bin/curl "http://testflightapp.com/api/builds.json" \
-F file=@"${PATH_APK}" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build ${BUILD_NUMBER} uploaded automatically from script shell on in jenkins." \
-F notify=True \
-F distribution_lists='all'

exit 0
