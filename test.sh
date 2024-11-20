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

    # Tách từng block từ <a ...> đến </a>
    grep -oPz '<a class="accent_color"[^>]*>.*?</a>' | while IFS= read -r -d '' block; do
        # Kiểm tra xem block có thỏa mãn cả 3 điều kiện không
        if echo "$block" | grep -q "$dpi" &&
           echo "$block" | grep -q "$arch" &&
           echo "$block" | grep -q ">${type}</span>"; then
            # Trích xuất href nếu tất cả điều kiện đều đúng
            echo "$block" | sed -nE 's/.*href="([^"]*)".*/\1/p'
        fi
    done
}


# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
link=$(req - "$url" | grep -oPz '<a class="accent_color"[^>]*>.*?</a>')

echo "$link"
