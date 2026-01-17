#!/bin/bash

###############################################################################
# Quick Build Script for BitcoinPurple Core
# Automates dependencies installation, BerkeleyDB setup, and compilation
# With ccache support for faster rebuilds
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run this script as root (sudo will be called when needed)"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect host architecture for depends system
# Query the depends system to get the correct HOST value
# This ensures compatibility with how depends actually determines the platform
ARCH=$(uname -m)
HOST_PLATFORM=$(cd "$SCRIPT_DIR/depends" && make print-HOST 2>/dev/null | grep -oP 'HOST=\K.*' || echo "")

if [ -z "$HOST_PLATFORM" ]; then
    log_error "Failed to detect HOST platform from depends system"
    exit 1
fi

log_info "Detected architecture: $ARCH"
log_info "Depends HOST platform: $HOST_PLATFORM"

###############################################################################
# STEP 1: Install Dependencies
###############################################################################
install_dependencies() {
    log_info "Installing build dependencies..."

    sudo apt update

    # Essential build tools
    log_info "Installing essential build tools..."
    sudo apt install -y \
        build-essential \
        libtool \
        autotools-dev \
        automake \
        pkg-config \
        bsdmainutils \
        python3 \
        git \
        curl

    # BitcoinPurple core dependencies
    log_info "Installing BitcoinPurple core dependencies..."
    sudo apt install -y \
        libevent-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libboost-test-dev \
        libboost-thread-dev \
        libsqlite3-dev

    # Qt 5 for GUI
    log_info "Installing Qt5 for GUI..."
    sudo apt install -y \
        libqt5gui5 \
        libqt5core5a \
        libqt5dbus5 \
        qttools5-dev \
        qttools5-dev-tools \
        qtbase5-dev \
        qtwayland5

    # Optional dependencies
    log_info "Installing optional dependencies..."
    sudo apt install -y \
        libqrencode-dev \
        libzmq3-dev \
        libminiupnpc-dev \
        libnatpmp-dev \
        systemtap-sdt-dev

    # Debugging tools
    log_info "Installing debugging tools..."
    sudo apt install -y gdb valgrind

    # ccache for faster rebuilds
    log_info "Installing ccache for faster rebuilds..."
    sudo apt install -y ccache

    log_info "Dependencies installed successfully!"
}

###############################################################################
# STEP 2: Install BerkeleyDB 4.8
###############################################################################
install_berkeleydb() {
    log_info "Installing BerkeleyDB 4.8 via depends system..."

    BDB_PREFIX="$SCRIPT_DIR/depends/$HOST_PLATFORM"

    if [ -f "$BDB_PREFIX/lib/libdb_cxx-4.8.a" ]; then
        log_warn "BerkeleyDB already built in depends/$HOST_PLATFORM"
        log_warn "Remove depends/$HOST_PLATFORM to rebuild"
        return 0
    fi

    log_info "Building BerkeleyDB for $HOST_PLATFORM using depends system..."
    log_info "This includes necessary patches for modern GCC..."

    # Clean PATH from Windows paths (WSL2 compatibility)
    # Remove /mnt/c paths that contain spaces and break the build
    CLEAN_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/[a-z]" | tr '\n' ':' | sed 's/:$//')

    log_info "Cleaning PATH for depends build (WSL2 compatibility)..."

    # Build only BerkeleyDB using depends (with patches)
    PATH="$CLEAN_PATH" make -C "$SCRIPT_DIR/depends" \
        NO_BOOST=1 \
        NO_LIBEVENT=1 \
        NO_QT=1 \
        NO_SQLITE=1 \
        NO_NATPMP=1 \
        NO_UPNP=1 \
        NO_ZMQ=1 \
        NO_USDT=1 \
        -j"$(nproc)"

    if [ -f "$BDB_PREFIX/lib/libdb_cxx-4.8.a" ]; then
        log_info "BerkeleyDB 4.8 installed successfully at $BDB_PREFIX"
    else
        log_error "BerkeleyDB build failed"
        exit 1
    fi
}

###############################################################################
# STEP 3: Create placeholder Makefiles
###############################################################################
create_placeholder_makefiles() {
    log_info "Creating placeholder Makefile files if needed..."

    # Create placeholder Makefile files if they don't exist
    # (required by some versions of configure.ac for AC_CONFIG_LINKS)
    if [ ! -f "src/qt/Makefile" ]; then
        log_info "Creating placeholder src/qt/Makefile..."
        touch src/qt/Makefile
    fi
    if [ ! -f "src/qt/test/Makefile" ]; then
        log_info "Creating placeholder src/qt/test/Makefile..."
        mkdir -p src/qt/test
        touch src/qt/test/Makefile
    fi
    if [ ! -f "src/test/Makefile" ]; then
        log_info "Creating placeholder src/test/Makefile..."
        touch src/test/Makefile
    fi
}

