#!/bin/bash

# Frontend Test Script
# Tests that the frontend is accessible and functional

set -e

FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
PASSED=0
FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_result() {
    if [ "$1" = "pass" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $2 - $3"
        FAILED=$((FAILED + 1))
    fi
}

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   Frontend Test Suite${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Test 1: Frontend Accessible
echo "Testing: Frontend Accessibility"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
if [ "$HTTP_CODE" = "200" ]; then
    print_result "pass" "Frontend returns HTTP 200"
else
    print_result "fail" "Frontend accessibility" "Got HTTP $HTTP_CODE"
fi

# Test 2: Frontend Contains Title
echo "Testing: Page Contains Title"
RESPONSE=$(curl -s "$FRONTEND_URL")
if echo "$RESPONSE" | grep -q "Metrics Dashboard"; then
    print_result "pass" "Page contains Metrics Dashboard title"
else
    print_result "fail" "Page title" "Title not found in HTML"
fi

# Test 3: Frontend Loads CSS
echo "Testing: CSS Loading"
if echo "$RESPONSE" | grep -q "_next"; then
    print_result "pass" "Next.js assets referenced"
else
    print_result "fail" "CSS loading" "Next.js assets not found"
fi

# Test 4: Frontend Contains Interactive Elements
echo "Testing: Interactive Elements"
if echo "$RESPONSE" | grep -qi "button\|click"; then
    print_result "pass" "Interactive elements present"
else
    # Check for React hydration markers instead
    if echo "$RESPONSE" | grep -q "__NEXT"; then
        print_result "pass" "React/Next.js hydration markers present"
    else
        print_result "fail" "Interactive elements" "No buttons or click handlers found"
    fi
fi

# Test 5: Response Time
echo "Testing: Response Time"
START=$(date +%s%3N)
curl -s "$FRONTEND_URL" > /dev/null
END=$(date +%s%3N)
DURATION=$((END - START))
if [ "$DURATION" -lt 3000 ]; then
    print_result "pass" "Response time acceptable (${DURATION}ms)"
else
    print_result "fail" "Response time" "Took ${DURATION}ms (> 3000ms)"
fi

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   Test Results${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi

