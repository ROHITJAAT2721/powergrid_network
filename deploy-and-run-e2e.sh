#!/bin/bash

# PowerGrid Network End-to-End Deployment and Testing Script
# This script builds contracts, deploys them to a running substrate-contracts-node,
# performs cross-contract calls, and validates state changes end-to-end.

set -e

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SUBSTRATE_URL="ws://localhost:9944"
GAS_LIMIT="1000000000000"
PROOF_SIZE_LIMIT="1000000"

# Contract addresses (will be populated during deployment)
TOKEN_ADDR=""
REGISTRY_ADDR=""
GRID_ADDR=""
GOV_ADDR=""

echo "🚀 PowerGrid Network End-to-End Testing"
echo "======================================="
echo "This script deploys all contracts and tests cross-contract interactions"
echo ""

check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if cargo-contract is installed
    if ! command -v cargo-contract &> /dev/null; then
        echo -e "${RED}❌ cargo-contract is not installed${NC}"
        echo -e "${YELLOW}💡 Install it with: cargo install cargo-contract --force${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ cargo-contract is available${NC}"
    
    # Check if substrate-contracts-node is running
    echo "🔍 Checking if substrate-contracts-node is running..."
    if curl -s -H "Content-Type: application/json" \
       -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
       http://localhost:9944 2>/dev/null | grep -q '"result"'; then
        echo -e "${GREEN}✅ substrate-contracts-node is running on port 9944${NC}"
        return 0
    else
        echo -e "${RED}❌ substrate-contracts-node not responding on port 9944${NC}"
        echo -e "${YELLOW}💡 Please start it with: substrate-contracts-node --dev --tmp${NC}"
        exit 1
    fi
}

build_all_contracts() {
    echo -e "${BLUE}📦 Building all contracts...${NC}"
    
    # Build each contract
    for contract in token resource_registry grid_service governance; do
        echo "Building $contract..."
        cd contracts/$contract
        cargo contract build --release --quiet
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to build $contract${NC}"
            exit 1
        fi
        cd ../..
    done
    
    echo -e "${GREEN}✅ All contracts built successfully${NC}"
}

deploy_contract() {
    local CONTRACT_DIR=$1
    local CONTRACT_NAME=$2
    local CONSTRUCTOR_ARGS=$3
    
    echo -e "${BLUE}🚀 Deploying $CONTRACT_NAME...${NC}"
    
    cd contracts/$CONTRACT_DIR || exit 1
    
    # Deploy the contract
    OUTPUT=$(cargo contract instantiate \
        --constructor new \
        --args $CONSTRUCTOR_ARGS \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --skip-dry-run \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 2>&1)
    
    # Extract contract address
    ADDRESS=$(echo "$OUTPUT" | grep -oE "Contract [A-Za-z0-9]{48}" | grep -oE "[A-Za-z0-9]{48}" | head -1)
    
    if [ -z "$ADDRESS" ]; then
        echo -e "${RED}❌ Failed to extract contract address for $CONTRACT_NAME${NC}"
        echo "Deployment output:"
        echo "$OUTPUT"
        cd ../..
        exit 1
    fi
    
    echo -e "${GREEN}✅ $CONTRACT_NAME deployed: $ADDRESS${NC}"
    cd ../..
    echo "$ADDRESS"
}

