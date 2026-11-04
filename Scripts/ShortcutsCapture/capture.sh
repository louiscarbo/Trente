#!/bin/zsh
# Retakes the Shortcuts setup screenshots shown in Settings > Connect Trente to Apple Pay.
# Walks the Wallet automation flow in the Shortcuts app on headless simulators, once per
# language, and writes the crops into the asset catalog as localized images.
#
# Usage: Scripts/ShortcutsCapture/capture.sh
# Env:   SHORTCUTS_CAPTURE_LANGUAGES="fr ko" retakes only those, keeping the other captures.
#        SHORTCUTS_CAPTURE_SIMULATORS="A,B,C" spreads the languages over these simulators in
#        parallel. A simulator without Apple Intelligence skips the Edit step and keeps each
#        language's previous Edit image. The default simslim profile doesn't work yet: Shortcuts
#        finds no Trente action there, likely because the "siri" category (siriactionsd) is off.
#        SHORTCUTS_CAPTURE_SKIP_BUILD=1

set -euo pipefail

SCRIPT_DIR=${0:A:h}
ROOT=${SCRIPT_DIR:h:h}
DERIVED="$HOME/Library/Developer/Xcode/DerivedData/TrenteShortcutsCapture"
OUT="$DERIVED/captures"
ASSETS="$ROOT/Trente/Assets.xcassets/Shortcuts Setup"
ALL_LANGUAGES=(en en-GB fr es es-419 it de ko pt-BR pt-PT)
LANGUAGES=(${=SHORTCUTS_CAPTURE_LANGUAGES:-$ALL_LANGUAGES})
SIMULATORS=(${(s:,:)SHORTCUTS_CAPTURE_SIMULATORS:-Shortcuts Capture})
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-17
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-27-0

typeset -A LOCALES=(
    en en_US en-GB en_GB fr fr_FR es es_ES es-419 es_MX it it_IT
    de de_DE ko ko_KR pt-BR pt_BR pt-PT pt_PT
)

UDIDS=()

log() { print -r -- "[$(date +%H:%M:%S)] $*" }

cleanup() {
    for udid in $UDIDS; do
        xcrun simctl shutdown $udid 2>/dev/null || true
    done
}
trap cleanup EXIT
trap "cleanup; exit 1" ZERR

simulator_udid() {
    xcrun simctl list devices available -j | python3 -I -c '
import json, sys
devices = json.load(sys.stdin)["devices"].get(sys.argv[1], [])
print(next((d["udid"] for d in devices if d["name"] == sys.argv[2]), ""))
' $RUNTIME $1
}

build_trente() {
    if [[ -n ${SHORTCUTS_CAPTURE_SKIP_BUILD:-} ]]; then return; fi
    log "Building Trente Dev (low priority)…"
    taskpolicy -b xcodebuild \
        -project "$ROOT/Trente.xcodeproj" \
        -scheme "Trente Dev" \
        -configuration Debug \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath "$DERIVED" \
        -quiet build
}

# Shortcuts lists actions under the app's name, so the capture app is renamed "Trente".
prepare_app() {
    local built="$DERIVED/Build/Products/Debug-iphonesimulator/Trente Dev.app"
    [[ -d $built ]] || { log "Missing $built" >&2; exit 1 }
    local app="$DERIVED/capture-app/Trente.app"
    rm -rf "$app"
    mkdir -p "${app:h}"
    cp -R "$built" "$app"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Trente" "$app/Info.plist"
    codesign --force --sign - --preserve-metadata=entitlements "$app" 2>/dev/null
    print -r -- $app
}

build_runner() {
    log "Building the capture runner…"
    xcodegen generate --quiet --spec "$SCRIPT_DIR/project.yml" --project "$SCRIPT_DIR"
    taskpolicy -b xcodebuild build-for-testing \
        -project "$SCRIPT_DIR/ShortcutsCapture.xcodeproj" \
        -scheme CaptureHost \
        -destination "id=$UDIDS[1]" \
        -derivedDataPath "$DERIVED/runner" \
        -quiet
}

set_system_language() {
    local udid=$1 language=$2
    local prefs="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/Library/Preferences/.GlobalPreferences.plist"
    [[ -f $prefs ]] || plutil -create xml1 "$prefs"
    plutil -replace AppleLanguages -json "[\"$language\"]" "$prefs"
    plutil -replace AppleLocale -string $LOCALES[$language] "$prefs"
}

# Typing from XCUITest counts as a hardware keyboard; with minimization on, the software
# keyboard then stays hidden and the variable bar drops to the bottom of the screen.
keep_software_keyboard() {
    local prefs="$HOME/Library/Developer/CoreSimulator/Devices/$1/data/Library/Preferences/com.apple.keyboard.preferences.plist"
    [[ -f $prefs ]] || plutil -create xml1 "$prefs"
    plutil -replace AutomaticMinimizationEnabled -bool NO "$prefs"
}

