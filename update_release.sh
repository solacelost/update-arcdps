#!/bin/bash
# This script is just for me to update releases easier and is run from my Linux
#   laptop. It's not part of the normal release, not copied on updates, and
#   isn't necessary for installation.
while [ $# -gt 0 ]; do
    case $1 in
        -c|--commit)
            commit='true' ;;
        *)
            echo "Unknown option, $1" >&2
            exit 1
            ;;
    esac; shift
done

cd $(realpath $(dirname $0))
if ! git status |& grep -qF 'nothing to commit, working tree clean'; then
    echo 'Your working directory is dirty. Please commit changes.' >&2
    exit 1
fi

read -p 'Version of the new update: ' new_version

if ! echo "$new_version" | grep -q '^[0-9]\.[0-9]\.[0-9]$'; then
    echo "Version must match bare semver standards for major.minor.patch (e.g. 0.1.2)" >&2
    exit 2
fi

if ! grep -qF "    $new_version - " Update-ArcDPS.ps1; then
    read -p 'Enter update text for the new version: ' update_text
    update_text_lines=$(echo "$update_text" | fold -s -w68)
    update_text_firstline=$(echo "$update_text_lines" | head -1)
    update_text_remainder=$(echo "$update_text_lines" | tail -n +2)
    sed -i '/^    Version History:$/a'"\            $update_text_remainder" Update-ArcDPS.ps1
    sed -i '/^    Version History:$/a'"\    $new_version - $update_text_firstline" Update-ArcDPS.ps1
fi
sed -i 's/\$scriptversion = .*/\$scriptversion = '"'$new_version'"'/' Update-ArcDPS.ps1
sed -i 's/SCRIPT VERSION: .*/SCRIPT VERSION: '"$new_version"'/' Update-ArcDPS.ps1
sed -i 's/\/[0-9]\.[0-9]\.[0-9]\//\/'"$new_version"'\//g' Bootstrap-ArcDPS.ps1
sed -i 's/\/[0-9]\.[0-9]\.[0-9]\//\/'"$new_version"'\//g' docs/README.md

if [ -n "$commit" ]; then
    git add Update-ArcDPS.ps1
    git add Bootstrap-ArcDPS.ps1
    git add docs/README.md
    git commit -m "Bumping to version $new_version"
    if [ -n "$update_text" ]; then
        git tag -s $new_version -m "Releasing version $new_version" -m "$update_text"
    else
        git tag -s $new_version -m "Releasing version $new_version"
    fi
    git push
    git push --tags
fi
