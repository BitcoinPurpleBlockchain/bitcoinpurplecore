# Dockerfile for BitcoinPurple Core - Windows x64 Cross-Compilation
# Produces Windows binaries from Linux using MinGW

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

###############################################################################
# Install Build Dependencies
###############################################################################
RUN apt-get update && \
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
        # MinGW cross-compilation toolchain
        g++-mingw-w64-x86-64 \
        mingw-w64-x86-64-dev \
        # Additional tools
        zip \
        unzip \
        nsis \
        # Build optimization
        ccache && \
    rm -rf /var/lib/apt/lists/*

# Update alternatives for POSIX threads
RUN update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix && \
    update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

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
