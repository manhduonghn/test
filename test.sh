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
    local architecture="$1"
    awk -v arch="$architecture" '
    BEGIN { link = ""; dpi_found = 0; arch_found = 0; bundle_found = 0 }
    # Trích xuất href khi gặp thẻ <a class="accent_color">
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }
    # Kiểm tra "nodpi" trong các dòng HTML
    /table-cell.*nodpi/ { dpi_found = 1 }
    # Kiểm tra kiến trúc phù hợp (sử dụng giá trị của arch)
    /table-cell/ && $0 ~ arch { arch_found = 1 }
    # Kiểm tra "APK" trong các dòng HTML
    /<span class="apkm-badge">APK/ { bundle_found = 1 }
    # Khi cả ba điều kiện được thỏa mãn, in link và reset
    dpi_found && arch_found && bundle_found {
        print link
        dpi_found = 0
        arch_found = 0
        bundle_found = 0
        link = ""
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/google-inc/chrome/chrome-131-0-6778-39-release/"

# Gọi req và trích xuất thông tin
url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "armeabi-v7a" | sed 1q)"

echo "$url"
