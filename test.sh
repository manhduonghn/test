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
    BEGIN { link = ""; dpi_found = 0; arch_found = 0; type_found = 0; printed = 0; }

    # Tìm thẻ <a class="accent_color"> chứa link
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }

    # Tìm các phần tử liên quan đến arch, dpi và type trong cùng một hàng
    /<div class="table-cell"/ {
        # Kiểm tra arch, dpi và type trong các cột liền kề
        if ($0 ~ arch) arch_found = 1
        if ($0 ~ dpi) dpi_found = 1
        if ($0 ~ type) type_found = 1
    }

    # Khi tất cả các điều kiện đều thỏa mãn và chưa in link, in ra và thoát
    link && arch_found && dpi_found && type_found && !printed {
        print link
        printed = 1
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")"
echo "$url"