###############################################################################
# STEP 4: Build BitcoinPurple Core
###############################################################################
build_bitcoinpurple() {
    log_info "Starting BitcoinPurple Core build process..."

    # Clean previous build if Makefile exists
    if [ -f "Makefile" ]; then
        log_info "Cleaning previous build configuration..."
        make distclean 2>/dev/null || true
    fi

    # Create placeholder Makefiles
    create_placeholder_makefiles

    # Generate configure script (first time only)
    if [ ! -f "./configure" ]; then
        log_info "Generating configure script..."
        ./autogen.sh
    else
        log_info "Configure script already exists, skipping autogen.sh"
    fi

    # Set BerkeleyDB prefix from depends
    export BDB_PREFIX="$SCRIPT_DIR/depends/$HOST_PLATFORM"
    BDB_CONFIG=""

    if [ -f "$BDB_PREFIX/lib/libdb_cxx-4.8.a" ]; then
        log_info "Using BerkeleyDB 4.8 from depends/$HOST_PLATFORM"
        BDB_CONFIG="BDB_LIBS=\"-L${BDB_PREFIX}/lib -ldb_cxx-4.8\" BDB_CFLAGS=\"-I${BDB_PREFIX}/include\""
    else
        log_warn "BerkeleyDB 4.8 not found in depends"
        log_warn "Will use system BerkeleyDB (may break wallet compatibility)"
        BDB_CONFIG="--with-incompatible-bdb"
    fi

    # Setup ccache for faster rebuilds
    if command -v ccache &> /dev/null; then
        log_info "Enabling ccache for faster compilation..."
        # Add ccache to PATH (it will wrap gcc/g++ automatically)
        export PATH="/usr/lib/ccache:$PATH"
        # Use plain gcc/g++ names (ccache wrappers will intercept them)
        export CC="gcc"
        export CXX="g++"
        ccache -z  # Zero statistics before build
    else
        log_warn "ccache not found, using plain gcc/g++..."
        export CC="gcc"
        export CXX="g++"
    fi

    # Calculate optimal number of parallel jobs
    JOBS=$(nproc)

    log_info "Available CPU cores: $JOBS"
    log_info "Using $JOBS parallel jobs"

    # Configure build with optimization flags
    log_info "Configuring build with Qt5..."
    eval ./configure \
        --enable-gui=qt5 \
        --with-gui=qt5 \
        --enable-zmq \
        --with-miniupnpc \
        --disable-tests \
        --disable-bench \
        CXXFLAGS=\"-O2 -pipe\" \
        $BDB_CONFIG

    # Compile with parallel jobs
    log_info "Starting parallel compilation..."
    START_TIME=$(date +%s)

    # Use make with parallel jobs
    make -j"$JOBS"

    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))

    log_info "Build completed successfully in ${BUILD_TIME}s!"

    # Show ccache stats after build
    if command -v ccache &> /dev/null; then
        log_info "ccache statistics:"
        ccache -s | head -n 10
    fi

    log_info "Binaries location:"
    log_info "  - bitcoinpurpled: $SCRIPT_DIR/src/bitcoinpurpled"
    log_info "  - bitcoinpurple-cli: $SCRIPT_DIR/src/bitcoinpurple-cli"
    log_info "  - bitcoinpurple-qt: $SCRIPT_DIR/src/qt/bitcoinpurple-qt"
    log_info "  - bitcoinpurple-tx: $SCRIPT_DIR/src/bitcoinpurple-tx"
    log_info "  - bitcoinpurple-wallet: $SCRIPT_DIR/src/bitcoinpurple-wallet"
}

###############################################################################
# STEP 5: Clean build artifacts
###############################################################################
clean_build() {
    log_info "Cleaning build artifacts..."

    if [ -f "Makefile" ]; then
        make clean
        log_info "Build artifacts cleaned"
    else
        log_warn "No Makefile found, nothing to clean"
    fi

    if [ -f "configure" ]; then
        log_info "Removing configure script..."
        make distclean 2>/dev/null || true
    fi
}

