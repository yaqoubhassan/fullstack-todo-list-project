# Todo List Application - Container Tests (Windows PowerShell Version)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Todo List Application - Container Tests" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command succeeded
function Check-Status {
    param($TestName, $Success)
    
    if ($Success) {
        Write-Host "✓ $TestName" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $TestName" -ForegroundColor Red
        return $false
    }
}

# Function to wait for a service
function Wait-ForService {
    param($ServiceName, $Port)
    
    Write-Host "Waiting for $ServiceName to be ready..." -ForegroundColor Yellow
    $attempts = 0
    $maxAttempts = 30
    
    while ($attempts -lt $maxAttempts) {
        try {
            $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet
            if ($connection) {
                Write-Host "✓ $ServiceName is ready!" -ForegroundColor Green
                return $true
            }
        } catch {}
        
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        $attempts++
    }
    
    Write-Host ""
    Write-Host "✗ $ServiceName failed to start after $maxAttempts seconds" -ForegroundColor Red
    return $false
}

$totalTests = 0
$passedTests = 0

# Test 1: Check if Docker is installed
Write-Host "1. Checking Prerequisites..." -ForegroundColor Yellow
Write-Host "----------------------------"

try {
    docker --version | Out-Null
    Check-Status "Docker is installed" $true
    $passedTests++
} catch {
    Check-Status "Docker is installed" $false
}
$totalTests++

try {
    docker-compose --version | Out-Null
    Check-Status "Docker Compose is installed" $true
    $passedTests++
} catch {
    Check-Status "Docker Compose is installed" $false
}
$totalTests++

Write-Host ""

# Test 2: Check if containers are running
Write-Host "2. Checking Container Status..." -ForegroundColor Yellow
Write-Host "-------------------------------"

$runningContainers = docker-compose ps --services --filter "status=running" 2>$null

if ($runningContainers -match "mongodb") {
    Check-Status "MongoDB container is running" $true
    $passedTests++
} else {
    Check-Status "MongoDB container is running" $false
}
$totalTests++

if ($runningContainers -match "backend") {
    Check-Status "Backend container is running" $true
    $passedTests++
} else {
    Check-Status "Backend container is running" $false
}
$totalTests++

if ($runningContainers -match "frontend") {
    Check-Status "Frontend container is running" $true
    $passedTests++
} else {
    Check-Status "Frontend container is running" $false
}
$totalTests++

Write-Host ""

# Test 3: Check service connectivity
Write-Host "3. Checking Service Connectivity..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

if (Wait-ForService "MongoDB" 27017) { $passedTests++ }
$totalTests++

if (Wait-ForService "Backend" 3000) { $passedTests++ }
$totalTests++

if (Wait-ForService "Frontend" 80) { $passedTests++ }
$totalTests++

Write-Host ""

# Test 4: Test Backend API Health
Write-Host "4. Testing Backend API..." -ForegroundColor Yellow
Write-Host "-------------------------"

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/" -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Check-Status "Backend health check passed (HTTP $($response.StatusCode))" $true
        Write-Host "  Response: $($response.Content)" -ForegroundColor Green
        $passedTests++
    } else {
        Check-Status "Backend health check failed (HTTP $($response.StatusCode))" $false
    }
} catch {
    Check-Status "Backend health check failed" $false
}
$totalTests++

Write-Host ""
Write-Host "Testing API Endpoints:"

# Test GET todos
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/gettodos" -UseBasicParsing -ErrorAction Stop
    Check-Status "GET /api/gettodos endpoint is working" $true
    $passedTests++
} catch {
    Check-Status "GET /api/gettodos endpoint failed" $false
}
$totalTests++

# Test POST todo
try {
    $body = @{
        title = "Test Todo from PowerShell Script"
        description = "This is a test todo created by the testing script"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/todos" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing `
        -ErrorAction Stop
    
    if ($response.StatusCode -eq 201) {
        Check-Status "POST /api/todos endpoint is working" $true
        $passedTests++
    } else {
        Check-Status "POST /api/todos endpoint failed" $false
    }
} catch {
    Check-Status "POST /api/todos endpoint failed" $false
}
$totalTests++

Write-Host ""

# Test 5: Test Frontend
Write-Host "5. Testing Frontend..." -ForegroundColor Yellow
Write-Host "----------------------"

try {
    $response = Invoke-WebRequest -Uri "http://localhost/" -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Check-Status "Frontend is accessible (HTTP $($response.StatusCode))" $true
        
        if ($response.Content -match "<!DOCTYPE html>" -or $response.Content -match "<html") {
            Check-Status "Frontend is serving HTML content" $true
            $passedTests++
        } else {
            Write-Host "⚠ Frontend response doesn't look like HTML" -ForegroundColor Yellow
        }
    } else {
        Check-Status "Frontend is not accessible" $false
    }
} catch {
    Check-Status "Frontend is not accessible" $false
}
$totalTests++

Write-Host ""

# Test 6: Check Docker resources
Write-Host "6. Checking Docker Resources..." -ForegroundColor Yellow
Write-Host "-------------------------------"
Write-Host "Container Resource Usage:"
docker stats --no-stream --format "table {{.Container}}`t{{.CPUPerc}}`t{{.MemUsage}}`t{{.NetIO}}"

Write-Host ""

# Test 7: Check volumes
Write-Host "7. Checking Docker Volumes..." -ForegroundColor Yellow
Write-Host "-----------------------------"

$volumes = docker volume ls
if ($volumes -match "mongodb_data") {
    Check-Status "MongoDB data volume exists" $true
    $passedTests++
} else {
    Check-Status "MongoDB data volume not found" $false
}
$totalTests++

Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "Tests Passed: " -NoNewline
Write-Host "$passedTests" -ForegroundColor Green -NoNewline
Write-Host " / $totalTests"

if ($passedTests -eq $totalTests) {
    Write-Host ""
    Write-Host "✓ All tests passed! The application is running correctly." -ForegroundColor Green
    Write-Host ""
    Write-Host "You can access the application at: http://localhost" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "✗ Some tests failed. Please check the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "- Run 'docker-compose logs' to see detailed error messages"
    Write-Host "- Ensure all ports (80, 3000, 27017) are not in use by other applications"
    Write-Host "- Try 'docker-compose down' and then 'docker-compose up --build -d' to restart"
    exit 1
}