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
        # Core dependencies
        libevent-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libboost-test-dev \
        libboost-thread-dev \
        libsqlite3-dev \
        libdb++-dev \
        # Qt5 for GUI
        libqt5gui5 \
        libqt5core5a \
        libqt5dbus5 \
        qttools5-dev \
        qttools5-dev-tools \
        qtbase5-dev \
        libqt5svg5-dev \
        # Optional dependencies
        libqrencode-dev \
        libzmq3-dev \
        libminiupnpc-dev \
        libnatpmp-dev \
        # Build optimization
        ccache && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# Build BerkeleyDB 4.8.30
###############################################################################
WORKDIR /tmp

RUN wget -q http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz && \
    echo "12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz" | sha256sum -c - && \
    tar -xzf db-4.8.30.NC.tar.gz && \
    cd db-4.8.30.NC/build_unix && \
    ../dist/configure \
        --prefix=/opt/db4 \
        --enable-cxx \
        --disable-shared \
        --with-pic && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf db-4.8.30.NC*

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
