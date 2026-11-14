#!/bin/zsh
# Retakes the App Store dashboard captures without taking over the Mac:
# low-priority builds, headless simulators, Mac window activated for ~1 s per language.
#
# Usage: Scripts/StoreCapture/capture.sh [iphone] [ipad] [mac] [duo]
# Env:   STORE_CAPTURE_LANGUAGES="en fr"  STORE_CAPTURE_MAC_APPEARANCES="dark"
#        STORE_CAPTURE_OUT=<dir>  STORE_CAPTURE_SKIP_BUILD=1

set -euo pipefail

SCRIPT_DIR=${0:A:h}
ROOT=${SCRIPT_DIR:h:h}
OUT=${STORE_CAPTURE_OUT:-"$HOME/Pictures/Trente App Store Captures/$(date +%F)"}
DERIVED=${STORE_CAPTURE_DERIVED_DATA:-"$HOME/Library/Developer/Xcode/DerivedData/TrenteStoreCapture"}
LANGUAGES=(${=STORE_CAPTURE_LANGUAGES:-en fr es it de ko pt-BR pt-PT da el ja sv nb})
TARGETS=("$@")
(( $# )) || TARGETS=(iphone ipad mac duo)
MAC_APPEARANCES=(${=STORE_CAPTURE_MAC_APPEARANCES:-light dark})
SETTLE=${STORE_CAPTURE_SETTLE:-15}
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-27-0
IPHONE_NAME="iPhone 17 Pro Max"
IPAD_NAME="iPad Pro 13-inch (M5)"
DUO_NAME="iPhone Duo"
DUO_RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-27-1
DUO_HINGE="$ROOT/Scripts/DuoHinge/duo-hinge"
DUO_FOLDED_ANGLE=165
MAC_WINDOW=(1260 800)
HELPER="$DERIVED/store-capture-helper"

typeset -A LOCALES=(en en_US fr fr_FR es es_ES it it_IT de de_DE ko ko_KR pt-BR pt_BR pt-PT pt_PT da da_DK el el_GR ja ja_JP sv sv_SE nb nb_NO)

BOOTED_UDID=""
MAC_PID=""

log() { print -r -- "[$(date +%H:%M:%S)] $*" }

cleanup() {
    [[ -n $MAC_PID ]] && kill $MAC_PID 2>/dev/null || true
    [[ -n $BOOTED_UDID ]] && xcrun simctl shutdown $BOOTED_UDID 2>/dev/null || true
}
trap cleanup EXIT
trap "cleanup; exit 1" ZERR

build() {
    local destination=$1
    if [[ -n ${STORE_CAPTURE_SKIP_BUILD:-} ]]; then return; fi
    log "Building for $destination (low priority)…"
    taskpolicy -b xcodebuild \
        -project "$ROOT/Trente.xcodeproj" \
        -scheme "Trente Dev" \
        -configuration Debug \
        -destination "$destination" \
        -derivedDataPath "$DERIVED" \
        -quiet build
}

app_in() {
    local apps=("$DERIVED/Build/Products/$1"/*.app(N))
    (( ${#apps} == 1 )) || { log "Expected one app in $1"; exit 1 }
    print -r -- $apps[1]
}

compile_helper() {
    local source="$SCRIPT_DIR/StoreCaptureHelper.swift"
    if [[ ! -x $HELPER || $source -nt $HELPER ]]; then
        mkdir -p "$DERIVED"
        taskpolicy -b xcrun swiftc -O "$source" -o "$HELPER"
    fi
}

udid_for() {
    xcrun simctl list devices available -j | python3 -I -c '
import json, sys
devices = json.load(sys.stdin)["devices"].get(sys.argv[1], [])
print(next(d["udid"] for d in devices if d["name"] == sys.argv[2]))
' ${2:-$RUNTIME} $1
}

set_system_language() {
    local udid=$1 language=$2
    local prefs="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/Library/Preferences/.GlobalPreferences.plist"
    [[ -f $prefs ]] || plutil -create xml1 "$prefs"
    plutil -replace AppleLanguages -json "[\"$language\"]" "$prefs"
    plutil -replace AppleLocale -string $LOCALES[$language] "$prefs"
    if [[ $language == en ]]; then
        plutil -remove AppleICUForce24HourTime "$prefs" 2>/dev/null || true
    else
        plutil -replace AppleICUForce24HourTime -bool YES "$prefs"
    fi
}

boot() {
    local udid=$1 clock=${2:-9:41}
    log "Booting $udid headless…"
    xcrun simctl boot $udid
    BOOTED_UDID=$udid
    xcrun simctl bootstatus $udid >/dev/null
    sleep $(( SETTLE * 2 ))
    xcrun simctl status_bar $udid override \
        --time "$clock" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

shutdown_booted() {
    if [[ -z $BOOTED_UDID ]]; then return; fi
    xcrun simctl shutdown $BOOTED_UDID
    BOOTED_UDID=""
}

launch_ios() {
    local udid=$1 bundle=$2 language=$3
    xcrun simctl launch --terminate-running-process $udid $bundle \
        -storeCapture -AppleLanguages "($language)" -AppleLocale $LOCALES[$language] >/dev/null
    sleep $SETTLE
}

screenshot_ios() {
    local udid=$1 bundle=$2 language=$3 file=$4
    xcrun simctl io $udid screenshot --type=png "$file" >/dev/null 2>&1
    if (( $("$HELPER" distinct-colors "$file") < 8 )); then
        log "Blank shot, retrying once: ${file:t}"
        launch_ios $udid $bundle $language
        xcrun simctl io $udid screenshot --type=png "$file" >/dev/null 2>&1
    fi
}

capture_language_ios() {
    local udid=$1 bundle=$2 language=$3 device=$4
    local folder="$OUT/$language"
    mkdir -p "$folder"
    for appearance in light dark; do
        xcrun simctl ui $udid appearance $appearance
        launch_ios $udid $bundle $language
        local file="$folder/$device-dashboard-$appearance.png"
        screenshot_ios $udid $bundle $language "$file"
        if [[ $device == ipad ]]; then "$HELPER" paint-grabber "$file"; fi
        log "Saved $language/${file:t}"
    done
}

prepare_ios_app() {
    local app=$(app_in Debug-iphonesimulator)
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Trente" "$app/Info.plist"
    codesign --force --sign - --preserve-metadata=entitlements "$app" 2>/dev/null
    print -r -- $app
}

capture_iphone() {
    local app=$1 bundle=$2 udid=$(udid_for $IPHONE_NAME)
    for language in $LANGUAGES; do
        set_system_language $udid $language
        boot $udid
        xcrun simctl install $udid "$app"
        capture_language_ios $udid $bundle $language iphone
        shutdown_booted
    done
}

capture_ipad() {
    local app=$1 bundle=$2 udid=$(udid_for $IPAD_NAME)
    for language in $LANGUAGES; do
        set_system_language $udid $language
        boot $udid
        xcrun simctl install $udid "$app"
        capture_language_ios $udid $bundle $language ipad
        shutdown_booted
    done
}

set_duo_system_language() {
    local udid=$1 language=$2
    local prefs="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/Library/Preferences/.GlobalPreferences.plist"
    [[ -f $prefs ]] || plutil -create xml1 "$prefs"
    plutil -replace AppleLanguages -json "[\"$language\"]" "$prefs"
    plutil -replace AppleLocale -string $LOCALES[$language] "$prefs"
    plutil -remove AppleICUForce24HourTime "$prefs" 2>/dev/null || true
    plutil -remove AppleICUForce12HourTime "$prefs" 2>/dev/null || true
    case $language in
        en) ;;
        es) plutil -replace AppleICUForce12HourTime -bool YES "$prefs" ;;
        *) plutil -replace AppleICUForce24HourTime -bool YES "$prefs" ;;
    esac
}

duo_clock() {
    case $1 in
        en|es|ja) print -r -- "9:41" ;;
        da) print -r -- "09.41" ;;
        *) print -r -- "09:41" ;;
    esac
}

set_duo_pose() {
    local udid=$1 angle=$2 orientation=$3
    "$DUO_HINGE" $angle --orientation $orientation --device $udid --verify >/dev/null \
        || { log "The hinge did not move to $angle°"; exit 1 }
}

screenshot_duo() {
    local udid=$1 bundle=$2 language=$3 display=$4 file=$5 launch_flags=$6
    xcrun simctl io $udid screenshot --display=$display --type=png "$file" >/dev/null 2>&1
    if (( $("$HELPER" distinct-colors "$file") < 8 )); then
        log "Blank shot, retrying once: ${file:t}"
        launch_duo $udid $bundle $language $=launch_flags
        xcrun simctl io $udid screenshot --display=$display --type=png "$file" >/dev/null 2>&1
    fi
}

launch_duo() {
    local udid=$1 bundle=$2 language=$3
    shift 3
    xcrun simctl launch --terminate-running-process $udid $bundle \
        -storeCapture $@ -AppleLanguages "($language)" -AppleLocale $LOCALES[$language] >/dev/null
    sleep $SETTLE
}

capture_duo() {
    local app=$1 bundle=$2 udid=$(udid_for $DUO_NAME $DUO_RUNTIME)
    simslim on $udid --preserve-boot-state >/dev/null
    for language in $LANGUAGES; do
        local folder="$OUT/$language"
        mkdir -p "$folder"
        set_duo_system_language $udid $language
        boot $udid $(duo_clock $language)
        xcrun simctl install $udid "$app"
        xcrun simctl ui $udid appearance light

        launch_duo $udid $bundle $language
        screenshot_duo $udid $bundle $language primary "$folder/duo-closed.png" ""
        log "Saved $language/duo-closed.png"

        set_duo_pose $udid 180 landscape-left
        launch_duo $udid $bundle $language
        screenshot_duo $udid $bundle $language primary-1 "$folder/duo-open.png" ""
        log "Saved $language/duo-open.png"

        set_duo_pose $udid $DUO_FOLDED_ANGLE portrait
        launch_duo $udid $bundle $language -storeCaptureDetailOnly
        screenshot_duo $udid $bundle $language primary-1 "$folder/duo-folded.png" "-storeCaptureDetailOnly"
        log "Saved $language/duo-folded.png"
        shutdown_booted
    done
}

frontmost_bundle() {
    lsappinfo info "$(lsappinfo front)" | sed -n 's/.*bundleID="\(.*\)".*/\1/p' | head -1
}

capture_mac() {
    local app=$(app_in Debug)
    local executable="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$app/Contents/Info.plist")"
    local window front
    for language in $LANGUAGES; do
        mkdir -p "$OUT/$language"
        for appearance in $MAC_APPEARANCES; do
            local flags=(-storeCapture)
            if [[ $appearance == dark ]]; then flags+=(-storeCaptureDark); fi
            open -g -n -a "$app" --args \
                $flags -AppleLanguages "($language)" -AppleLocale $LOCALES[$language] \
                -ApplePersistenceIgnoreState YES
            sleep 2
            MAC_PID=$(pgrep -n -f "^$executable")
            # SwiftUI opens no window when launched in the background; a reopen event creates it.
            open -g -a "$app"
            window=""
            for attempt in {1..15}; do
                sleep 2
                window=$("$HELPER" window-id $MAC_PID $MAC_WINDOW 2>/dev/null) && break
                if (( attempt == 5 )); then open -g -a "$app"; fi
            done
            [[ -n $window ]] || { log "No window for $language $appearance"; exit 1 }
            sleep $SETTLE
            # Inactive windows draw grey traffic lights: activate for one second, then hand focus back.
            front=$(frontmost_bundle)
            open -a "$app"
            sleep 1
            local file="$OUT/$language/mac-dashboard-$appearance.png"
            screencapture -o -x -l $window "$file"
            if ! "$HELPER" check-mac-shot "$file" $(( MAC_WINDOW[1] * 2 )); then
                log "Retrying once: $language/${file:t}"
                open -a "$app"
                sleep 1
                screencapture -o -x -l $window "$file"
            fi
            if [[ -n $front ]]; then open -b $front; fi
            log "Saved $language/mac-dashboard-$appearance.png"
            kill $MAC_PID
            while kill -0 $MAC_PID 2>/dev/null; do sleep 1; done
            MAC_PID=""
        done
    done
}

compile_helper

if (( ${TARGETS[(I)iphone]} || ${TARGETS[(I)ipad]} || ${TARGETS[(I)duo]} )); then
    build "generic/platform=iOS Simulator"
    ios_app=$(prepare_ios_app)
    ios_bundle=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$ios_app/Info.plist")
    if (( ${TARGETS[(I)iphone]} )); then capture_iphone "$ios_app" $ios_bundle; fi
    if (( ${TARGETS[(I)ipad]} )); then capture_ipad "$ios_app" $ios_bundle; fi
    if (( ${TARGETS[(I)duo]} )); then capture_duo "$ios_app" $ios_bundle; fi
fi

if (( ${TARGETS[(I)mac]} )); then
    build "platform=macOS"
    capture_mac
fi

log "Done → $OUT"
