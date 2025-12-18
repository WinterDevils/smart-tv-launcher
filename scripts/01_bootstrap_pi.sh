#!/usr/bin/env bash
#
# bootstrap_pi.sh - System bootstrap script for Raspberry Pi Smart TV setup
#
# This script prepares a fresh Raspberry Pi OS Bookworm installation by:
# - Updating system packages
# - Installing essential software (Chromium, CEC utils, etc.)
# - Updating certificates and firmware
#
# Usage: sudo ./scripts/bootstrap_pi.sh
#
# Note: This script is idempotent and safe to re-run.

set -euo pipefail

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Update system packages
update_system() {
    log_info "Updating package lists..."
    if apt update; then
        log_success "Package lists updated"
    else
        log_error "Failed to update package lists"
        return 1
    fi

    log_info "Upgrading installed packages (this may take a while)..."
    if apt upgrade -y; then
        log_success "System packages upgraded"
    else
        log_warning "Some packages failed to upgrade"
        return 1
    fi
}

# Install essential packages
install_packages() {
    local packages=(
        "chromium"
        "cec-utils"
        "ca-certificates"
        "network-manager"
        "git"
        "curl"
        "wget"
        "unclutter"  # Hide mouse cursor for TV experience
        "xdotool"    # Useful for automation
    )

    log_info "Installing essential packages..."
    
    local to_install=()
    local already_installed=()

    for pkg in "${packages[@]}"; do
        if is_package_installed "$pkg"; then
            already_installed+=("$pkg")
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#already_installed[@]} -gt 0 ]]; then
        log_info "Already installed: ${already_installed[*]}"
    fi

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing: ${to_install[*]}"
        if apt install -y "${to_install[@]}"; then
            log_success "Packages installed successfully"
        else
            log_error "Failed to install some packages"
            return 1
        fi
    else
        log_success "All required packages are already installed"
    fi
}

# Update CA certificates
update_certificates() {
    log_info "Updating CA certificates..."
    if update-ca-certificates; then
        log_success "CA certificates updated"
    else
        log_warning "Failed to update CA certificates"
        return 1
    fi
}

# Update Raspberry Pi firmware/EEPROM
update_firmware() {
    log_info "Checking for firmware updates..."
    
    if ! command -v rpi-eeprom-update &> /dev/null; then
        log_warning "rpi-eeprom-update not found, skipping firmware update"
        return 0
    fi

    # Check if updates are available
    local update_output
    update_output=$(rpi-eeprom-update 2>&1 || true)
    
    if echo "$update_output" | grep -qi "update available"; then
        log_info "Firmware update available, applying..."
        if rpi-eeprom-update -a; then
            log_success "Firmware updated (reboot required to apply)"
            return 2  # Special return code to indicate reboot needed
        else
            log_warning "Failed to apply firmware update"
            return 1
        fi
    else
        log_success "Firmware is up to date"
        return 0
    fi
}

# Clean up unnecessary packages
cleanup_system() {
    log_info "Cleaning up unnecessary packages..."
    if apt autoremove -y && apt clean; then
        log_success "System cleanup completed"
    else
        log_warning "Cleanup had some issues (non-critical)"
    fi
}

# Print summary
print_summary() {
    local reboot_needed=$1
    
    echo ""
    echo "=================================================="
    log_success "Bootstrap completed successfully!"
    echo "=================================================="
    echo ""
    log_info "Summary:"
    log_info "  - System packages: Updated"
    log_info "  - Essential software: Installed"
    log_info "  - CA certificates: Updated"
    
    if [[ $reboot_needed -eq 1 ]]; then
        echo ""
        log_warning "REBOOT REQUIRED to complete firmware update"
        log_warning "Run: sudo reboot"
    fi
    
    echo ""
    log_info "Next steps:"
    log_info "  1. Run: ./scripts/install_apps.sh"
    log_info "  2. Configure your apps and launcher"
    echo ""
}

# Main execution
main() {
    log_info "Starting Raspberry Pi Smart TV bootstrap..."
    echo ""
    
    check_root
    
    local reboot_needed=0
    local errors=0
    
    # Execute bootstrap steps
    update_system || ((errors++))
    install_packages || ((errors++))
    update_certificates || ((errors++))
    
    # Check firmware (special handling for reboot requirement)
    update_firmware
    local fw_status=$?
    if [[ $fw_status -eq 2 ]]; then
        reboot_needed=1
    elif [[ $fw_status -eq 1 ]]; then
        ((errors++))
    fi
    
    cleanup_system  # Non-critical, don't count errors
    
    echo ""
    if [[ $errors -gt 0 ]]; then
        log_warning "Bootstrap completed with $errors error(s)"
        log_info "You may need to investigate and re-run this script"
    fi
    
    print_summary $reboot_needed
}

# Run main function
main "$@"
