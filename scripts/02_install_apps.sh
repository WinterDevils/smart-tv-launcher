#!/usr/bin/env bash
#
# install_apps.sh - Install Smart TV application launchers
#
# This script installs .desktop files and application configurations
# from the files/ directory into the appropriate system locations.
#
# Usage: ./scripts/install_apps.sh
#
# Note: This script is idempotent and safe to re-run.

set -euo pipefail

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILES_DIR="${REPO_ROOT}/files/desktop"
USER_HOME="${HOME}"
TARGET_USER="${USER:-pi}"

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
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Ensure directories exist
ensure_directories() {
    local local_apps_dir="${USER_HOME}/.local/share/applications"
    local desktop_dir="${USER_HOME}/Desktop"
    
    log_info "Ensuring required directories exist..."
    
    mkdir -p "$local_apps_dir"
    mkdir -p "$desktop_dir"
    
    log_success "Directories ready"
}

# Backup existing file
backup_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        local backup="${file}.bak"
        local timestamp=$(date +%Y%m%d_%H%M%S)
        backup="${file}.${timestamp}.bak"
        
        log_info "Backing up existing file to: $backup"
        cp "$file" "$backup"
    fi
}

# Install a single .desktop file
install_desktop_file() {
    local source_file="$1"
    local filename=$(basename "$source_file")
    local local_apps_dir="${USER_HOME}/.local/share/applications"
    local target_file="${local_apps_dir}/${filename}"
    
    log_info "Installing ${filename}..."
    
    # Backup if exists
    if [[ -f "$target_file" ]]; then
        backup_file "$target_file"
    fi
    
    # Copy the file
    cp "$source_file" "$target_file"
    chmod 644 "$target_file"
    
    log_success "Installed ${filename}"
}

# Install all .desktop files
install_desktop_files() {
    log_info "Looking for .desktop files in ${FILES_DIR}..."
    
    local desktop_files=("${FILES_DIR}"/*.desktop)
    
    if [[ ! -e "${desktop_files[0]}" ]]; then
        log_warning "No .desktop files found in ${FILES_DIR}"
        return 0
    fi
    
    local count=0
    for desktop_file in "${desktop_files[@]}"; do
        if [[ -f "$desktop_file" ]]; then
            install_desktop_file "$desktop_file"
            ((count++))
        fi
    done
    
    log_success "Installed ${count} .desktop file(s)"
}

# Update desktop database
update_desktop_database() {
    log_info "Updating desktop database..."
    
    if command -v update-desktop-database &> /dev/null; then
        local local_apps_dir="${USER_HOME}/.local/share/applications"
        update-desktop-database "$local_apps_dir" 2>/dev/null || true
        log_success "Desktop database updated"
    else
        log_warning "update-desktop-database not found, skipping"
    fi
}

# Verify Chromium installation
verify_chromium() {
    log_info "Verifying Chromium installation..."
    
    if command -v chromium &> /dev/null; then
        local version=$(chromium --version 2>/dev/null || echo "unknown")
        log_success "Chromium found: $version"
        return 0
    else
        log_error "Chromium not found! Please run bootstrap_pi.sh first."
        return 1
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=================================================="
    log_success "Application installation completed!"
    echo "=================================================="
    echo ""
    log_info "Installed applications:"
    log_info "  - YouTube TV (Smart TV interface)"
    echo ""
    log_info "Applications are available in:"
    log_info "  - Application menu (under 'AudioVideo')"
    log_info "  - ~/.local/share/applications/"
    echo ""
    log_info "To launch YouTube TV:"
    log_info "  - From GUI: Find 'YouTube TV' in your application menu"
    log_info "  - From terminal: gtk-launch youtube-tv.desktop"
    echo ""
}

# Main execution
main() {
    log_info "Starting Smart TV application installation..."
    log_info "Repository root: ${REPO_ROOT}"
    log_info "Files directory: ${FILES_DIR}"
    log_info "User home: ${USER_HOME}"
    echo ""
    
    # Verify prerequisites
    if ! verify_chromium; then
        log_error "Prerequisites not met. Run bootstrap_pi.sh first."
        exit 1
    fi
    
    # Install applications
    ensure_directories
    install_desktop_files
    update_desktop_database
    
    print_summary
}

# Run main function
main "$@"
