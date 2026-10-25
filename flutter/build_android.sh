#!/usr/bin/env bash

MODE=${MODE:=release}
"${ANDROID_NDK_HOME}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip" android/app/src/main/jniLibs/arm64-v8a/*
flutter packages pub get --enforce-lockfile

# basilgello: Unfortunately, this protection is not enough to prevent hijack
# because `flutter build` calls another `dart pub get` under the hood and we
# can not pass `--enforce-lockfile` to `flutter build` to make it enforce the
# lockfile.
#
# We can not pass `--no-pub` to `flutter build` either because it also disables
# generation of flutter headers and causes weird CMake errors like
# `missing flutter_generated.cmake`.
#
# However, we can abuse the fact that `flutter build` skips unprotected `pub get`
# entirely if package lockfile (`.dart_tool/package_lock.json`) was created by
# the generator other than `pub`.
#
# So we patch that file so `flutter build` skips unprotected package re-resolution.
if [ -f '.dart_tool/package_lock.json' ]; then
  sed -i -e 's/"pub"/"pubForced"/' '.dart_tool/package_lock.json'
fi

flutter build apk --target-platform android-arm64,android-arm "--${MODE}" --obfuscate --split-debug-info ./split-debug-info
flutter build apk --split-per-abi --target-platform android-arm64,android-arm "--${MODE}" --obfuscate --split-debug-info ./split-debug-info
flutter build appbundle --target-platform  android-arm64,android-arm "--${MODE}" --obfuscate --split-debug-info ./split-debug-info

# build in linux
# $ANDROID_NDK/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip android/app/src/main/jniLibs/arm64-v8a/*
