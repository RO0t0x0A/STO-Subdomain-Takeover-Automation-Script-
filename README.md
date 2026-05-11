# STO — Subdomain Takeover Automation Script

A fast Bash-based automation script for subdomain enumeration, live host detection, and subdomain takeover discovery.

This project combines multiple reconnaissance engines with takeover detection tools to help security researchers identify potential subdomain takeover vulnerabilities quickly.

> Built for bug bounty hunting and authorized security testing only.

---

# Features

* Parallel subdomain enumeration with 9 engines
* Live subdomain detection using `httpx`
* Automated takeover scanning using `subzy`
* dig to find CNAME records for vuln subdomains 

---

# Workflow

```text
Subdomain Enumeration
        ↓
Live Host Detection
        ↓
Subdomain Takeover Scan
        ↓
Potential Vulnerability Report
```

---

# Included Scripts

## 1. `subdomains`

Performs subdomain enumeration using multiple engines in parallel.

### Engines Used

* subfinder
* assetfinder
* amass
* findomain
* chaos
* subenum
* github-subdomains
* ffuf
* httpx

### Output Files

```bash
all_target.com.txt
live_target.com.txt
```

---

## 2. `subto`

Filters and analyzes `subzy` TXT results.

### Features

* Extracts only vulnerable entries
* Resolves CNAME records
* Retrieves HTTPS status codes
* Generates clean reports

### Example Output

```text
[VULNERABLE] test.example.com
 ├─ CNAME: example.herokudns.com
 └─ HTTPS Status: 404
```

---

## 3. `sto`

Main automation wrapper.

Runs the complete workflow automatically:

1. Enumerates subdomains
2. Detects live hosts
3. Runs subzy takeover scan
4. Filters results with `subto`
5. Generates final report

---

# Installation

## Requirements

Install the following tools first:

```bash
sudo apt install jq ffuf dnsutils curl
```

### Go Tools

```bash
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/owasp-amass/amass/v4/...@master
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/chaos-client/cmd/chaos@latest
go install github.com/LukaSikic/subzy@latest
go install github.com/gwen001/github-subdomains@latest
```

### Additional Tools

```bash
cargo install findomain
pip install subenum
```

---

# Setup

Clone the repository:

```bash
git clone https://github.com/RO0t0x0A/STO-Subdomain-Takeover-Automation-Script-.git
cd STO-Subdomain-Takeover-Automation-Tool
```

Make scripts executable:

```bash
chmod +x sto subdomains subto
```

Move them to your PATH (optional):

```bash
sudo mv sto /usr/local/bin/
sudo mv subdomains /usr/local/bin/
sudo mv subto /usr/local/bin/
```

---

# Configuration

The `subdomains` script requires:

* GitHub token
* Chaos API key

Edit the script and add your tokens:

```bash
GITHUB_TOKEN="your_github_token"
CHAOS_TOKEN="your_chaos_token"
```

---

# Usage

## Full Automation

```bash
sto example.com
```

---

## Enumeration Only

```bash
subdomains example.com
```

---

## Filter Subzy Results

```bash
subto live_target.com-subzy.txt 
```

---

# Example Run

```bash
$ sto example.com

[01] SUBDOMAIN ENUMERATION
[✔] enumeration complete

[02] TAKEOVER SCAN
[✔] subzy complete

[03] VULNERABILITY FILTER
[VULNERABLE] test.example.com
 ├─ CNAME: example.herokudns.com
 └─ HTTPS Status: 404
```

---

# Output Files

| File                            | Description               |
| ------------------------------- | ------------------------- |
| `all_target.com.txt`            | All discovered subdomains |
| `live_target.com.txt`           | Live subdomains           |
| `live_target.com-subzy.txt`     | Raw subzy TXT results     |
| `live_target.com-potential_sto` | Final takeover report     |

---

# Recommended Improvements

Future improvements that can be added:

* Parallel `httpx` probing optimization
* active subdomain enumeration tools 
* Slack/Discord notifications
* JSON export mode

---

# Security Notice

This tool is intended for:

* Bug bounty hunting
* Authorized penetration testing
* Security research

Do not use this tool against targets without permission.

The author is not responsible for misuse.

---

# Credits

Huge respect to the developers of:

* ProjectDiscovery
* Tomnomnom
* OWASP Amass
* LukaSikic (Subzy)
* Findomain
* FFUF

---

# License

MIT License
