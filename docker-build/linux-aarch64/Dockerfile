# Dockerfile for BitcoinPurple Core - Linux ARM64/AARCH64 Cross-Compilation
# Produces ARM64 Linux binaries from x86_64

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

###############################################################################
# Install Build Dependencies
###############################################################################
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Build essentials
        build-essential \
        libtool \
        autotools-dev \
        automake \
        pkg-config \
        bsdmainutils \
        python3 \
        git \
        ca-certificates \
        wget \
        curl \
        bison \
        flex \
        # ARM64 cross-compilation toolchain
        g++-aarch64-linux-gnu \
        gcc-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu \
        # Build optimization
        ccache && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# Configure ccache
###############################################################################
ENV CCACHE_DIR=/ccache
ENV CCACHE_SIZE=5G
ENV PATH="/usr/lib/ccache:$PATH"

RUN ccache --set-config=max_size=5G && \
    ccache --set-config=compression=true && \
    ccache --set-config=compression_level=6

###############################################################################
# Setup Build Environment
###############################################################################
WORKDIR /build

# Build script will be run when container starts
COPY build-in-docker.sh /build/
RUN chmod +x /build/build-in-docker.sh

# Output directory for built binaries
RUN mkdir -p /output

# Entry point
ENTRYPOINT ["/build/build-in-docker.sh"]
