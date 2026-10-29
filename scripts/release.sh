#!/bin/sh
set -e

version="$1"
if ! echo "$version" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
    echo "usage: scripts/release.sh <version>   e.g. scripts/release.sh 1.0.1"
    exit 1
fi

cd "$(git rev-parse --show-toplevel)"

if [ "$(git rev-parse --abbrev-ref HEAD)" != "develop" ]; then
    echo "Run this from develop."
    exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is not clean."
    exit 1
fi
if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
    echo "Tag v$version already exists."
    exit 1
fi

git fetch --quiet origin
if [ "$(git rev-parse develop)" != "$(git rev-parse origin/develop)" ]; then
    echo "develop and origin/develop differ. Push or pull first."
    exit 1
fi

sed -i '' -E "s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $version;/" Trente.xcodeproj/project.pbxproj
if [ -n "$(git status --porcelain)" ]; then
    git commit --quiet -am "chore: set version to $version"
fi

git checkout --quiet prod 2>/dev/null || git checkout --quiet -b prod origin/prod
git merge --quiet --ff-only origin/prod
git merge --quiet --no-ff --no-edit -m "Release $version" develop
git tag -a "v$version" -m "Trente $version"
git checkout --quiet develop
git merge --quiet --ff-only prod

echo
echo "Ready: prod and develop are at Release $version, tagged v$version."
echo "Nothing was pushed. When you're happy:"
echo "    git push origin develop prod v$version"
