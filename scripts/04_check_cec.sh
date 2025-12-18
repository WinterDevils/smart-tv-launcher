#!/usr/bin/env bash
#
# cec_diagnostics.sh - HDMI CEC diagnostic and testing tool
#
# This script helps diagnose and test HDMI CEC functionality.
# Useful for troubleshooting TV control issues.
#
# Usage: ./scripts/cec_diagnostics.sh
#
# Note: Requires cec-utils package (installed by bootstrap_pi.sh)

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

# Check if cec-client is available
check_cec_client() {
    if ! command -v cec-client &> /dev/null; then
        log_error "cec-client not found!"
        log_error "Please run bootstrap_pi.sh to install cec-utils"
        exit 1
    fi
    log_success "cec-client is installed"
}

# Scan CEC devices
scan_devices() {
    log_info "Scanning for CEC devices..."
    echo ""
    
    # Use echo to send scan command to cec-client
    echo "scan" | cec-client -s -d 1 2>&1 | grep -E "device|address|vendor|osd name" || log_warning "No devices found or scan failed"
    
    echo ""
}

# Check Raspberry Pi CEC status
check_rpi_cec() {
    log_info "Checking Raspberry Pi CEC configuration..."
    
    # Check if hdmi_ignore_cec is set in config.txt
    if [[ -f /boot/config.txt ]]; then
        if grep -q "^hdmi_ignore_cec=1" /boot/config.txt; then
            log_warning "CEC is DISABLED in /boot/config.txt (hdmi_ignore_cec=1)"
            log_info "To enable CEC, remove or comment out this line and reboot"
        else
            log_success "CEC is not disabled in /boot/config.txt"
        fi
    elif [[ -f /boot/firmware/config.txt ]]; then
        if grep -q "^hdmi_ignore_cec=1" /boot/firmware/config.txt; then
            log_warning "CEC is DISABLED in /boot/firmware/config.txt (hdmi_ignore_cec=1)"
            log_info "To enable CEC, remove or comment out this line and reboot"
        else
            log_success "CEC is not disabled in /boot/firmware/config.txt"
        fi
    fi
    echo ""
}

# Test TV power command
test_tv_power() {
    log_info "Testing TV power toggle capability..."
    log_warning "This will attempt to turn your TV on/off - are you ready?"
    log_info "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
    sleep 5
    
    log_info "Sending power toggle command..."
    echo "pow 0" | cec-client -s -d 1
    
    echo ""
    log_info "Did your TV respond? If not, CEC may not be working properly."
    echo ""
}

# Show CEC addresses
show_addresses() {
    log_info "CEC Device Addresses:"
    echo ""
    echo "  0: TV"
    echo "  1: Recording Device 1"
    echo "  2: Recording Device 2"
    echo "  3: Tuner 1"
    echo "  4: Playback Device 1 (usually Raspberry Pi)"
    echo "  5: Audio System"
    echo "  6: Tuner 2"
    echo "  7: Tuner 3"
    echo "  8: Playback Device 2"
    echo "  9: Recording Device 3"
    echo "  10: Tuner 4"
    echo "  11: Playback Device 3"
    echo "  12: Reserved"
    echo "  13: Reserved"
    echo "  14: Free use"
    echo "  15: Unregistered/Broadcast"
    echo ""
}

# Interactive CEC commands
interactive_mode() {
    log_info "Starting interactive CEC mode..."
    log_info "Useful commands:"
    echo "  scan               - Scan for devices"
    echo "  pow 0              - Toggle TV power"
    echo "  on 0               - Turn TV on"
    echo "  standby 0          - Turn TV off"
    echo "  as                 - Set Raspberry Pi as active source"
    echo "  quit               - Exit"
    echo ""
    
    cec-client
}

# Print usage
print_usage() {
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  scan       - Scan for CEC devices (default)"
    echo "  test       - Test TV power toggle"
    echo "  interactive - Start interactive CEC mode"
    echo "  addresses  - Show CEC address reference"
    echo "  help       - Show this help message"
    echo ""
}

# Print summary
print_summary() {
    echo "=================================================="
    log_info "CEC Diagnostic Information"
    echo "=================================================="
    echo ""
    log_info "Troubleshooting tips:"
    echo "  - Ensure HDMI cable is properly connected"
    echo "  - Check TV settings for CEC (may be called Anynet+, Bravia Sync, etc.)"
    echo "  - Try a different HDMI port on the TV"
    echo "  - Verify CEC is not disabled in /boot/config.txt"
    echo ""
    log_info "For more control, run: $0 interactive"
    echo ""
}

# Main execution
main() {
    local mode="${1:-scan}"
    
    echo "=================================================="
    log_info "Smart TV CEC Diagnostics"
    echo "=================================================="
    echo ""
    
    check_cec_client
    
    case "$mode" in
        scan)
            check_rpi_cec
            scan_devices
            print_summary
            ;;
        test)
            test_tv_power
            ;;
        interactive)
            interactive_mode
            ;;
        addresses)
            show_addresses
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            log_error "Unknown option: $mode"
            print_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
