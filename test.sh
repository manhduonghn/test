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
    # Truyền các điều kiện vào thông qua các tham số
    dpi=$1
    arch=$2
    type=$3

    awk -v dpi="$dpi" -v arch="$arch" -v type="$type" '
    BEGIN { 
        link = ""; 
        dpi_found = 0; 
        arch_found = 0; 
        type_found = 0; 
        printed = 0 
    }
    
    # Lặp qua từng dòng và tìm <a class="accent_color">
    {
        # Trích xuất giá trị href từ thẻ <a class="accent_color">
        if (match($0, /<a class="accent_color"[^>]*href="([^"]+)"/, arr)) {
            link = arr[1]
        }
        
        # Kiểm tra điều kiện "dpi"
        if (dpi && $0 ~ ("table-cell.*" dpi)) { dpi_found = 1 }
        else { dpi_found = 0 }
        
        # Kiểm tra điều kiện "arch"
        if (arch && $0 ~ ("table-cell.*" arch)) { arch_found = 1 }
        else { arch_found = 0 }
        
        # Kiểm tra điều kiện "type"
        if (type && $0 ~ ("<span class=\"apkm-badge\">" type)) { type_found = 1 }
        else { type_found = 0 }
        
        # Nếu tất cả điều kiện thỏa mãn, in ra link
        if (dpi_found && arch_found && type_found && link != "" && !printed) {
            print link
            printed = 1
        }
    }
    '
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"

# Tải HTML và trích xuất link thỏa mãn điều kiện
url=$(req - "$url" | extract_filtered_links "nodpi" "arm64-v8a" "APK")

# In ra URL tìm được
echo "$url"