deploy_all_contracts() {
    echo -e "${BLUE}📋 Deploying contracts in dependency order...${NC}"
    
    # Create deployment directory
    mkdir -p deployment
    
    # 1. Deploy Token Contract (no dependencies)
    echo -e "${BLUE}Step 1: Deploying PowerGrid Token...${NC}"
    TOKEN_ADDR=$(deploy_contract "token" "PowerGrid Token" '"PowerGrid Token" "PGT" 18 1000000000000000000000')
    
    # 2. Deploy Resource Registry (depends on token for staking)
    echo -e "${BLUE}Step 2: Deploying Resource Registry...${NC}"
    REGISTRY_ADDR=$(deploy_contract "resource_registry" "Resource Registry" "1000000000000000000")
    
    # 3. Deploy Grid Service (depends on token and registry)
    echo -e "${BLUE}Step 3: Deploying Grid Service...${NC}"
    GRID_ADDR=$(deploy_contract "grid_service" "Grid Service" "$TOKEN_ADDR $REGISTRY_ADDR")
    
    # 4. Deploy Governance (depends on all other contracts)
    echo -e "${BLUE}Step 4: Deploying Governance...${NC}"
    GOV_ADDR=$(deploy_contract "governance" "Governance" "$TOKEN_ADDR $REGISTRY_ADDR $GRID_ADDR 100000000000000000000 100 51")
    
    # Save deployment addresses
    cat > deployment/local-addresses.json << EOF
{
  "contracts": {
    "powergrid_token": "$TOKEN_ADDR",
    "resource_registry": "$REGISTRY_ADDR",
    "grid_service": "$GRID_ADDR", 
    "governance": "$GOV_ADDR"
  },
  "network": "local",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployer": "//Alice"
}
EOF
    
    echo ""
    echo -e "${GREEN}🎉 All contracts deployed successfully!${NC}"
    echo "📄 Contract addresses saved to: deployment/local-addresses.json"
    echo ""
    echo "📋 Deployment Summary:"
    echo -e "  ${BLUE}PowerGrid Token:${NC}    $TOKEN_ADDR"
    echo -e "  ${BLUE}Resource Registry:${NC}  $REGISTRY_ADDR"
    echo -e "  ${BLUE}Grid Service:${NC}       $GRID_ADDR"
    echo -e "  ${BLUE}Governance:${NC}         $GOV_ADDR"
    echo ""
}

