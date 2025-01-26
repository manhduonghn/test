#!/bin/bash
# Script make by Mạnh Dương

# Make requests like send from Firefox Android 
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

# Filtered key words to extract link
extract_filtered_links() {
    local dpi="$1" arch="$2" type="$3"
    
    perl -ne '
        BEGIN {
            $block = ""; $link = ""; $found_dpi = $found_arch = $found_type = $printed = 0;
        }
        if (/<a class="accent_color"/) {
            if ($printed) { next; }
            if ($block ne "" && $link ne "" && $found_dpi && $found_arch && $found_type && !$printed) {
                print "$link\n";
                $printed = 1;
            }
            $block = $_; $found_dpi = $found_arch = $found_type = 0;
            $link = $1 if /href="([^"]+)"/;
        } else {
            $block .= $_;
        }
        $found_dpi = 1 if /table-cell/ && /'"$dpi"'/;
        $found_arch = 1 if /table-cell/ && /'"$arch"'/;
        $found_type = 1 if /apkm-badge/ && />'"$type"'<\/span>/;
        END {
            if ($block ne "" && $link ne "" && $found_dpi && $found_arch && $found_type && !$printed) {
                print "$link\n";
            }
        }
    ' 
}

# Get some versions of application on APKmirror pages 
get_apkmirror_version() {
    grep -oP 'class="fontBlack"[^>]*href="[^"]+"\s*>\K[^<]+' | sed 20q | awk '{print $NF}'
}

# Best but sometimes not work because APKmirror protection 
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

# X not work (maybe more)
uptodown() {
    config_file="./apps/uptodown/$1.json"
    name=$(jq -r '.name' "$config_file")
    package=$(jq -r '.package' "$config_file")
    version=$(jq -r '.version' "$config_file")
    version="${version:-$(get_supported_version "$package")}"
    url="https://$name.en.uptodown.com/android/versions"
    version="${version:-$(req - 2>/dev/null $url | grep -oP 'class="version">\K[^<]+' | get_latest_version)}"

    # Fetch data_code
    data_code=$(req - "$url" | grep 'detail-app-name' | grep -oP '(?<=data-code=")[^"]+')

    page=1
    while :; do
        json=$(req - "https://$name.en.uptodown.com/android/apps/$data_code/versions/$page" | jq -r '.data')
        
        # Exit if no valid JSON or no more pages
        [ -z "$json" ] && break
        
        # Search for version URL
        version_url=$(echo "$json" | jq -r --arg version "$version" '[.[] | select(.version == $version and .kindFile == "apk")][0].versionURL // empty')
        if [ -n "$version_url" ]; then
            download_url=$(req - "${version_url}-x" | grep -oP '(?<=data-url=")[^"]+')
            [ -n "$download_url" ] && req "$name-v$version.apk" "https://dw.uptodown.com/dwn/$download_url" && break
        fi
        
        # Check if all versions are less than target version
        all_lower=$(echo "$json" | jq -r --arg version "$version" '.[] | select(.kindFile == "apk") | .version | select(. < $version)' | wc -l)
        total_versions=$(echo "$json" | jq -r '.[] | select(.kindFile == "apk") | .version' | wc -l)
        [ "$all_lower" -eq "$total_versions" ] && break

        page=$((page + 1))
    done
}

# Tiktok not work because not available version supported 
apkpure() {
    config_file="./apps/apkpure/$1.json"
    name=$(jq -r '.name' "$config_file")
    package=$(jq -r '.package' "$config_file")
    version=$(jq -r '.version' "$config_file")
    url="https://apkpure.net/$name/$package/versions"
    #version="${version:-$(get_supported_version "$package")}"
    version="${version:-$(req - $url | grep -oP 'data-dt-version="\K[^"]*' | sed 10q | get_latest_version)}"
    url="https://apkpure.net/$name/$package/download/$version"
    url=$(req - $url | grep -oP '<a[^>]*id="download_link"[^>]*href="\K[^"]*' | head -n 1)
    req $name-v$version.apk "$url"
}

download_resources
apkmirror "youtube"
apkmirror "youtube-music"
uptodown "youtube"
uptodown "youtube-music"
apkpure "youtube"
apkpure "youtube-music"
