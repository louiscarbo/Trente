#!/bin/sh
set -e

if [ "$CI_XCODEBUILD_ACTION" != "archive" ] || [ -z "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
    exit 0
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"
git fetch --tags --quiet || true

previous_tag=$(git describe --tags --abbrev=0 --match 'v*' HEAD^ 2>/dev/null || true)
range="${previous_tag:+$previous_tag..}HEAD"

mkdir -p TestFlight
git log "$range" --no-merges --pretty='%s' \
    | grep -E '^(feat|fix)' \
    | sed -E 's/^(feat|fix)(\([^)]*\))?: /- /' \
    | head -n 40 \
    > TestFlight/WhatToTest.en-US.txt

echo "What to Test ($range):"
cat TestFlight/WhatToTest.en-US.txt
