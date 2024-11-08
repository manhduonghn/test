#!/bin/bash
req() {
    wget --header="User-Agent: Mozilla/5.0 (Android 13; Mobile; rv:125.0) Gecko/125.0 Firefox/125.0" \
         --header="Content-Type: application/octet-stream" \
         --header="Accept-Language: en-US,en;q=0.9" \
         --header="Connection: keep-alive" \
         --header="Upgrade-Insecure-Requests: 1" \
         --header="Cache-Control: max-age=0" \
         --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
         --keep-session-cookies --timeout=30 -nv -O "$1" "$2"
}

download_resources() {
    for repo in revanced-patches revanced-cli; do
        githubApiUrl="https://api.github.com/repos/revanced/$repo/releases"
        page=$(req - 2>/dev/null "$githubApiUrl")
        assetUrls=$(echo "$page" | jq -r '[.[] | select(.prerelease == true)] | sort_by(.created_at) | last | .assets[] | select(.name | endswith(".asc") | not) | "\(.browser_download_url) \(.name)"')
        while read -r downloadUrl assetName; do
            req "$assetName" "$downloadUrl" 
        done <<< "$assetUrls"
    done
}

find_max_version() {
    package_name=$1
    output=$(java -jar revanced-cli*.jar list-versions -f "$package_name" patch*.rvp)
    version=$(echo "$output" | tail -n +3 | sed 's/ (.*)//' | grep -v -w "Any" | head -n 1 | xargs)
    echo "$version"
}

# Main

download_resources

version=$(find_max_version "com.google.android.music")

echo "$version"
