#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run this script as root!"
    exit 1
fi

# Global Variables
DISK_FILE="/bigfile"
LOCKED_USER="testuser"
LOG_FILE="/var/log/fault_injection.log"
BACKUP_DIR="/tmp/system_backups"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Backup function
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        log_message "INFO" "Backed up $file to $BACKUP_DIR"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create a kernel panic (CRASHES SYSTEM!)
kernel_panic() {
    log_message "WARNING" "Attempting to trigger Kernel Panic..."
    echo 1 > /proc/sys/kernel/panic
    echo 1 > /proc/sys/kernel/panic_on_oops
    # Uncomment below line to **force a real crash** (Dangerous!)
    # echo c > /proc/sysrq-trigger
}

# Function to break GRUB and prevent booting
break_grub() {
    log_message "INFO" "Breaking GRUB Bootloader..."
    backup_file "/etc/default/grub"
    echo "GRUB_CMDLINE_LINUX='invalid_option'" >> /etc/default/grub
    if command_exists update-grub; then
        update-grub
    else
        log_message "ERROR" "update-grub command not found"
    fi
}

# Function to remove essential system binaries
delete_critical_binaries() {
    log_message "INFO" "Removing essential system utilities..."
    for binary in systemctl sudo; do
        if [ -f "/bin/$binary" ]; then
            backup_file "/bin/$binary"
            mv "/bin/$binary" "/bin/$binary.bak"
        fi
    done
}

# Function to fill up disk space (100% usage)
fill_disk() {
    log_message "INFO" "Filling up disk space..."
    local available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    local fill_size=$((available_space - 1))  # Leave 1GB free
    fallocate -l "${fill_size}G" "$DISK_FILE" || log_message "ERROR" "Failed to fill disk"
}

# Function to corrupt filesystem metadata
corrupt_filesystem() {
    log_message "WARNING" "Corrupting filesystem metadata..."
    if mount | grep -q "/dev/sda1"; then
        umount /dev/sda1
        dd if=/dev/zero of=/dev/sda1 bs=512 count=100
    else
        log_message "ERROR" "Device /dev/sda1 not found or not mounted"
    fi
}

# Function to break SSH and prevent remote access
disable_ssh() {
    log_message "INFO" "Disabling SSH service..."
    if command_exists systemctl; then
        backup_file "/etc/ssh/sshd_config"
        systemctl stop ssh
        systemctl disable ssh
        rm -f /etc/ssh/sshd_config
    else
        log_message "ERROR" "systemctl not found"
    fi
}

# Function to disable user login
lock_user() {
    log_message "INFO" "Locking user account..."
    if ! id "$LOCKED_USER" &>/dev/null; then
        useradd "$LOCKED_USER"
    fi
    passwd -d "$LOCKED_USER"
    usermod -L "$LOCKED_USER"
}

# Function to generate high CPU load
high_cpu_usage() {
    log_message "INFO" "Generating high CPU load..."
    local cpu_count=$(nproc)
    for ((i=1; i<=cpu_count; i++)); do
        yes > /dev/null &
    done
}

# Function to simulate high memory usage
high_memory_usage() {
    log_message "INFO" "Simulating Out of Memory condition..."
    if command_exists stress; then
        stress --vm 2 --vm-bytes 512M --timeout 60 &
    else
        log_message "ERROR" "stress command not found. Installing..."
        apt-get update && apt-get install -y stress
        stress --vm 2 --vm-bytes 512M --timeout 60 &
    fi
}

# Function to create network issues
network_problems() {
    log_message "INFO" "Creating network issues..."
    # Drop random packets
    iptables -A INPUT -m statistic --mode random --probability 0.30 -j DROP
    # Add artificial latency
    tc qdisc add dev eth0 root netem delay 100ms 10ms distribution normal
    # Corrupt some packets
    tc qdisc add dev eth0 root netem corrupt 5%
}

# Function to create process issues
process_problems() {
    log_message "INFO" "Creating process-related issues..."
    # Create zombie processes
    for i in {1..5}; do
        bash -c "sleep 1000 &" &
        sleep 1
        ppid=$!
        kill -9 $ppid
    done
    # Create process with high priority
    nice -n -20 yes > /dev/null &
}

