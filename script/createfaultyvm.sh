#!/bin/bash

# Variables
VM_NAME="FaultyLabVM"
VM_DISK="FaultyLabVM.vdi"
VM_RAM="2048"
VM_CPUS="2"
VM_OS_TYPE="Ubuntu_64"
VM_ISO_PATH="/home/ubuntu/Downloads/ubuntu-22.04.1-desktop-amd64.iso" # Update this path with your Ubuntu ISO file
VM_SNAPSHOT="FaultyBaseline"

# Function to check if VBoxManage is installed
check_vboxmanage() {
    if ! command -v VBoxManage &> /dev/null; then
        echo "[ERROR] VBoxManage is not installed. Install VirtualBox and try again."
        exit 1
    fi
}

# Step 1: Create VirtualBox VM
create_vm() {
    echo "[INFO] Creating VirtualBox VM: $VM_NAME"
    VBoxManage createvm --name "$VM_NAME" --ostype "$VM_OS_TYPE" --register
    VBoxManage modifyvm "$VM_NAME" --memory "$VM_RAM" --cpus "$VM_CPUS" --nic1 nat
    VBoxManage createhd --filename "$VM_DISK" --size 20000
    VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DISK"
    VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide
    VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$VM_ISO_PATH"
    VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk
    echo "[INFO] VirtualBox VM $VM_NAME created successfully!"
}

# Step 2: Start the VM for initial installation
start_vm() {
    echo "[INFO] Starting the VM for installation..."
    VBoxManage startvm "$VM_NAME" --type gui
    echo "[INFO] Please complete the OS installation manually. Then shut down the VM."
}

# Step 3: Create a snapshot after installation
create_snapshot() {
    echo "[INFO] Taking a snapshot of the VM after installation..."
    VBoxManage snapshot "$VM_NAME" take "$VM_SNAPSHOT" --description "Baseline VM for Fault Injection"
    echo "[INFO] Snapshot $VM_SNAPSHOT created successfully!"
}

# Step 4: Inject Faults into the VM
inject_faults() {
    echo "[INFO] Injecting faults into the VM..."
    
    # Copy the fault injection script to VM
    VBoxManage guestcontrol "$VM_NAME" copyto --username ubuntu --password ubuntu \
        "script/faults.sh" "/tmp/faults.sh"
    
    # Make the script executable
    VBoxManage guestcontrol "$VM_NAME" run --username ubuntu --password ubuntu -- /bin/bash -c "chmod +x /tmp/faults.sh"
    
    # Start VM and wait for boot
    VBoxManage startvm "$VM_NAME" --type headless
    sleep 60

    # Execute the fault injection script with sudo
    VBoxManage guestcontrol "$VM_NAME" run --username ubuntu --password ubuntu -- /bin/bash -c "sudo /tmp/faults.sh"
    
    # Clean up the script
    VBoxManage guestcontrol "$VM_NAME" run --username ubuntu --password ubuntu -- /bin/bash -c "rm /tmp/faults.sh"

    VBoxManage controlvm "$VM_NAME" poweroff
    echo "[INFO] VM faults injected and powered off."
}

# Step 5: Export the Faulty VM
export_vm() {
    echo "[INFO] Exporting the faulty VM as an OVA file..."
    VBoxManage export "$VM_NAME" --output "${VM_NAME}_Faulty.ova"
    echo "[INFO] Faulty VM exported successfully to ${VM_NAME}_Faulty.ova"
}

# Main Execution
main() {
    check_vboxmanage
    create_vm
    start_vm

    echo "[INFO] Complete the installation of the OS in the VM. Then press Enter to continue."
    read -p ""

    create_snapshot
    inject_faults
    export_vm

    echo "[INFO] VM setup with faults completed successfully!"
}

main