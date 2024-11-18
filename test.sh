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
    dpi=$1
    arch=$2
    type=$3

    # Biến lưu trạng thái các điều kiện
    found_dpi=0
    found_arch=0
    found_type=0
    link=""

    # Lặp qua các dòng để xử lý các điều kiện
    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    BEGIN {
        # Biến kiểm tra tình trạng điều kiện
        found_dpi = 0
        found_arch = 0
        found_type = 0
        link = ""
    }

    # Xử lý mỗi dòng HTML
    {
        # Kiểm tra href của thẻ <a class="accent_color">
        if (match($0, /<a class="accent_color"[^>]*href="([^"]+)"/, arr)) {
            link = arr[1]  # Lưu giá trị href
        }

        # Kiểm tra điều kiện dpi, arch và type
        if (dpi && $0 ~ ("<div class=\"table-cell" && $0 ~ dpi)) {
            found_dpi = 1
        } else {
            found_dpi = 0
        }

        if (arch && $0 ~ ("<div class=\"table-cell" && $0 ~ arch)) {
            found_arch = 1
        } else {
            found_arch = 0
        }

        if (type && $0 ~ ("<span class=\"apkm-badge\">" type)) {
            found_type = 1
        } else {
            found_type = 0
        }

        # Nếu tất cả điều kiện thỏa mãn, in ra link
        if (found_dpi && found_arch && found_type && link != "") {
            print link
        }
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"

# Tải HTML và trích xuất link thỏa mãn điều kiện
url=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")

# In ra URL tìm được
echo "$url"