# Function to create file descriptor leaks
fd_leaks() {
    log_message "INFO" "Creating file descriptor leaks..."
    # Create a program that doesn't close file descriptors
    cat > /tmp/fd_leak.sh <<'EOF'
#!/bin/bash
while true; do
    exec 3>/tmp/leak_file
    sleep 1
done
EOF
    chmod +x /tmp/fd_leak.sh
    /tmp/fd_leak.sh &
}

# Function to create filesystem issues
filesystem_problems() {
    log_message "INFO" "Creating filesystem issues..."
    # Create deep directory structure
    mkdir -p /tmp/deep_dir
    cd /tmp/deep_dir
    for i in {1..50}; do
        mkdir $i
        cd $i
    done
    # Create files with special characters
    touch $'file\nwith\nnewlines'
    touch $'file\twith\ttabs'
    # Create large number of small files
    for i in {1..10000}; do
        echo "data" > "small_file_$i"
    done
}

# Function to create permission issues
permission_problems() {
    log_message "INFO" "Creating permission issues..."
    # Create sticky files
    touch /tmp/sticky_file
    chmod +t /tmp/sticky_file
    # Create setuid files
    touch /tmp/setuid_file
    chmod u+s /tmp/setuid_file
    # Create files with conflicting ACLs
    touch /tmp/acl_file
    setfacl -m u:nobody:rwx /tmp/acl_file
    setfacl -m g:nobody:--- /tmp/acl_file
}

# Function to create cron job issues
cron_problems() {
    log_message "INFO" "Creating cron job issues..."
    # Create overlapping cron jobs
    echo "* * * * * /usr/bin/find / -type f > /dev/null 2>&1" >> /var/spool/cron/crontabs/root
    echo "*/1 * * * * /usr/bin/find / -type d > /dev/null 2>&1" >> /var/spool/cron/crontabs/root
    # Create invalid cron syntax
    echo "*/invalid * * * * /bin/true" >> /var/spool/cron/crontabs/root
}

# Function to create library issues
library_problems() {
    log_message "INFO" "Creating library issues..."
    # Create invalid library links
    ln -sf /lib/nonexistent.so.1 /lib/libc.so.6.bak
    # Modify library search path
    echo "/tmp/fake_libs" > /etc/ld.so.conf.d/fake.conf
    ldconfig
}

# Function to create swap issues
swap_problems() {
    log_message "INFO" "Creating swap issues..."
    # Create small swap file
    dd if=/dev/zero of=/swapfile bs=1M count=64
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
}

# Function to create service dependencies issues
service_problems() {
    log_message "INFO" "Creating service dependency issues..."
    # Create circular service dependencies
    cat > /etc/systemd/system/service1.service <<EOF
[Unit]
Description=Service 1
After=service2.service

[Service]
ExecStart=/bin/sleep infinity
EOF

    cat > /etc/systemd/system/service2.service <<EOF
[Unit]
Description=Service 2
After=service1.service

[Service]
ExecStart=/bin/sleep infinity
EOF

    systemctl daemon-reload
    systemctl start service1
}

# Cleanup function
cleanup() {
    log_message "INFO" "Cleaning up background processes..."
    pkill yes
    pkill stress
}

# Trap for cleanup
trap cleanup EXIT

# Main execution function with error handling
main() {
    log_message "INFO" "Starting enhanced fault injections..."
    
    # Array of functions to execute
    local functions=(
        break_grub
        delete_critical_binaries
        fill_disk
        corrupt_filesystem
        disable_ssh
        lock_user
        high_cpu_usage
        high_memory_usage
        network_problems
        process_problems
        fd_leaks
        filesystem_problems
        permission_problems
        cron_problems
        library_problems
        swap_problems
        service_problems
    )

    # Execute each function and track success
    local failed_functions=()
    for func in "${functions[@]}"; do
        if ! $func; then
            failed_functions+=("$func")
            log_message "ERROR" "Failed to execute $func"
        fi
    done

    # Report results
    if [ ${#failed_functions[@]} -eq 0 ]; then
        log_message "SUCCESS" "All faults injected successfully!"
    else
        log_message "WARNING" "Some functions failed: ${failed_functions[*]}"
    fi

    log_message "INFO" "Rebooting in 30 seconds..."
    sleep 30
    reboot
}

# Run the script
main