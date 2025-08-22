# NGINX API Gateway with Microservices

A production-ready API Gateway built with NGINX that orchestrates multiple microservices with advanced features like JWT validation, rate limiting, caching, and monitoring.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   NGINX Gateway │    │   Microservices │
│                 │    │                 │    │                 │
│ - Web Apps      │───▶│ - Reverse Proxy │───▶│ - Auth Service  │
│ - Mobile Apps   │    │ - JWT Validation│    │ - User Service  │
│ - API Clients   │    │ - Rate Limiting │    │ - Product Svc   │
└─────────────────┘    │ - Caching       │    └─────────────────┘
                       │ - TLS Termination│
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Monitoring    │
                       │                 │
                       │ - Prometheus    │
                       │ - Grafana       │
                       └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Running the Project

1. **Clone and navigate to the project:**
   ```bash
   cd nginx-api-gateway
   ```

2. **Start all services:**
   ```bash
   docker-compose up -d
   ```

3. **Verify services are running:**
   ```bash
   docker-compose ps
   ```

4. **Access the services:**
   - **API Gateway:** http://localhost
   - **Grafana Dashboard:** http://localhost:3000 (admin/admin)
   - **Prometheus:** http://localhost:9090

## 📡 API Endpoints

### Authentication Service (`/auth/*`)
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `GET /auth/validate` - JWT token validation (internal)

### User Service (`/users/*`)
- `GET /users/profile` - Get user profile (requires JWT)
- `PUT /users/profile` - Update user profile (requires JWT)
- `GET /users/{id}` - Get user by ID (requires JWT)

### Product Service (`/products/*`)
- `GET /products` - List all products (cached)
- `GET /products/{id}` - Get product by ID (cached)
- `POST /products` - Create product (requires JWT)
- `PUT /products/{id}` - Update product (requires JWT)

## 🔧 NGINX Features

### 1. **JWT Validation**
- All `/users/*` and protected `/products/*` endpoints require valid JWT
- NGINX validates tokens via `auth_request` directive
- Invalid tokens return 401 Unauthorized

### 2. **Rate Limiting**
- **10 requests per second** per client IP
- Burst allowance of 20 requests
- Applied globally to all endpoints

### 3. **Response Caching**
- Product listings cached for **30 seconds**
- Reduces load on product service
- Cache stored in `/var/cache/nginx`

### 4. **TLS Termination**
- Self-signed certificates for development
- HTTP → HTTPS redirect
- HTTP/2 support enabled

### 5. **Structured Logging**
- Request time tracking
- Client IP logging
- JWT token logging (for debugging)
- Response status codes

## 📊 Monitoring & Observability

### Prometheus Metrics
- NGINX request metrics
- Response time histograms
- Error rate tracking
- Service-specific metrics

### Grafana Dashboards
- **API Gateway Overview**
  - Requests per second by service
  - Response time percentiles
  - Error rate trends
  - Rate limiting events

### Accessing Dashboards
1. Open http://localhost:3000
2. Login with `admin/admin`
3. Navigate to "API Gateway Dashboard"

## 🐳 Docker Services

| Service | Port | Description |
|---------|------|-------------|
| nginx | 80, 443 | API Gateway with TLS |
| auth-service | 8080 | Authentication & JWT |
| user-service | 8081 | User management |
| product-service | 8082 | Product catalog |
| prometheus | 9090 | Metrics collection |
| grafana | 3000 | Monitoring dashboards |

## 🔐 Security Features

- **JWT-based authentication** for protected endpoints
- **Rate limiting** to prevent abuse
- **TLS encryption** for all traffic
- **Request validation** at gateway level
- **Structured logging** for security auditing

## 🛠️ Development

### Adding New Services
1. Create service directory with `main.go` and `Dockerfile`
2. Add upstream in `nginx/nginx.conf`
3. Add service to `docker-compose.yml`
4. Update routing rules

### Customizing NGINX Config
- Edit `nginx/nginx.conf`
- Restart with `docker-compose restart nginx`

### Viewing Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs nginx
docker-compose logs auth-service
```

## 📈 Production Considerations

### SSL Certificates
Replace self-signed certificates with Let's Encrypt or your CA:
```nginx
ssl_certificate     /etc/nginx/certs/your-domain.crt;
ssl_certificate_key /etc/nginx/certs/your-domain.key;
```

### Rate Limiting
Adjust limits based on your traffic patterns:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
```

### Caching
Optimize cache settings for your use case:
```nginx
proxy_cache_valid 200 5m;  # Cache for 5 minutes
```

### Monitoring
- Set up alerting in Grafana
- Configure log aggregation (ELK stack)
- Add health checks for all services

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `docker-compose up`
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

---

**Built with ❤️ for scalable microservices architecture**
