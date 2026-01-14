#!/bin/bash
###############################################################################
# BitcoinPurple Core - Build All Platforms Script
# Builds binaries for Linux x86_64, Windows x64, and Linux ARM64
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Track build status
BUILD_STATUS=()
START_TIME=$(date +%s)

# Function to build a platform
build_platform() {
    local platform=$1
    local platform_name=$2

    log_step "Building $platform_name..."

    local platform_start=$(date +%s)

    if cd "$SCRIPT_DIR/$platform" && ./build.sh "$@"; then
        local platform_end=$(date +%s)
        local platform_duration=$((platform_end - platform_start))
        BUILD_STATUS+=("✓ $platform_name (${platform_duration}s)")
        log_info "$platform_name build completed in ${platform_duration}s"
        cd "$SCRIPT_DIR"
        return 0
    else
        local platform_end=$(date +%s)
        local platform_duration=$((platform_end - platform_start))
        BUILD_STATUS+=("✗ $platform_name FAILED (${platform_duration}s)")
        log_error "$platform_name build failed after ${platform_duration}s"
        cd "$SCRIPT_DIR"
        return 1
    fi
}

# Main
log_step "BitcoinPurple Core - Building All Platforms"
log_info "This will build binaries for:"
echo "  1. Linux x86_64"
echo "  2. Windows x64"
echo "  3. Linux ARM64/AARCH64"
echo "  4. Linux ARMv7 (32-bit ARM)"
echo ""
log_warn "This process may take 2-3 hours depending on your hardware"
echo ""

# Parse arguments
EXTRA_ARGS=""
BUILD_COMMIT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            EXTRA_ARGS="--no-cache"
            log_warn "Building without cache (will take longer)"
            shift
            ;;
        BUILD_COMMIT=*)
            BUILD_COMMIT="${1#*=}"
            EXTRA_ARGS="$EXTRA_ARGS BUILD_COMMIT=$BUILD_COMMIT"
            log_info "Building commit: $BUILD_COMMIT"
            shift
            ;;
        *)
            log_error "Unknown argument: $1"
            echo "Usage: $0 [--no-cache] [BUILD_COMMIT=<commit-hash>]"
            exit 1
            ;;
    esac
done

# Ask for confirmation
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Build cancelled"
    exit 0
fi

# Build all platforms
FAILED=0

build_platform "linux-x86_64" "Linux x86_64" $EXTRA_ARGS || FAILED=1
build_platform "windows-x64" "Windows x64" $EXTRA_ARGS || FAILED=1
build_platform "linux-aarch64" "Linux ARM64" $EXTRA_ARGS || FAILED=1
build_platform "linux-armv7" "Linux ARMv7" $EXTRA_ARGS || FAILED=1

# Calculate total time
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
HOURS=$((TOTAL_DURATION / 3600))
MINUTES=$(((TOTAL_DURATION % 3600) / 60))
SECONDS=$((TOTAL_DURATION % 60))

# Print summary
echo ""
log_step "Build Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for status in "${BUILD_STATUS[@]}"; do
    echo "  $status"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "Total time: "
if [ $HOURS -gt 0 ]; then
    printf "%dh " $HOURS
fi
if [ $MINUTES -gt 0 ]; then
    printf "%dm " $MINUTES
fi
printf "%ds\n" $SECONDS
echo ""

if [ $FAILED -eq 0 ]; then
    log_step "All builds completed successfully!"
    log_info "Binaries are in: $PROJECT_ROOT/build-output/"
    echo ""
    log_info "Directory structure:"
    tree -L 2 "$PROJECT_ROOT/build-output/" 2>/dev/null || ls -lR "$PROJECT_ROOT/build-output/"
    echo ""
    log_info "To create release checksums:"
    echo "  cd $PROJECT_ROOT/build-output"
    echo "  sha256sum */*.tar.gz */*.zip > SHA256SUMS.txt"
    exit 0
else
    log_error "Some builds failed. Check the output above for details."
    exit 1
fi
