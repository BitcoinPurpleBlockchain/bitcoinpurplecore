# Dockerfile for BitcoinPurple Core - Linux x86_64 Build
# Produces native Linux binaries for x86_64 architecture

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
        # Additional tools for depends system
        cmake \
        xz-utils \
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
