#!/bin/bash

# ============================================
# Linux Enumeration Script
# Version: 1.0
# Author: OffSecBoy
# Description: Comprehensive Linux enumeration script
#              that adapts to user privileges
# ============================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    IS_ROOT=true
    echo -e "${GREEN}[+] Running with root privileges${NC}"
else
    IS_ROOT=false
    echo -e "${YELLOW}[!] Running without root privileges${NC}"
    echo -e "${YELLOW}[!] Some commands will be skipped or modified${NC}"
fi

# Output file
OUTPUT_FILE="enum_report_$(date +%Y%m%d_%H%M%S).txt"
echo "Linux Enumeration Report - $(date)" > $OUTPUT_FILE
echo "=====================================" >> $OUTPUT_FILE

# Function to run command and log output
run_cmd() {
    local cmd="$1"
    local description="$2"
    local requires_root="${3:-false}"
    
    echo -e "\n${BLUE}[*] $description${NC}"
    echo -e "\n[*] $description" >> $OUTPUT_FILE
    echo "Command: $cmd" >> $OUTPUT_FILE
    echo "--------------------------------------------------" >> $OUTPUT_FILE
    
    if [[ "$requires_root" == "true" && "$IS_ROOT" == "false" ]]; then
        echo -e "${YELLOW}[-] Skipped (requires root)${NC}"
        echo "Skipped (requires root privileges)" >> $OUTPUT_FILE
        return 1
    fi
    
    # Execute command with timeout
    timeout 10 bash -c "$cmd" 2>/dev/null >> $OUTPUT_FILE
    
    if [ $? -eq 124 ]; then
        echo -e "${YELLOW}[-] Command timed out${NC}"
        echo "Command timed out after 10 seconds" >> $OUTPUT_FILE
    else
        echo -e "${GREEN}[+] Executed${NC}"
    fi
    
    echo "" >> $OUTPUT_FILE
}

# Function to check if command exists
command_exists() {
    command -v $1 >/dev/null 2>&1
}

# ============================================
# SYSTEM INFORMATION
# ============================================
echo -e "\n${GREEN}=== SYSTEM INFORMATION ===${NC}"
echo -e "\n=== SYSTEM INFORMATION ===" >> $OUTPUT_FILE

run_cmd "uname -a" "System kernel and architecture information" "false"
run_cmd "cat /etc/issue 2>/dev/null || echo 'Not available'" "Distribution name and version" "false"
run_cmd "cat /etc/*release* 2>/dev/null || echo 'Not available'" "Detailed distribution release information" "false"
run_cmd "hostname" "System hostname" "false"
run_cmd "hostnamectl 2>/dev/null || echo 'hostnamectl not available'" "Systemd hostname control information" "false"

# Environment variables
run_cmd "env" "Environment variables" "false"
run_cmd "printenv" "Alternative environment variables listing" "false"
run_cmd "echo \$PATH" "PATH environment variable" "false"

# ============================================
# HARDWARE INFORMATION
# ============================================
echo -e "\n${GREEN}=== HARDWARE INFORMATION ===${NC}"
echo -e "\n=== HARDWARE INFORMATION ===" >> $OUTPUT_FILE

if command_exists "lscpu"; then
    run_cmd "lscpu" "CPU architecture information" "false"
fi

if command_exists "lsmem"; then
    run_cmd "lsmem" "Memory information" "true"
fi

run_cmd "free -h" "Memory usage in human readable format" "false"

if command_exists "lspci"; then
    run_cmd "lspci" "PCI devices information" "false"
fi

if command_exists "lsusb"; then
    run_cmd "lsusb" "USB devices information" "false"
fi

# ============================================
# USER & GROUP INFORMATION
# ============================================
echo -e "\n${GREEN}=== USER & GROUP INFORMATION ===${NC}"
echo -e "\n=== USER & GROUP INFORMATION ===" >> $OUTPUT_FILE

run_cmd "id" "Current user ID and group information" "false"
run_cmd "whoami" "Current username" "false"

