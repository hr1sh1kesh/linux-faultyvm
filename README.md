# Linux Fault Injection Lab

A comprehensive testing environment that creates intentionally faulty Virtual Machines for developing advanced Linux debugging skills.

## Overview

This project helps system administrators and developers master Linux debugging by creating VMs with controlled, intentional faults. It provides hands-on experience with a wide range of system issues commonly encountered in production environments.

## Features

### Automated Fault Injection
- Kernel and Hardware Faults
  - Invalid GRUB configurations
  - Disk corruption simulation
  - Hardware resource exhaustion
- Service Disruptions
  - SSH service failures
  - Circular service dependencies
  - Configuration corruption
- Resource Management
  - Memory leaks
  - CPU load issues
  - Disk space problems
- Network Issues
  - Packet loss and corruption
  - Latency simulation
  - Connection problems
- Process Management
  - Zombie processes
  - Priority conflicts
  - Resource contention
- File System Issues
  - Deep directory structures
  - Special character handling
  - Permission conflicts
- System Monitoring
  - Log rotation issues
  - Invalid configurations
  - Monitoring disruptions

## Prerequisites

### System Requirements
- VirtualBox 6.1 or later
- 25GB+ free disk space
- 4GB+ RAM (2GB for VM)
- 2+ CPU cores
- Ubuntu Desktop ISO (22.04 LTS recommended)
- Sudo privileges
- Network connectivity

### Software Dependencies
The test script will verify these requirements:
- VirtualBox installation
- Required disk space
- Network connectivity
- Script permissions
- Sudo access
- ISO availability

## Quick Start

1. Clone this repository:

```bash
git clone https://github.com/yourusername/linux-fault-injection-lab
cd linux-fault-injection-lab
```

2. Run the test script:
```bash
./script/test_setup.sh
```

3. Create the faulty VM:
```bash
./script/createfaultyvm.sh
```

## Project Structure

```
.
├── README.md
└── script/
    ├── README.md        # Detailed script documentation
    ├── test_setup.sh    # Environment validation
    ├── createfaultyvm.sh # VM creation and management
    └── faults.sh        # Fault injection commands
```

## Debugging Skills Covered

- System log analysis
- Resource monitoring
- Network troubleshooting
- Process management
- Storage issues
- Service dependencies
- Security problems
- Performance analysis

## VM Details

- Base: Ubuntu 22.04 LTS
- RAM: 2GB
- Disk: 20GB
- CPUs: 2
- Network: NAT with SSH port forwarding (2222)
- Credentials:
  - Username: ubuntu
  - Password: ubuntu

## Safety Warning

⚠️ This project creates intentionally broken VMs. Use only in isolated test environments. Never use on production systems.

## Contributing

Contributions welcome! Areas for improvement:
- Additional fault scenarios
- Better documentation
- Testing enhancements
- Bug fixes

## License

MIT License - See LICENSE file for details.

## Acknowledgments

Thanks to the Linux and VirtualBox communities for making this project possible.

## Script Details

### test_setup.sh
Validates your environment by checking:
- VirtualBox installation
- Script permissions
- Available disk space
- Ubuntu ISO presence
- Network connectivity
- Script syntax
- Sudo access

### createfaultyvm.sh
Manages VM lifecycle:
- Creates VirtualBox VM
- Configures VM settings
- Manages VM snapshots
- Injects faults
- Exports final VM
- Provides detailed logging

### faults.sh
Injects various system faults:
- System-level faults
- Service disruptions
- Resource exhaustion
- Permission issues
- Network problems
- Process issues

## VM Configuration

### Base Settings
- OS: Ubuntu 22.04 LTS
- RAM: 2GB
- Disk: 20GB
- CPUs: 2
- Network: NAT
- Port Forwarding: Host 2222 → Guest 22 (SSH)

### Credentials
- Username: ubuntu
- Password: ubuntu
- Hostname: faultylab

## Debugging Skills Developed

1. **System Analysis**
   - Kernel log analysis
   - System resource monitoring
   - Performance troubleshooting
   - Boot process debugging

2. **Network Debugging**
   - Packet analysis
   - Network latency issues
   - Connection problems
   - DNS troubleshooting

3. **Process Management**
   - Zombie process handling
   - Resource contention
   - Priority issues
   - Service dependencies

4. **Storage Issues**
   - Filesystem corruption
   - Disk space problems
   - I/O bottlenecks
   - Inode exhaustion

5. **Service Management**
   - Dependency issues
   - Configuration problems
   - Service recovery
   - Systemd debugging

6. **Security**
   - Permission problems
   - User management
   - Access control
   - File ownership

## Troubleshooting Guide

### VM Creation Issues
- Verify VirtualBox installation
- Check available resources
- Confirm ISO path
- Review VBoxManage errors

### Fault Injection Problems
- Check sudo access
- Verify script permissions
- Review logs in /var/log/fault_injection.log
- Ensure VM network connectivity

### Network Problems
- Verify host network connectivity
- Check VirtualBox network settings
- Confirm port forwarding
- Review iptables rules

## Safety Considerations

⚠️ **Important Warnings**:
1. Use only in isolated test environments
2. Never use on production systems
3. Keep snapshots of working states
4. Backup important data
5. Some faults may require VM recreation

## Contributing

Contributions are welcome! Areas for improvement:

1. **New Features**
   - Additional fault scenarios
   - More automated tests
   - Recovery scripts
   - Documentation improvements

2. **Bug Fixes**
   - Script improvements
   - Error handling
   - VM configuration
   - Fault injection reliability

3. **Documentation**
   - Additional examples
   - Troubleshooting guides
   - Best practices
   - Use cases

## License

MIT License - See LICENSE file for details.

## Acknowledgments

- Linux community for debugging tools and documentation
- VirtualBox team for VM management capabilities
- Contributors and testers

## Support

For issues and questions:
1. Check existing GitHub issues
2. Review troubleshooting guide
3. Create detailed bug reports
4. Include script logs

## Version History

- 1.0.0: Initial release
  - Basic fault injection
  - VM automation
  - Testing framework

## Installation & Usage

1. Clone this repository:

```bash
git clone https://github.com/yourusername/linux-fault-injection-lab
cd linux-fault-injection-lab
```

2. Make scripts executable:
```
chmod +x script/*.sh
```

3. Run the test script:
```
./script/test_setup.sh
```

4. Create the faulty VM:
```
./script/createfaultyvm.sh
```