#!/bin/bash

# Hàm gửi yêu cầu HTTP
req() {
    wget --header="User-Agent: Mozilla/5.0 (Android 13; Mobile; rv:125.0) Gecko/125.0 Firefox/125.0" \
         --header="Content-Type: application/octet-stream" \
         --header="Accept-Language: en-US,en;q=0.9" \
         --header="Connection: keep-alive" \
         --header="Upgrade-Insecure-Requests: 1" \
         --header="Cache-Control: max-age=0" \
         --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
         --keep-session-cookies --timeout=30 -nv "$@"
}

filter_lines_reverse() {
    local start_pattern="$1"  # Dòng bắt đầu: `</a class="accent_color"`
    local end_pattern="$2"    # Dòng kết thúc: `>nodpi<`
    local buffer=()
    local found=0

    # Đọc nội dung từng dòng ngược lại (bắt đầu từ `end_pattern`)
    tac | while IFS= read -r line; do
        # Bắt đầu thu thập nếu khớp `end_pattern`
        if [[ $line =~ $end_pattern ]]; then
            found=1
        fi

        # Thu thập các dòng
        if [[ $found -eq 1 ]]; then
            buffer=("$line" "${buffer[@]}")
        fi

        # Dừng thu thập khi khớp `start_pattern`
        if [[ $line =~ $start_pattern ]]; then
            found=0
            break
        fi
    done

    # Xuất nội dung đã thu thập (ngược thứ tự để trả về đúng)
    printf "%s\n" "${buffer[@]}" | tac
}

# URL để tải nội dung
url="https://www.apkmirror.com/apk/google-inc/youtube-music/youtube-music-7-27-53-release/"
dpi="nodpi"

# Lấy nội dung trang
page_content=$(req - "$url" | grep '>nodpi<')

# Lọc nội dung từ `</a class="accent_color"` đến `>nodpi<`
filtered_content=$(echo "$page_content" | filter_lines_reverse '</a class="accent_color"' ">'${dpi}'<")

# In kết quả
echo "$filtered_content"
