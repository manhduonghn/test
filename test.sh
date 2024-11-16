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

url="https://youtube.en.uptodown.com/android/versions"
data_code=$(req - "$url" | grep 'detail-app-name' | grep -oP '(?<=data-code=")[^"]+')
url="https://youtube.en.uptodown.com/android/apps/$data_code/versions/1"
url=$(req - $url | jq -r '.data[] | select(.version == "19.44.37") | .versionURL')
url="https://dw.uptodown.com/dwn/$(req - $url | grep -oP '(?<=data-url=")[^"]+')"
req youtube-v19.44.37 $url
