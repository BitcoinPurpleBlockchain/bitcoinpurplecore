# BitcoinPurple Core - Docker Build System

Cross-platform Docker-based build system for compiling BitcoinPurple Core for multiple architectures.

## Supported Platforms

- **Linux x86_64** - Native build with Qt5 GUI and BerkeleyDB 4.8
- **Windows x64** - Cross-compilation from Linux using MinGW
- **Linux ARM64/AARCH64** - Cross-compilation for ARM64 (64-bit)
- **Linux ARMv7** - Cross-compilation for ARMv7 (32-bit ARM, e.g., Raspberry Pi 2/3)

## Host Requirements

### Host Architecture
- **x86_64 (amd64)** - Required for all builds
- ARM64/AARCH64 and ARMv7 builds use cross-compilation from x86_64 host
- Running on ARM64 host is not currently supported

### Operating System
- **Linux** (recommended): Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux
- **macOS**: 11+ with Docker Desktop (Intel or Apple Silicon with Rosetta)
- **Windows**: 10/11 with WSL2 and Docker Desktop

### Required Software

#### Docker
```bash
# Check Docker installation
docker --version  # Required: 20.10+

# Verify Docker is running
docker ps

# Enable BuildKit for optimized builds (recommended)
export DOCKER_BUILDKIT=1
```

**Tested versions**: Docker 20.10+ through 29.1+

#### Docker Permissions
User must have permissions to run Docker:
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

#### Disk Space Check
Verify available space:
```bash
df -h /var/lib/docker    # Docker images and volumes
df -h $(pwd)             # Working directory for output
```

### Verify Prerequisites

Run this command to verify your system is ready:
```bash
# Complete test
docker run --rm hello-world && \
docker volume create test-volume && \
docker volume rm test-volume && \
echo "Docker configured correctly!"
```

## Reproducible Builds

This Docker build system is designed to produce **deterministic and reproducible builds**.

### What is "Reproducible"

A build is reproducible when:
- Same source code produces identical binaries (same SHA256 hash)
- Build can be independently verified by anyone
- Eliminates possibility of backdoors or unauthorized modifications

### How It Works

#### 1. Fixed Base Image
```dockerfile
FROM ubuntu:22.04  # Specific version, not 'latest'
```

#### 2. Precise Dependency Versions
- BerkeleyDB 4.8.30 (SHA256 checksum verified)
- Depends system builds everything from source with fixed versions
- Package manager with specified versions where possible

#### 3. Immutable Source Code
```bash
# Source code mounted read-only
docker run -v "$PROJECT_ROOT:/workspace:ro"
```

#### 4. Deterministic Build Process
- `SOURCE_DATE_EPOCH` for reproducible timestamps
- Consistent compiler flags
- Deterministic binary stripping

### Verifying a Build

To verify that a build is reproducible:

#### Step 1: Initial Build
```bash
cd docker-build/linux-x86_64
./build.sh
# Save hash
sha256sum ../../build-output/linux-x86_64/bitcoinpurple-linux-x86_64.tar.gz > hash1.txt
```

#### Step 2: Clean Rebuild
```bash
# Clean everything
docker rmi bitcoinpurple-builder:linux-x86_64
docker volume rm bitcoinpurple_ccache_linux
rm -rf ../../build-output/linux-x86_64

# Rebuild from scratch
./build.sh
sha256sum ../../build-output/linux-x86_64/bitcoinpurple-linux-x86_64.tar.gz > hash2.txt
```

#### Step 3: Compare
```bash
diff hash1.txt hash2.txt && echo "✓ Build is reproducible!" || echo "✗ Hashes differ"
```

### Factors Affecting Reproducibility

#### Guaranteed Deterministic
- Source code (same Git commit)
- Dependencies built via depends system
- Compiler flags and configuration
- Docker base image (fixed version)

#### Potential Variations
- **Timestamps**: Mitigated by `SOURCE_DATE_EPOCH`
- **Hostname**: Embedded in some binaries (mitigated by Docker)
- **Username**: Embedded in some binaries (mitigated by Docker)
- **Absolute paths**: Read-only mount prevents this

#### Non-Deterministic (but acceptable)
- **ccache**: Cache doesn't influence final output
- **Filesystem order**: Docker overlay2 is consistent
- **Parallelism**: `-j$(nproc)` doesn't affect output

### Best Practices for Reproducible Builds

#### 1. Use Specific Git Commits
```bash
# Don't use floating branches
git checkout main  # branch can change

# Use immutable commit hash or tag
git checkout v1.0.0  # immutable tag
git checkout abc123def456  # commit hash
```

