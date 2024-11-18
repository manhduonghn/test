#!/bin/bash

# Hàm req để tải HTML
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

# Hàm trích xuất href thoả mãn điều kiện
extract_filtered_links() {
    dpi=$1
    arch=$2
    type=$3

    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    BEGIN { link = ""; dpi_found = 0; arch_found = 0; type_found = 0; printed = 0 }
    
    # Match the anchor tag <a class="accent_color">
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }

    # Match the dpi (e.g., nodpi) condition
    dpi && $0 ~ ("table-cell.*\\b" dpi "\\b") { dpi_found = 1 }

    # Match the arch (e.g., x86) condition
    arch && $0 ~ ("table-cell.*\\b" arch "\\b") { arch_found = 1 }

    # Match the type (e.g., APK) condition
    type && $0 ~ ("<span class=\"apkm-badge\">" type "<\\/span>") { type_found = 1 }

    # Print the link if all conditions are met
    dpi_found && arch_found && type_found && !printed {
        print link
        printed = 1
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-483-0-0-62-109-release/"
url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")"
echo "$url"