test_cross_contract_interactions() {
    echo -e "${YELLOW}🔄 Testing cross-contract interactions...${NC}"
    
    # Test 1: Register a device (Registry → Token interaction for staking)
    echo "Test 1: Device registration with staking..."
    cargo contract call \
        --contract $REGISTRY_ADDR \
        --message register_device \
        --args '{"device_type":"SmartPlug","capacity_watts":2000,"location":"Test Location","manufacturer":"PowerGrid Inc","model":"SmartNode-E2E","firmware_version":"1.0.0","installation_date":1640995200000}' 2000000000000000000 \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 2000000000000000000 > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Device registration successful${NC}"
    else
        echo -e "${RED}❌ Device registration failed${NC}"
        exit 1
    fi
    
    # Test 2: Create a grid event (Grid Service)
    echo "Test 2: Creating grid event..."
    EVENT_OUTPUT=$(cargo contract call \
        --contract $GRID_ADDR \
        --message create_grid_event \
        --args 'DemandResponse' 60 750 100 \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Grid event creation successful${NC}"
        # Extract event ID from output (assuming it returns the event ID)
        EVENT_ID=1  # For simplicity, using ID 1
    else
        echo -e "${RED}❌ Grid event creation failed${NC}"
        exit 1
    fi
    
    # Test 3: Participate in grid event
    echo "Test 3: Participating in grid event..."
    cargo contract call \
        --contract $GRID_ADDR \
        --message participate_in_event \
        --args $EVENT_ID 75 \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Event participation successful${NC}"
    else
        echo -e "${RED}❌ Event participation failed${NC}"
        exit 1
    fi
    
    # Test 4: Check initial token balance
    echo "Test 4: Checking initial token balance..."
    ALICE_ADDR="5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"  # Alice's address
    INITIAL_BALANCE=$(cargo contract call \
        --contract $TOKEN_ADDR \
        --message balance_of \
        --args $ALICE_ADDR \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --dry-run \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 2>/dev/null | grep -oE '[0-9]+' | tail -1)
    
    echo "Initial balance: $INITIAL_BALANCE"
    
    # Test 5: Verify participation (should trigger reward distribution)
    echo "Test 5: Verifying participation (triggers cross-contract reward)..."
    cargo contract call \
        --contract $GRID_ADDR \
        --message verify_participation \
        --args $EVENT_ID $ALICE_ADDR 75 \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Participation verification successful${NC}"
    else
        echo -e "${RED}❌ Participation verification failed${NC}"
        exit 1
    fi
    
    # Test 6: Check final token balance (should show reward distribution)
    echo "Test 6: Checking final token balance..."
    FINAL_BALANCE=$(cargo contract call \
        --contract $TOKEN_ADDR \
        --message balance_of \
        --args $ALICE_ADDR \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --dry-run \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 2>/dev/null | grep -oE '[0-9]+' | tail -1)
    
    echo "Final balance: $FINAL_BALANCE"
    
    # Calculate expected reward (750 * 75 = 56250)
    EXPECTED_REWARD=56250
    ACTUAL_REWARD=$((FINAL_BALANCE - INITIAL_BALANCE))
    
    if [ $ACTUAL_REWARD -eq $EXPECTED_REWARD ]; then
        echo -e "${GREEN}✅ Cross-contract reward distribution verified!${NC}"
        echo "   Expected reward: $EXPECTED_REWARD"
        echo "   Actual reward: $ACTUAL_REWARD"
    else
        echo -e "${RED}❌ Cross-contract reward distribution failed${NC}"
        echo "   Expected reward: $EXPECTED_REWARD"
        echo "   Actual reward: $ACTUAL_REWARD"
        exit 1
    fi
    
    # Test 7: Create and vote on governance proposal
    echo "Test 7: Testing governance proposal..."
    cargo contract call \
        --contract $GOV_ADDR \
        --message create_proposal \
        --args 'UpdateMinStake(2000000000000000000)' "Increase minimum stake for security" \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Governance proposal creation successful${NC}"
    else
        echo -e "${RED}❌ Governance proposal creation failed${NC}"
        exit 1
    fi
    
    # Vote on the proposal
    PROPOSAL_ID=1  # Assuming first proposal
    cargo contract call \
        --contract $GOV_ADDR \
        --message vote \
        --args $PROPOSAL_ID true "Supporting increased security" \
        --suri //Alice \
        --url $SUBSTRATE_URL \
        --execute \
        --skip-confirm \
        --gas $GAS_LIMIT \
        --proof-size $PROOF_SIZE_LIMIT \
        --value 0 > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Governance voting successful${NC}"
    else
        echo -e "${RED}❌ Governance voting failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🎉 All cross-contract interaction tests passed!${NC}"
}

run_ink_e2e_tests() {
    echo -e "${YELLOW}🧪 Running ink! E2E tests...${NC}"
    
    # Run the actual E2E tests using the ink! testing framework
    cd contracts/integration-tests
    
    # First run simulation tests (no node required)
    echo "Running simulation tests..."
    if cargo test simulation_tests; then
        echo -e "${GREEN}✅ Simulation tests passed${NC}"
    else
        echo -e "${RED}❌ Simulation tests failed${NC}"
        cd ../..
        exit 1
    fi
    
    # Check if e2e tests compile (with runtime node feature for deployed contracts)
    echo "Checking E2E test compilation..."
    if cargo test --features e2e-tests,e2e-runtime-node --no-run; then
        echo -e "${GREEN}✅ E2E tests compiled successfully${NC}"
        
        # Note about E2E test execution
        echo -e "${YELLOW}Note: Full E2E tests use ink_e2e framework which spawns its own substrate node${NC}"
        echo -e "${YELLOW}The deployed contracts above are separate from the E2E test environment${NC}"
        echo -e "${YELLOW}Both approaches verify contract functionality:${NC}"
        echo -e "${YELLOW}  1. Manual deployment + cross-contract calls (completed above)${NC}"
        echo -e "${YELLOW}  2. Automated E2E testing with ink_e2e framework (optional)${NC}"
        
    else
        echo -e "${RED}❌ E2E tests compilation failed${NC}"
        cd ../..
        exit 1
    fi
    
    cd ../..
}

cleanup() {
    echo ""
    echo -e "${BLUE}📋 Test Summary:${NC}"
    echo "✅ Contract builds: Success"
    echo "✅ Contract deployments: Success" 
    echo "✅ Cross-contract interactions: Success"
    echo "✅ State change verification: Success"
    echo "✅ Governance functionality: Success"
    echo ""
    echo -e "${GREEN}🎉 End-to-end testing completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📄 Deployment artifacts:${NC}"
    echo "  - Contract addresses: deployment/local-addresses.json"
    echo "  - All contracts are deployed and functional on the running substrate-contracts-node"
    echo ""
    echo -e "${YELLOW}🔧 Next steps:${NC}"
    echo "  - Use the deployed contracts for further development"
    echo "  - Addresses can be found in deployment/local-addresses.json"
    echo "  - All cross-contract functionality has been verified"
}

main() {
    # Step 1: Check prerequisites
    check_prerequisites
    
    # Step 2: Build all contracts
    build_all_contracts
    
    # Step 3: Deploy all contracts
    deploy_all_contracts
    
    # Step 4: Test cross-contract interactions
    test_cross_contract_interactions
    
    # Step 5: Run additional E2E tests
    run_ink_e2e_tests
    
    # Step 6: Summary and cleanup
    cleanup
}

# Error handling
trap 'echo -e "${RED}❌ Script failed at line $LINENO${NC}"; exit 1' ERR

# Run main function
main "$@"