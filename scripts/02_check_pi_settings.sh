#!/usr/bin/env bash
#
# 02_check_pi_settings.sh - Raspberry Pi diagnostic and verification tool
#
# This script checks network connectivity and HDMI CEC functionality.
# Run this after bootstrap to verify the Pi is properly configured.
#
# Usage: ./scripts/02_check_pi_settings.sh

set -euo pipefail

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# AUDIO CHECKS
# ============================================================================

# Check audio output
check_audio() {
    log_info "Checking audio configuration..."
    
    # Check if audio device exists
    if ! command_exists aplay; then
        log_error "aplay command not found"
        return 1
    fi
    
    # List audio devices
    log_info "Available audio devices:"
    aplay -l 2>/dev/null || log_warning "Could not list audio devices"
    echo ""
    
    # Check current audio output
    if command_exists amixer; then
        log_info "Checking audio output routing..."
        local output=$(amixer cget numid=3 2>/dev/null | grep ": values=" | cut -d= -f2)
        
        local needs_change=false
        case "$output" in
            0) 
                log_warning "Audio output: Auto (may not use HDMI)"
                needs_change=true
                ;;
            1) 
                log_warning "Audio output: Analog (3.5mm jack) - should be HDMI for TV"
                needs_change=true
                ;;
            2) 
                log_success "Audio output: HDMI"
                ;;
            *) 
                log_warning "Audio output: Unknown ($output)"
                needs_change=true
                ;;
        esac
        
        # Auto-switch to HDMI if not already set
        if [[ "$needs_change" == true ]]; then
            log_info "Switching audio output to HDMI..."
            if amixer cset numid=3 2 &>/dev/null; then
                log_success "Audio output switched to HDMI"
            else
                log_error "Failed to switch audio output to HDMI"
                log_info "Try manually: raspi-config > System Options > Audio > Select HDMI"
                return 1
            fi
        fi
        
        # Check volume level
        local volume=$(amixer get PCM 2>/dev/null | grep -oP '\[\d+%\]' | head -1 | tr -d '[]%')
        if [[ -n "$volume" ]]; then
            if [[ $volume -eq 0 ]]; then
                log_error "Volume is muted (0%)"
            elif [[ $volume -lt 20 ]]; then
                log_warning "Volume is very low ($volume%)"
            else
                log_success "Volume level: $volume%"
            fi
        fi
    else
        log_warning "amixer not found, cannot check volume"
    fi
    
    echo ""
    
    # Test audio playback
    log_info "Testing audio playback..."
    if [[ -f /usr/share/sounds/alsa/Front_Center.wav ]]; then
        log_info "Playing test sound (you should hear a voice saying 'Front Center')..."
        if aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null; then
            log_success "Audio playback test completed"
            log_info "Did you hear the test sound? If YES, audio is working correctly."
        else
            log_error "Audio playback test failed"
            log_info "Try: raspi-config > System Options > Audio > Select HDMI"
        fi
    else
        log_warning "Test sound file not found, skipping playback test"
    fi
    
    return 0
}

# ============================================================================
# NETWORK CHECKS
# ============================================================================

