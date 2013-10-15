export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

MODE_DEBUG=false
API_TOKEN=3afe2aac8655ec73f6b3495d4ab42ff5_MTExMTM0OTIwMTMtMDYtMTQgMDY6MDU6NTMuNzMzNzI3
TEAM_TOKEN=94cd09572b29a973f20ac0dbaad361db_MjM2NTY2MjAxMy0wNi0xNCAwNjoxNjoxMC42NzIwMjU 
PROJECT="pdfcomponent_with_vf"
SIGNING_IDENTITY="iPhone Distribution: Extentia Information Technology" 
PROVISIONING_PROFILE="${WORKSPACE}/AdHoc_Distribution.mobileprovision"

xcodebuild -scheme $PROJECT -sdk iphonesimulator \
-configuration Release clean build | grep "warning generated." \
> /tmp/log_build 2> /tmp/error_build

NUMBER_ERRORS=$(cat /tmp/error_build | wc -l)
NUMBER_WARNINGS=$(cat /tmp/log_build | wc -l)

echo "Build "$PROJECT

if [ $NUMBER_ERRORS -gt 0 ]; then
    echo "Build failed" 1>&2
else
    echo "First Part Over - Build"
fi

if $MODE_DEBUG ; then
    if [ $NUMBER_WARNINGS -gt 0 ]; then
	echo "Error warnings" 1>&2
    else
	echo "No warnings"
    fi
fi

ARCHIVE=$(find $HOME -name *${PROJECT}*.xcarchive | head -1)
IPA_DIR=$(find $HOME -name *.xcodeproj/project.xcworkspace | head -1)
APP=$(find . -name *.app)
MOBILE_PROVISION=$(find . -name *.mobileprovision)

xcodebuild -scheme $PROJECT clean 1> /tmp/log_clean
echo "Second Part Over - Clean"
xcodebuild -scheme $PROJECT archive 1> /tmp/log_archive
echo "Third Part Over - Archive"

DSYM=$(find $HOME -name ${PROJECT}.app.dSYM | head -1)
cp -r $DSYM .
zip -r ${PROJECT}.app.dSYM.zip ${PROJECT}.app.dSYM
rm -rf ${PROJECT}.app.dSYM

PATH_IPA_TMP="/tmp/${PROJECT}.ipa"

/usr/bin/xcrun -sdk iphoneos PackageApplication -v $APP -o $PATH_IPA_TMP \
--sign $SIGNING_IDENTITY --embed $MOBILE_PROVISION 1> /tmp/log_ipa

echo ".ipa generated"

/usr/bin/curl "http://testflightapp.com/api/builds.json" \
-F file=$PATH_IPA_TMP \
-F dsym=@"${PROJECT}.app.dSYM.zip" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build ${BUILD_NUMBER} uploaded automatically from Xcode." \
-F notify=True \
-F distribution_lists='all' > /tmp/log_testflight

sed -n '3,4p' /tmp/log_testflight

echo "Application sent to testflight.com"
echo "Clean tempory files"
rm -f /tmp/log_testflight \
/tmp/log_ipa \
/tmp/log_clean \
/tmp/log_archive \
/tmp/erro_build \
/tmp/log_build \
$PATH_IPA_TMP
