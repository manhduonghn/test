#!/bin/bash

# Function to send HTTP requests
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

# Function to download a specific APK version
uptodown() {
    config_file="./apps/uptodown/$1.json"
    name=$(jq -r '.name' "$config_file")
    package=$(jq -r '.package' "$config_file")
    version=$(jq -r '.version' "$config_file")
    version="${version:-$(get_supported_version "$package")}"
    url="https://$name.en.uptodown.com/android/versions"
    version="${version:-$(req - 2>/dev/null $url | grep -oP 'class="version">\K[^<]+' | get_latest_version)}"

    local page=1
    local found=0
    local data_code
    # Fetch the data_code
    data_code=$(req - "$url" | grep 'detail-app-name' | grep -oP '(?<=data-code=")[^"]+')
    if [ -z "$data_code" ]; then
        echo "Failed to retrieve data code. Exiting."
        return 1
    fi

    while [ $found -eq 0 ]; do
        echo "Checking page $page..."
        local url="https://$name.en.uptodown.com/android/apps/$data_code/versions/$page"
        local json
        json=$(req - "$url" | jq -r '.data')

        # Check if valid JSON response is present
        if [ -z "$json" ]; then
            echo "No more pages to check or invalid JSON response."
            break
        fi

        # Look for the target version
        local version_url
        version_url=$(echo "$json" | jq -r --arg version "$version" '.[] | select(.version == $version and .kindFile == "apk") | .versionURL end')

        if [ -n "$version_url" ]; then
            echo "Found versionURL: $version_url"
            local download_url
            download_url=$(req - "$version_url" | grep -oP '(?<=data-url=")[^"]+')
            if [ -n "$download_url" ]; then
                req "youtube-v$version.apk" "https://dw.uptodown.com/dwn/$download_url"
                echo "Downloaded version $version successfully."
                found=1
            else
                echo "Failed to extract download URL."
            fi
            break
        fi

        # Check if all versions are less than target_version
        local all_lower
        local total_versions
        all_lower=$(echo "$json" | jq -r --arg version "$version" '.[] | select(.kindFile == "apk") | .version | select(. < $version)' | wc -l)
        total_versions=$(echo "$json" | jq -r '.[] | select(.kindFile == "apk") | .version' | wc -l)

        if [ "$all_lower" -eq "$total_versions" ]; then
            echo "All APK versions on page $page are less than $version. Stopping search."
            break
        fi

        # Increment page number
        page=$((page + 1))
    done

    if [ $found -eq 0 ]; then
        echo "Version $version not found or no suitable APK available."
        return 1
    fi

    return 0
}

# Example usage
uptodown "youtube"
uptodown "youtube-music"
