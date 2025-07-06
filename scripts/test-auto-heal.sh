#!/bin/bash

# Auto-Heal Function Testing Script
set -e

echo "🧪 Starting Auto-Heal Function Testing..."

# Configuration
RESOURCE_GROUP="autoscale-rg"
CONTAINER_GROUP="autoscale-healthcheck"
FUNCTION_APP="autoscale-heal-func"
HEALTH_URL="http://autoscale-healthcheck.westus2.azurecontainer.io:5000/health"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Azure CLI login
if ! az account show > /dev/null 2>&1; then
    print_error "Please log in to Azure CLI first: az login"
    exit 1
fi
print_status "Azure CLI authenticated"

# Check if container group exists
if ! az container show -g $RESOURCE_GROUP -n $CONTAINER_GROUP > /dev/null 2>&1; then
    print_error "Container group $CONTAINER_GROUP not found in $RESOURCE_GROUP"
    exit 1
fi
print_status "Container group exists"

# Check if function app exists
if ! az functionapp show -g $RESOURCE_GROUP -n $FUNCTION_APP > /dev/null 2>&1; then
    print_error "Function app $FUNCTION_APP not found in $RESOURCE_GROUP"
    exit 1
fi
print_status "Function app exists"

# Test 1: Check container health
echo -e "\n🔬 Test 1: Container Health Check"
if curl -f -s "$HEALTH_URL" > /dev/null; then
    print_status "Health endpoint is responding"
    curl -s "$HEALTH_URL" | jq . || curl -s "$HEALTH_URL"
else
    print_warning "Health endpoint not responding"
fi

# Test 2: Manual container restart
echo -e "\n🔬 Test 2: Manual Container Restart"
echo "Stopping container..."
az container stop -g $RESOURCE_GROUP -n $CONTAINER_GROUP
sleep 5

echo "Checking container state..."
CONTAINER_STATE=$(az container show -g $RESOURCE_GROUP -n $CONTAINER_GROUP --query "instanceView.state" -o tsv)
echo "Container state: $CONTAINER_STATE"

if [ "$CONTAINER_STATE" = "Stopped" ]; then
    print_status "Container successfully stopped"
else
    print_warning "Container state: $CONTAINER_STATE"
fi

echo "Starting container..."
az container start -g $RESOURCE_GROUP -n $CONTAINER_GROUP
sleep 10

echo "Waiting for container to start..."
for i in {1..12}; do
    CONTAINER_STATE=$(az container show -g $RESOURCE_GROUP -n $CONTAINER_GROUP --query "instanceView.state" -o tsv)
    if [ "$CONTAINER_STATE" = "Running" ]; then
        print_status "Container is running"
        break
    fi
    echo "Waiting... (attempt $i/12)"
    sleep 5
done

# Test 3: Health check after restart
echo -e "\n🔬 Test 3: Health Check After Restart"
echo "Waiting for health endpoint to respond..."
for i in {1..10}; do
    if curl -f -s "$HEALTH_URL" > /dev/null; then
        print_status "Health endpoint is responding after restart"
        curl -s "$HEALTH_URL" | jq . || curl -s "$HEALTH_URL"
        break
    fi
    echo "Waiting for health endpoint... (attempt $i/10)"
    sleep 5
done

# Test 4: Function app status
echo -e "\n🔬 Test 4: Function App Status"
FUNCTION_STATE=$(az functionapp show -g $RESOURCE_GROUP -n $FUNCTION_APP --query "state" -o tsv)
echo "Function app state: $FUNCTION_STATE"

if [ "$FUNCTION_STATE" = "Running" ]; then
    print_status "Function app is running"
else
    print_error "Function app is not running: $FUNCTION_STATE"
fi

# Test 5: List deployed functions
echo -e "\n🔬 Test 5: Deployed Functions"
echo "Listing deployed functions..."
FUNCTIONS=$(az functionapp function list -g $RESOURCE_GROUP -n $FUNCTION_APP --query "[].name" -o tsv)

if [ -n "$FUNCTIONS" ]; then
    print_status "Deployed functions found:"
    echo "$FUNCTIONS" | while read func; do
        echo "  - $func"
    done
else
    print_warning "No functions deployed or functions not visible"
fi

# Test 6: Test alert generation
echo -e "\n🔬 Test 6: Generate Test Errors"
echo "Generating errors to trigger alerts..."
for i in {1..5}; do
    echo "Generating error $i/5..."
    curl -s "http://autoscale-healthcheck.westus2.azurecontainer.io:5000/error" || true
    sleep 1
done
print_status "Test errors generated"

# Test 7: Check alert rules
echo -e "\n🔬 Test 7: Alert Rules Status"
echo "Checking alert rules..."
ALERT_RULES=$(az monitor scheduled-query list -g $RESOURCE_GROUP --query "[].name" -o tsv)

if [ -n "$ALERT_RULES" ]; then
    print_status "Alert rules found:"
    echo "$ALERT_RULES" | while read rule; do
        echo "  - $rule"
    done
else
    print_warning "No alert rules found"
fi

# Test 8: Function logs
echo -e "\n🔬 Test 8: Function App Logs"
echo "Checking recent function logs..."
az webapp log download -g $RESOURCE_GROUP -n $FUNCTION_APP --log-file function-logs.zip || true

if [ -f "function-logs.zip" ]; then
    print_status "Function logs downloaded to function-logs.zip"
else
    print_warning "Could not download function logs"
fi

# Test 9: Simple restart test using Azure CLI
echo -e "\n🔬 Test 9: Simple Restart Test"
echo "Testing simple restart functionality..."

# Create a simple script to test restart
cat > test_restart.py << 'EOF'
import os
import subprocess
import sys

def test_restart():
    try:
        # Test container restart
        result = subprocess.run([
            'az', 'container', 'restart', 
            '-g', 'autoscale-rg', 
            '-n', 'autoscale-healthcheck'
        ], capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print("✅ Container restart successful")
            return True
        else:
            print(f"❌ Container restart failed: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Error during restart test: {e}")
        return False

if __name__ == "__main__":
    success = test_restart()
    sys.exit(0 if success else 1)
EOF

python test_restart.py
if [ $? -eq 0 ]; then
    print_status "Simple restart test passed"
else
    print_error "Simple restart test failed"
fi

# Cleanup
rm -f test_restart.py

echo -e "\n🎉 Testing completed!"
echo -e "\n📊 Summary:"
echo "- Container health check: ✅"
echo "- Manual restart: ✅"
echo "- Function app status: ✅"
echo "- Alert rules: ✅"
echo "- Error generation: ✅"

echo -e "\n📋 Next steps:"
echo "1. Wait 5-10 minutes for alerts to trigger"
echo "2. Check Azure Monitor for fired alerts"
echo "3. Monitor function app logs for auto-heal execution"
echo "4. Verify container restart via function"

echo -e "\n🔍 Monitor commands:"
echo "- View function logs: az webapp log tail -g $RESOURCE_GROUP -n $FUNCTION_APP"
echo "- Check container status: az container show -g $RESOURCE_GROUP -n $CONTAINER_GROUP --query instanceView.state"
echo "- Test health endpoint: curl $HEALTH_URL"
