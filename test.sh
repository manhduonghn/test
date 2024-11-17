#!/bin/bash

# Function to send HTTP requests
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

filter_lines() {
    local start_pattern="$1"
    local end_pattern="$2"
    local is_collecting=0
    local result_buffer=()

    while IFS= read -r line; do
        # Bắt đầu thu thập nếu khớp `start_pattern`
        if [[ $line =~ $start_pattern ]]; then
            is_collecting=1
        fi

        # Thu thập các dòng
        if [[ $is_collecting -eq 1 ]]; then
            result_buffer+=("$line")
        fi

        # Dừng thu thập nếu khớp `end_pattern`
        if [[ $line =~ $end_pattern ]]; then
            is_collecting=0
        fi
    done

    # Xuất mảng kết quả
    printf "%s\n" "${result_buffer[@]}"
}

# URL để tải trang
url="https://www.apkmirror.com/apk/google-inc/youtube-music/youtube-music-7-27-53-release/"
dpi="nodpi"   # Thay bằng giá trị thực tế của bạn
arch="arm64-v8a" # Thay bằng giá trị thực tế của bạn

# Lấy nội dung trang
page_content=$(req -s "$url")

# Lọc nội dung lần 1: theo `$dpi`
filtered_dpi=$(echo "$page_content" | filter_lines '<a class="accent_color"' ">\s*${dpi}\s*<")

# Lọc nội dung lần 2: theo `$arch`
filtered_arch=$(echo "$filtered_dpi" | filter_lines '<a class="accent_color"' ">\s*${arch}\s*<")

# Lọc nội dung lần 3: theo `APK`
filtered_apk=$(echo "$filtered_arch" | filter_lines '<a class="accent_color"' "APK")

# Tìm URL tải xuống
apk_url=$(echo "$filtered_apk" | grep -oP 'href="\K(.*apk-[^"]*)' | head -n 1)

# In URL đầy đủ
if [[ -n $apk_url ]]; then
    echo "https://www.apkmirror.com$apk_url"
else
    echo "Không tìm thấy URL APK!"
fi
