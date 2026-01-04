# Custom Metrics App

A full-stack application demonstrating Prometheus custom metrics with a Go backend and Next.js frontend.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    Frontend     │────▶│     Backend     │◀────│   Prometheus    │
│   (Next.js)     │     │      (Go)       │     │                 │
│   Port: 3000    │     │   Port: 8080    │     │   Port: 9090    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │     Grafana     │
                                               │   Port: 3001    │
                                               └─────────────────┘
```

## Custom Metrics Exposed

| Metric | Type | Description |
|--------|------|-------------|
| `app_http_requests_total` | Counter | Total HTTP requests by method, endpoint, status |
| `app_http_request_duration_seconds` | Histogram | Request duration distribution |
| `app_active_users` | Gauge | Currently active users |
| `app_tasks_total` | Counter | Tasks by type (feature/bug/improvement/docs) and status |
| `app_order_value_dollars` | Histogram | Order values distribution |
| `app_system_load` | Gauge | Simulated system load (cpu/memory/network/disk) |

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### Access Points

| Service | URL |
|---------|-----|
| **Frontend Dashboard** | http://localhost:3000 |
| **Backend API** | http://localhost:8080 |
| **Raw Metrics** | http://localhost:8080/metrics |
| **Prometheus** | http://localhost:9090 |
| **Grafana** | http://localhost:3001 (admin/admin) |

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/status` | GET | Get current app state |
| `/api/user/join` | POST | Simulate user joining |
| `/api/user/leave` | POST | Simulate user leaving |
| `/api/task/create` | POST | Create a random task |
| `/api/task/complete` | POST | Complete a random task |
| `/api/order/place` | POST | Place an order with random value |
| `/api/simulate/load` | POST | Simulate system load changes |
| `/api/reset` | POST | Reset all state |
| `/metrics` | GET | Prometheus metrics endpoint |
| `/health` | GET | Health check endpoint |

## Local Development

### Backend (Go)

```bash
cd backend
go mod download
go run main.go
```

### Frontend (Next.js)

```bash
cd frontend
npm install
npm run dev
```

## Running Tests

Test scripts are provided to verify the application is working correctly:

```bash
# Run all tests (requires both services running)
./test_all.sh

# Run backend tests only
./test_backend.sh

# Run frontend tests only
./test_frontend.sh
```

The test suite includes:
- **Backend Tests (15)**: API endpoints, state management, Prometheus metrics
- **Frontend Tests (5)**: Accessibility, page content, response time

## Sample Prometheus Queries

```promql
# Request rate per endpoint
rate(app_http_requests_total[1m])

# Active users
app_active_users

# 95th percentile request duration
histogram_quantile(0.95, rate(app_http_request_duration_seconds_bucket[5m]))

# Total tasks created by type
sum by (type) (app_tasks_total{status="created"})

# Order value percentiles
histogram_quantile(0.50, rate(app_order_value_dollars_bucket[5m]))
histogram_quantile(0.95, rate(app_order_value_dollars_bucket[5m]))

# System load by component
app_system_load

# CPU load over time
app_system_load{component="cpu"}
```

## Project Structure

```
custom-metrics-app/
├── backend/
│   ├── main.go          # Go server with Prometheus metrics
│   ├── go.mod           # Go dependencies
│   └── Dockerfile
├── frontend/
│   ├── src/app/
│   │   ├── page.tsx     # Dashboard UI
│   │   ├── layout.tsx   # Root layout
│   │   └── globals.css  # Styles
│   ├── package.json
│   └── Dockerfile
├── prometheus/
│   └── prometheus.yml   # Prometheus configuration
├── grafana/
│   ├── provisioning/    # Auto-provisioning configs
│   └── dashboards/      # Pre-built dashboards
├── docker-compose.yml
└── README.md
```

## Learning Objectives

1. **Counter metrics** - Track cumulative values (requests, tasks)
2. **Gauge metrics** - Track values that go up and down (active users, load)
3. **Histogram metrics** - Track distributions (request duration, order values)
4. **Labels** - Add dimensions to metrics for filtering
5. **Prometheus scraping** - Configure targets and intervals
6. **Grafana visualization** - Build dashboards from metrics