#### 2. Document Build Versions
Create a `build-manifest.txt`:
```bash
echo "Git Commit: $(git rev-parse HEAD)" > build-manifest.txt
echo "Git Tag: $(git describe --tags --always)" >> build-manifest.txt
echo "Build Date: $(date -u +%Y-%m-%d)" >> build-manifest.txt
echo "Docker Version: $(docker --version)" >> build-manifest.txt
echo "Ubuntu Base: 22.04" >> build-manifest.txt
```

#### 3. Verify Dependency Checksums
```bash
# BerkeleyDB checksum verified in Dockerfile
RUN echo "12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz" | sha256sum -c -
```

#### 4. Build Without Cache for Releases
```bash
# For official releases, always clean build
./build.sh --no-cache
```

### Build Attestation

For official builds, create signed attestation:

```bash
#!/bin/bash
# generate-attestation.sh

cd build-output

# Generate checksums
sha256sum */*.tar.gz */*.zip > SHA256SUMS.txt

# Sign with GPG (if you have a key)
gpg --detach-sign --armor SHA256SUMS.txt

# Create JSON attestation
cat > build-attestation.json <<EOF
{
  "version": "1.0.0",
  "gitCommit": "$(git rev-parse HEAD)",
  "gitTag": "$(git describe --tags --always)",
  "buildDate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "builder": {
    "system": "Docker",
    "baseImage": "ubuntu:22.04"
  },
  "platforms": [
    "linux-x86_64",
    "windows-x64",
    "linux-aarch64",
    "linux-armv7"
  ]
}
EOF

echo "✓ Attestation created: SHA256SUMS.txt, SHA256SUMS.txt.asc, build-attestation.json"
```

**Automated Script**: Use `./generate-attestation.sh` in the `docker-build/` directory to automatically create all attestation files.

### Verifying Third-Party Builds

If someone provides you with binaries, verify them:

```bash
# Download binaries and checksums
wget https://example.com/bitcoinpurple-linux-x86_64.tar.gz
wget https://example.com/SHA256SUMS.txt
wget https://example.com/SHA256SUMS.txt.asc

# Verify GPG signature (optional)
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt

# Verify checksum
sha256sum -c SHA256SUMS.txt --ignore-missing

# To verify independently:
# 1. Clone repository at the same commit
git clone https://github.com/yourorg/bitcoinpurplecore.git
cd bitcoinpurplecore
git checkout <COMMIT_HASH>

# 2. Build yourself
cd docker-build/linux-x86_64
./build.sh

# 3. Compare checksums
sha256sum ../../build-output/linux-x86_64/bitcoinpurple-linux-x86_64.tar.gz
```

## Quick Start

### Single Platform Build

```bash
# Linux x86_64
cd docker-build/linux-x86_64
./build.sh

# Windows x64
cd docker-build/windows-x64
./build.sh

# Linux ARM64
cd docker-build/linux-aarch64
./build.sh

# Linux ARMv7
cd docker-build/linux-armv7
./build.sh
```

### Build All Platforms

```bash
cd docker-build
./build-all.sh
```

### Build Specific Git Commit

You can build any specific Git commit by specifying `BUILD_COMMIT`:

```bash
# Build current HEAD (default)
./build.sh

# Build a specific commit hash
./build.sh BUILD_COMMIT=abc123def456

# Build a specific tag
./build.sh BUILD_COMMIT=v1.0.0

# Build with specific commit and no cache
./build.sh BUILD_COMMIT=abc123def456 --no-cache

# Build all platforms at specific commit
cd docker-build
./build-all.sh BUILD_COMMIT=v1.0.0
```

