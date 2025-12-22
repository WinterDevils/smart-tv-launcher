#!/usr/bin/env bash
#
# 04_setup_launcher.sh - Install Smart TV Launcher and enable autostart
#
# This script:
# - Copies all .desktop files from files/desktop/ to ~/.local/share/applications/
# - Replaces the __LAUNCHER_INDEX_HTML__ placeholder in smart-tv-launcher.desktop
# - Enables autostart for the Smart TV Launcher
#
# Usage: ./scripts/04_setup_launcher.sh
#
# Note: This script is idempotent and safe to re-run.

set -euo pipefail

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Detect repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Paths
FILES_DESKTOP="${REPO_ROOT}/files/desktop"
LAUNCHER_INDEX="${REPO_ROOT}/files/launcher/index.html"
LAUNCHER_JS="${REPO_ROOT}/files/launcher/launcher.js"
USER_HOME="${HOME}"
LOCAL_APPS="${USER_HOME}/.local/share/applications"
AUTOSTART_DIR="${USER_HOME}/.config/autostart"

# Print header
print_header() {
    echo ""
    echo "=================================================="
    log_info "Smart TV Launcher Setup"
    echo "=================================================="
    echo ""
    log_info "Repository root: ${REPO_ROOT}"
    log_info "Launcher index: ${LAUNCHER_INDEX}"
    log_info "Target directory: ${LOCAL_APPS}"
    echo ""
}

# Verify launcher files exist
verify_launcher_files() {
    log_info "Verifying launcher files..."
    
    local all_present=true
    
    if [[ ! -f "${LAUNCHER_INDEX}" ]]; then
        log_error "Launcher index.html not found: ${LAUNCHER_INDEX}"
        all_present=false
    else
        log_success "Found: index.html"
    fi
    
    if [[ ! -f "${LAUNCHER_JS}" ]]; then
        log_error "Launcher launcher.js not found: ${LAUNCHER_JS}"
        all_present=false
    else
        log_success "Found: launcher.js"
    fi
    
    if [[ ! -d "${FILES_DESKTOP}" ]]; then
        log_error "Desktop files directory not found: ${FILES_DESKTOP}"
        all_present=false
    else
        log_success "Found: files/desktop/"
    fi
    
    if [[ "$all_present" == false ]]; then
        log_error "Missing required launcher files"
        return 1
    fi
    
    echo ""
    return 0
}

# Ensure directories exist
ensure_directories() {
    log_info "Ensuring required directories exist..."
    
    mkdir -p "${LOCAL_APPS}"
    mkdir -p "${AUTOSTART_DIR}"
    
    log_success "Directories ready"
    echo ""
}

