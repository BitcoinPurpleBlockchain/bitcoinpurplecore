#!/bin/bash
###############################################################################
# BitcoinPurple Core - Linux ARM64 Docker Build Wrapper
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

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build-output/linux-aarch64"

# Parse arguments
NO_CACHE=""
BUILD_COMMIT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            NO_CACHE="--no-cache"
            log_warn "Building without cache"
            shift
            ;;
        BUILD_COMMIT=*)
            BUILD_COMMIT="${1#*=}"
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

# If BUILD_COMMIT not specified, use current HEAD
if [ -z "$BUILD_COMMIT" ]; then
    BUILD_COMMIT="HEAD"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

log_step "Building BitcoinPurple Core for Linux ARM64/AARCH64"
log_info "Project root: $PROJECT_ROOT"
log_info "Output directory: $OUTPUT_DIR"

# Build Docker image
log_step "Building Docker image..."
docker build $NO_CACHE -t bitcoinpurple-builder:linux-aarch64 -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"

# Create ccache and depends volumes if needed
if ! docker volume inspect bitcoinpurple_ccache_arm64 >/dev/null 2>&1; then
    log_info "Creating ccache volume..."
    docker volume create bitcoinpurple_ccache_arm64
fi

if ! docker volume inspect bitcoinpurple_depends_arm64 >/dev/null 2>&1; then
    log_info "Creating depends volume..."
    docker volume create bitcoinpurple_depends_arm64
fi

# Checkout specific commit if needed
if [ "$BUILD_COMMIT" != "HEAD" ]; then
    log_step "Checking out commit: $BUILD_COMMIT"
    cd "$PROJECT_ROOT"
    git checkout "$BUILD_COMMIT" || {
        log_error "Failed to checkout commit: $BUILD_COMMIT"
        exit 1
    }
    cd "$SCRIPT_DIR"
fi

# Get actual commit hash for logging
ACTUAL_COMMIT=$(cd "$PROJECT_ROOT" && git rev-parse HEAD)
log_info "Building commit: $ACTUAL_COMMIT"

# Run build in container
log_step "Running build in container..."
docker run --rm \
    -v "$PROJECT_ROOT:/workspace:ro" \
    -v "$OUTPUT_DIR:/output" \
    -v bitcoinpurple_ccache_arm64:/ccache \
    -v bitcoinpurple_depends_arm64:/depends-cache \
    -e GIT_COMMIT="$ACTUAL_COMMIT" \
    bitcoinpurple-builder:linux-aarch64

log_step "Build complete!"
log_info "Binaries are in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
