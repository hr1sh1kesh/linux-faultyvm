#!/bin/bash

# Variables
VM_NAME="FaultyLabVM"
VM_DISK="FaultyLabVM.vdi"
VM_RAM="2048"
VM_CPUS="2"
VM_OS_TYPE="Ubuntu_64"
VM_ISO_PATH="/home/ubuntu/Downloads/ubuntu-22.04.1-desktop-amd64.iso"
VM_SNAPSHOT="FaultyBaseline"
LOG_FILE="vm_creation.log"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local command=$1
    if [ $exit_code -ne 0 ]; then
        log_message "ERROR" "Command '$command' failed with exit code $exit_code"
        exit $exit_code
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log_message "INFO" "Checking prerequisites..."
    
    # Check VBoxManage
    if ! command -v VBoxManage &> /dev/null; then
        log_message "ERROR" "VBoxManage is not installed. Install VirtualBox and try again."
        exit 1
    fi

    # Check ISO file exists
    if [ ! -f "$VM_ISO_PATH" ]; then
        log_message "ERROR" "Ubuntu ISO not found at $VM_ISO_PATH"
        exit 1
    fi

    # Check disk space
    local required_space=$((25*1024*1024)) # 25GB in KB
    local available_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ $available_space -lt $required_space ]; then
        log_message "ERROR" "Insufficient disk space. Need at least 25GB free."
        exit 1
    fi
}

# Function to create VirtualBox VM
create_vm() {
    log_message "INFO" "Creating VirtualBox VM: $VM_NAME"
    
    # Check if VM already exists
    if VBoxManage showvminfo "$VM_NAME" &>/dev/null; then
        log_message "ERROR" "VM '$VM_NAME' already exists. Please remove it first."
        exit 1
    fi


    # Create and configure VM
    VBoxManage createvm --name "$VM_NAME" --ostype "$VM_OS_TYPE" --register
    handle_error "createvm"

    VBoxManage modifyvm "$VM_NAME" \
        --memory "$VM_RAM" \
        --cpus "$VM_CPUS" \
        --nic1 nat \
        --natpf1 "guestssl,tcp,,2222,,22" \
        --vram 128 \
        --graphicscontroller vmsvga \
        --accelerate3d on \
        --audio none \
        --clipboard bidirectional
    handle_error "modifyvm"

    # Create and attach storage
    VBoxManage createhd --filename "$VM_DISK" --size 20000
    handle_error "createhd"

    VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DISK"
    VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide
    VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$VM_ISO_PATH"
    VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk

    log_message "SUCCESS" "VM created successfully!"
}

# Function to start VM and wait for installation
start_vm() {
    log_message "INFO" "Starting VM for installation..."
    VBoxManage startvm "$VM_NAME" --type gui
    
    log_message "INFO" "Please complete the Ubuntu installation with these settings:"
    echo "Username: ubuntu"
    echo "Password: ubuntu"
    echo "Hostname: faultylab"
    echo "Enable SSH server during installation"
}

# Function to create snapshot
create_snapshot() {
    log_message "INFO" "Creating baseline snapshot..."
    VBoxManage snapshot "$VM_NAME" take "$VM_SNAPSHOT" --description "Baseline VM for Fault Injection"
    handle_error "snapshot"
}

# Function to inject faults
inject_faults() {
    log_message "INFO" "Starting fault injection process..."
    
    # Wait for VM to be powered off
    while VBoxManage showvminfo "$VM_NAME" | grep -q "running"; do
        log_message "INFO" "Waiting for VM to be powered off..."
        sleep 10
    done

    # Copy and execute fault script
    VBoxManage startvm "$VM_NAME" --type headless
    sleep 60  # Wait for boot

    # Retry mechanism for guest control
    local max_retries=5
    local retry_count=0
    local success=false

    while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
        if VBoxManage guestcontrol "$VM_NAME" copyto --username ubuntu --password ubuntu \
            "script/faults.sh" "/tmp/faults.sh"; then
            success=true
        else
            retry_count=$((retry_count + 1))
            log_message "WARNING" "Failed to copy script, attempt $retry_count of $max_retries"
            sleep 10
        fi
    done

    if [ "$success" = false ]; then
        log_message "ERROR" "Failed to copy fault script after $max_retries attempts"
        return 1
    fi

    # Execute fault script
    VBoxManage guestcontrol "$VM_NAME" run --username ubuntu --password ubuntu -- /bin/bash -c "chmod +x /tmp/faults.sh && sudo /tmp/faults.sh"
    handle_error "fault injection"

    log_message "SUCCESS" "Faults injected successfully"
}

# Function to export VM
export_vm() {
    log_message "INFO" "Exporting faulty VM..."
    local export_path="${VM_NAME}_Faulty.ova"
    
    VBoxManage export "$VM_NAME" --output "$export_path" --manifest --ovf20
    handle_error "export"
    
    log_message "SUCCESS" "VM exported to $export_path"
}

# Cleanup function
cleanup() {
    log_message "INFO" "Performing cleanup..."
    if [ -f "/tmp/faults.sh" ]; then
        rm -f "/tmp/faults.sh"
    fi
}

# Main execution with error handling
main() {
    trap cleanup EXIT
    
    log_message "INFO" "Starting VM creation process..."
    
    check_prerequisites
    create_vm
    start_vm

    log_message "INFO" "Waiting for installation completion..."
    read -p "Press Enter once OS installation is complete and VM is shut down..."

    create_snapshot
    inject_faults
    export_vm

    log_message "SUCCESS" "VM setup completed successfully!"
}

main
