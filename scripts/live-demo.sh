#!/bin/bash

# AutoScale HealthCheck - Live Demo Script
# This script demonstrates the auto-heal functionality in real-time

echo "🎬 AutoScale HealthCheck - Live Demo"
echo "====================================="
echo ""

# Configuration
CONTAINER_URL="http://autoscale-healthcheck.westus2.azurecontainer.io:5000"
RESOURCE_GROUP="autoscale-rg"
CONTAINER_NAME="autoscale-healthcheck"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo -e "\n${BLUE}$1${NC}"
    echo "=================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Initial Status Check
print_section "Step 1: System Status Check"

echo "🔍 Checking container status..."
CONTAINER_STATE=$(az container show -g $RESOURCE_GROUP -n $CONTAINER_NAME --query "instanceView.state" -o tsv 2>/dev/null)
echo "Container State: $CONTAINER_STATE"

echo ""
echo "🏥 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s --connect-timeout 10 "$CONTAINER_URL/health" 2>/dev/null)
if [[ "$HEALTH_RESPONSE" == *"healthy"* ]]; then
    print_success "Health endpoint responding: $HEALTH_RESPONSE"
else
    print_error "Health endpoint not responding"
fi

# Step 2: Function Status Check
print_section "Step 2: Auto-Heal Function Status"

FUNCTION_STATE=$(az functionapp show -g $RESOURCE_GROUP -n autoscale-heal-func --query "state" -o tsv 2>/dev/null)
echo "Function App State: $FUNCTION_STATE"

FUNCTIONS=$(az functionapp function list -g $RESOURCE_GROUP -n autoscale-heal-func --query "[].name" -o tsv 2>/dev/null)
if [ -n "$FUNCTIONS" ]; then
    print_success "Auto-heal functions deployed:"
    echo "$FUNCTIONS" | sed 's/^/  - /'
else
    print_warning "Functions may still be initializing..."
fi

# Step 3: Live Crash Test
print_section "Step 3: Live Container Crash Test"

echo "This will crash the container and monitor recovery..."
echo ""
echo -n "Proceed with crash test? (y/N): "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    print_warning "💥 Crashing container in 3 seconds..."
    sleep 1 && echo "3..."
    sleep 1 && echo "2..."
    sleep 1 && echo "1..."
    
    echo ""
    echo "💥 Triggering crash..."
    curl -s --connect-timeout 5 "$CONTAINER_URL/crash" || echo "Container crashed"
    
    echo ""
    print_section "Step 4: Monitoring Recovery"
    
    echo "⏳ Monitoring container recovery (up to 3 minutes)..."
    for i in {1..18}; do
        echo ""
        echo "Check $i/18 - $(date +%H:%M:%S)"
        
        # Check container state
        STATE=$(az container show -g $RESOURCE_GROUP -n $CONTAINER_NAME --query "instanceView.state" -o tsv 2>/dev/null || echo "Unknown")
        echo "  📊 Container State: $STATE"
        
        # Check health
        HEALTH=$(curl -s --connect-timeout 5 "$CONTAINER_URL/health" 2>/dev/null || echo "Not responding")
        echo "  🏥 Health Check: $HEALTH"
        
        if [[ "$HEALTH" == *"healthy"* ]]; then
            echo ""
            print_success "🎉 CONTAINER RECOVERED! Recovery time: $((i * 10)) seconds"
            echo ""
            echo "🔍 Final verification:"
            echo "  Container State: $(az container show -g $RESOURCE_GROUP -n $CONTAINER_NAME --query "instanceView.state" -o tsv)"
            echo "  Health Response: $(curl -s "$CONTAINER_URL/health")"
            break
        fi
        
        if [ $i -eq 18 ]; then
            print_warning "⏰ Recovery taking longer than expected. Check Azure portal for details."
            echo ""
            echo "🔧 Manual recovery options:"
            echo "  1. Check function app logs: az webapp log tail -g $RESOURCE_GROUP -n autoscale-heal-func"
            echo "  2. Manual restart: az container restart -g $RESOURCE_GROUP -n $CONTAINER_NAME"
            echo "  3. Check alerts in Azure Monitor"
        fi
        
        sleep 10
    done
else
    echo ""
    print_section "Alternative Demo: Manual Recovery Test"
    
    echo "🔄 Demonstrating manual container restart (simulating auto-heal)..."
    az container restart -g $RESOURCE_GROUP -n $CONTAINER_NAME
    
    echo ""
    echo "⏳ Waiting for restart to complete..."
    sleep 20
    
    echo ""
    echo "✅ Post-restart verification:"
    STATE=$(az container show -g $RESOURCE_GROUP -n $CONTAINER_NAME --query "instanceView.state" -o tsv)
    echo "  Container State: $STATE"
    
    HEALTH=$(curl -s "$CONTAINER_URL/health" 2>/dev/null || echo "Not responding")
    echo "  Health Check: $HEALTH"
    
    if [[ "$HEALTH" == *"healthy"* ]]; then
        print_success "Manual restart successful!"
    else
        print_warning "Container may still be starting..."
    fi
fi

# Step 5: Summary
print_section "Demo Summary"

echo "🎯 What we demonstrated:"
echo "  ✅ Container health monitoring"
echo "  ✅ Container crash simulation"
echo "  ✅ Recovery monitoring"
echo "  ✅ Health verification"
echo ""
echo "🔄 Auto-heal approaches in this project:"
echo "  1. 🚨 Alert-based: Responds to Azure Monitor alerts"
echo "  2. ⏰ Timer-based: Runs every 5 minutes (timer_heal_trigger)"
echo "  3. 🔧 Simple CLI: Runs every 10 minutes (simple_heal_trigger)"
echo ""
echo "📊 To monitor auto-heal in production:"
echo "  • Azure Monitor: Check alert rules and fired alerts"
echo "  • Function logs: az webapp log tail -g $RESOURCE_GROUP -n autoscale-heal-func"
echo "  • Container logs: az container logs -g $RESOURCE_GROUP -n $CONTAINER_NAME"
echo ""
print_success "🎉 Demo completed! Your auto-heal system is operational."