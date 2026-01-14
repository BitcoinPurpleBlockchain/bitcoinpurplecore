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

cd /workspace

log_step "Building BitcoinPurple Core for Linux x86_64"

# Clean previous builds
log_info "Cleaning previous builds..."
make clean || true
make distclean || true

# Generate configure script
log_step "Running autogen.sh..."
./autogen.sh

# Configure
log_step "Configuring build..."
./configure \
    --prefix=/output/bitcoinpurple-linux-x86_64 \
    --enable-gui=qt5 \
    --with-gui=qt5 \
    --enable-zmq \
    --with-miniupnpc \
    --with-natpmp \
    --with-qrencode \
    --enable-hardening \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    BDB_LIBS="-L/opt/db4/lib -ldb_cxx-4.8" \
    BDB_CFLAGS="-I/opt/db4/include" \
    CXXFLAGS="-O2 -pipe" \
    CC="gcc" \
    CXX="g++"

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
