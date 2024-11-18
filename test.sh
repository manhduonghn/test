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

    perl -e '
    use strict;
    use warnings;

    my ($dpi, $arch, $type) = @ARGV;
    my ($link, $dpi_found, $arch_found, $type_found, $printed) = ("", 0, 0, 0, 0);

    while (<STDIN>) {
        # Trích xuất href khi gặp thẻ <a class="accent_color">
        if (/<a class="accent_color"/) {
            if (/href="([^"]+)"/) {
                $link = $1;
            }
        }
        # Kiểm tra điều kiện "dpi"
        $dpi_found = 1 if $dpi && /table-cell.*$dpi/;
        # Kiểm tra điều kiện "arch"
        $arch_found = 1 if $arch && /table-cell.*$arch/;
        # Kiểm tra điều kiện "type"
        $type_found = 1 if $type && /<span class="apkm-badge">$type/;
        # Khi cả ba điều kiện được thỏa mãn và chưa in link, in ra và thoát
        if ($dpi_found && $arch_found && $type_found && !$printed) {
            print "$link\n";
            $printed = 1;
            last;
        }
    }
    ' "$dpi" "$arch" "$type"
}

# URL cần tải
url="https://www.apkmirror.com/apk/facebook-2/messenger/messenger-484-0-0-68-109-release/"
url="https://www.apkmirror.com$(req - "$url" | extract_filtered_links "nodpi" "armeabi-v7a" "APK")"
echo "$url"
