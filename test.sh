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
        link = ""
        found_dpi = 0
        found_arch = 0
        found_type = 0
        printed = 0
    }

    # Bắt đầu khối mới từ <a class="accent_color" href
    /<a class="accent_color"/ {
        if (printed) next
        if (block != "") {
            # Kiểm tra khối trước đó
            if (link != "" && found_dpi && found_arch && found_type && !printed) {
                print link
                printed = 1
            }
        }
        # Bắt đầu khối mới
        block = $0
        found_dpi = 0
        found_arch = 0
        found_type = 0
        link = ""
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }

    # Tiếp tục thêm dòng vào khối hiện tại
    {
        if (!printed) block = block "\n" $0
    }

    # Tìm thấy điều kiện DPI
    /<div class="table-cell rowheight addseparator expand pad dowrap">/ && $0 ~ dpi {
        found_dpi = 1
    }

    # Tìm thấy điều kiện ARCH
    /<div class="table-cell rowheight addseparator expand pad dowrap">/ && $0 ~ arch {
        found_arch = 1
    }

    # Tìm thấy điều kiện TYPE
    /<span class="apkm-badge">/ && $0 ~ ("<span class=\"apkm-badge\">" type "</span>") {
        found_type = 1
    }

    # Kiểm tra khối cuối cùng khi kết thúc file
    END {
        if (block != "" && link != "" && found_dpi && found_arch && found_type && !printed) {
            print link
        }
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/google-inc/youtube/youtube-19-45-35-release/"
link=$(req - "$url" | extract_filtered_links "" "" "APK")
echo "https://www.apkmirror.com$link"
