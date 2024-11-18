#!/bin/bash

# Hàm req (không thay đổi)
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

# Hàm filter_html_sections (không thay đổi)
filter_html_sections() {
    local end_pattern="$1"  # Mẫu kết thúc, ví dụ: >nodpi<, >arm63-v8a<, >APK<

    # Sử dụng awk để lọc các đoạn văn bản
    awk -v end_pattern="$end_pattern" '
    {
        # Tạo regex động với mẫu kết thúc
        regex = "<a class=\"accent_color[^>]*>.*" end_pattern

        # Kiểm tra từng dòng
        while (match($0, regex)) {
            # Lấy đoạn khớp với regex
            match_text = substr($0, RSTART, RLENGTH)

            # Đếm số lần xuất hiện của <a class="accent_color
            count = gsub(/<a class="accent_color/, "", match_text)

            # Nếu chỉ xuất hiện 1 lần, in ra
            if (count == 1) {
                print match_text
            }

            # Xóa đoạn đã xử lý để tiếp tục kiểm tra
            $0 = substr($0, RSTART + RLENGTH)
        }
    }'
}

# URL để tải HTML
url="https://www.apkmirror.com/apk/google-inc/chrome/chrome-131-0-6778-39-release/"

# Gọi req để tải nội dung từ URL, pipe kết quả qua filter_html_sections
echo "Lọc với >nodpi<:"
page=$(req - "$url" | filter_html_sections ">nodpi<")
echo "$page"
exit

echo "Lọc với >arm63-v8a<:"
req "$url" | filter_html_sections ">arm63-v8a<"

echo "Lọc với >APK<:"
req "$url" | filter_html_sections ">APK<"
