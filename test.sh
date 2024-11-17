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

url="https://www.apkmirror.com/apk/google-inc/chrome/chrome-131-0-6778-39-release/"
url=$(req - $url | perl -ne 'push @buffer, $_; if (/>\s*nodpi\s*</) { print @buffer[-16..-1]; @buffer = (); }' \
                 | perl -ne 'push @buffer, $_; if (/>\s*arm64v8a\s*</) { print @buffer[-14..-1]; @buffer = (); }' \
                 | perl -ne 'push @buffer, $_; if (/>\s*APK\s*</) { print @buffer[-6..-1]; @buffer = (); }' \
                 | perl -ne 'print "https://www.apkmirror.com$1\n" if /.*href="(.*apk-[^"]*)".*/ && ++$i == 1;')

echo "$url"
