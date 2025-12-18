#!/usr/bin/env bash
#
# 03_install_youtube.sh - Install YouTube TV and YouTube Kids launchers
#
# This script installs YouTube application launchers.
#
# Usage: ./scripts/03_install_youtube.sh
#
# Note: This script is idempotent and safe to re-run.

set -euo pipefail

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Get the repository root directory
REPO_ROOT="$(get_repo_root)"
FILES_DIR="${REPO_ROOT}/files/desktop"
USER_HOME="${HOME}"
TARGET_USER="${USER:-pi}"

# Ensure directories exist
ensure_directories() {
    local local_apps_dir="${USER_HOME}/.local/share/applications"
    local desktop_dir="${USER_HOME}/Desktop"
    
    log_info "Ensuring required directories exist..."
    
    mkdir -p "$local_apps_dir"
    mkdir -p "$desktop_dir"
    
    log_success "Directories ready"
}

# Install a single .desktop file
install_desktop_file() {
    local source_file="$1"
    local filename=$(basename "$source_file")
    local local_apps_dir="${USER_HOME}/.local/share/applications"
    local target_file="${local_apps_dir}/${filename}"
    
    log_info "Installing ${filename}..."
    log_info "  Source: ${source_file}"
    log_info "  Target: ${target_file}"
    
    # Copy the file (overwrite if exists)
    if cp "$source_file" "$target_file"; then
        chmod 644 "$target_file"
        log_success "Installed ${filename}"
    else
        log_error "Failed to copy ${filename}"
        return 1
    fi
}

# Install YouTube launchers
install_youtube_launchers() {
    log_info "Looking for YouTube launchers in ${FILES_DIR}..."
    
    # Debug: list all files in the directory
    log_info "Files in ${FILES_DIR}:"
    ls -la "${FILES_DIR}" || log_warning "Could not list directory"
    
    local installed_count=0
    local youtube_files=("youtube-tv.desktop" "youtube-kids.desktop")
    local all_found=true
    
    for filename in "${youtube_files[@]}"; do
        local source_file="${FILES_DIR}/${filename}"
        log_info "Checking for ${filename}..."
        
        if [[ -f "$source_file" ]]; then
            log_success "Found ${filename}"
            if install_desktop_file "$source_file"; then
                ((installed_count++))
            else
                log_error "Failed to install ${filename}"
                all_found=false
            fi
        else
            log_error "${filename} not found at ${source_file}"
            all_found=false
        fi
    done
    
    if [[ "$all_found" == false ]]; then
        log_error "Missing required YouTube launcher files"
        return 1
    fi
    
    log_success "Installed ${installed_count} YouTube launcher(s)"
}

# Update desktop database
update_desktop_database() {
    log_info "Updating desktop database..."
    
    if command_exists update-desktop-database; then
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
    
    if command_exists chromium; then
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
    log_success "YouTube launchers installed!"
    echo "=================================================="
    echo ""
    log_info "Installed applications:"
    log_info "  - YouTube TV (Smart TV interface)"
    log_info "  - YouTube Kids"
    echo ""
    log_info "Applications are available in:"
    log_info "  - Application menu (under 'AudioVideo')"
    log_info "  - ~/.local/share/applications/"
    echo ""
    log_info "To launch:"
    log_info "  - From GUI: Find apps in your application menu"
    log_info "  - From terminal: gtk-launch youtube-tv.desktop"
    echo ""
}

# Main execution
main() {
    log_info "Starting YouTube launcher installation..."
    log_info "Repository root: ${REPO_ROOT}"
    log_info "Files directory: ${FILES_DIR}"
    log_info "User home: ${USER_HOME}"
    echo ""
    
    # Verify prerequisites
    if ! verify_chromium; then
        log_error "Prerequisites not met. Run 01_bootstrap_pi.sh first."
        exit 1
    fi
    
    # Install YouTube launchers
    ensure_directories
    install_youtube_launchers
    update_desktop_database
    
    print_summary
}

# Run main function
main "$@"
