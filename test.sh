#!/bin/bash

req() {
    wget --header="User-Agent: Mozilla/5.0 (Android 13; Mobile; rv:125.0) Gecko/125.0 Firefox/125.0" \
         --header="Content-Type: application/octet-stream" \
         --header="Accept-Language: en-US,en;q=0.9" \
         --header="Connection: keep-alive" \
         --header="Upgrade-Insecure-Requests: 1" \
         --header="Cache-Control: max-age=0" \
         --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
         --keep-session-cookies --timeout=30 -nv -O "$@"
}

# Find max version
max() {
	local max=0
	while read -r v || [ -n "$v" ]; do
		if [[ ${v//[!0-9]/} -gt ${max//[!0-9]/} ]]; then max=$v; fi
	done
	if [[ $max = 0 ]]; then echo ""; else echo "$max"; fi
}

# Get largest version (Just compatible with my way of getting versions code)
get_latest_version() {
    grep -Evi 'alpha|beta' | grep -oPi '\b\d+(\.\d+)+(?:\-\w+)?(?:\.\d+)?(?:\.\w+)?\b' | max
}

# Read highest supported versions from Revanced 
get_supported_version() {
    package_name=$1
    output=$(java -jar revanced-cli*.jar list-versions -f "$package_name" patch*.rvp)
    version=$(echo "$output" | tail -n +3 | sed 's/ (.*)//' | grep -v -w "Any" | max | xargs)
    echo "$version"
}

# Download necessary resources to patch from Github latest release 
download_resources() {
    for repo in revanced-patches revanced-cli ; do
        githubApiUrl="https://api.github.com/repos/revanced/$repo/releases/latest"
        page=$(req - 2>/dev/null $githubApiUrl)
        assetUrls=$(echo $page | jq -r '.assets[] | select(.name | endswith(".asc") | not) | "\(.browser_download_url) \(.name)"')
        while read -r downloadUrl assetName; do
            req "$assetName" "$downloadUrl" 
        done <<< "$assetUrls"
    done
}

apkpure() {
    config_file="./apps/apkpure/$1.json"
    name=$(jq -r '.name' "$config_file")
    package=$(jq -r '.package' "$config_file")
    version=$(jq -r '.version' "$config_file")
    url="https://apkpure.net/$name/$package/versions"
    version="${version:-$(get_supported_version "$package")}"
    version="${version:-$(req - $url | grep -oP 'data-dt-version="\K[^"]*' | sed 10q | get_latest_version)}"
    url="https://apkpure.net/$name/$package/download/$version"
    url=$(req - $url | grep -oP '<a[^>]*id="download_link"[^>]*href="\K[^"]*' | head -n 1)
    req $name-v$version.apk "$url"
}

apkpure "youtube"
apkpure "youtube-music"
