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
    local filters=("$@")  # Nhận các điều kiện qua tham số
    awk -v filters="${filters[*]}" '
    BEGIN {
        link = ""; 
        split(filters, conds, " ");  # Chia các điều kiện thành mảng
        matches = 0; 
        total_conditions = length(conds);
    }
    # Trích xuất href khi gặp thẻ <a class="accent_color">
    /<a class="accent_color"/ {
        if (match($0, /href="([^"]+)"/, arr)) {
            link = arr[1];
        }
    }
    # Kiểm tra từng điều kiện trong mảng conds
    {
        for (i = 1; i <= total_conditions; i++) {
            if ($0 ~ conds[i]) {
                matches++;
                break;
            }
        }
    }
    # Khi đủ số điều kiện, in link và reset
    matches == total_conditions {
        print link;
        link = "";
        matches = 0;
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/google-inc/youtube/youtube-19-45-35-release/"

# Gọi req và trích xuất thông tin với các điều kiện
url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "APK" "universal" "nodpi" | sed 1q)"

echo "$url"
