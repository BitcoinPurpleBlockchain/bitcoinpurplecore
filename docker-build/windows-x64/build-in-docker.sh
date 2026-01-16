#!/bin/bash
###############################################################################
# BitcoinPurple Core - Windows x64 Cross-Compilation Script (runs inside Docker)
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

log_step "Building BitcoinPurple Core for Windows x64"

# Copy source to writable directory (workspace is read-only)
log_info "Copying source code to build directory..."
cp -a /workspace /build/source
cd /build/source

# Restore cached depends if available
if [ -d "/depends-cache/x86_64-w64-mingw32" ]; then
    log_info "Restoring cached dependencies..."
    cp -r /depends-cache/* depends/ 2>/dev/null || true
fi

# Build dependencies using depends system
log_step "Building dependencies for Windows..."
cd depends
make HOST=x86_64-w64-mingw32 -j$(nproc)

# Save built depends to cache
log_info "Caching dependencies..."
cp -r x86_64-w64-mingw32 /depends-cache/ 2>/dev/null || true

cd ..

# Clean previous builds
log_info "Cleaning previous builds..."
make clean || true
make distclean || true

# Clean secp256k1 subdirectory
log_info "Cleaning secp256k1..."
cd src/secp256k1
make clean || true
make distclean || true
cd ../..

# Remove pre-generated Qt resource files that may cause issues
log_info "Removing pre-generated Qt resource files..."
rm -f src/qt/qrc_bitcoinpurple.cpp src/qt/qrc_bitcoinpurple_locale.cpp

# Generate configure script
log_step "Running autogen.sh..."
./autogen.sh

# Configure for Windows cross-compilation
log_step "Configuring build..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/output/bitcoinpurple-windows-x64 \
    --disable-tests \
    --disable-bench

# Build
log_step "Building (using $(nproc) cores)..."
make -j$(nproc)

# Install to output directory
log_step "Installing binaries..."
make install

# Strip Windows binaries
log_step "Stripping binaries..."
x86_64-w64-mingw32-strip /output/bitcoinpurple-windows-x64/bin/*.exe

# Create ZIP archive
log_step "Creating ZIP archive..."
cd /output
zip -r bitcoinpurple-windows-x64.zip bitcoinpurple-windows-x64/

# Show results
log_step "Build complete!"
log_info "Output files:"
ls -lh /output/

log_info "Binaries:"
ls -lh /output/bitcoinpurple-windows-x64/bin/

log_step "Done! Binaries are in /output/"
