#!/bin/bash

LOG_FILE="test_setup.log"

# Logging function
log_test() {
    local status="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message" | tee -a "$LOG_FILE"
}

# Test VirtualBox installation
test_virtualbox() {
    log_test "TEST" "Checking VirtualBox installation..."
    
    if ! command -v VBoxManage &> /dev/null; then
        log_test "FAIL" "VirtualBox is not installed"
        return 1
    fi
    
    local version=$(VBoxManage --version)
    log_test "PASS" "VirtualBox version $version found"
    return 0
}

# Test script permissions
test_permissions() {
    log_test "TEST" "Checking script permissions..."
    
    local scripts=("createfaultyvm.sh" "faults.sh")
    local all_executable=true
    
    for script in "${scripts[@]}"; do
        if [ ! -x "$script" ]; then
            log_test "FAIL" "$script is not executable"
            all_executable=false
            chmod +x "$script"
            log_test "INFO" "Fixed permissions for $script"
        fi
    done
    
    if [ "$all_executable" = true ]; then
        log_test "PASS" "All scripts have correct permissions"
        return 0
    fi
    return 1
}

# Test disk space
test_disk_space() {
    log_test "TEST" "Checking available disk space..."
    
    local required_space=$((25*1024*1024)) # 25GB in KB
    local available_space=$(df -k . | awk 'NR==2 {print $4}')
    
    if [ $available_space -lt $required_space ]; then
        log_test "FAIL" "Insufficient disk space. Need 25GB, have $((available_space/1024/1024))GB"
        return 1
    fi
    
    log_test "PASS" "Sufficient disk space available: $((available_space/1024/1024))GB"
    return 0
}

# Test Ubuntu ISO
test_iso() {
    log_test "TEST" "Checking Ubuntu ISO..."
    
    local iso_path="/home/ubuntu/Downloads/ubuntu-22.04.1-desktop-amd64.iso"
    
    if [ ! -f "$iso_path" ]; then
        log_test "FAIL" "Ubuntu ISO not found at $iso_path"
        log_test "INFO" "Please download Ubuntu ISO from https://ubuntu.com/download/desktop"
        return 1
    fi
    
    log_test "PASS" "Ubuntu ISO found"
    return 0
}

# Test network connectivity
test_network() {
    log_test "TEST" "Checking network connectivity..."
    
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_test "FAIL" "No internet connectivity"
        return 1
    fi
    
    log_test "PASS" "Network connectivity verified"
    return 0
}

# Test script syntax
test_script_syntax() {
    log_test "TEST" "Checking script syntax..."
    
    local scripts=("createfaultyvm.sh" "faults.sh")
    local syntax_ok=true
    
    for script in "${scripts[@]}"; do
        if ! bash -n "$script"; then
            log_test "FAIL" "Syntax error in $script"
            syntax_ok=false
        fi
    done
    
    if [ "$syntax_ok" = true ]; then
        log_test "PASS" "All scripts have valid syntax"
        return 0
    fi
    return 1
}

# Test sudo access
test_sudo() {
    log_test "TEST" "Checking sudo access..."
    
    if ! sudo -n true 2>/dev/null; then
        log_test "FAIL" "No sudo access or requires password"
        return 1
    fi
    
    log_test "PASS" "Sudo access verified"
    return 0
}

# Run all tests
main() {
    log_test "INFO" "Starting test suite..."
    
    local tests=(
        test_virtualbox
        test_permissions
        test_disk_space
        test_iso
        test_network
        test_script_syntax
        test_sudo
    )
    
    local failed_tests=0
    
    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done
    
    echo "----------------------------------------"
    if [ $failed_tests -eq 0 ]; then
        log_test "SUCCESS" "All tests passed! You can proceed with VM creation."
    else
        log_test "WARNING" "$failed_tests test(s) failed. Please fix the issues before proceeding."
    fi
    
    return $failed_tests
}

# Run main function
main 