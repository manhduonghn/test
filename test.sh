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

    # Vòng lặp kiểm tra các link
    while read -r line; do
        dpi_found=0
        arch_found=0
        type_found=0

        # Trích xuất href từ thẻ <a class="accent_color">
        if [[ "$line" =~ <a\ class=\"accent_color\".*href=\"([^\"]+)\" ]]; then
            link="${BASH_REMATCH[1]}"
        else
            continue
        fi

        # Kiểm tra điều kiện dpi
        if [[ "$line" =~ "table-cell.*$dpi" ]]; then
            dpi_found=1
        fi

        # Kiểm tra điều kiện arch
        if [[ "$line" =~ "table-cell.*$arch" ]]; then
            arch_found=1
        fi

        # Kiểm tra điều kiện type
        if [[ "$line" =~ "<span\ class=\"apkm-badge\">$type</span>" ]]; then
            type_found=1
        fi

        # Nếu tất cả các điều kiện đều thỏa mãn, in ra và thoát
        if [[ $dpi_found -eq 1 && $arch_found -eq 1 && $type_found -eq 1 ]]; then
            echo "$link"
            break
        fi
    done
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
# Tải HTML từ URL và trích xuất liên kết hợp lệ
link=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")
echo "$link"
