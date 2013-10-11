#!/bin/bash
# file: script_build_ios.sh
#/usr/bin/xcodebuild -target TargetYouWantToBuild -configuration Debug

path_project='pdfcomponent_with_vf'
configuration='Debug'
path_xcodebuilder='/usr/bin/xcodebuild'
command=$path_xcodebuilder' -target '$path_project' -configuration '$configuration
ls='ls -l'

echo 'try build : ' $path_fgproject
echo 'command build : ' $command
ls -l /usr/bin/xcodebuild > /dev/null
$command | grep "warning generated." > /tmp/log_config 2> /tmp/error_compile

number_errors==$(cat /tmp/error_compile | wc -l)
number_warnings=$(cat /tmp/log_config | wc -l)

if [ $number_errors -gt 0 ]; then
    2> echo "Compilation failed"
else
    echo "Compilation success"
fi

if [ $number_warnings -gt 0 ]; then
    2> echo "warnings!"
else
    echo "no warnings"
fi
