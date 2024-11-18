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
    # Truyền các điều kiện vào thông qua các tham số
    pattern1=$1
    pattern2=$2
    pattern3=$3

    awk -v pattern1="$pattern1" -v pattern2="$pattern2" -v pattern3="$pattern3" '
    BEGIN { link = ""; dpi_found = 0; arch_found = 0; bundle_found = 0; printed = 0 }
    # Trích xuất href khi gặp thẻ <a class="accent_color">
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }
    # Kiểm tra điều kiện 1
    pattern1 && $0 ~ ("table-cell.*" pattern1) { dpi_found = 1 }
    # Kiểm tra điều kiện 2
    pattern2 && $0 ~ ("table-cell.*" pattern2) { arch_found = 1 }
    # Kiểm tra điều kiện 3
    pattern3 && $0 ~ ("<span class=\"apkm-badge\">" pattern3) { bundle_found = 1 }
    # Khi cả ba điều kiện được thỏa mãn và chưa in link, in ra và thoát
    dpi_found && arch_found && bundle_found && !printed {
        print link
        printed = 1
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/google-inc/chrome/chrome-131-0-6778-39-release/"
url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")"
echo "$url"
