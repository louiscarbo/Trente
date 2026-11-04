#!/bin/sh
set -e

cd "$(git rev-parse --show-toplevel)"

git config merge.xcstrings.name "String Catalog merge, string by string and language by language"
git config merge.xcstrings.driver "python3 Scripts/merge-xcstrings.py %O %A %B"

echo "String Catalog merge driver set up for this clone."
