#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Todo List Application - Container Tests"
echo "========================================="
echo ""

# Function to check if a command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
        return 0
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# Function to wait for a service to be ready
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Waiting for $service to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✓ $service is ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ $service failed to start after $max_attempts seconds${NC}"
    return 1
}

# Test 1: Check if Docker and Docker Compose are installed
echo "1. Checking Prerequisites..."
echo "----------------------------"
docker --version > /dev/null 2>&1
check_status "Docker is installed"

docker-compose --version > /dev/null 2>&1
check_status "Docker Compose is installed"
echo ""

# Test 2: Check if containers are running
echo "2. Checking Container Status..."
echo "-------------------------------"
docker-compose ps --services --filter "status=running" | grep -q "mongodb"
check_status "MongoDB container is running"

docker-compose ps --services --filter "status=running" | grep -q "backend"
check_status "Backend container is running"

docker-compose ps --services --filter "status=running" | grep -q "frontend"
check_status "Frontend container is running"
echo ""

# Test 3: Check service connectivity
echo "3. Checking Service Connectivity..."
echo "-----------------------------------"

# Wait for services to be ready
wait_for_service "MongoDB" 27017
wait_for_service "Backend" 3000
wait_for_service "Frontend" 80
echo ""

# Test 4: Test Backend API Health
echo "4. Testing Backend API..."
echo "-------------------------"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Backend health check passed (HTTP $response)${NC}"
    
    # Get the actual response
    health_response=$(curl -s http://localhost:3000/)
    echo -e "${GREEN}  Response: $health_response${NC}"
else
    echo -e "${RED}✗ Backend health check failed (HTTP $response)${NC}"
fi

# Test Backend API endpoints
echo ""
echo "Testing API Endpoints:"

# Test GET todos
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/gettodos)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ GET /api/gettodos endpoint is working${NC}"
else
    echo -e "${RED}✗ GET /api/gettodos endpoint failed (HTTP $response)${NC}"
fi

# Test POST todo
test_todo='{"title":"Test Todo from Script","description":"This is a test todo created by the testing script"}'
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/todos \
    -H "Content-Type: application/json" \
    -d "$test_todo")
if [ "$response" = "201" ]; then
    echo -e "${GREEN}✓ POST /api/todos endpoint is working${NC}"
else
    echo -e "${RED}✗ POST /api/todos endpoint failed (HTTP $response)${NC}"
fi
echo ""

# Test 5: Test Frontend
echo "5. Testing Frontend..."
echo "----------------------"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Frontend is accessible (HTTP $response)${NC}"
    
    # Check if it's actually returning HTML
    content=$(curl -s http://localhost/ | head -n 1)
    if [[ "$content" == *"<!DOCTYPE html>"* ]] || [[ "$content" == *"<html"* ]]; then
        echo -e "${GREEN}✓ Frontend is serving HTML content${NC}"
    else
        echo -e "${YELLOW}⚠ Frontend response doesn't look like HTML${NC}"
    fi
else
    echo -e "${RED}✗ Frontend is not accessible (HTTP $response)${NC}"
fi
echo ""

# Test 6: Test MongoDB Connection
echo "6. Testing MongoDB Connection..."
echo "--------------------------------"
docker-compose exec -T mongodb mongosh --quiet --eval "db.adminCommand('ping')" \
    -u root -p password123 --authenticationDatabase admin > /dev/null 2>&1
check_status "MongoDB is responding to queries"

# Check if todos database exists
docker-compose exec -T mongodb mongosh --quiet --eval "db.getMongo().getDBNames().indexOf('todos') >= 0" \
    -u root -p password123 --authenticationDatabase admin > /dev/null 2>&1
check_status "Todos database exists"
echo ""

# Test 7: Network connectivity between containers
echo "7. Testing Inter-Container Communication..."
echo "------------------------------------------"

# Test backend can reach MongoDB
docker-compose exec -T backend sh -c "nc -zv mongodb 27017" > /dev/null 2>&1
check_status "Backend can connect to MongoDB"

# Test frontend nginx can reach backend
docker-compose exec -T frontend sh -c "wget -q -O /dev/null http://backend:3000/" > /dev/null 2>&1
check_status "Frontend can connect to Backend"
echo ""

# Test 8: Check Docker resources
echo "8. Checking Docker Resources..."
echo "-------------------------------"
echo "Container Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

# Test 9: Check volumes
echo "9. Checking Docker Volumes..."
echo "-----------------------------"
volume_exists=$(docker volume ls | grep -c "mongodb_data")
if [ $volume_exists -gt 0 ]; then
    echo -e "${GREEN}✓ MongoDB data volume exists${NC}"
    
    # Get volume details
    volume_size=$(docker system df -v | grep "mongodb_data" | awk '{print $4}')
    if [ ! -z "$volume_size" ]; then
        echo -e "${GREEN}  Volume size: $volume_size${NC}"
    fi
else
    echo -e "${RED}✗ MongoDB data volume not found${NC}"
fi
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="

# Count successes and failures
total_tests=0
passed_tests=0

# Re-run all checks silently to count
docker --version > /dev/null 2>&1 && ((passed_tests++))
((total_tests++))

docker-compose --version > /dev/null 2>&1 && ((passed_tests++))
((total_tests++))

docker-compose ps --services --filter "status=running" | grep -q "mongodb" && ((passed_tests++))
((total_tests++))

docker-compose ps --services --filter "status=running" | grep -q "backend" && ((passed_tests++))
((total_tests++))

docker-compose ps --services --filter "status=running" | grep -q "frontend" && ((passed_tests++))
((total_tests++))

nc -z localhost 27017 2>/dev/null && ((passed_tests++))
((total_tests++))

nc -z localhost 3000 2>/dev/null && ((passed_tests++))
((total_tests++))

nc -z localhost 80 2>/dev/null && ((passed_tests++))
((total_tests++))

[ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)" = "200" ] && ((passed_tests++))
((total_tests++))

[ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)" = "200" ] && ((passed_tests++))
((total_tests++))

echo -e "Tests Passed: ${GREEN}$passed_tests${NC} / $total_tests"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}✓ All tests passed! The application is running correctly.${NC}"
    echo ""
    echo -e "${GREEN}You can access the application at: http://localhost${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please check the errors above.${NC}"
    echo ""
    echo "Troubleshooting tips:"
    echo "- Run 'docker-compose logs' to see detailed error messages"
    echo "- Ensure all ports (80, 3000, 27017) are not in use by other applications"
    echo "- Try 'docker-compose down' and './start.sh' to restart"
    exit 1
fi