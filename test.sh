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
    local dpi="$1"
    local arch="$2"
    local type="$3"

    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    BEGIN {
        block = ""
        found_href = 0
        found_dpi = 0
        found_arch = 0
        found_type = 0
        printed = 0
    }

    # Khi gặp <a class="accent_color", bắt đầu một khối mới
    /<a class="accent_color"/ {
        if (printed) next
        if (block != "" && found_href && found_dpi && found_arch && found_type && !printed) {
            if (match(block, /href="([^"]+)"/, arr)) {
                print arr[1]
                printed = 1
            }
        }
        block = $0
        found_href = 1
        found_dpi = 0
        found_arch = 0
        found_type = 0
    }

    # Thêm dòng vào khối hiện tại
    {
        if (found_href && !printed) {
            block = block "\n" $0
        }
    }

    # Đánh dấu nếu khối chứa thông tin dpi
    /<\/div>/ && $0 ~ dpi {
        found_dpi = 1
    }

    # Đánh dấu nếu khối chứa thông tin arch
    /<\/div>/ && $0 ~ arch {
        found_arch = 1
    }

    # Đánh dấu nếu khối chứa thông tin type
    /<\/span>/ && $0 ~ ("<span class=\"apkm-badge\">" type "</span>") {
        found_type = 1
    }

    # Xử lý khối cuối cùng khi kết thúc file
    END {
        if (block != "" && found_href && found_dpi && found_arch && found_type && !printed) {
            if (match(block, /href="([^"]+)"/, arr)) {
                print arr[1]
            }
        }
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
link=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")
echo "https://www.apkmirror.com$link"