**How it works:**
1. Script checks out the specified commit before building
2. Commit hash is passed to Docker container via `GIT_COMMIT` environment variable
3. Useful for building release versions or testing specific commits
4. Original Git state is preserved (script checks out but doesn't commit)

## Output

Compiled binaries are saved in:
```
build-output/
├── linux-x86_64/
│   ├── bitcoinpurple-linux-x86_64.tar.gz
│   └── bitcoinpurple-linux-x86_64/
│       └── bin/
│           ├── bitcoinpurpled
│           ├── bitcoinpurple-cli
│           ├── bitcoinpurple-qt
│           ├── bitcoinpurple-tx
│           └── bitcoinpurple-wallet
├── windows-x64/
│   ├── bitcoinpurple-windows-x64.zip
│   └── bitcoinpurple-windows-x64/
│       └── bin/
│           ├── bitcoinpurpled.exe
│           ├── bitcoinpurple-cli.exe
│           ├── bitcoinpurple-qt.exe
│           ├── bitcoinpurple-tx.exe
│           └── bitcoinpurple-wallet.exe
├── linux-aarch64/
│   ├── bitcoinpurple-linux-aarch64.tar.gz
│   └── bitcoinpurple-linux-aarch64/
│       └── bin/
│           ├── bitcoinpurpled
│           ├── bitcoinpurple-cli
│           ├── bitcoinpurple-qt
│           ├── bitcoinpurple-tx
│           └── bitcoinpurple-wallet
└── linux-armv7/
    ├── bitcoinpurple-linux-armv7.tar.gz
    └── bitcoinpurple-linux-armv7/
        └── bin/
            ├── bitcoinpurpled
            ├── bitcoinpurple-cli
            ├── bitcoinpurple-qt
            ├── bitcoinpurple-tx
            └── bitcoinpurple-wallet
```

## Usage Examples

### Development Build
```bash
# Quick development build of current code
cd docker-build/linux-x86_64
./build.sh
```

### Release Build
```bash
# Official release build with clean cache
cd docker-build
./build-all.sh BUILD_COMMIT=v1.0.0 --no-cache

# After building, create attestation
cd ../build-output
sha256sum */*.tar.gz */*.zip > SHA256SUMS.txt
gpg --detach-sign --armor SHA256SUMS.txt
```

### Testing a Pull Request
```bash
# Build a specific PR commit to test
./build.sh BUILD_COMMIT=pr-feature-branch

# Test the binaries
../build-output/linux-x86_64/bitcoinpurple-linux-x86_64/bin/bitcoinpurpled --version
```

### Building Multiple Versions
```bash
# Build v1.0.0
./build.sh BUILD_COMMIT=v1.0.0
mv ../build-output/linux-x86_64 ../build-output/linux-x86_64-v1.0.0

# Build v1.1.0
./build.sh BUILD_COMMIT=v1.1.0
mv ../build-output/linux-x86_64 ../build-output/linux-x86_64-v1.1.0

# Compare binaries
diff -r ../build-output/linux-x86_64-v1.0.0 ../build-output/linux-x86_64-v1.1.0
```

### Verifying Reproducibility
```bash
# First build
./build.sh BUILD_COMMIT=abc123 --no-cache
sha256sum ../build-output/linux-x86_64/*.tar.gz > hash1.txt

# Clean everything
docker volume rm bitcoinpurple_ccache_linux
rm -rf ../build-output/linux-x86_64

# Second build (should produce identical binaries)
./build.sh BUILD_COMMIT=abc123 --no-cache
sha256sum ../build-output/linux-x86_64/*.tar.gz > hash2.txt

# Verify they match
diff hash1.txt hash2.txt && echo "✓ Reproducible!" || echo "✗ Not reproducible"
```

## Build Details

### Linux x86_64
- **Base**: Ubuntu 22.04
- **Features**: Qt5 GUI, BerkeleyDB 4.8, ZMQ, UPnP, NAT-PMP, QR codes
- **Build Time**: ~30-45 minutes (first build), ~5-10 minutes (rebuild with ccache)
- **Output Size**: ~50MB (stripped binaries)

### Windows x64
- **Base**: Ubuntu 22.04 + MinGW-w64
- **Method**: Cross-compilation using depends system
- **Features**: All cross-platform compatible features
- **Build Time**: ~45-60 minutes (first build with depends)
- **Output Size**: ~40MB (stripped executables)

### Linux ARM64
- **Base**: Ubuntu 22.04 amd64 + ARM64 cross-compilation toolchain (aarch64-linux-gnu)
- **Method**: Cross-compilation from x86_64 host using depends system
- **Host Requirement**: x86_64 architecture (uses docker buildx with --platform linux/amd64)
- **Features**: All cross-platform compatible features
- **Build Time**: ~45-60 minutes (first build with depends)
- **Output Size**: ~50MB (stripped binaries)

### Linux ARMv7
- **Base**: Ubuntu 22.04 amd64 + ARMv7 cross-compilation toolchain (arm-linux-gnueabihf)
- **Method**: Cross-compilation from x86_64 host using depends system
- **Host Requirement**: x86_64 architecture (uses docker buildx with --platform linux/amd64)
- **Target**: ARMv7 32-bit hard-float (Raspberry Pi 2/3, Odroid, BeagleBone Black)
- **Features**: All cross-platform compatible features
- **Build Time**: ~45-60 minutes (first build with depends)
- **Output Size**: ~45MB (stripped binaries)

## Cache and Optimization

The system uses Docker volumes for persistent caches:

- `bitcoinpurple_ccache_linux` - Linux compilation cache
- `bitcoinpurple_ccache_windows` - Windows compilation cache
- `bitcoinpurple_ccache_arm64` - ARM64 compilation cache
- `bitcoinpurple_ccache_armv7` - ARMv7 compilation cache
- `bitcoinpurple_depends_windows` - Pre-built Windows dependencies
- `bitcoinpurple_depends_arm64` - Pre-built ARM64 dependencies
- `bitcoinpurple_depends_armv7` - Pre-built ARMv7 dependencies

### Clean Build (without cache)

```bash
./build.sh --no-cache
```

### Clean All Caches

```bash
# Remove all cache volumes
docker volume rm bitcoinpurple_ccache_linux bitcoinpurple_ccache_windows \
                 bitcoinpurple_ccache_arm64 bitcoinpurple_ccache_armv7 \
                 bitcoinpurple_depends_windows bitcoinpurple_depends_arm64 \
                 bitcoinpurple_depends_armv7

# Remove Docker images
docker rmi bitcoinpurple-builder:linux-x86_64 \
           bitcoinpurple-builder:windows-x64 \
           bitcoinpurple-builder:linux-aarch64 \
           bitcoinpurple-builder:linux-armv7
```

## Troubleshooting

### Build fails with "out of memory"

Add more RAM to Docker daemon or reduce parallel jobs:
```bash
# Edit build-in-docker.sh, change:
make -j$(nproc)
# to:
make -j2
```

### Dependencies fail to download

Verify internet connection and retry with `--no-cache`.

### Windows build fails

Ensure MinGW alternatives are set correctly (script does this automatically).

### ARM64 or ARMv7 build fails on x86_64 host

The build system requires Docker Buildx for cross-compilation:

```bash
# Verify buildx is available
docker buildx version

# If not available, update Docker to version 19.03+ or install buildx plugin
```

**Note**: These builds do NOT require QEMU emulation as they use native x86_64 cross-compilation toolchains (aarch64-linux-gnu for ARM64, arm-linux-gnueabihf for ARMv7).

### Permission denied errors

```bash
# Ensure user is in docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Disk space issues

```bash
# Clean Docker system
docker system prune -a
docker volume prune

# Check space
df -h /var/lib/docker
```

## Important Notes

1. **BerkeleyDB 4.8**: Linux x86_64 uses BerkeleyDB 4.8.30 for legacy wallet compatibility
2. **Depends System**: Windows and ARM platforms use Bitcoin Core's depends system for dependency management
3. **Read-only Mount**: Source code is mounted read-only, so builds don't modify your repository
4. **ccache**: Linux x86_64 uses native ccache; other platforms get it through depends

## Testing Built Binaries

### Linux x86_64
```bash
build-output/linux-x86_64/bitcoinpurple-linux-x86_64/bin/bitcoinpurpled --version
build-output/linux-x86_64/bitcoinpurple-linux-x86_64/bin/bitcoinpurple-cli --help
```

### Windows x64 (on Linux with Wine)
```bash
wine build-output/windows-x64/bitcoinpurple-windows-x64/bin/bitcoinpurpled.exe --version
```

### Linux ARM64 (on ARM64 system or with QEMU)
```bash
# On ARM64 system
build-output/linux-aarch64/bitcoinpurple-linux-aarch64/bin/bitcoinpurpled --version

# With QEMU (if installed)
qemu-aarch64 -L /usr/aarch64-linux-gnu \
  build-output/linux-aarch64/bitcoinpurple-linux-aarch64/bin/bitcoinpurpled --version
```

### Linux ARMv7 (on ARMv7 system or with QEMU)
```bash
# On ARMv7 system (e.g., Raspberry Pi 2/3)
build-output/linux-armv7/bitcoinpurple-linux-armv7/bin/bitcoinpurpled --version

# With QEMU (if installed)
qemu-arm -L /usr/arm-linux-gnueabihf \
  build-output/linux-armv7/bitcoinpurple-linux-armv7/bin/bitcoinpurpled --version
```

## Release Distribution

The `.tar.gz` and `.zip` files in `build-output/` are ready for distribution:

```bash
# Generate SHA256 checksums for all archives
cd build-output
sha256sum */*.tar.gz */*.zip > SHA256SUMS.txt

# Sign checksums with GPG (optional)
gpg --detach-sign --armor SHA256SUMS.txt

# Display checksums
cat SHA256SUMS.txt
```

## Support

For issues or questions, please open an issue on GitHub.

## License

This build system follows the same license as BitcoinPurple Core (MIT License).