# Check basic connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    
    local test_hosts=(
        "8.8.8.8"           # Google DNS
        "1.1.1.1"           # Cloudflare DNS
        "www.youtube.com"
    )
    
    local success_count=0
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &> /dev/null; then
            log_success "Can reach $host"
            ((success_count++))
        else
            log_error "Cannot reach $host"
        fi
    done
    
    echo ""
    if [[ $success_count -eq ${#test_hosts[@]} ]]; then
        log_success "Internet connectivity: GOOD"
        return 0
    elif [[ $success_count -gt 0 ]]; then
        log_warning "Internet connectivity: PARTIAL"
        return 1
    else
        log_error "Internet connectivity: FAILED"
        return 2
    fi
}

# Check DNS resolution
check_dns() {
    log_info "Checking DNS resolution..."
    
    local test_domains=(
        "www.youtube.com"
        "www.google.com"
    )
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" &> /dev/null; then
            log_success "DNS resolution for $domain: OK"
        else
            log_error "DNS resolution failed for $domain"
        fi
    done
    echo ""
}

# Check network interfaces
check_interfaces() {
    log_info "Network interfaces:"
    
    if command_exists ip; then
        ip addr show | grep -E "^[0-9]+:|inet " | while read -r line; do
            echo "  $line"
        done
    else
        ifconfig | grep -E "^[a-z]|inet "
    fi
    echo ""
}

# ============================================================================
# CEC CHECKS
# ============================================================================

# Check if cec-client is available
check_cec_client() {
    log_info "Checking for CEC tools..."
    
    if ! command_exists cec-client; then
        log_error "cec-client not found!"
        log_error "Please run 01_bootstrap_pi.sh to install cec-utils"
        return 1
    fi
    log_success "cec-client is installed"
    return 0
}

# Check Raspberry Pi CEC configuration
check_rpi_cec_config() {
    log_info "Checking Raspberry Pi CEC configuration..."
    
    # Check if hdmi_ignore_cec is set in config.txt
    if [[ -f /boot/config.txt ]]; then
        if grep -q "^hdmi_ignore_cec=1" /boot/config.txt; then
            log_warning "CEC is DISABLED in /boot/config.txt (hdmi_ignore_cec=1)"
            log_info "To enable CEC, remove or comment out this line and reboot"
            return 1
        else
            log_success "CEC is not disabled in /boot/config.txt"
        fi
    elif [[ -f /boot/firmware/config.txt ]]; then
        if grep -q "^hdmi_ignore_cec=1" /boot/firmware/config.txt; then
            log_warning "CEC is DISABLED in /boot/firmware/config.txt (hdmi_ignore_cec=1)"
            log_info "To enable CEC, remove or comment out this line and reboot"
            return 1
        else
            log_success "CEC is not disabled in /boot/firmware/config.txt"
        fi
    fi
    echo ""
    return 0
}

# Scan for CEC devices
scan_cec_devices() {
    log_info "Scanning for CEC devices..."
    echo ""
    
    # Use echo to send scan command to cec-client
    local scan_output
    scan_output=$(echo "scan" | cec-client -s -d 1 2>&1)
    
    if echo "$scan_output" | grep -qi "device"; then
        echo "$scan_output" | grep -E "device|address|vendor|osd name"
        echo ""
        log_success "CEC devices detected"
    else
        log_warning "No CEC devices found (may be normal if TV doesn't support CEC)"
    fi
    
    echo ""
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

# Check Chromium installation
check_chromium() {
    log_info "Checking Chromium installation..."
    
    if command_exists chromium; then
        local version=$(chromium --version 2>/dev/null || echo "unknown")
        log_success "Chromium: $version"
        return 0
    else
        log_error "Chromium not found! Please run 01_bootstrap_pi.sh"
        return 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

print_header() {
    echo "=================================================="
    log_info "Raspberry Pi Settings Check"
    echo "=================================================="
    echo ""
}

print_summary() {
    local errors=$1
    
    echo ""
    echo "=================================================="
    log_info "Summary"
    echo "=================================================="
    echo ""
    
    if [[ $errors -eq 0 ]]; then
        log_success "All checks passed! Your Pi is ready."
        echo ""
        log_info "Next step: Run ./scripts/03_install_apps.sh"
    else
        log_warning "$errors check(s) failed or need attention"
        echo ""
        log_info "Common issues:"
        log_info "  - No internet: Check WiFi/Ethernet connection"
        log_info "  - No sound: Use raspi-config to set audio output to HDMI"
        log_info "  - CEC not working: Verify TV settings and HDMI cable"
        log_info "  - Missing packages: Re-run 01_bootstrap_pi.sh"
    fi
    echo ""
}

main() {
    print_header
    
    local errors=0
    
    # System checks
    log_info "=== System Configuration ==="
    echo ""
    check_chromium || ((errors++))
    echo ""
    
    # Audio checks
    log_info "=== Audio Configuration ==="
    echo ""
    check_audio || ((errors++))
    echo ""
    
    # Network checks
    log_info "=== Network Connectivity ==="
    echo ""
    check_interfaces
    check_internet || ((errors++))
    check_dns || ((errors++))
    
    # CEC checks
    log_info "=== HDMI CEC Configuration ==="
    echo ""
    if check_cec_client; then
        check_rpi_cec_config || ((errors++))
        scan_cec_devices  # Don't count as error
    else
        ((errors++))
    fi
    
    print_summary $errors
    
    exit $errors
}

# Run main function
main "$@"
