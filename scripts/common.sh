#!/usr/bin/env bash
#
# common.sh - Shared functions for Smart TV Launcher scripts
#
# This library provides common functionality used across multiple scripts.
# Source this file at the beginning of other scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

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

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if package is installed
is_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Get repository root directory
get_repo_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    echo "$(cd "${script_dir}/.." && pwd)"
}
