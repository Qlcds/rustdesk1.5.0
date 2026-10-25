#!/usr/bin/env bash
# https://docs.flutter.dev/deployment/ios
# flutter build ipa --release --obfuscate --split-debug-info=./split-debug-info
# no obfuscate, because no easy to check errors
cd "$(dirname "$(dirname "$(which flutter)")")"
git apply ~/rustdesk/.github/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff
cd -

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

flutter build ipa --release
