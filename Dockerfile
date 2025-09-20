# PowerGrid Network Dockerfile
# Creates a container with Rust stable, WASM target, and cargo-contract v5.0.1 for building ink! contracts

FROM rust:1.82-bookworm

# Set environment variables
ENV CARGO_CONTRACT_VERSION=5.0.1

# Install system dependencies needed for substrate/ink development
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
        build-essential \
        curl \
        wget \
        git \
        clang \
        pkg-config \
        libssl-dev \
        jq \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Update certificates and rustup to handle SSL issues
RUN update-ca-certificates && \
    rustup self update

# Add wasm32 target and rust-src component  
RUN rustup target add wasm32-unknown-unknown && \
    rustup component add rust-src

# Install cargo-contract v5.0.1 (matching the project requirements)
RUN cargo install --force --locked cargo-contract --version ${CARGO_CONTRACT_VERSION}

# Verify installations
RUN rustc --version && \
    cargo --version && \
    cargo contract --version && \
    rustup target list --installed | grep wasm32-unknown-unknown && \
    rustup component list --installed | grep rust-src

# Set working directory
WORKDIR /powergrid_network

# Copy project files
COPY . .

# Build all contracts during image creation to cache dependencies
# Note: This may fail in environments with SSL certificate issues, but the image will still be usable
RUN echo "Attempting to build contracts to cache dependencies..." && \
    (./scripts/build-all.sh && echo "✅ Contract build successful") || \
    echo "⚠️  Contract build failed, but continuing. You can build manually after running the container."

# Default command
CMD ["./scripts/deploy-and-run-e2e.sh"]