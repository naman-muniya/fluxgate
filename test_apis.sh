#!/bin/bash

# FluxGate API Testing Script
# This script tests all available APIs in the FluxGate project

BASE_URL="http://localhost"
JWT_TOKEN=""

echo "🚀 FluxGate API Testing Script"
echo "================================"
echo ""

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo "✅ $2"
    else
        echo "❌ $2"
    fi
}

# Function to extract JWT token from response
extract_jwt() {
    echo "$1" | grep -o '"token":"[^"]*"' | cut -d'"' -f4
}

echo "1. Testing Health Checks"
echo "------------------------"

# Test Gateway Health
echo "Testing Gateway Health..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Gateway Health: $HTTP_CODE"

# Test Auth Service Health
echo "Testing Auth Service Health..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/auth/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Auth Service Health: $HTTP_CODE"

# Test User Service Health
echo "Testing User Service Health..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/users/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "User Service Health: $HTTP_CODE"

# Test Product Service Health
echo "Testing Product Service Health..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/products/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Product Service Health: $HTTP_CODE"

echo ""
echo "2. Testing Authentication"
echo "-------------------------"

# Test User Registration
echo "Testing User Registration..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "newuser",
        "email": "newuser@example.com",
        "password": "password123"
    }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "201" ] && echo 0 || echo 1) "User Registration: $HTTP_CODE"

# Extract JWT token from registration
JWT_TOKEN=$(extract_jwt "$BODY")
if [ -n "$JWT_TOKEN" ]; then
    echo "   JWT Token extracted from registration"
else
    # Try login if registration didn't work
    echo "   Trying login instead..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "password": "password123"
        }')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "User Login: $HTTP_CODE"
    JWT_TOKEN=$(extract_jwt "$BODY")
fi

# Test Login with Invalid Credentials
echo "Testing Login with Invalid Credentials..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "invaliduser",
        "password": "wrongpassword"
    }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "401" ] && echo 0 || echo 1) "Invalid Login: $HTTP_CODE"

echo ""
echo "3. Testing Public Product Endpoints"
echo "-----------------------------------"

# Test Get All Products
echo "Testing Get All Products..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/products")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Get All Products: $HTTP_CODE"

# Test Get Product by ID
echo "Testing Get Product by ID..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/products/1")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Get Product by ID: $HTTP_CODE"

echo ""
echo "4. Testing Protected Endpoints"
echo "------------------------------"

if [ -n "$JWT_TOKEN" ]; then
    echo "Using JWT Token: ${JWT_TOKEN:0:20}..."
    
    # Test Get User Profile
    echo "Testing Get User Profile..."
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $JWT_TOKEN")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Get User Profile: $HTTP_CODE"
    
    # Test Update User Profile
    echo "Testing Update User Profile..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/users/profile" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d '{
            "first_name": "Updated",
            "last_name": "Name",
            "email": "updated@example.com"
        }')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Update User Profile: $HTTP_CODE"
    
    # Test Get User by ID
    echo "Testing Get User by ID..."
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/users/user1" \
        -H "Authorization: Bearer $JWT_TOKEN")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Get User by ID: $HTTP_CODE"
    
    # Test Create Product
    echo "Testing Create Product..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d '{
            "name": "New Product",
            "description": "A brand new product",
            "price": 99.99,
            "category": "Electronics",
            "stock": 10
        }')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "201" ] && echo 0 || echo 1) "Create Product: $HTTP_CODE"
    
    # Test Update Product
    echo "Testing Update Product..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/products/1" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d '{
            "name": "Updated Product",
            "price": 149.99,
            "stock": 25
        }')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Update Product: $HTTP_CODE"
    
    # Test Delete Product
    echo "Testing Delete Product..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/products/1" \
        -H "Authorization: Bearer $JWT_TOKEN")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    print_status $([ "$HTTP_CODE" = "204" ] && echo 0 || echo 1) "Delete Product: $HTTP_CODE"
    
else
    echo "❌ No JWT token available, skipping protected endpoint tests"
fi

echo ""
echo "5. Testing Error Scenarios"
echo "--------------------------"

# Test Access Protected Endpoint Without JWT
echo "Testing Access Protected Endpoint Without JWT..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/users/profile")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "401" ] && echo 0 || echo 1) "Access Without JWT: $HTTP_CODE"

# Test Access Protected Endpoint With Invalid JWT
echo "Testing Access Protected Endpoint With Invalid JWT..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/users/profile" \
    -H "Authorization: Bearer invalid.token.here")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "401" ] && echo 0 || echo 1) "Access With Invalid JWT: $HTTP_CODE"

# Test Create Product Without JWT
echo "Testing Create Product Without JWT..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Unauthorized Product",
        "price": 99.99
    }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)
print_status $([ "$HTTP_CODE" = "401" ] && echo 0 || echo 1) "Create Product Without JWT: $HTTP_CODE"

echo ""
echo "6. Testing Cache and Performance"
echo "--------------------------------"

# Test Product Cache
echo "Testing Product Cache (first request)..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/products")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
CACHE_STATUS=$(echo "$RESPONSE" | grep -i "x-cache-status" | head -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "First Product Request: $HTTP_CODE"

echo "Testing Product Cache (second request)..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/products")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
CACHE_STATUS=$(echo "$RESPONSE" | grep -i "x-cache-status" | head -1)
print_status $([ "$HTTP_CODE" = "200" ] && echo 0 || echo 1) "Second Product Request: $HTTP_CODE"

echo ""
echo "7. Testing Rate Limiting"
echo "------------------------"

echo "Testing Rate Limiting (making 15 rapid requests)..."
for i in {1..15}; do
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" = "429" ]; then
        echo "   Rate limit hit at request $i"
        break
    fi
    echo -n "."
done
echo ""
print_status 0 "Rate Limiting Test Completed"

echo ""
echo "🎉 API Testing Complete!"
echo "========================"
echo ""
echo "📊 Monitoring URLs:"
echo "   - Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo "   - Prometheus Metrics: http://localhost:9090"
echo ""
echo "📝 Next Steps:"
echo "   1. Import the Postman collection for interactive testing"
echo "   2. Check the Grafana dashboard for metrics"
echo "   3. Review service logs: docker-compose logs"
echo ""
