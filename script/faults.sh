#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run this script as root!"
    exit 1
fi

# Global Variables
DISK_FILE="/bigfile"
LOCKED_USER="testuser"

# Function to create a kernel panic (CRASHES SYSTEM!)
kernel_panic() {
    echo "[INFO] Triggering a Kernel Panic..."
    echo 1 > /proc/sys/kernel/panic
    echo 1 > /proc/sys/kernel/panic_on_oops
    # Uncomment below line to **force a real crash** (Dangerous!)
    # echo c > /proc/sysrq-trigger
}

# Function to break GRUB and prevent booting
break_grub() {
    echo "[INFO] Breaking GRUB Bootloader..."
    echo "GRUB_CMDLINE_LINUX='invalid_option'" >> /etc/default/grub
    update-grub
}

# Function to remove essential system binaries
delete_critical_binaries() {
    echo "[INFO] Removing essential system utilities..."
    mv /bin/systemctl /bin/systemctl.bak
    mv /bin/sudo /bin/sudo.bak
}

# Function to fill up disk space (100% usage)
fill_disk() {
    echo "[INFO] Filling up disk space..."
    fallocate -l 10G "$DISK_FILE"
}

# Function to corrupt filesystem metadata
corrupt_filesystem() {
    echo "[INFO] Corrupting filesystem metadata..."
    umount /dev/sda1
    dd if=/dev/zero of=/dev/sda1 bs=512 count=100
}

# Function to break SSH and prevent remote access
disable_ssh() {
    echo "[INFO] Disabling SSH service..."
    systemctl stop ssh
    rm -f /etc/ssh/sshd_config
}

# Function to disable user login
lock_user() {
    echo "[INFO] Locking user account..."
    useradd "$LOCKED_USER"
    passwd -d "$LOCKED_USER"
    usermod -L "$LOCKED_USER"
}

# Function to generate high CPU load
high_cpu_usage() {
    echo "[INFO] Generating high CPU load..."
    for i in {1..4}; do yes > /dev/null & done
}

# Function to simulate high memory usage (Out of Memory)
high_memory_usage() {
    echo "[INFO] Simulating Out of Memory condition..."
    stress --vm 2 --vm-bytes 512M --timeout 60 &
}

# Function to break log rotation (logrotate)
break_logging() {
    echo "[INFO] Breaking log rotation..."
    echo "/var/log/syslog { daily rotate 5 compress invalid_option }" > /etc/logrotate.d/syslog
}

# Function to introduce slow disk performance
slow_disk_io() {
    echo "[INFO] Introducing slow disk I/O..."
    for i in {1..5}; do dd if=/dev/zero of=/tmp/disk_test bs=1M count=10000 oflag=sync & done
}

# Function to remove sudo permissions for all users
remove_sudo_permissions() {
    echo "[INFO] Removing sudo access from all users..."
    chmod 400 /usr/bin/sudo
}

# Function to disable networking
disable_networking() {
    echo "[INFO] Disabling network interface..."
    ip link set eth0 down
}

# Function to remove cron jobs
delete_cron_jobs() {
    echo "[INFO] Deleting all scheduled cron jobs..."
    rm -rf /etc/cron.*
}

# Function to break MySQL database
break_mysql() {
    echo "[INFO] Breaking MySQL database..."
    systemctl stop mysql
    mv /var/lib/mysql /var/lib/mysql.bak
}

# Function to introduce a fake disk failure
simulate_disk_failure() {
    echo "[INFO] Simulating a fake disk failure..."
    echo "1" > /sys/block/sda/device/delete
}

# Function to introduce random reboots
random_reboots() {
    echo "[INFO] Scheduling random system reboots..."
    (sleep $((RANDOM % 120)) && reboot) &
}

# Execute all fault injections
main() {
    echo "[INFO] Starting fault injections..."
    
    break_grub
    delete_critical_binaries
    fill_disk
    corrupt_filesystem
    disable_ssh
    lock_user
    high_cpu_usage
    high_memory_usage
    break_logging
    slow_disk_io
    remove_sudo_permissions
    disable_networking
    delete_cron_jobs
    break_mysql
    simulate_disk_failure
    random_reboots

    echo "[INFO] All faults injected! Rebooting in 30 seconds..."
    sleep 30
    reboot
}

# Run the script
main