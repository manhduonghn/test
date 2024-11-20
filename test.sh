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
    local dpi="$1" arch="$2" type="$3"

    sed -nE '
    # Đặt trạng thái ban đầu
    /<a class="accent_color"/ {
        block = ""
        link = ""
        found_dpi = 0
        found_arch = 0
        found_type = 0
    }

    # Lấy link href
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) link = arr[1]
        block = $0
    }

    # Kiểm tra điều kiện dpi
    /table-cell/ {
        if ($0 ~ dpi) found_dpi = 1
    }

    # Kiểm tra điều kiện arch
    /table-cell/ {
        if ($0 ~ arch) found_arch = 1
    }

    # Kiểm tra điều kiện type
    /apkm-badge/ {
        if ($0 ~ (">" type "</span>")) found_type = 1
    }

    # In link nếu tất cả điều kiện thỏa mãn
    END {
        if (link != "" && found_dpi && found_arch && found_type) print link
    }
    '
}


# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
link=$(req - "$url" | extract_filtered_links "" "" "BUNDLE")
echo "https://www.apkmirror.com$link"
