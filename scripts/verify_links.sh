#!/bin/bash

# Android App Link Verification Helper
PACKAGE_NAME="com.gajanan.maharaj.sevekari"
DOMAIN="gajananmaharajsevekari.org"

echo "----------------------------------------------------------------"
echo "Android App Link Verification Helper"
echo "----------------------------------------------------------------"

# 1. Check if device is connected
adb devices | grep -v "List of devices" | grep "device" > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: No Android device connected via ADB."
    exit 1
fi

echo "1. Testing Namjap Deep Link (https://$DOMAIN/namjap/test)..."
adb shell am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "https://$DOMAIN/namjap/test"
echo "Check your device: App should open to Namjap Detail screen."
sleep 2

echo -e "\n2. Testing Parayan Deep Link (https://$DOMAIN/parayan/test)..."
adb shell am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "https://$DOMAIN/parayan/test"
echo "Check your device: App should open to Parayan Detail screen."
sleep 2

echo -e "\n3. Checking System Verification Status..."
adb shell dumpsys package d | grep -A 10 "$PACKAGE_NAME"
echo "----------------------------------------------------------------"
echo "Verification Complete."
echo "If the status is not 'always', check your assetlinks.json hosting."
