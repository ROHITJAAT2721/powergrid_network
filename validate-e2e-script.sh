#!/bin/bash

# Quick validation script for deploy-and-run-e2e.sh
# Tests the script logic without actual deployment

echo "🧪 Testing deploy-and-run-e2e.sh script logic..."

# Test 1: Check if script exists and is executable
if [ -x "./deploy-and-run-e2e.sh" ]; then
    echo "✅ Script exists and is executable"
else
    echo "❌ Script not found or not executable"
    exit 1
fi

# Test 2: Check script syntax
if bash -n ./deploy-and-run-e2e.sh; then
    echo "✅ Script syntax is valid"
else
    echo "❌ Script has syntax errors"
    exit 1
fi

# Test 3: Check if all required functions are defined
REQUIRED_FUNCTIONS=("check_prerequisites" "build_all_contracts" "deploy_all_contracts" "test_cross_contract_interactions" "run_ink_e2e_tests" "cleanup" "main")

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if grep -q "^${func}()" ./deploy-and-run-e2e.sh; then
        echo "✅ Function $func is defined"
    else
        echo "❌ Function $func is missing"
        exit 1
    fi
done

# Test 4: Check if script has proper error handling
if grep -q "set -e" ./deploy-and-run-e2e.sh; then
    echo "✅ Script has error handling (set -e)"
else
    echo "❌ Script missing error handling"
fi

# Test 5: Check if script has proper color definitions
COLORS=("GREEN" "BLUE" "YELLOW" "RED" "NC")
for color in "${COLORS[@]}"; do
    if grep -q "^${color}=" ./deploy-and-run-e2e.sh; then
        echo "✅ Color $color is defined"
    else
        echo "❌ Color $color is missing"
        exit 1
    fi
done

# Test 6: Check contract directories exist
CONTRACTS=("token" "resource_registry" "grid_service" "governance")
for contract in "${CONTRACTS[@]}"; do
    if [ -d "contracts/$contract" ]; then
        echo "✅ Contract directory $contract exists"
    else
        echo "❌ Contract directory $contract is missing"
        exit 1
    fi
done

# Test 7: Check integration tests exist
if [ -f "contracts/integration-tests/Cargo.toml" ]; then
    echo "✅ Integration tests package exists"
else
    echo "❌ Integration tests package is missing"
    exit 1
fi

# Test 8: Check if E2E deployment guide exists
if [ -f "E2E_DEPLOYMENT_GUIDE.md" ]; then
    echo "✅ E2E deployment guide exists"
else
    echo "❌ E2E deployment guide is missing"
    exit 1
fi

echo ""
echo "🎉 All validation tests passed!"
echo "✅ deploy-and-run-e2e.sh script is ready for use"
echo ""
echo "📋 Next steps to test with actual deployment:"
echo "1. Install substrate-contracts-node and cargo-contract"
echo "2. Start substrate-contracts-node with: substrate-contracts-node --dev --tmp"
echo "3. Run: ./deploy-and-run-e2e.sh"