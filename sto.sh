#!/bin/bash

# ─────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ─────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────
clear
echo -e "${R}"
cat << 'EOF'
  ██████ ▄▄▄█████▓ ▒█████  
▒██    ▒ ▓  ██▒ ▓▒▒██▒  ██▒
░ ▓██▄   ▒ ▓██░ ▒░▒██░  ██▒
  ▒   ██▒░ ▓██▓ ░ ▒██   ██░
▒██████▒▒  ▒██▒ ░ ░ ████▓▒░
▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒░▒░▒░ 
░ ░▒  ░ ░    ░      ░ ▒ ▒░ 
░  ░  ░    ░      ░ ░ ░ ▒  
      ░               ░ ░  
EOF
echo -e "${RESET}"
echo -e "${DIM}${W}        Subdomain Takeover Script 🎯${RESET}"
echo -e "${DIM}        by Someone | Sali 3la El nabi Mohammed${RESET}"
echo ""
echo -e "${DIM}${R}  ────────────────────────────────────────${RESET}"
echo ""

# ─────────────────────────────────────────────
# Usage check
# ─────────────────────────────────────────────
if [ -z "$1" ]; then
    echo -e "${R}  [!]${W} Usage: sto <target.com>${RESET}"
    echo ""
    exit 1
fi

DOMAIN="$1"
ALL_SUBS="all_${DOMAIN}.txt"
LIVE_SUBS="live_${DOMAIN}.txt"
SUBZY_OUT="live_${DOMAIN}-subzy.txt"
FINAL_OUT="live_${DOMAIN}-potential_sto"
START_TIME=$(date +%s)

# ─── Ctrl+C handler ───
cleanup() {
    echo -e "\n${R}  [!]${RESET} Interrupted! Cleaning up..."
    echo -e "${DIM}  removing temp files...${RESET}"
    rm -f "$SUBZY_OUT" "$FINAL_OUT" 2>/dev/null
    echo -e "${R}  [!]${RESET} Aborted.\n"
    exit 1
}
trap cleanup INT

echo -e "  ${DIM}target   ${RESET}${W}${DOMAIN}${RESET}"
echo -e "  ${DIM}started  ${RESET}${W}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo ""
echo -e "${DIM}${R}  ────────────────────────────────────────${RESET}"
echo ""

# ─────────────────────────────────────────────
# PHASE 1
# ─────────────────────────────────────────────
echo -e "  ${M}[01]${RESET} ${BOLD}SUBDOMAIN ENUMERATION${RESET} ${DIM}// 9 engines${RESET}"
echo ""

subdomains "$DOMAIN"

if [ ! -f "$LIVE_SUBS" ]; then
    echo -e "\n  ${R}[ERR]${RESET} live subdomains file not found.\n"
    exit 1
fi

ALL_COUNT=$(wc -l < "$ALL_SUBS" 2>/dev/null || echo "0")
LIVE_COUNT=$(wc -l < "$LIVE_SUBS" 2>/dev/null || echo "0")

echo ""
echo -e "${DIM}${R}  ────────────────────────────────────────${RESET}"
echo -e "  ${G}[✔]${RESET} enumeration complete"
echo -e "      ${DIM}all    →${RESET} ${W}${ALL_COUNT}${RESET} subdomains ${DIM}(${ALL_SUBS})${RESET}"
echo -e "      ${DIM}live   →${RESET} ${W}${LIVE_COUNT}${RESET} subdomains ${DIM}(${LIVE_SUBS})${RESET}"
echo ""

# ─────────────────────────────────────────────
# PHASE 2
# ─────────────────────────────────────────────
echo -e "  ${M}[02]${RESET} ${BOLD}TAKEOVER SCAN${RESET} ${DIM}// subzy${RESET}"
echo ""

subzy run --targets "$LIVE_SUBS" --output "$SUBZY_OUT" > /dev/null 2>&1

if [ ! -f "$SUBZY_OUT" ]; then
    echo -e "\n  ${R}[ERR]${RESET} subzy output not found.\n"
    exit 1
fi

SUBZY_COUNT=$(wc -l < "$SUBZY_OUT" 2>/dev/null || echo "0")

echo -e "${DIM}${R}  ────────────────────────────────────────${RESET}"
echo -e "  ${G}[✔]${RESET} subzy complete"
echo -e "      ${DIM}output →${RESET} ${W}${SUBZY_COUNT}${RESET} entries ${DIM}(${SUBZY_OUT})${RESET}"
echo ""

# ─────────────────────────────────────────────
# PHASE 3
# ─────────────────────────────────────────────
echo -e "  ${M}[03]${RESET} ${BOLD}VULNERABILITY FILTER${RESET} ${DIM}// subto${RESET}"
echo ""

subto "$SUBZY_OUT" -o "$FINAL_OUT"

if [ ! -f "$FINAL_OUT" ]; then
    echo -e "\n  ${R}[ERR]${RESET} final output not found.\n"
    exit 1
fi

FINAL_COUNT=$(wc -l < "$FINAL_OUT" 2>/dev/null || echo "0")
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo -e "${DIM}${R}  ────────────────────────────────────────${RESET}"
echo -e "  ${G}[✔]${RESET} filter complete"
echo -e "      ${DIM}output →${RESET} ${W}${FINAL_COUNT}${RESET} entries ${DIM}(${FINAL_OUT})${RESET}"
echo ""

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
echo -e "${DIM}${R}  ════════════════════════════════════════${RESET}"
echo -e "  ${R}${BOLD}SUMMARY${RESET}"
echo -e "${DIM}${R}  ════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${DIM}target     ${RESET}${W}${DOMAIN}${RESET}"
echo -e "  ${DIM}elapsed    ${RESET}${W}${ELAPSED}s${RESET}"
echo ""
echo -e "  ${DIM}all subs   ${RESET}${W}${ALL_COUNT}${RESET}  ${DIM}→ ${ALL_SUBS}${RESET}"
echo -e "  ${DIM}live subs  ${RESET}${W}${LIVE_COUNT}${RESET}  ${DIM}→ ${LIVE_SUBS}${RESET}"
echo -e "  ${DIM}subzy      ${RESET}${W}${SUBZY_COUNT}${RESET}  ${DIM}→ ${SUBZY_OUT}${RESET}"
echo -e "  ${DIM}potential  ${RESET}${R}${BOLD}${FINAL_COUNT}${RESET}  ${DIM}→ ${FINAL_OUT}${RESET}"
echo ""
echo -e "${DIM}${R}  ════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${G}${BOLD}done.${RESET} ${DIM}happy hunting 🎯${RESET}"
echo ""
