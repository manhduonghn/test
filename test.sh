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

# Hàm filter_lines (lấy từ `</a class="accent_color"` gần nhất tới `>nodpi<`)
filter_lines() {
    local start_pattern="</a class=\"accent_color\""
    local end_pattern=">nodpi<"
    local buffer=()
    local found=0

    # Duyệt qua từng dòng
    while IFS= read -r line; do
        # Nếu khớp với dòng chứa `end_pattern`, bật chế độ thu thập
        if [[ $line =~ $end_pattern ]]; then
            found=1
        fi

        # Nếu đang thu thập, lưu dòng vào buffer
        if [[ $found -eq 1 ]]; then
            buffer+=("$line")
        fi

        # Nếu gặp dòng chứa `start_pattern`, dừng thu thập
        if [[ $found -eq 1 && $line =~ $start_pattern ]]; then
            break
        fi
    done

    # In các dòng đã thu thập (ngược thứ tự)
    printf "%s\n" "${buffer[@]}" | tac
}

# URL để tải nội dung
url="https://www.apkmirror.com/apk/google-inc/youtube-music/youtube-music-7-27-53-release/"
dpi="nodpi"

# Lấy nội dung trang
page_content=$(req - "$url")

# Lọc nội dung từ `</a class="accent_color"` đến `>nodpi<`
filtered_content=$(echo "$page_content" | grep '>nodpi<')

# In kết quả
echo "$filtered_content"
