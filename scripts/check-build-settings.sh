#!/bin/bash
destination=${1:?}
STATUS=0
assertSuccess() {
    if [ $? -ne 0 ];then
        echo "error: ${1}"
        STATUS=1
    fi
}
assertFailure() {
    if [ $? -eq 0 ];then
        echo "error: ${1}"
        STATUS=1
    fi
}

tmp=`mktemp`

checkValues="APPLICATION_EXTENSION_API_ONLY=YES"
for expected in $checkValues
do
    msg="[${destination}]: This platform should contain ${expected}"
    xcodebuild -project Async.xcodeproj -scheme Async -destination "$destination" -showBuildSettings 2> /dev/null | \
        tr -d " " > $tmp
    grep $expected $tmp
    assertSuccess "${msg}"
done

rm $tmp

exit $STATUS

