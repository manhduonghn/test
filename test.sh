#!/bin/bash
req() {
    wget --header="User-Agent: Mozilla/5.0 (Android 13; Mobile; rv:125.0) Gecko/125.0 Firefox/125.0" \
         --header="Content-Type: application/octet-stream" \
         --header="Accept-Language: en-US,en;q=0.9" \
         --header="Connection: keep-alive" \
         --header="Upgrade-Insecure-Requests: 1" \
         --header="Cache-Control: max-age=0" \
         --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
         --keep-session-cookies --timeout=30 -nv -O "$1" "$2"
}

download_resources() {
    for repo in revanced-patches revanced-cli; do
        githubApiUrl="https://api.github.com/repos/revanced/$repo/releases"
        page=$(req - 2>/dev/null "$githubApiUrl")
        assetUrls=$(echo "$page" | jq -r '[.[] | select(.prerelease == true)] | sort_by(.created_at) | last | .assets[] | select(.name | endswith(".asc") | not) | "\(.browser_download_url) \(.name)"')
        while read -r downloadUrl assetName; do
            req "$assetName" "$downloadUrl" 
        done <<< "$assetUrls"
    done
}

download_resources

# Định nghĩa hàm để tìm phiên bản cao nhất của một package
find_max_version() {
    package_name=$1

    # Chạy lệnh và lưu kết quả vào biến
    output=$(java -jar revanced-cli*.jar list-versions -f "$package_name" patch*.rvp)

    # Kiểm tra nếu output không có kết quả hoặc có lỗi
    if [[ -z "$output" ]]; then
        echo "None"
        return
    fi

    # Loại bỏ 2 dòng đầu tiên, bỏ văn bản trong ngoặc `()`, và chỉ giữ lại phiên bản
    versions=$(echo "$output" | tail -n +3 | sed 's/ (.*)//')

    # Kiểm tra nếu không có phiên bản nào hoặc phiên bản là 'Any'
    if [[ -z "$versions" || "$versions" == "Any" ]]; then
        echo "None"
        return
    fi

    # Hàm so sánh hai phiên bản và trả về phiên bản cao nhất
    compare_versions() {
        printf "%s\n%s" "$1" "$2" | sort -V | tail -n 1
    }

    # Khởi tạo phiên bản cao nhất là phần tử đầu tiên
    max_version=$(echo "$versions" | head -n 1)

    # Lặp qua các phiên bản còn lại và tìm phiên bản cao nhất
    while read -r version; do
        max_version=$(compare_versions "$max_version" "$version")
    done <<< "$versions"

    # Trả về phiên bản cao nhất
    echo "$max_version"
}

# Gọi hàm với package cần tìm và gán kết quả vào biến
version=$(find_max_version "com.google.android.youtube")

echo $version
