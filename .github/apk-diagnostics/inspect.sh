#!/usr/bin/env bash
# Static inspection of the downloaded APKs. Prints everything to the log.
set -uo pipefail
BT=$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)
echo "build-tools: $BT"
mkdir -p diag
status=0
for label in working failing; do
  apk="apks/$label/app-debug.apk"
  want_var="$(echo "$label" | tr a-z A-Z)_SHA256"
  want="${!want_var}"
  echo "::group::$label APK"
  ls -la "apks/$label"
  if [ ! -f "$apk" ]; then echo "MISSING $apk"; status=1; echo "::endgroup::"; continue; fi
  got=$(sha256sum "$apk" | cut -d' ' -f1)
  echo "size: $(stat -c %s "$apk") bytes"
  echo "sha256: $got"
  if [ "$got" = "$want" ]; then echo "SHA256 MATCHES build log"; else echo "SHA256 MISMATCH (expected $want)"; status=1; fi
  echo "-- unzip -t"; unzip -tq "$apk" || status=1
  echo "-- aapt2 dump badging"; "$BT/aapt2" dump badging "$apk" 2>&1 | grep -E "^package|sdkVersion|native-code|application-debuggable|testOnly|uses-feature" || status=1
  echo "-- manifest attributes"; "$BT/aapt2" dump xmltree --file AndroidManifest.xml "$apk" | grep -E "minSdk|targetSdk|testOnly|extractNativeLibs|debuggable|package=" || true
  echo "-- native libraries (method, size, name)"; unzip -v "$apk" | grep '\.so$' | awk '{print $2, $1, $8}'
  echo "-- apksigner"; "$BT/apksigner" verify --verbose --print-certs "$apk" 2>&1 | grep -vE '^WARNING: META-INF' || status=1
  echo "-- zipalign -c -v 4"; "$BT/zipalign" -c -v 4 "$apk" | tail -1 || status=1
  echo "-- zipalign -c -P 16 -v 4"; "$BT/zipalign" -c -P 16 -v 4 "$apk" | grep -E '\.so|Verification' || status=1
  echo "-- entry list"; unzip -Z1 "$apk" | sort > "diag/entries-$label.txt"; wc -l < "diag/entries-$label.txt"
  echo "::endgroup::"
done
echo "-- entries only in working:"; comm -23 diag/entries-working.txt diag/entries-failing.txt || true
echo "-- entries only in failing:"; comm -13 diag/entries-working.txt diag/entries-failing.txt || true
exit $status
