# 🐳 PowerGrid Network Docker Setup

This guide helps you run the PowerGrid Network in a cross-platform Docker environment.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 4GB of available RAM
- 10GB of free disk space

### Validation (Recommended)
Before building, validate your Docker setup:
```bash
./scripts/validate-docker.sh
```

This will check:
- ✅ Docker and Docker Compose installation
- ✅ Dockerfile and docker-compose.yml syntax
- ✅ Project structure and required scripts
- ✅ Basic Docker functionality

### 1. One-Command Setup
```bash
# Run everything with Docker Compose
docker compose up --build
```

This will:
- Build the PowerGrid Network container with Rust stable, wasm32 target, rust-src, and cargo-contract v5.0.1
- Start substrate-contracts-node
- Build all contracts
- Deploy contracts to the local node
- Run E2E tests

### 2. Using the Helper Script
```bash
# Use the provided helper script
./scripts/docker-run.sh
```

## 📋 What's Included

### Docker Services

1. **substrate-node**: Runs `parity/substrate-contracts-node:v0.42.0`
   - Ports: 9944 (WebSocket), 9933 (HTTP), 30333 (P2P)
   - Pre-configured for development with `--dev --tmp`

2. **powergrid-runner**: Custom container with:
   - Rust stable (1.82+)
   - wasm32-unknown-unknown target
   - rust-src component
   - cargo-contract v5.0.1
   - All project dependencies

### Build Process

The Dockerfile installs:
- ✅ Rust stable toolchain
- ✅ wasm32-unknown-unknown target for WASM compilation
- ✅ rust-src component for source inspection
- ✅ cargo-contract v5.0.1 (matching project requirements)
- ✅ System dependencies (clang, pkg-config, libssl-dev, etc.)

## 🔧 Manual Commands

### Build Docker Image Only
```bash
docker build -t powergrid-network .
```

### Run Individual Services
```bash
# Start only substrate node
docker compose up substrate-node

# Run PowerGrid container interactively
docker compose run --rm powergrid-runner bash
```

### Run Specific Scripts
```bash
# Build contracts only
docker compose run --rm powergrid-runner ./scripts/build-all.sh

# Run unit tests only
docker compose run --rm powergrid-runner ./scripts/test-all.sh

# Deploy contracts only (requires substrate-node running)
docker compose run --rm powergrid-runner ./scripts/deploy-local.sh
```

## 🧪 E2E Testing

The `deploy-and-run-e2e.sh` script performs comprehensive testing:

1. **Health Check**: Verifies substrate-contracts-node is running
2. **Build**: Compiles all ink! contracts
3. **Unit Tests**: Runs all contract unit tests
4. **Deployment**: Deploys contracts to local substrate node
5. **E2E Tests**: Validates cross-contract functionality
6. **Integration**: Runs interaction tests

### Expected Output
```
🚀 PowerGrid Network Deploy and E2E Test Script
================================================
✅ substrate-contracts-node is running on port 9944
✅ All contracts built successfully
✅ All unit tests passed
✅ All contracts deployed successfully
✅ E2E test framework: SUCCESS
🎉 All tests completed successfully!
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Substrate Node Image Not Found
The docker-compose uses `prosopo/substrate-contracts-node:latest`. If this image is unavailable, you have alternatives:

**Option A: Build substrate-contracts-node locally**
```bash
# Clone and build substrate-contracts-node
git clone https://github.com/paritytech/substrate-contracts-node.git
cd substrate-contracts-node
docker build -t substrate-contracts-node .

# Update docker-compose.yml to use local image
# Change: image: prosopo/substrate-contracts-node:latest
# To:     image: substrate-contracts-node:latest
```

**Option B: Use alternative Docker image**
```bash
# Try other available images
docker run -p 9944:9944 blockcoders/substrate-contracts-node --dev --tmp --rpc-external --ws-external
```

**Option C: Run substrate-contracts-node outside Docker**
```bash
# Install substrate-contracts-node binary
cargo install contracts-node --git https://github.com/paritytech/substrate-contracts-node.git --force --locked

# Run manually
substrate-contracts-node --dev --tmp --rpc-cors all --rpc-methods=unsafe

# Then run only the PowerGrid container
docker compose run --rm powergrid-runner
```

#### 1. SSL Certificate Errors
If you encounter SSL/TLS certificate errors during build:
```bash
# Build with network host mode
docker build --network=host -t powergrid-network .
```

#### 2. Container Build Fails
Try using a more recent Rust base image:
```dockerfile
FROM rust:latest
```

#### 3. substrate-contracts-node Health Check Fails
Ensure no other services are using port 9944:
```bash
# Check what's using the port
lsof -i :9944

# Kill any existing substrate node
pkill substrate-contracts-node
```

#### 4. Out of Memory
Increase Docker's memory limit to at least 4GB:
- Docker Desktop: Settings → Resources → Memory

### Debug Mode
Run containers in debug mode for more verbose output:
```bash
# Run with verbose output
docker compose up --build --verbose

# Access container shell for debugging
docker compose run --rm powergrid-runner bash
```

## 📁 Persistent Storage

Docker volumes are used to cache build artifacts:
- `powergrid-target`: Stores Rust target directory
- `powergrid-cargo`: Stores Cargo registry cache

To clean up:
```bash
# Remove containers and volumes
docker compose down -v

# Remove images
docker rmi $(docker images powergrid* -q)
```

## 🌐 Network Configuration

The docker-compose setup creates a dedicated network (`powergrid-network`) for service communication:
- substrate-node accessible at `ws://substrate-node:9944` from runner
- External access available at `localhost:9944`

## ⚡ Performance Tips

1. **Multi-stage builds**: The Dockerfile caches Rust toolchain installation
2. **Volume mounts**: Build artifacts persist between runs
3. **Health checks**: Ensures substrate-node is ready before running tests

## 📝 Development Workflow

For active development:
```bash
# Start substrate node in background
docker compose up -d substrate-node

# Run development container with code mounted
docker compose run --rm -v $(pwd):/powergrid_network powergrid-runner bash

# Inside container, make changes and test
cargo test
./scripts/build-all.sh
./scripts/deploy-local.sh
```

## 🎯 Production Notes

- This setup is optimized for development and testing
- For production deployment, consider:
  - Multi-stage builds to reduce image size
  - Security hardening
  - Resource limits
  - Persistent storage for substrate data