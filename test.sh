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

    # Tìm thẻ <a class="accent_color"> chứa link
    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    # Tìm thẻ <a class="accent_color">
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }
    
    # Tìm thông tin các cột liên quan đến arch, dpi và type
    /<div class="table-cell"/ {
        if ($0 ~ arch) arch_found = 1
        if ($0 ~ dpi) dpi_found = 1
    }
    
    # Tìm type từ thẻ <span class="apkm-badge">
    /<span class="apkm-badge"/ {
        if ($0 ~ type) type_found = 1
    }

    # Nếu tất cả các điều kiện thỏa mãn và link đã tìm thấy, in ra
    link && arch_found && dpi_found && type_found {
        print link
        exit 0
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
# Gọi hàm req và sau đó trích xuất link
url=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")
echo "$url"
