#!/usr/bin/env bash
# Runs inside the API 33 emulator step. Installs each exact APK with two
# methods and captures PackageManager / logcat output. Never stops early.
set -u
mkdir -p diag
adb shell getprop ro.build.version.sdk
adb shell getprop ro.product.cpu.abilist
for label in working failing; do
  apk="apks/$label/app-debug.apk"
  echo "::group::install $label"
  adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
  adb logcat -c
  echo "-- adb install -r (streamed session)"
  adb install -r "$apk" 2>&1 | tee "diag/install-$label.txt"
  echo "-- installed?"; adb shell pm list packages "$PACKAGE" | tee -a "diag/install-$label.txt"
  adb shell dumpsys package "$PACKAGE" | grep -E "versionName|primaryCpuAbi|targetSdk|minSdk|codePath|flags" | head -12
  echo "-- launch"
  adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
  sleep 20
  echo "pid: $(adb shell pidof "$PACKAGE" || echo none)"
  adb logcat -d > "diag/logcat-$label.txt"
  grep -E "PackageManager|PackageInstaller|INSTALL_|InstallParams|FATAL|AndroidRuntime|flutter" "diag/logcat-$label.txt" | tail -40
  echo "-- push + pm install (non-streamed, like a file-manager install)"
  adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
  adb push "$apk" /data/local/tmp/check.apk >/dev/null
  adb shell pm install -r /data/local/tmp/check.apk 2>&1 | tee -a "diag/install-$label.txt"
  adb shell rm -f /data/local/tmp/check.apk
  echo "::endgroup::"
done
echo "== summary"; for f in diag/install-*.txt; do echo "$f:"; cat "$f"; done
