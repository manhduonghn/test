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

extract_filtered_links() {
    dpi=$1
    arch=$2
    type=$3

    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    BEGIN { link = ""; dpi_found = 0; arch_found = 0; type_found = 0; printed = 0 }
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }
    dpi && $0 ~ ("table-cell.*" dpi) { dpi_found = 1 }
    arch && $0 ~ ("table-cell.*" arch) { arch_found = 1 }
    type && $0 ~ ("<span class=\"apkm-badge\">" type) { type_found = 1 }
    dpi_found && arch_found && type_found && !printed {
        print link
        printed = 1
    }
    '
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


get_apkmirror_version() {
    grep -oP 'class="fontBlack"[^>]*href="[^"]+"\s*>\K[^<]+' | sed 20q | awk '{print $NF}'
}

apkmirror() {
    config_file="./apps/apkmirror/$1.json"
    org=$(jq -r '.org' "$config_file")
    name=$(jq -r '.name' "$config_file")
    type=$(jq -r '.type' "$config_file")
    arch=$(jq -r '.arch' "$config_file")
    dpi=$(jq -r '.dpi' "$config_file")
    package=$(jq -r '.package' "$config_file")
    version=$(jq -r '.version' "$config_file")

    version="${version:-$(get_supported_version "$package")}"
    url="https://www.apkmirror.com/uploads/?appcategory=$name"
    version="${version:-$(req - $url | get_apkmirror_version | get_latest_version)}"
    url="https://www.apkmirror.com/apk/$org/$name/$name-${version//./-}-release"
    url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "$dpi" "$arch" "$type")"
    url="https://www.apkmirror.com$(req - "$url" | grep -oP 'class="[^"]*downloadButton[^"]*"[^>]*href="\K[^"]+')"
    url="https://www.apkmirror.com$(req - "$url" | grep -oP 'id="download-link"[^>]*href="\K[^"]+')"
    req $name-v$version.apk $url
}

download_resources
apkmirror "youtube"
apkmirror "youtube-music"