###############################################################################
# STEP 6: Quick rebuild (without reconfigure)
###############################################################################
rebuild_bitcoinpurple() {
    log_info "Quick rebuild (keeping existing configuration)..."

    if [ ! -f "Makefile" ]; then
        log_error "No Makefile found. Run --build first to configure."
        exit 1
    fi

    # Setup ccache for faster rebuilds
    if command -v ccache &> /dev/null; then
        log_info "Enabling ccache for faster compilation..."
        # Add ccache to PATH (it will wrap gcc/g++ automatically)
        export PATH="/usr/lib/ccache:$PATH"
        # Use plain gcc/g++ names (ccache wrappers will intercept them)
        export CC="gcc"
        export CXX="g++"
        ccache -z  # Zero statistics before build
    else
        log_warn "ccache not found, using plain gcc/g++..."
        export CC="gcc"
        export CXX="g++"
    fi

    # Calculate optimal number of parallel jobs
    JOBS=$(nproc)

    log_info "Available CPU cores: $JOBS"
    log_info "Using $JOBS parallel jobs"

    # Clean only object files (fast)
    make clean

    # Compile with parallel jobs
    log_info "Starting parallel compilation..."
    START_TIME=$(date +%s)

    make -j"$JOBS"

    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))

    log_info "Rebuild completed successfully in ${BUILD_TIME}s!"

    # Show ccache stats after rebuild
    if command -v ccache &> /dev/null; then
        log_info "ccache statistics:"
        ccache -s | head -n 10
    fi

    log_info "Binaries location:"
    log_info "  - bitcoinpurpled: $SCRIPT_DIR/src/bitcoinpurpled"
    log_info "  - bitcoinpurple-cli: $SCRIPT_DIR/src/bitcoinpurple-cli"
    log_info "  - bitcoinpurple-qt: $SCRIPT_DIR/src/qt/bitcoinpurple-qt"
    log_info "  - bitcoinpurple-tx: $SCRIPT_DIR/src/bitcoinpurple-tx"
    log_info "  - bitcoinpurple-wallet: $SCRIPT_DIR/src/bitcoinpurple-wallet"
}

###############################################################################
# STEP 7: Setup ccache configuration
###############################################################################
setup_ccache() {
    log_info "Setting up ccache configuration for optimal performance..."

    if ! command -v ccache &> /dev/null; then
        log_error "ccache is not installed. Please install it first:"
        echo "  sudo apt install ccache"
        exit 1
    fi

    # Set ccache size to 5GB (adjust as needed)
    ccache -M 5G

    # Show current configuration
    log_info "ccache configuration:"
    ccache -p | grep -E "(max_size|cache_dir)"

    log_info "ccache setup completed!"
    log_info "Current cache statistics:"
    ccache -s
}

###############################################################################
# Main script
###############################################################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Quick build script for BitcoinPurple Core with ccache support

OPTIONS:
    --help              Show this help message
    --install-deps      Install system dependencies only
    --install-db        Install BerkeleyDB 4.8 only
    --build             Full build with reconfigure (distclean + configure + make)
    --rebuild           Quick rebuild without reconfigure (clean + make) [FAST FOR TESTING]
    --clean             Clean build artifacts
    --full              Full build (deps + db + build) [DEFAULT]
    --setup-ccache      Setup ccache configuration for optimal performance

EXAMPLES:
    $0                  # Full build with all steps
    $0 --build          # Full rebuild (reconfigures everything)
    $0 --rebuild        # Quick rebuild (keeps configuration, fastest for testing!)
    $0 --clean          # Clean build artifacts
    $0 --install-deps   # Install dependencies only
    $0 --setup-ccache   # Configure ccache for optimal performance

CCACHE BENEFITS:
    - First build: Normal compilation time
    - Subsequent builds: 5-10x faster (only recompiles changed files)
    - Perfect for testing and iterative development

EOF
}

# Parse command line arguments
case "${1:-}" in
    --help)
        show_help
        exit 0
        ;;
    --install-deps)
        install_dependencies
        ;;
    --install-db)
        install_berkeleydb
        ;;
    --build)
        build_bitcoinpurple
        ;;
    --rebuild)
        rebuild_bitcoinpurple
        ;;
    --clean)
        clean_build
        ;;
    --setup-ccache)
        setup_ccache
        ;;
    --full|"")
        log_info "Starting full build process..."
        install_dependencies
        install_berkeleydb
        build_bitcoinpurple
        log_info "Full build process completed!"
        ;;
    *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

exit 0
