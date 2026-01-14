#!/bin/bash
###############################################################################
# BitcoinPurple Core - Linux ARM64 Cross-Compilation Script (runs inside Docker)
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

cd /workspace

log_step "Building BitcoinPurple Core for Linux ARM64/AARCH64"

# Build dependencies using depends system
log_step "Building dependencies for ARM64..."
cd depends
make HOST=aarch64-linux-gnu -j$(nproc)
cd ..

# Clean previous builds
log_info "Cleaning previous builds..."
make clean || true
make distclean || true

# Generate configure script
log_step "Running autogen.sh..."
./autogen.sh

# Configure for ARM64 cross-compilation
log_step "Configuring build..."
CONFIG_SITE=$PWD/depends/aarch64-linux-gnu/share/config.site ./configure \
    --prefix=/output/bitcoinpurple-linux-aarch64 \
    --disable-tests \
    --disable-bench

# Build
log_step "Building (using $(nproc) cores)..."
make -j$(nproc)

# Install to output directory
log_step "Installing binaries..."
make install

# Strip ARM64 binaries
log_step "Stripping binaries..."
aarch64-linux-gnu-strip /output/bitcoinpurple-linux-aarch64/bin/*

# Create archive
log_step "Creating tarball..."
cd /output
tar -czf bitcoinpurple-linux-aarch64.tar.gz bitcoinpurple-linux-aarch64/

# Show results
log_step "Build complete!"
log_info "Output files:"
ls -lh /output/

log_info "Binaries:"
ls -lh /output/bitcoinpurple-linux-aarch64/bin/

log_step "Done! Binaries are in /output/"
