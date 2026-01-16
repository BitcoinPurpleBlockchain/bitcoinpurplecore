#!/bin/bash
###############################################################################
# BitcoinPurple Core - Linux x86_64 Build Script (runs inside Docker)
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

log_step "Building BitcoinPurple Core for Linux x86_64"

# Copy source to writable directory (workspace is read-only)
log_info "Copying source code to build directory..."
cp -a /workspace /build/source
cd /build/source

# Build dependencies using depends system
log_step "Building dependencies for x86_64..."
cd depends
make HOST=x86_64-pc-linux-gnu -j$(nproc)
cd ..

# Clean previous builds
log_info "Cleaning previous builds..."
make clean || true
make distclean || true

# Generate configure script
log_step "Running autogen.sh..."
./autogen.sh

# Configure using depends
log_step "Configuring build..."
CONFIG_SITE=$PWD/depends/x86_64-pc-linux-gnu/share/config.site ./configure \
    --prefix=/output/bitcoinpurple-linux-x86_64 \
    --disable-tests \
    --disable-bench

# Build
log_step "Building (using $(nproc) cores)..."
make -j$(nproc)

# Install to output directory
log_step "Installing binaries..."
make install

# Strip binaries to reduce size
log_step "Stripping binaries..."
strip /output/bitcoinpurple-linux-x86_64/bin/*

# Create archive
log_step "Creating tarball..."
cd /output
tar -czf bitcoinpurple-linux-x86_64.tar.gz bitcoinpurple-linux-x86_64/

# Show results
log_step "Build complete!"
log_info "Output files:"
ls -lh /output/

log_info "Binaries:"
ls -lh /output/bitcoinpurple-linux-x86_64/bin/

# Show versions
log_info "bitcoinpurpled version:"
/output/bitcoinpurple-linux-x86_64/bin/bitcoinpurpled --version || true

log_step "Done! Binaries are in /output/"
