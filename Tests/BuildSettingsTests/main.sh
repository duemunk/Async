#!/bin/bash
DESTINATION=${1:?}

echo "=== BuildSettingsTests started ==="

BUILD_SETTINGS=$(make settings DESTINATION="$DESTINATION" | tr -d " ")
set +e
MISSING=
BASE_DIR=$(cd $(dirname $0);pwd)
EXPECTED_XCCONFIG=$BASE_DIR/expected.xcconfig
while read expected
do
    if ! echo "$BUILD_SETTINGS" | grep $expected
    then
        MISSING="${MISSING} ${expected}"
    fi
done < $EXPECTED_XCCONFIG
if [ "$MISSING" ]
then
    echo "Missing configurations detected. : ${MISSING}"
    exit 1
fi
echo "Test Successful."
echo "=== BuildSettingsTests ended ==="
exit 0
