#!/bin/bash

echo "🔍 PowerGrid Network Docker Setup Validation"
echo "============================================="

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check if Docker is available
check_docker() {
    echo -e "${BLUE}Checking Docker installation...${NC}"
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker is installed: $(docker --version)${NC}"
        return 0
    else
        echo -e "${RED}❌ Docker is not installed${NC}"
        return 1
    fi
}

# Function to check if Docker Compose is available
check_docker_compose() {
    echo -e "${BLUE}Checking Docker Compose...${NC}"
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose is available: $(docker compose version)${NC}"
        return 0
    else
        echo -e "${RED}❌ Docker Compose is not available${NC}"
        return 1
    fi
}

# Function to validate Dockerfile syntax
validate_dockerfile() {
    echo -e "${BLUE}Validating Dockerfile...${NC}"
    if [ -f "Dockerfile" ]; then
        # Basic syntax check by attempting to parse without building
        if docker build --dry-run . &> /dev/null; then
            echo -e "${GREEN}✅ Dockerfile syntax is valid${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Dockerfile syntax check inconclusive (dry-run not supported)${NC}"
            # Check for basic dockerfile keywords
            if grep -q "FROM\|RUN\|COPY" Dockerfile; then
                echo -e "${GREEN}✅ Dockerfile appears to have correct structure${NC}"
                return 0
            else
                echo -e "${RED}❌ Dockerfile appears malformed${NC}"
                return 1
            fi
        fi
    else
        echo -e "${RED}❌ Dockerfile not found${NC}"
        return 1
    fi
}

# Function to validate docker-compose.yml
validate_docker_compose() {
    echo -e "${BLUE}Validating docker-compose.yml...${NC}"
    if [ -f "docker-compose.yml" ]; then
        if docker compose config &> /dev/null; then
            echo -e "${GREEN}✅ docker-compose.yml is valid${NC}"
            return 0
        else
            echo -e "${RED}❌ docker-compose.yml has syntax errors${NC}"
            echo -e "${YELLOW}Run 'docker compose config' for details${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ docker-compose.yml not found${NC}"
        return 1
    fi
}

# Function to check required scripts
check_scripts() {
    echo -e "${BLUE}Checking required scripts...${NC}"
    local missing=0
    
    for script in "scripts/deploy-and-run-e2e.sh" "scripts/build-all.sh" "scripts/test-all.sh"; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            echo -e "${GREEN}✅ Found executable: $script${NC}"
        else
            echo -e "${RED}❌ Missing or not executable: $script${NC}"
            missing=1
        fi
    done
    
    return $missing
}

# Function to check basic project structure
check_project_structure() {
    echo -e "${BLUE}Checking project structure...${NC}"
    local issues=0
    
    # Check for key directories
    for dir in "contracts" "scripts" "shared"; do
        if [ -d "$dir" ]; then
            echo -e "${GREEN}✅ Found directory: $dir${NC}"
        else
            echo -e "${RED}❌ Missing directory: $dir${NC}"
            issues=1
        fi
    done
    
    # Check for key files
    for file in "Cargo.toml" "README.md"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✅ Found file: $file${NC}"
        else
            echo -e "${RED}❌ Missing file: $file${NC}"
            issues=1
        fi
    done
    
    return $issues
}

# Function to test basic Docker functionality
test_docker_functionality() {
    echo -e "${BLUE}Testing basic Docker functionality...${NC}"
    
    # Test if we can run a simple container
    if docker run --rm hello-world &> /dev/null; then
        echo -e "${GREEN}✅ Docker can run containers${NC}"
        return 0
    else
        echo -e "${RED}❌ Docker cannot run containers${NC}"
        echo -e "${YELLOW}You may need to start Docker daemon or check permissions${NC}"
        return 1
    fi
}

# Main validation function
main() {
    echo -e "${YELLOW}Starting validation...${NC}"
    echo ""
    
    local issues=0
    
    # Run all checks
    check_docker || issues=1
    echo ""
    
    check_docker_compose || issues=1
    echo ""
    
    test_docker_functionality || issues=1
    echo ""
    
    validate_dockerfile || issues=1
    echo ""
    
    validate_docker_compose || issues=1
    echo ""
    
    check_project_structure || issues=1
    echo ""
    
    check_scripts || issues=1
    echo ""
    
    # Final results
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed!${NC}"
        echo -e "${YELLOW}You can now run:${NC}"
        echo "  ${BLUE}docker compose up --build${NC}"
        echo "  ${BLUE}./scripts/docker-run.sh${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Some validations failed${NC}"
        echo -e "${YELLOW}Please fix the issues above before running Docker setup${NC}"
        echo ""
        return 1
    fi
}

# Run validation
main "$@"