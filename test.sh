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

    # Gom tất cả nội dung HTML thành một chuỗi
    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    BEGIN { block = ""; link = ""; dpi_found = 0; arch_found = 0; type_found = 0; printed = 0 }
    
    # Nếu gặp thẻ <div class="table-cell rowheight addseparator">, đóng khối trước đó và bắt đầu khối mới
    /<div class="table-cell rowheight addseparator/ {
        if (block != "" && printed == 0) {
            # Kiểm tra điều kiện
            if (link != "" && dpi_found && arch_found && type_found) {
                print link
                printed = 1
            }
        }
        # Reset block và trạng thái điều kiện
        block = ""
        link = ""
        dpi_found = 0
        arch_found = 0
        type_found = 0
    }

    # Gộp tất cả các dòng thuộc cùng một khối
    {
        block = block $0
    }

    # Lưu liên kết từ thẻ <a class="accent_color">
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1]
        }
    }

    # Đánh dấu nếu tìm thấy điều kiện dpi
    dpi && $0 ~ ("table-cell.*" dpi) {
        dpi_found = 1
    }

    # Đánh dấu nếu tìm thấy điều kiện arch
    arch && $0 ~ ("table-cell.*" arch) {
        arch_found = 1
    }

    # Đánh dấu nếu tìm thấy điều kiện type
    type && $0 ~ ("<span class=\"apkm-badge\">" type "</span>") {
        type_found = 1
    }

    # Khi đọc xong toàn bộ HTML, kiểm tra khối cuối cùng
    END {
        if (block != "" && printed == 0) {
            if (link != "" && dpi_found && arch_found && type_found) {
                print link
            }
        }
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
# Tải HTML từ URL và trích xuất liên kết hợp lệ
link=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")
echo "$link"