# Sudo privileges check
if command_exists "sudo"; then
    run_cmd "sudo -l 2>/dev/null || echo 'No sudo privileges or password required'" "Sudo privileges for current user" "false"
else
    echo "sudo not available" >> $OUTPUT_FILE
fi

# User information
run_cmd "cat /etc/passwd" "All system users" "false"
run_cmd "getent passwd" "Alternative user listing" "false"
run_cmd "cat /etc/group" "All system groups" "false"
run_cmd "getent group" "Alternative group listing" "false"

# Home directories
run_cmd "ls -la /home/ 2>/dev/null || echo '/home not accessible'" "Home directories listing" "false"

# Login history
run_cmd "last 2>/dev/null | head -20" "Recent login history" "true"
run_cmd "who" "Currently logged in users" "false"
run_cmd "w" "Logged in users and their processes" "false"

# ============================================
# PROCESS INFORMATION
# ============================================
echo -e "\n${GREEN}=== PROCESS INFORMATION ===${NC}"
echo -e "\n=== PROCESS INFORMATION ===" >> $OUTPUT_FILE

run_cmd "ps aux" "All running processes" "false"
run_cmd "ps -ef" "Alternative process listing" "false"
run_cmd "top -b -n 1 2>/dev/null | head -20" "Top processes" "false"

if command_exists "lsof"; then
    run_cmd "lsof -i 2>/dev/null | head -30" "Processes with network connections" "true"
fi

# ============================================
# NETWORK INFORMATION
# ============================================
echo -e "\n${GREEN}=== NETWORK INFORMATION ===${NC}"
echo -e "\n=== NETWORK INFORMATION ===" >> $OUTPUT_FILE

# Network interfaces
if command_exists "ifconfig"; then
    run_cmd "ifconfig" "Network interfaces (ifconfig)" "false"
else
    run_cmd "ip addr" "Network interfaces (ip addr)" "false"
fi

# Network connections
if command_exists "netstat"; then
    run_cmd "netstat -tulpn 2>/dev/null || netstat -tulpn" "Listening ports and processes" "true"
    run_cmd "netstat -antp 2>/dev/null || netstat -antp" "All network connections" "true"
    run_cmd "netstat -rn" "Routing table" "false"
else
    run_cmd "ss -tulpn" "Listening ports and processes (ss)" "true"
    run_cmd "ss -antp" "All network connections (ss)" "true"
    run_cmd "ip route" "Routing table (ip route)" "false"
fi

# DNS information
run_cmd "cat /etc/resolv.conf 2>/dev/null || echo 'resolv.conf not accessible'" "DNS configuration" "false"
run_cmd "cat /etc/hosts" "Local hosts file" "false"

# ============================================
# FILE SYSTEM INFORMATION
# ============================================
echo -e "\n${GREEN}=== FILE SYSTEM INFORMATION ===${NC}"
echo -e "\n=== FILE SYSTEM INFORMATION ===" >> $OUTPUT_FILE

# Mount information
run_cmd "mount" "Mounted filesystems" "false"
run_cmd "df -h" "Disk usage" "false"
run_cmd "cat /etc/fstab 2>/dev/null || echo 'fstab not accessible'" "Filesystem table" "true"

# Special permission files (adjusted for non-root)
if [[ "$IS_ROOT" == "true" ]]; then
    run_cmd "find / -perm -u=s -type f 2>/dev/null | head -50" "SUID binaries" "true"
    run_cmd "find / -perm -g=s -type f 2>/dev/null | head -50" "SGID binaries" "true"
    run_cmd "getcap -r / 2>/dev/null | head -50" "Files with capabilities" "true"
else
    run_cmd "find /home -perm -u=s -type f 2>/dev/null 2>/dev/null | head -30" "SUID binaries in /home" "false"
    run_cmd "find /tmp /var/tmp -perm -o+w -type f 2>/dev/null | head -30" "World-writable files in temp directories" "false"
    run_cmd "find /home -perm -o+w -type f 2>/dev/null 2>/dev/null | head -30" "World-writable files in /home" "false"
fi

