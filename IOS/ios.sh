export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

#Name of the project
PROJECT="KxMenuExample"

MODE_DEBUG=false
API_TOKEN=3afe2aac8655ec73f6b3495d4ab42ff5_MTExMTM0OTIwMTMtMDYtMTQgMDY6MDU6NTMuNzMzNzI3
TEAM_TOKEN=94cd09572b29a973f20ac0dbaad361db_MjM2NTY2MjAxMy0wNi0xNCAwNjoxNjoxMC42NzIwMjU 
SIGNING_IDENTITY="iPhone Distribution: Extentia Information Technology" 
PROVISIONING_PROFILE=$(find "/Users/$USER/Library/MobileDevice/Provisioning Profiles/" -name *.mobileprovision | head -1)

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
print "Send mail"
EOF
}

xcodebuild -scheme $PROJECT -sdk iphonesimulator \
-configuration Release clean build | grep "warning generated." \
> /tmp/log_build 2> /tmp/error_build

RET=$?
echo "RET = ${RET}"
if [[ "${RET}" != "0" ]]
then
    send_mail "Error build ${ROJECT} fail :\nbuild failed"
    echo "Build failed" 1>&2
fi

NUMBER_ERRORS=$(cat /tmp/error_build | wc -l)
NUMBER_WARNINGS=$(cat /tmp/log_build | wc -l)

echo "Build "$PROJECT
echo "number error = ${NUMBER_ERRORS}"

if $MODE_DEBUG ; then
    if [ $NUMBER_WARNINGS -gt 0 ]; then
	send_mail "Error build ${ROJECT} fail :\nWarnings detected in the compilation"
	echo "Error warnings" 1>&2
    else
	echo "No warnings"
    fi
fi

ARCHIVE=$(find "/Users/$USER" -name *${PROJECT}*.xcarchive | head -1) 2> /dev/null
IPA_DIR=$(find "/Users/$USER" -name *.xcodeproj/project.xcworkspace | head -1) 2> /dev/null
APP=$(find "/Users/$USER/Library/Developer/Xcode/DerivedData/" -name "${PROJECT}" | head -1) 2> /dev/null
PATH_MOBILE_PROVISION=$(find "/Users/${USER}/Library/Developer/Xcode" -name "${PROJECT}*" | head -1) 2> /dev/null
MOBILE_PROVISION=$(find "${PATH_MOBILE_PROVISION}" -name *.mobileprovision | head -1) 2> /dev/null

if [[ -z $ARCHIVE ]] || [[ -z $IPA_DIR ]] || [[ -z $APP]] || [[ -z $PATH_MOBILE_PROVISION ]] || [[ -z $MOBILE_PROVISION ]]
then
    send_mail "Error build ${ROJECT} fail :\nError found project file"
    echo "Error found projects file" 1>&2
fi

xcodebuild -scheme $PROJECT clean 1> /tmp/log_clean 2> /dev/null
RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    send_mail "Error build ${PROJECT} fail :\nError clean project"
    echo "Error clean project" 1>&2
fi

xcodebuild -scheme $PROJECT archive 1> /tmp/log_archive
RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    send_mail "Error build ${PROJECT} fail :\nCreate archive failed"
    echo "Create archive failed" 1>&2
fi

APP=$(find "/Users/$USER/Library/Developer/Xcode/Archives/" -name "${PROJECT}.app" | head -1)

if [[ -z $APP ]]
then
    send_mail "Error build ${PROJECT} fail :\nApp project not found"
    echo "App project not found" 1>&2    
fi

echo "Second Part Over - Clean"
echo "Third Part Over - Archive"

DSYM=$(find /Users/$USER -name ${PROJECT}.app.dSYM | head -1)
DSYM="`(cd \"$DSYM\"; pwd)`"

cp -r "$DSYM" .
zip -r ${PROJECT}.app.dSYM.zip ${PROJECT}.app.dSYM
rm -rf ${PROJECT}.app.dSYM

PATH_IPA_TMP="/tmp/${PROJECT}.ipa"

echo "check ALL variable before IPA = "
echo "APP = "$APP


/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${APP}" -o "${PATH_IPA_TMP}" --sign $SIGNING_IDENTITY --embed "${MOBILE_PROVISION}" 1> /tmp/log_ipa 2> /dev/null

RET=$?
if [[ ! "${RET}" -eq "0" ]]
then
    send_mail "Error build ${PROJECT} fail :\nIPA failed"
    echo "IPA failed" 1>&2
fi

echo ".ipa generated"

/usr/bin/curl "http://testflightapp.com/api/builds.json" \
-F file=$PATH_IPA_TMP \
-F dsym=@"${PROJECT}.app.dSYM.zip" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build ${BUILD_NUMBER} uploaded automatically from script shell on in jenkins." \
-F notify=True \
-F distribution_lists='all'

sed -n '3,4p' /tmp/log_testflight

echo "Application sent to testflight.com"
echo "Clean tempory files"

rm -f /tmp/log_ipa \
/tmp/log_clean \
/tmp/log_archive \
/tmp/erro_build \
/tmp/log_build \
$PATH_IPA_TMP

exit 0