boot() {
    local udid=$1
    xcrun simctl boot $udid
    xcrun simctl bootstatus $udid >/dev/null
    sleep 20
    xcrun simctl ui $udid appearance light
    xcrun simctl status_bar $udid override \
        --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

install_only_trente() {
    local udid=$1 app=$2
    for bundle in louiscarboestaque.Trente louiscarboestaque.Trente.dev louiscarboestaque.TrenteVingt; do
        xcrun simctl uninstall $udid $bundle 2>/dev/null || true
    done
    xcrun simctl install $udid "$app"
}

run_capture_test() {
    local udid=$1 folder=$2
    rm -rf "$folder"
    mkdir -p "$folder"
    TEST_RUNNER_OUTPUT_DIR="$folder" taskpolicy -b xcodebuild test-without-building \
        -project "$SCRIPT_DIR/ShortcutsCapture.xcodeproj" \
        -scheme CaptureHost \
        -destination "id=$udid" \
        -derivedDataPath "$DERIVED/runner" \
        -only-testing:CaptureUITests/ShortcutsSetupCaptureTests \
        -test-timeouts-enabled YES \
        -maximum-test-execution-time-allowance 300 \
        -quiet
}

# Each run adds a shortcut; with older ones around, Shortcuts names the new one "New Shortcut 2".
clear_shortcuts_library() {
    rm -f "$HOME/Library/Developer/CoreSimulator/Devices/$1/data/Library/Shortcuts"/Shortcuts.sqlite*
}

# New captures land next to the old ones and replace them only once complete,
# so a run without the Edit step keeps the previous Edit image.
capture_language() {
    local udid=$1 language=$2 app=$3
    local fresh="$OUT/new-$language"
    xcrun simctl shutdown $udid 2>/dev/null || true
    clear_shortcuts_library $udid
    set_system_language $udid $language
    keep_software_keyboard $udid
    boot $udid
    install_only_trente $udid "$app"
    log "Capturing $language…"
    if ! run_capture_test $udid "$fresh"; then
        log "Capture failed for $language, retrying once…"
        run_capture_test $udid "$fresh"
    fi
    xcrun simctl shutdown $udid
    mkdir -p "$OUT/$language"
    cp "$fresh"/* "$OUT/$language/"
    rm -rf "$fresh"
    log "Captured $language"
}

capture_queue() {
    trap - EXIT ZERR
    local udid=$1 app=$2
    shift 2
    for language in "$@"; do
        capture_language $udid $language "$app" || { log "Gave up on $language"; return 1 }
    done
}

write_asset_catalog() {
    log "Writing $ASSETS…"
    python3 -I - "$OUT" "$ASSETS" $ALL_LANGUAGES <<'PYTHON'
import json, pathlib, shutil, sys

captures, assets, languages = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3:]
shutil.rmtree(assets, ignore_errors=True)
assets.mkdir(parents=True)
(assets / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
for capture in sorted((captures / "en").glob("*.jpg")):
    image_set = assets / f"Shortcuts Setup {capture.stem}.imageset"
    image_set.mkdir()
    images = []
    for language in languages:
        filename = f"{capture.stem} {language}.jpg"
        shutil.copy(captures / language / capture.name, image_set / filename)
        entry = {"filename": filename, "idiom": "iphone"}
        if language != "en":
            entry["locale"] = language
        images.append(entry)
    contents = {"images": images, "info": {"author": "xcode", "version": 1}, "properties": {"localizable": True}}
    (image_set / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
PYTHON
}

for name in $SIMULATORS; do
    udid=$(simulator_udid $name)
    if [[ -z $udid ]]; then
        log "Creating $name…"
        udid=$(xcrun simctl create $name $DEVICE_TYPE $RUNTIME)
    fi
    UDIDS+=($udid)
done

build_trente
app=$(prepare_app)
build_runner

typeset -A QUEUES
for index in {1..${#LANGUAGES}}; do
    slot=$(( (index - 1) % ${#UDIDS} + 1 ))
    QUEUES[$slot]+="${LANGUAGES[index]} "
done
pids=()
for slot in {1..${#UDIDS}}; do
    [[ -n ${QUEUES[$slot]:-} ]] || continue
    capture_queue $UDIDS[slot] "$app" ${=QUEUES[$slot]} &
    pids+=($!)
done
failed=0
for pid in $pids; do
    wait $pid || failed=1
done
(( failed == 0 )) || { log "Some languages failed"; exit 1 }

for language in $ALL_LANGUAGES; do
    [[ -f "$OUT/$language/labels.json" ]] || { log "Missing captures for $language"; exit 1 }
done
write_asset_catalog
log "Done → $ASSETS"
