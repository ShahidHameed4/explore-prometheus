#!/bin/bash

# Backend API Test Script
# Tests all endpoints and validates responses

set -e

API_URL="${API_URL:-http://localhost:8080}"
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
echo -e "${YELLOW}   Backend API Test Suite${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Test 1: Health Check
echo "Testing: Health Check"
RESPONSE=$(curl -s "$API_URL/health")
if echo "$RESPONSE" | grep -q '"status":"healthy"'; then
    print_result "pass" "Health endpoint returns healthy status"
else
    print_result "fail" "Health endpoint" "Expected healthy status"
fi

# Test 2: Initial Status
echo "Testing: Status Endpoint"
RESPONSE=$(curl -s "$API_URL/api/status")
if echo "$RESPONSE" | grep -q '"users"'; then
    print_result "pass" "Status endpoint returns user count"
else
    print_result "fail" "Status endpoint" "Missing users field"
fi

# Test 3: User Join
echo "Testing: User Join"
RESPONSE=$(curl -s -X POST "$API_URL/api/user/join")
if echo "$RESPONSE" | grep -q '"message":"User joined"'; then
    print_result "pass" "User join creates new user"
else
    print_result "fail" "User join" "Expected User joined message"
fi

# Test 4: User Leave
echo "Testing: User Leave"
curl -s -X POST "$API_URL/api/user/join" > /dev/null  # Ensure at least 1 user
RESPONSE=$(curl -s -X POST "$API_URL/api/user/leave")
if echo "$RESPONSE" | grep -q '"message":"User left"'; then
    print_result "pass" "User leave decrements users"
else
    print_result "fail" "User leave" "Expected User left message"
fi

# Test 5: Create Task
echo "Testing: Create Task"
RESPONSE=$(curl -s -X POST "$API_URL/api/task/create")
if echo "$RESPONSE" | grep -q '"taskType"'; then
    print_result "pass" "Task creation returns task type"
else
    print_result "fail" "Task creation" "Missing taskType field"
fi

# Test 6: Complete Task
echo "Testing: Complete Task"
RESPONSE=$(curl -s -X POST "$API_URL/api/task/complete")
if echo "$RESPONSE" | grep -q '"message":"Task completed"'; then
    print_result "pass" "Task completion works"
else
    print_result "fail" "Task completion" "Expected Task completed message"
fi

# Test 7: Place Order
echo "Testing: Place Order"
RESPONSE=$(curl -s -X POST "$API_URL/api/order/place")
if echo "$RESPONSE" | grep -q '"value"'; then
    print_result "pass" "Order placement returns value"
else
    print_result "fail" "Order placement" "Missing value field"
fi

# Test 8: Simulate Load
echo "Testing: Simulate Load"
RESPONSE=$(curl -s -X POST "$API_URL/api/simulate/load")
if echo "$RESPONSE" | grep -q '"cpuLoad"'; then
    print_result "pass" "Load simulation returns CPU load"
else
    print_result "fail" "Load simulation" "Missing cpuLoad field"
fi

# Test 9: Reset
echo "Testing: Reset"
RESPONSE=$(curl -s -X POST "$API_URL/api/reset")
if echo "$RESPONSE" | grep -q '"message":"State reset"'; then
    print_result "pass" "Reset clears state"
else
    print_result "fail" "Reset" "Expected State reset message"
fi

# Test 10: Verify Reset
echo "Testing: Verify Reset"
RESPONSE=$(curl -s "$API_URL/api/status")
USERS=$(echo "$RESPONSE" | grep -o '"users":[0-9]*' | cut -d':' -f2)
if [ "$USERS" = "0" ]; then
    print_result "pass" "Users reset to 0 after reset"
else
    print_result "fail" "Users reset" "Expected 0 users, got $USERS"
fi

# Test 11: Metrics Endpoint
echo "Testing: Prometheus Metrics"
RESPONSE=$(curl -s "$API_URL/metrics")
if echo "$RESPONSE" | grep -q 'app_http_requests_total'; then
    print_result "pass" "Prometheus metrics exposed"
else
    print_result "fail" "Prometheus metrics" "Custom metrics not found"
fi

# Test 12: Active Users Metric
echo "Testing: Active Users Metric"
curl -s -X POST "$API_URL/api/user/join" > /dev/null
curl -s -X POST "$API_URL/api/user/join" > /dev/null
RESPONSE=$(curl -s "$API_URL/metrics")
if echo "$RESPONSE" | grep -q 'app_active_users 2'; then
    print_result "pass" "Active users metric tracks correctly"
else
    print_result "fail" "Active users metric" "Expected 2 users"
fi

# Test 13: Task Counter Metric
echo "Testing: Task Counter Metric"
curl -s -X POST "$API_URL/api/task/create" > /dev/null
RESPONSE=$(curl -s "$API_URL/metrics")
if echo "$RESPONSE" | grep -q 'app_tasks_total'; then
    print_result "pass" "Task counter metric exists"
else
    print_result "fail" "Task counter metric" "Metric not found"
fi

# Test 14: Order Histogram Metric
echo "Testing: Order Histogram Metric"
curl -s -X POST "$API_URL/api/order/place" > /dev/null
RESPONSE=$(curl -s "$API_URL/metrics")
if echo "$RESPONSE" | grep -q 'app_order_value_dollars_bucket'; then
    print_result "pass" "Order histogram metric exists"
else
    print_result "fail" "Order histogram metric" "Metric not found"
fi

# Test 15: System Load Metric
echo "Testing: System Load Metric"
curl -s -X POST "$API_URL/api/simulate/load" > /dev/null
RESPONSE=$(curl -s "$API_URL/metrics")
if echo "$RESPONSE" | grep -q 'app_system_load{component="cpu"}'; then
    print_result "pass" "System load metric with labels exists"
else
    print_result "fail" "System load metric" "Metric with labels not found"
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

