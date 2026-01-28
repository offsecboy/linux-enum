#!/bin/bash

# ============================================
# Linux Enumeration Script
# Version: 2.0
# Author: OffSecBoy
# Description: Comprehensive Linux enumeration script
#              that adapts to user privileges with user choice
# ============================================

# Ask user if they want to run as root
ask_for_root() {
    echo "[?] Do you want to run privileged commands? (y/n): "
    read -r response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "[*] Attempting to gain root privileges..."
        
        # Try sudo first
        if command -v sudo >/dev/null 2>&1; then
            echo "[!] Please enter your password for sudo:"
            if sudo -v; then
                echo "[+] Sudo authentication successful"
                return 0
            else
                echo "[-] Sudo authentication failed"
            fi
        fi
        
        # Try su as fallback
        echo "[!] Trying su... Please enter root password:"
        if su -c "echo 'Root access test'" root; then
            echo "[+] Root authentication successful"
            return 0
        else
            echo "[-] Root authentication failed"
            return 1
        fi
    else
        echo "[*] Continuing without root privileges"
        return 1
    fi
}

# Function to run privileged commands
run_privileged() {
    local cmd="$1"
    
    if [[ "$HAS_ROOT" == "true" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo bash -c "$cmd"
        else
            su -c "$cmd" root
        fi
    else
        echo "[-] Command requires root privileges (skipped)"
        return 1
    fi
}

# Check if running as root initially
if [[ $EUID -eq 0 ]]; then
    IS_ROOT=true
    HAS_ROOT=true
    echo "[+] Running with root privileges"
else
    IS_ROOT=false
    
    # Ask user if they want root access
    if ask_for_root; then
        HAS_ROOT=true
        echo "[+] Running with root privileges (via sudo/su)"
    else
        HAS_ROOT=false
        echo "[!] Running without root privileges"
        echo "[!] Some commands will be skipped or modified"
    fi
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
    local output=""
    
    echo ""
    echo "[*] $description"
    echo "" >> $OUTPUT_FILE
    echo "[*] $description" >> $OUTPUT_FILE
    echo "Command: $cmd" >> $OUTPUT_FILE
    echo "--------------------------------------------------" >> $OUTPUT_FILE
    
    if [[ "$requires_root" == "true" && "$HAS_ROOT" == "false" ]]; then
        echo "[-] Skipped (requires root)"
        echo "Skipped (requires root privileges)" >> $OUTPUT_FILE
        return 1
    fi
    
    # Execute command
    if [[ "$requires_root" == "true" && "$HAS_ROOT" == "true" && "$IS_ROOT" == "false" ]]; then
        # User is not root but has root access via sudo/su
        output=$(run_privileged "$cmd" 2>/dev/null)
        echo "$output" >> $OUTPUT_FILE
    else
        # Run normally
        timeout 10 bash -c "$cmd" >> $OUTPUT_FILE 2>&1
    fi
    
    if [ $? -eq 124 ]; then
        echo "[-] Command timed out"
        echo "Command timed out after 10 seconds" >> $OUTPUT_FILE
    else
        echo "[+] Executed"
    fi
    
    echo "" >> $OUTPUT_FILE
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================
# SYSTEM INFORMATION
# ============================================
echo ""
echo "=== SYSTEM INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== SYSTEM INFORMATION ===" >> $OUTPUT_FILE

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
echo ""
echo "=== HARDWARE INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== HARDWARE INFORMATION ===" >> $OUTPUT_FILE

if command_exists "lscpu"; then
    run_cmd "lscpu" "CPU architecture information" "false"
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
echo ""
echo "=== USER & GROUP INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== USER & GROUP INFORMATION ===" >> $OUTPUT_FILE

run_cmd "id" "Current user ID and group information" "false"
run_cmd "whoami" "Current username" "false"

# Sudo privileges check
run_cmd "sudo -l 2>/dev/null || echo 'No sudo privileges or password required'" "Sudo privileges for current user" "false"

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
echo ""
echo "=== PROCESS INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== PROCESS INFORMATION ===" >> $OUTPUT_FILE

run_cmd "ps aux" "All running processes" "false"
run_cmd "ps -ef" "Alternative process listing" "false"
run_cmd "top -b -n 1 2>/dev/null | head -20" "Top processes" "false"

if command_exists "lsof"; then
    run_cmd "lsof -i 2>/dev/null | head -30" "Processes with network connections" "true"
fi

# ============================================
# NETWORK INFORMATION
# ============================================
echo ""
echo "=== NETWORK INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== NETWORK INFORMATION ===" >> $OUTPUT_FILE

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
echo ""
echo "=== FILE SYSTEM INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== FILE SYSTEM INFORMATION ===" >> $OUTPUT_FILE

# Mount information
run_cmd "mount" "Mounted filesystems" "false"
run_cmd "df -h" "Disk usage" "false"
run_cmd "cat /etc/fstab 2>/dev/null || echo 'fstab not accessible'" "Filesystem table" "true"

# Special permission files (adjusted for non-root)
if [[ "$HAS_ROOT" == "true" ]]; then
    run_cmd "find / -perm -u=s -type f 2>/dev/null | head -50" "SUID binaries" "true"
    run_cmd "find / -perm -g=s -type f 2>/dev/null | head -50" "SGID binaries" "true"
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
echo ""
echo "=== CREDENTIALS & SECRETS ==="
echo "" >> $OUTPUT_FILE
echo "=== CREDENTIALS & SECRETS ===" >> $OUTPUT_FILE

# SSH keys
run_cmd "find /home -name 'id_rsa' -o -name 'id_dsa' -o -name '*.pem' 2>/dev/null" "SSH private keys in /home" "false"
run_cmd "ls -la ~/.ssh/ 2>/dev/null || echo 'No .ssh directory'" "Current user SSH directory" "false"

# History files
run_cmd "cat ~/.bash_history 2>/dev/null | tail -20 || echo 'No bash history'" "Bash history" "false"
run_cmd "cat ~/.zsh_history 2>/dev/null | tail -20 2>/dev/null || echo 'No zsh history'" "Zsh history" "false"

# ============================================
# SERVICE INFORMATION
# ============================================
echo ""
echo "=== SERVICE INFORMATION ==="
echo "" >> $OUTPUT_FILE
echo "=== SERVICE INFORMATION ===" >> $OUTPUT_FILE

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
# QUICK WINS - PRIORITY CHECKS
# ============================================
echo ""
echo "=== QUICK WINS - PRIORITY CHECKS ==="
echo "" >> $OUTPUT_FILE
echo "=== QUICK WINS - PRIORITY CHECKS ===" >> $OUTPUT_FILE

echo ""
echo "[!] Running Quick Wins checks..."

# 1. Sudo privileges (most important)
echo ""
echo "[*] 1. Checking sudo privileges..."
if command_exists "sudo"; then
    sudo -l 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[!] POSSIBLE PRIVILEGE ESCALATION: User has sudo privileges"
        echo "POSSIBLE PRIVILEGE ESCALATION: User has sudo privileges" >> $OUTPUT_FILE
    else
        echo "[-] No sudo privileges found"
    fi
fi

# 2. SUID binaries
echo ""
echo "[*] 2. Checking for SUID binaries..."
if [[ "$HAS_ROOT" == "true" ]]; then
    if [[ "$IS_ROOT" == "true" ]]; then
        find / -perm -u=s -type f 2>/dev/null | head -20
        suid_count=$(find / -perm -u=s -type f 2>/dev/null | wc -l)
    else
        run_privileged "find / -perm -u=s -type f 2>/dev/null | head -20"
        suid_count=$(run_privileged "find / -perm -u=s -type f 2>/dev/null | wc -l")
    fi
    echo "Found $suid_count SUID binaries" >> $OUTPUT_FILE
else
    find /home -perm -u=s -type f 2>/dev/null 2>/dev/null | head -10
    suid_count=$(find /home -perm -u=s -type f 2>/dev/null 2>/dev/null | wc -l)
    echo "Found $suid_count SUID binaries in /home" >> $OUTPUT_FILE
fi

# 3. World-writable files
echo ""
echo "[*] 3. Checking for world-writable files..."
find /tmp /var/tmp -perm -o+w -type f 2>/dev/null | head -10
ww_count=$(find /tmp /var/tmp -perm -o+w -type f 2>/dev/null | wc -l)
echo "Found $ww_count world-writable files in temp directories" >> $OUTPUT_FILE

# 4. Cron jobs
echo ""
echo "[*] 4. Checking cron jobs..."
crontab -l 2>/dev/null
if [[ "$HAS_ROOT" == "true" ]]; then
    if [[ "$IS_ROOT" == "true" ]]; then
        ls -la /etc/cron* 2>/dev/null
    else
        run_privileged "ls -la /etc/cron* 2>/dev/null"
    fi
fi

# ============================================
# FINAL SUMMARY
# ============================================
echo ""
echo "=== ENUMERATION COMPLETE ==="
echo "" >> $OUTPUT_FILE
echo "=== ENUMERATION COMPLETE ===" >> $OUTPUT_FILE

echo ""
echo "[+] Report saved to: $OUTPUT_FILE"
echo ""
echo "[!] Summary:"
echo "  - Root privileges: $HAS_ROOT"
echo "  - File size: $(du -h $OUTPUT_FILE | cut -f1)"

if [[ "$HAS_ROOT" == "false" ]]; then
    echo ""
    echo "[!] Note: Some commands were skipped due to lack of root privileges"
    echo "Note: Some commands were skipped due to lack of root privileges" >> $OUTPUT_FILE
fi

echo ""
echo "[*] Next steps:"
echo "  1. Review $OUTPUT_FILE for findings"
echo "  2. Check 'Quick Wins' section for privilege escalation vectors"
echo "  3. Look for misconfigurations in sudo, SUID binaries, and cron jobs"

echo ""
echo "[!] Disclaimer:"
echo "  This tool is for authorized security assessments only."
echo "  Always ensure you have proper authorization before use."

# Clean up
rm -f /tmp/enum_*.tmp 2>/dev/null

exit 0
