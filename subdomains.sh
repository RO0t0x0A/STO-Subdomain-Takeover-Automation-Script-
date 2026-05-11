#!/bin/bash

if [ -z "$1" ]; then
    echo -e "\e[1;31m[!] Usage: subdomains <example.com>\e[0m"
    exit 1
fi

DOMAIN=$1
GITHUB_TOKEN="Your_GITHUB_TOKEN"
CHAOS_TOKEN="Your_CHAOS_TOKEN"
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
TMPDIR=$(mktemp -d)

export PATH="$HOME/go/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# ─── Ctrl+C handler ───
cleanup() {
    echo -e "\n\e[1;31m[!] Interrupted! Cleaning up...\e[0m"
    kill 0
    rm -rf "$TMPDIR"
    rm -f "${DOMAIN}-$(date +%Y-%m-%d).txt" 2>/dev/null
    rm -f "${DOMAIN}.txt" 2>/dev/null
    rm -f "tmp-wayback-${DOMAIN}" 2>/dev/null
    exit 1
}
trap cleanup INT


strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g' | grep -oE '([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}' | grep -iE "(^|\.)${DOMAIN}$" | sort -u
}

echo -e "\e[1;34m[+] Launching 9 Engines in Parallel for: $DOMAIN\e[0m"

# 1. Subfinder
(subfinder -d $DOMAIN -all 2>/dev/null | sort -u > "$TMPDIR/s1.txt"
echo -e "\e[1;32m  [✔] Subfinder done ($(wc -l < "$TMPDIR/s1.txt"))\e[0m") &

# 2. Assetfinder
(assetfinder --subs-only $DOMAIN 2>/dev/null | sort -u > "$TMPDIR/s2.txt"
echo -e "\e[1;32m  [✔] Assetfinder done ($(wc -l < "$TMPDIR/s2.txt"))\e[0m") &

# 3. Amass — 800 seconds only - you can edit it as you like
(timeout 800 amass enum -passive -d $DOMAIN -o "$TMPDIR/s3.txt" > /dev/null 2>&1
touch "$TMPDIR/s3.txt"
echo -e "\e[1;32m  [✔] Amass done ($(wc -l < "$TMPDIR/s3.txt"))\e[0m") &

# 4. Findomain
(findomain -t $DOMAIN 2>/dev/null | strip_ansi > "$TMPDIR/s4.txt"
echo -e "\e[1;32m  [✔] Findomain done ($(wc -l < "$TMPDIR/s4.txt"))\e[0m") &

# 5. Chaos
(chaos -d $DOMAIN -key $CHAOS_TOKEN -silent 2>/dev/null | sort -u > "$TMPDIR/s5.txt"
echo -e "\e[1;32m  [✔] Chaos done ($(wc -l < "$TMPDIR/s5.txt"))\e[0m") &

# 6. Subenum 
(subenum -d $DOMAIN -u wayback,crt,abuseipdb -o "$TMPDIR/s6.txt" > /dev/null 2>&1
touch "$TMPDIR/s6.txt"
sort -u "$TMPDIR/s6.txt" -o "$TMPDIR/s6.txt"
echo -e "\e[1;32m  [✔] Subenum done ($(wc -l < "$TMPDIR/s6.txt"))\e[0m") &

# 7. Github-subdomains
(github-subdomains -d $DOMAIN -t $GITHUB_TOKEN 2>/dev/null \
| grep -oE '([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}' \
| grep -iE "(^|\.)${DOMAIN}$" \
| sort -u > "$TMPDIR/s7.txt"
echo -e "\e[1;32m  [✔] Github-subdomains done ($(wc -l < "$TMPDIR/s7.txt"))\e[0m") &

# 8. FFUF
if [ -f "$WORDLIST" ]; then
    (
        ffuf -w "$WORDLIST" \
             -u "https://FUZZ.${DOMAIN}" \
             -mc 200,301,302,403 \
             -rate 50 \
             -p 0.1 \
             -o "$TMPDIR/s8_raw.json" \
             -of json > /dev/null 2>&1

        python3 -c "
import json
try:
    with open('$TMPDIR/s8_raw.json') as f:
        data = json.load(f)
    for r in data.get('results', []):
        print(r['input']['FUZZ'] + '.$DOMAIN')
except:
    pass
" > "$TMPDIR/s8.txt" 2>/dev/null
        echo -e "\e[1;32m  [✔] FFUF done ($(wc -l < "$TMPDIR/s8.txt"))\e[0m"
    ) &
else
    echo -e "\e[1;33m[!] Wordlist not found — skipping ffuf\e[0m"
    touch "$TMPDIR/s8.txt"
fi

# waiting for all tools to finish
echo -e "\e[1;35m[*] Waiting for all engines to finish...\e[0m"
wait

# 9. Merging
echo -e "\e[1;32m[+] Merging results from all engines...\e[0m"
cat "$TMPDIR"/s*.txt 2>/dev/null | sort -u > "all_${DOMAIN}.txt"

# 10. httpx
echo -e "\e[1;33m[*] Running httpx to find live subdomains...\e[0m"
cat "all_${DOMAIN}.txt" | httpx -silent -fc 404 -o "live_${DOMAIN}.txt" > /dev/null 2>&1

# Cleanup
rm -rf "$TMPDIR"
rm -f "${DOMAIN}-$(date +%Y-%m-%d).txt" 2>/dev/null
rm -f "${DOMAIN}.txt" 2>/dev/null
rm -f "tmp-wayback-${DOMAIN}" 2>/dev/null

echo -e "\e[1;32m[#] Done! Check live_${DOMAIN}.txt\e[0m"
