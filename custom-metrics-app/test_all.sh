#!/bin/bash

# Master Test Script
# Runs all test suites

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Custom Metrics App - Test Suite      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

BACKEND_OK=false
FRONTEND_OK=false

# Check if backend is running
echo -e "${YELLOW}Checking services...${NC}"
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend is running on port 8080"
    BACKEND_OK=true
else
    echo -e "${RED}✗${NC} Backend not running on port 8080"
    echo "  Start with: cd backend && go run main.go"
fi

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Frontend is running on port 3000"
    FRONTEND_OK=true
else
    echo -e "${RED}✗${NC} Frontend not running on port 3000"
    echo "  Start with: cd frontend && npm run dev"
fi

echo ""

# Run tests if services are available
OVERALL_EXIT=0

if [ "$BACKEND_OK" = true ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Running Backend Tests${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    if bash "$SCRIPT_DIR/test_backend.sh"; then
        echo ""
    else
        OVERALL_EXIT=1
    fi
else
    echo -e "${YELLOW}Skipping backend tests (service not running)${NC}"
    OVERALL_EXIT=1
fi

echo ""

if [ "$FRONTEND_OK" = true ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Running Frontend Tests${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    if bash "$SCRIPT_DIR/test_frontend.sh"; then
        echo ""
    else
        OVERALL_EXIT=1
    fi
else
    echo -e "${YELLOW}Skipping frontend tests (service not running)${NC}"
    OVERALL_EXIT=1
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
if [ $OVERALL_EXIT -eq 0 ]; then
    echo -e "${CYAN}║${NC}   ${GREEN}All Test Suites Passed!${NC}              ${CYAN}║${NC}"
else
    echo -e "${CYAN}║${NC}   ${RED}Some Tests Failed${NC}                     ${CYAN}║${NC}"
fi
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"

exit $OVERALL_EXIT

