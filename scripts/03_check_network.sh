#!/usr/bin/env bash
#
# check_network.sh - Network connectivity diagnostic tool
#
# This script checks network connectivity and helps diagnose issues.
# Useful for troubleshooting streaming problems on the Smart TV.
#
# Usage: ./scripts/check_network.sh

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

# Check basic connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    
    local test_hosts=(
        "8.8.8.8"           # Google DNS
        "1.1.1.1"           # Cloudflare DNS
        "www.google.com"
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
            local ip=$(nslookup "$domain" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}')
            log_success "DNS resolution for $domain: $ip"
        else
            log_error "DNS resolution failed for $domain"
        fi
    done
    echo ""
}

# Check network interfaces
check_interfaces() {
    log_info "Network interfaces:"
    
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "^[0-9]+:|inet " | while read -r line; do
            echo "  $line"
        done
    else
        ifconfig | grep -E "^[a-z]|inet "
    fi
    echo ""
}

# Check WiFi status (if applicable)
check_wifi() {
    log_info "Checking WiFi status..."
    
    if command -v iwconfig &> /dev/null; then
        local wifi_info=$(iwconfig 2>&1 | grep -v "no wireless" || true)
        if [[ -n "$wifi_info" ]]; then
            echo "$wifi_info"
            
            # Try to get signal strength
            if command -v iwlist &> /dev/null; then
                local signal=$(iwlist scan 2>/dev/null | grep -i "signal level" | head -1 || true)
                if [[ -n "$signal" ]]; then
                    log_info "Signal: $signal"
                fi
            fi
        else
            log_info "No wireless interfaces found"
        fi
    fi
    echo ""
}

# Check network speed
check_speed() {
    log_info "Testing network speed (downloading small file)..."
    
    local test_url="http://www.google.com/robots.txt"
    local start_time=$(date +%s%N)
    
    if curl -s -o /dev/null -w "%{http_code}" "$test_url" &> /dev/null; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        log_success "Response time: ${duration}ms"
    else
        log_error "Speed test failed"
    fi
    echo ""
}

# Check streaming services
check_streaming() {
    log_info "Checking streaming service accessibility..."
    
    local services=(
        "https://www.youtube.com"
        "https://www.netflix.com"
    )
    
    for service in "${services[@]}"; do
        local name=$(echo "$service" | sed 's|https://www.||' | sed 's|/.*||')
        if curl -s -o /dev/null -w "%{http_code}" -L "$service" | grep -q "200\|302\|301"; then
            log_success "$name is accessible"
        else
            log_error "$name is not accessible"
        fi
    done
    echo ""
}

# Print network summary
print_summary() {
    echo "=================================================="
    log_info "Network Diagnostic Summary"
    echo "=================================================="
    echo ""
    log_info "Run this script if you experience streaming issues"
    log_info "If problems persist, check:"
    log_info "  - Router/modem status"
    log_info "  - WiFi signal strength"
    log_info "  - ISP connectivity"
    echo ""
}

# Main execution
main() {
    echo "=================================================="
    log_info "Smart TV Network Diagnostics"
    echo "=================================================="
    echo ""
    
    check_interfaces
    check_internet
    check_dns
    check_wifi
    check_speed
    check_streaming
    print_summary
}

# Run main function
main "$@"
