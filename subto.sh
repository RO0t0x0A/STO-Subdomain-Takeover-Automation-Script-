#!/bin/bash
# ============================
# Colors (console only)
# ============================
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
PURPLE="\e[95m"
RESET="\e[0m"

OUTPUT_FILE=""
INPUT_FILE=""

# ============================
# Parse Arguments
# ============================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$INPUT_FILE" ]; then
    echo -e "${RED}Usage: $0 <subzy_results.json> [-o report.txt]${RESET}"
    exit 1
fi

if ! command -v jq >/dev/null; then
    echo -e "${RED}Error: jq is required but missing. Run: sudo apt install jq${RESET}"
    exit 1
fi

echo -e "${BLUE}Reading Subzy JSON data...${RESET}"

MAP=$(jq -r 'if type == "array" then .[] else . end | select(.status=="vulnerable") | .subdomain' "$INPUT_FILE" 2>/dev/null)

if [ -z "$MAP" ]; then
    echo -e "${YELLOW}No vulnerable subdomains found in the JSON file.${RESET}"
    exit 0
fi

# ============================
# Prepare output file
# ============================
if [ -n "$OUTPUT_FILE" ]; then
    {
        echo "----------------------------------------"
        echo "Subdomain Takeover Probe Report"
        echo "Generated: $(date)"
        echo "----------------------------------------"
    } > "$OUTPUT_FILE"
fi

# ============================
# Process each vulnerable subdomain
# ============================
while read -r domain; do
    [ -z "$domain" ] && continue

    # clean the domain from "http / https"
    CLEAN_DOMAIN=$(echo "$domain" | sed 's|https\?://||g' | sed 's|/.*||g')

    # ---- DIG CNAME lookup
    DIG_RESULT=$(dig +nocmd +noall +answer "$CLEAN_DOMAIN")
    CNAME=$(echo "$DIG_RESULT" | awk '/CNAME/ {print $5}' | sed 's/\.$//')

    if [ -n "$CNAME" ]; then
        CNAME_CONSOLE="${PURPLE}$CNAME${RESET}"
    else
        CNAME="None"
        CNAME_CONSOLE="None"
    fi

    # ---- CURL HTTPS status code
    HTTP_CODE=$(curl -o /dev/null -s -k -L -w "%{http_code}" --max-time 10 "https://$CLEAN_DOMAIN")

    # color code
    if [[ "$HTTP_CODE" =~ ^2 ]]; then COLOR_HTTP="$GREEN"
    elif [[ "$HTTP_CODE" =~ ^3 ]]; then COLOR_HTTP="$BLUE"
    elif [[ "$HTTP_CODE" =~ ^4 ]]; then COLOR_HTTP="$YELLOW"
    elif [[ "$HTTP_CODE" =~ ^5 ]]; then COLOR_HTTP="$RED"
    else COLOR_HTTP="$PURPLE"
    fi
    HTTP_CONSOLE="${COLOR_HTTP}$HTTP_CODE${RESET}"

    # ============================
    # Print to CONSOLE (colored)
    # ============================
    echo -e "${RED}[VULNERABLE]${RESET} $CLEAN_DOMAIN"
    echo -e " ├─ CNAME: $CNAME_CONSOLE"
    echo -e " └─ HTTPS Status: $HTTP_CONSOLE"
    echo ""

    # ============================
    # Save to OUTPUT FILE (no colors)
    # ============================
    if [ -n "$OUTPUT_FILE" ]; then
        {
            echo "----------------------------------------"
            echo "Domain: $CLEAN_DOMAIN"
            echo "Status: vulnerable"
            echo "CNAME: $CNAME"
            echo "HTTPS Status: $HTTP_CODE"
            echo ""
        } >> "$OUTPUT_FILE"
    fi
done <<< "$MAP"

# ============================
# Finish message
# ============================
if [ -n "$OUTPUT_FILE" ]; then
    echo -e "${GREEN}Finished! Report saved to $OUTPUT_FILE${RESET}"
else
    echo -e "${GREEN}Done — console only.${RESET}"
fi
