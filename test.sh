#!/bin/bash

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

url="https://apkpure.net/youtube-music/com.google.android.apps.youtube.music/versions"
url=$(req - $url | grep '"ver-item"')
echo $url
exit

url="https://apkpure.net/youtube-music/com.google.android.apps.youtube.music/download/7.27.53"
url=$(req - $url | grep -oP '<a[^>]*id="download_link"[^>]*href="\K[^"]*' | head -n 1)
req youtube.apk $url