# Copy all .desktop files
copy_desktop_files() {
    log_info "Copying .desktop files..."
    
    local copied_count=0
    
    for desktop_file in "${FILES_DESKTOP}"/*.desktop; do
        if [[ -f "$desktop_file" ]]; then
            local filename=$(basename "$desktop_file")
            local target="${LOCAL_APPS}/${filename}"
            
            cp "$desktop_file" "$target"
            chmod 644 "$target"
            
            log_success "Copied: ${filename}"
            ((copied_count++))
        fi
    done
    
    if [[ $copied_count -eq 0 ]]; then
        log_error "No .desktop files found in ${FILES_DESKTOP}"
        return 1
    fi
    
    log_success "Copied ${copied_count} .desktop file(s)"
    echo ""
    return 0
}

# Replace placeholder in smart-tv-launcher.desktop
update_launcher_paths() {
    log_info "Updating Smart TV Launcher paths..."
    
    local launcher_desktop="${LOCAL_APPS}/smart-tv-launcher.desktop"
    
    if [[ ! -f "$launcher_desktop" ]]; then
        log_error "smart-tv-launcher.desktop not found in ${LOCAL_APPS}"
        return 1
    fi
    
    # Replace placeholder in .desktop file
    # Use @ as delimiter to avoid issues with forward slashes in paths
    log_info "Replacing __LAUNCHER_INDEX_HTML__ in smart-tv-launcher.desktop..."
    log_info "  Path: ${LAUNCHER_INDEX}"
    
    # Use @ as delimiter since paths contain /
    sed -i "s@__LAUNCHER_INDEX_HTML__@${LAUNCHER_INDEX}@g" "$launcher_desktop"
    
    # Verify replacement succeeded
    if grep -q "__LAUNCHER_INDEX_HTML__" "$launcher_desktop"; then
        log_error "Failed to replace placeholder in smart-tv-launcher.desktop"
        return 1
    fi
    log_success "Updated: smart-tv-launcher.desktop"
    
    # Show the actual Exec line for verification
    log_info "Exec line:"
    grep "^Exec=" "$launcher_desktop" | sed 's/^/  /'
    
    # Replace placeholder in a COPY of launcher.js (not the source)
    log_info "Copying launcher files to ${HOME}/.local/share/smart-tv-launcher/..."
    local launcher_data_dir="${HOME}/.local/share/smart-tv-launcher"
    mkdir -p "$launcher_data_dir"
    
    # Copy all launcher files
    cp "${REPO_ROOT}/files/launcher/"* "$launcher_data_dir/"
    
    # Now replace placeholder in the copied launcher.js
    local copied_launcher_js="${launcher_data_dir}/launcher.js"
    log_info "Replacing __LAUNCHER_INDEX_HTML__ in copied launcher.js..."
    sed -i "s@__LAUNCHER_INDEX_HTML__@${LAUNCHER_INDEX}@g" "$copied_launcher_js"
    
    # Verify replacement succeeded
    if grep -q "__LAUNCHER_INDEX_HTML__" "$copied_launcher_js"; then
        log_error "Failed to replace placeholder in launcher.js"
        return 1
    fi
    log_success "Updated: launcher.js (copy)"
    
    # Make desktop file executable
    chmod +x "$launcher_desktop"
    log_success "Made executable: smart-tv-launcher.desktop"
    
    echo ""
    return 0
}

# Enable autostart
enable_autostart() {
    log_info "Enabling autostart..."
    
    local launcher_desktop="${LOCAL_APPS}/smart-tv-launcher.desktop"
    local autostart_file="${AUTOSTART_DIR}/smart-tv-launcher.desktop"
    
    # Copy to autostart
    cp "$launcher_desktop" "$autostart_file"
    chmod +x "$autostart_file"
    
    log_success "Autostart enabled: ${autostart_file}"
    
    # Verify autostart file is valid
    log_info "Verifying autostart configuration..."
    if grep -q "^Exec=" "$autostart_file"; then
        log_success "Autostart Exec line present"
    else
        log_error "Autostart file is missing Exec line"
        return 1
    fi
    
    echo ""
    return 0
}

# Update desktop database
# Update desktop database
update_desktop_database() {
    log_info "Updating desktop database..."
    
    if command_exists update-desktop-database; then
        update-desktop-database "$LOCAL_APPS" 2>/dev/null || true
        log_success "Desktop database updated"
    else
        log_warning "update-desktop-database not found, skipping"
    fi
    
    echo ""
}

# Print summary
print_summary() {
    echo ""
    echo "=================================================="
    log_success "Smart TV Launcher Setup Complete!"
    echo "=================================================="
    echo ""
    log_info "Launcher configuration:"
    log_info "  - HTML file: ${LAUNCHER_INDEX}"
    log_info "  - Launcher data: ${HOME}/.local/share/smart-tv-launcher/"
    log_info "  - Desktop file: ${LOCAL_APPS}/smart-tv-launcher.desktop"
    log_info "  - Autostart: ${AUTOSTART_DIR}/smart-tv-launcher.desktop"
    echo ""
    log_info "The Smart TV Launcher will start automatically on login."
    log_info "To test manually, run:"
    log_info "  gtk-launch smart-tv-launcher.desktop"
    echo ""
    log_info "To verify autostart is enabled:"
    log_info "  ls -la ${AUTOSTART_DIR}/smart-tv-launcher.desktop"
    echo ""
    log_info "Next steps:"
    log_info "  - Log out and log back in to test autostart"
    log_info "  - Check ~/.xsession-errors if launcher doesn't start"
    echo ""
}

# Main execution
main() {
    print_header
    
    # Verify prerequisites
    if ! verify_launcher_files; then
        log_error "Prerequisites not met"
        exit 1
    fi
    
    # Setup launcher
    ensure_directories
    copy_desktop_files
    update_launcher_paths
    enable_autostart
    update_desktop_database
    
    print_summary
}

# Run main function
main "$@"
