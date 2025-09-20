# PowerGrid Network End-to-End Testing

This document explains how to run the complete end-to-end testing suite for the PowerGrid Network, which deploys all contracts to a running substrate-contracts-node and validates cross-contract interactions.

## Prerequisites

### 1. Install substrate-contracts-node

```bash
# Install substrate-contracts-node
cargo install substrate-contracts-node --git https://github.com/paritytech/substrate-contracts-node.git --tag v0.33.0
```

### 2. Install cargo-contract

```bash
# Install cargo-contract
cargo install cargo-contract --force
```

### 3. Start substrate-contracts-node

```bash
# Start the node in development mode
substrate-contracts-node --dev --tmp
```

The node should start and be accessible on `ws://localhost:9944`.

## Running End-to-End Tests

### Automated Deployment and Testing

Run the complete end-to-end test suite:

```bash
./deploy-and-run-e2e.sh
```

This script will:

1. ✅ **Check Prerequisites** - Verify cargo-contract and substrate-contracts-node are available
2. ✅ **Build All Contracts** - Compile all PowerGrid contracts (token, registry, grid_service, governance)
3. ✅ **Deploy Contracts** - Deploy contracts in dependency order to the running node
4. ✅ **Test Cross-Contract Interactions** - Perform real cross-contract calls and validate state changes
5. ✅ **Run E2E Tests** - Execute ink! E2E tests for additional validation
6. ✅ **Generate Summary** - Output deployment addresses and test results

### Manual Steps (Alternative)

If you prefer to run steps manually:

1. **Build contracts:**
   ```bash
   cargo build --workspace --release
   ```

2. **Deploy contracts manually:**
   ```bash
   ./scripts/setup-integration-tests.sh
   ```

3. **Run simulation tests:**
   ```bash
   cargo test --workspace
   ```

4. **Run E2E tests:**
   ```bash
   cargo test --features e2e-tests -p integration-tests
   ```

## Test Coverage

### Cross-Contract Functionality Tested

1. **Device Registration & Staking**
   - Register device in ResourceRegistry
   - Stake tokens for participation
   - Verify device status

2. **Grid Event Management**
   - Create demand response events
   - Participate in grid events  
   - Track energy contributions

3. **Reward Distribution**
   - Cross-contract calls from GridService to Token contract
   - Mint rewards based on verified participation
   - Validate token balance changes

4. **Governance Operations**
   - Create governance proposals
   - Vote on proposals with token-based voting power
   - Execute governance decisions

### State Validation

The tests verify actual state changes across deployed contracts:

- ✅ Token balances update after reward distribution
- ✅ Device registration status changes
- ✅ Grid event participation records
- ✅ Governance proposal and voting states
- ✅ Cross-contract authorization and access control

## Expected Output

When successful, you'll see:

```
🚀 PowerGrid Network End-to-End Testing
========================================
This script deploys all contracts and tests cross-contract interactions

✅ cargo-contract is available
✅ substrate-contracts-node is running on port 9944
✅ All contracts built successfully
✅ PowerGrid Token deployed: 5GrwvaEF5zXb...
✅ Resource Registry deployed: 5FHneW46xGXgs5...
✅ Grid Service deployed: 5FLSigC9HGRKVhB...
✅ Governance deployed: 5DAAnrj7VHTznn...
✅ All cross-contract interaction tests passed!
✅ E2E tests passed

🎉 End-to-end testing completed successfully!
```

## Contract Addresses

After deployment, contract addresses are saved to:
- `deployment/local-addresses.json`

Example format:
```json
{
  "contracts": {
    "powergrid_token": "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY",
    "resource_registry": "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty",
    "grid_service": "5FLSigC9HGRKVhB9FjxKbMLvQb9uGRCb8NJtJWJCZGZehVk1",
    "governance": "5DAAnrj7VHTznn2v5Y6w8vM6Md6bKLDdWQHcG6RkMoqPy6Bt"
  },
  "network": "local",
  "deployed_at": "2024-01-15T10:30:00Z",
  "deployer": "//Alice"
}
```

## Troubleshooting

### Common Issues

1. **Node not running:**
   ```
   ❌ substrate-contracts-node not responding on port 9944
   💡 Please start it with: substrate-contracts-node --dev --tmp
   ```

2. **cargo-contract not installed:**
   ```
   ❌ cargo-contract is not installed
   💡 Install it with: cargo install cargo-contract --force
   ```

3. **Build failures:**
   - Ensure Rust toolchain is up to date: `rustup update`
   - Clean and rebuild: `cargo clean && cargo build --workspace`

4. **Deployment failures:**
   - Check that the node has sufficient funds for Alice account
   - Verify node is in development mode
   - Try restarting the node: `substrate-contracts-node --dev --tmp`

### Getting Help

If you encounter issues:

1. Check the deployment log output for specific error messages
2. Verify all prerequisites are installed correctly
3. Ensure the substrate-contracts-node is running and accessible
4. Review the contract addresses in `deployment/local-addresses.json`

## Architecture

The PowerGrid Network consists of four main contracts:

1. **PowerGrid Token** - PSP22-compatible token for rewards and governance
2. **Resource Registry** - Device registration and verification system  
3. **Grid Service** - Grid event management and participation tracking
4. **Governance** - Token-based governance for network parameters

All contracts are designed to work together through cross-contract calls, enabling a complete decentralized energy grid management system.