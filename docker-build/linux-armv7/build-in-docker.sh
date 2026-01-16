#!/bin/bash
###############################################################################
# BitcoinPurple Core - Linux ARMv7 Cross-Compilation Script (runs inside Docker)
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

log_step "Building BitcoinPurple Core for Linux ARMv7 (32-bit ARM)"

# Copy source to writable directory (workspace is read-only)
log_info "Copying source code to build directory..."
cp -r /workspace /build/source
cd /build/source

# Restore cached depends if available
if [ -d "/depends-cache/arm-linux-gnueabihf" ]; then
    log_info "Restoring cached dependencies..."
    cp -r /depends-cache/* depends/ 2>/dev/null || true
fi

# Build dependencies using depends system
log_step "Building dependencies for ARMv7..."
cd depends
make HOST=arm-linux-gnueabihf -j$(nproc)

# Save built depends to cache
log_info "Caching dependencies..."
cp -r arm-linux-gnueabihf /depends-cache/ 2>/dev/null || true

cd ..

# Clean previous builds
log_info "Cleaning previous builds..."
make clean || true
make distclean || true

# Generate configure script
log_step "Running autogen.sh..."
./autogen.sh

# Configure for ARMv7 cross-compilation
log_step "Configuring build..."
CONFIG_SITE=$PWD/depends/arm-linux-gnueabihf/share/config.site ./configure \
    --prefix=/output/bitcoinpurple-linux-armv7 \
    --disable-tests \
    --disable-bench

# Build
log_step "Building (using $(nproc) cores)..."
make -j$(nproc)

# Install to output directory
log_step "Installing binaries..."
make install

# Strip ARMv7 binaries
log_step "Stripping binaries..."
arm-linux-gnueabihf-strip /output/bitcoinpurple-linux-armv7/bin/*

# Create archive
log_step "Creating tarball..."
cd /output
tar -czf bitcoinpurple-linux-armv7.tar.gz bitcoinpurple-linux-armv7/

# Show results
log_step "Build complete!"
log_info "Output files:"
ls -lh /output/

log_info "Binaries:"
ls -lh /output/bitcoinpurple-linux-armv7/bin/

log_step "Done! Binaries are in /output/"
