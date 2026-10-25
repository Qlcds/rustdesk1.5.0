#!/usr/bin/env bash

echo $MACOS_CODESIGN_IDENTITY
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
cd flutter
flutter pub get --enforce-lockfile

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

cd -
~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
./build.py --flutter
rm rustdesk-$VERSION.dmg
# security find-identity -v
codesign --force --options runtime -s $MACOS_CODESIGN_IDENTITY --deep --strict ./flutter/build/macos/Build/Products/Release/RustDesk.app -vvv
create-dmg --icon "RustDesk.app" 200 190 --hide-extension "RustDesk.app" --window-size 800 400 --app-drop-link 600 185 rustdesk-$VERSION.dmg ./flutter/build/macos/Build/Products/Release/RustDesk.app
codesign --force --options runtime -s $MACOS_CODESIGN_IDENTITY --deep --strict rustdesk-$VERSION.dmg -vvv
# notarize the rustdesk-${{ env.VERSION }}.dmg
rcodesign notary-submit --api-key-path ~/.p12/api-key.json  --staple rustdesk-$VERSION.dmg