# General file search (non-root friendly)
run_cmd "find /home -name '*.txt' -o -name '*.conf' -o -name '*.cfg' -o -name '*.sh' -o -name '*.py' 2>/dev/null | head -30" "Interesting files in /home" "false"
run_cmd "find /tmp /var/tmp -type f -mmin -60 2>/dev/null | head -20" "Recent files in temp directories" "false"

# ============================================
# CREDENTIALS & SECRETS
# ============================================
echo -e "\n${GREEN}=== CREDENTIALS & SECRETS ===${NC}"
echo -e "\n=== CREDENTIALS & SECRETS ===" >> $OUTPUT_FILE

# SSH keys
run_cmd "find /home -name 'id_rsa' -o -name 'id_dsa' -o -name '*.pem' 2>/dev/null" "SSH private keys in /home" "false"
run_cmd "ls -la ~/.ssh/ 2>/dev/null || echo 'No .ssh directory'" "Current user SSH directory" "false"

# Configuration files with passwords
run_cmd "find /home -name '*.conf' -o -name '*.cfg' -o -name '*.ini' 2>/dev/null | xargs grep -l -i 'pass\|pwd\|password' 2>/dev/null | head -10" "Config files with password mentions" "false"

# History files
run_cmd "cat ~/.bash_history 2>/dev/null | tail -20 || echo 'No bash history'" "Bash history" "false"
run_cmd "cat ~/.zsh_history 2>/dev/null | tail -20 2>/dev/null || echo 'No zsh history'" "Zsh history" "false"
run_cmd "history" "Current session history" "false"

# ============================================
# SERVICE INFORMATION
# ============================================
echo -e "\n${GREEN}=== SERVICE INFORMATION ===${NC}"
echo -e "\n=== SERVICE INFORMATION ===" >> $OUTPUT_FILE

# Service information
if command_exists "systemctl"; then
    run_cmd "systemctl list-units --type=service --state=running 2>/dev/null | head -20" "Running services (systemd)" "false"
else
    run_cmd "service --status-all 2>/dev/null | head -20" "Service status (SysV)" "false"
fi

# Cron jobs
run_cmd "crontab -l 2>/dev/null || echo 'No user cron jobs'" "Current user cron jobs" "false"
run_cmd "ls -la /etc/cron* 2>/dev/null || echo 'Cannot access cron directories'" "System cron directories" "true"
run_cmd "cat /etc/crontab 2>/dev/null || echo 'crontab not accessible'" "System crontab" "true"

# ============================================
# PRIVILEGE ESCALATION CHECKS
# ============================================
echo -e "\n${GREEN}=== PRIVILEGE ESCALATION CHECKS ===${NC}"
echo -e "\n=== PRIVILEGE ESCALATION CHECKS ===" >> $OUTPUT_FILE

# Sudo version
if command_exists "sudo"; then
    run_cmd "sudo -V 2>/dev/null | head -5" "Sudo version" "false"
fi

# Package information
if command_exists "dpkg"; then
    run_cmd "dpkg -l 2>/dev/null | grep -E '(sudo|openssl|ssh)' | head -10" "Security-related packages (dpkg)" "false"
elif command_exists "rpm"; then
    run_cmd "rpm -qa 2>/dev/null | grep -E '(sudo|openssl|ssh)' | head -10" "Security-related packages (rpm)" "false"
fi

# Kernel information for exploit research
run_cmd "uname -a | grep -o -E '(Ubuntu|Debian|CentOS|Red Hat|Fedora)' 2>/dev/null || echo 'Distribution not identified'" "Distribution identification" "false"

# ============================================
# QUICK WINS - PRIORITY CHECKS
# ============================================
echo -e "\n${GREEN}=== QUICK WINS - PRIORITY CHECKS ===${NC}"
echo -e "\n=== QUICK WINS - PRIORITY CHECKS ===" >> $OUTPUT_FILE

echo -e "\n${YELLOW}[!] Running Quick Wins checks...${NC}"

