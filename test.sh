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
        # Biến để lưu đoạn HTML hiện tại và trạng thái cắt
        current_block = ""
        matched_dpi = ""
        matched_arch = ""
        matched_type = ""
    }

    # Bắt đầu một block mới khi gặp thẻ <a class="accent_color">
    /<a class="accent_color"/ {
        current_block = $0
    }

    # Thêm dòng mới vào block hiện tại
    {
        if (current_block != "") {
            current_block = current_block "\n" $0
        }
    }

    # Khi gặp dòng chứa thông tin về "dpi", đánh dấu đoạn này phù hợp với dpi
    /table-cell/ && dpi && $0 ~ dpi {
        matched_dpi = current_block
    }

    # Khi gặp dòng chứa thông tin về "arch", đánh dấu đoạn phù hợp với arch (sau khi lọc qua dpi)
    /table-cell/ && arch && $0 ~ arch && matched_dpi {
        matched_arch = matched_dpi
        matched_dpi = ""
    }

    # Khi gặp dòng chứa thông tin về "type", kiểm tra đoạn cuối cùng
    /<span class="apkm-badge"/ && type && $0 ~ ("<span class=\"apkm-badge\">" type "</span>") && matched_arch {
        # Trích xuất href từ đoạn khớp với tất cả các điều kiện
        if (match(matched_arch, /href="([^"]+)"/, arr)) {
            print arr[1]
            exit
        }
    }

    # Kết thúc block hiện tại nếu gặp dòng mới
    /<\/div>/ {
        current_block = ""
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
# Tải HTML từ URL và trích xuất liên kết hợp lệ
link=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")
echo "$link"
