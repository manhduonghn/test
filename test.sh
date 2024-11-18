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

uptodown() {
    config_file="./apps/uptodown/$1.json"
    name=$(jq -r '.name' "$config_file")
    package=$(jq -r '.package' "$config_file")
    version=$(jq -r '.version' "$config_file")
    version="${version:-$(get_supported_version "$package")}"
    url="https://$name.en.uptodown.com/android/versions"
    version="${version:-$(req - 2>/dev/null $url | grep -oP 'class="version">\K[^<]+' | get_latest_version)}"
    data_code=$(req - "$url" | grep 'detail-app-name' | grep -oP '(?<=data-code=")[^"]+')

    found=0
    page=1

    while [ $found -eq 0 ]; do
        echo "Checking page $page..."
        url="https://$name.en.uptodown.com/android/apps/$data_code/versions/$page"
        json=$(req - "$url" | jq -r '.data')

        # Check if we have valid JSON data
        if [ -z "$json" ]; then
            echo "No more pages to check or invalid JSON response."
            break
        fi

        # Look for the target version with kindFile "apk"
        version_url=$(echo "$json" | jq -r --arg version "$version" '.[] | select(.version == $version and .kindFile == "apk") | .versionURL')

        if [ -n "$version_url" ]; then
            echo "Found versionURL: $version_url"
            url="https://dw.uptodown.com/dwn/$(req - $version_url | grep -oP '(?<=data-url=")[^"]+')"
            req youtube-v$version $url
            found=1
            break
        fi

        # Check if all versions on this page are less than target_version
        all_lower=$(echo "$json" | jq -r --arg version "$target_version" '.[] | select(.kindFile == "apk") | .version | select(. < $version)' | wc -l)
        total_versions=$(echo "$json" | jq -r '.[] | select(.kindFile == "apk") | .version' | wc -l)

        if [ "$all_lower" -eq "$total_versions" ]; then
            echo "All APK versions on page $page are less than $version. Stopping search."
            break
        fi

        # Increment page number to check the next page
        page=$((page + 1))
    done

    if [ $found -eq 0 ]; then
        echo "Version $version not found or no suitable APK found."
    fi
}


uptodown "youtube"