# 1. Sudo privileges (most important)
echo -e "\n${BLUE}[*] 1. Checking sudo privileges...${NC}"
if command_exists "sudo"; then
    sudo -l 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[!] POSSIBLE PRIVILEGE ESCALATION: User has sudo privileges${NC}"
        echo "POSSIBLE PRIVILEGE ESCALATION: User has sudo privileges" >> $OUTPUT_FILE
    else
        echo -e "[-] No sudo privileges found"
    fi
fi

# 2. SUID binaries
echo -e "\n${BLUE}[*] 2. Checking for SUID binaries...${NC}"
if [[ "$IS_ROOT" == "true" ]]; then
    find / -perm -u=s -type f 2>/dev/null | head -20
    suid_count=$(find / -perm -u=s -type f 2>/dev/null | wc -l)
    echo "Found $suid_count SUID binaries" >> $OUTPUT_FILE
else
    find /home -perm -u=s -type f 2>/dev/null 2>/dev/null | head -10
    suid_count=$(find /home -perm -u=s -type f 2>/dev/null 2>/dev/null | wc -l)
    echo "Found $suid_count SUID binaries in /home" >> $OUTPUT_FILE
fi

# 3. World-writable files
echo -e "\n${BLUE}[*] 3. Checking for world-writable files...${NC}"
find /tmp /var/tmp -perm -o+w -type f 2>/dev/null | head -10
ww_count=$(find /tmp /var/tmp -perm -o+w -type f 2>/dev/null | wc -l)
echo "Found $ww_count world-writable files in temp directories" >> $OUTPUT_FILE

# 4. Cron jobs
echo -e "\n${BLUE}[*] 4. Checking cron jobs...${NC}"
crontab -l 2>/dev/null
ls -la /etc/cron* 2>/dev/null

# ============================================
# COMPREHENSIVE ONE-LINER
# ============================================
echo -e "\n${GREEN}=== COMPREHENSIVE ENUMERATION ONE-LINER ===${NC}"
echo -e "\n=== COMPREHENSIVE ENUMERATION ONE-LINER ===" >> $OUTPUT_FILE

one_liner() {
    echo "===== $(date) ====="
    echo "===== SYSTEM ====="
    uname -a
    echo "===== USER ====="
    id
    echo "===== SUDO ====="
    sudo -l 2>/dev/null || echo "No sudo access"
    echo "===== NETWORK ====="
    ip addr 2>/dev/null || ifconfig 2>/dev/null || echo "No network tools"
    echo "===== PROCESSES ====="
    ps aux 2>/dev/null | head -20
}

run_cmd "one_liner" "Comprehensive enumeration one-liner" "false"

# ============================================
# FINAL SUMMARY
# ============================================
echo -e "\n${GREEN}=== ENUMERATION COMPLETE ===${NC}"
echo -e "\n=== ENUMERATION COMPLETE ===" >> $OUTPUT_FILE

echo -e "\n${GREEN}[+] Report saved to: $OUTPUT_FILE${NC}"
echo -e "\n${YELLOW}[!] Summary:${NC}"
echo "  - Commands executed: $(grep -c '\[*\] ' $OUTPUT_FILE)"
echo "  - Root privileges: $IS_ROOT"
echo "  - File size: $(du -h $OUTPUT_FILE | cut -f1)"

if [[ "$IS_ROOT" == "false" ]]; then
    echo -e "\n${YELLOW}[!] Note: Run with 'sudo' or as root for complete enumeration${NC}"
    echo "Note: Some commands were skipped due to lack of root privileges" >> $OUTPUT_FILE
fi

echo -e "\n${BLUE}[*] Next steps:${NC}"
echo "  1. Review $OUTPUT_FILE for findings"
echo "  2. Check 'Quick Wins' section for privilege escalation vectors"
echo "  3. Look for misconfigurations in sudo, SUID binaries, and cron jobs"

echo -e "\n${YELLOW}[!] Disclaimer:${NC}"
echo "  This tool is for authorized security assessments only."
echo "  Always ensure you have proper authorization before use."

# Clean up temporary files
rm -f /tmp/enum_*.tmp 2>/dev/null

exit 0