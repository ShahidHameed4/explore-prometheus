# Explore Prometheus

A learning repository for understanding metrics and monitoring using Prometheus.

## Projects

### 1. [Custom Metrics App](./custom-metrics-app/)

A full-stack application demonstrating Prometheus custom metrics:

| Component | Technology | Port |
|-----------|------------|------|
| Backend | Go + Prometheus client | 8080 |
| Frontend | Next.js (React) | 3000 |
| Prometheus | Time-series DB | 9090 |
| Grafana | Visualization | 3001 |

**Metrics implemented:**
- `app_http_requests_total` - Counter with labels
- `app_http_request_duration_seconds` - Histogram
- `app_active_users` - Gauge
- `app_tasks_total` - Counter by type/status
- `app_order_value_dollars` - Histogram
- `app_system_load` - Gauge with component labels

```bash
cd custom-metrics-app
docker-compose up --build   # or run locally with go/npm
./test_all.sh               # run 20 automated tests
```

## Concepts Covered

- **Metric Types**: Counters, Gauges, Histograms, Summaries
- **Scraping**: How Prometheus pulls metrics from targets
- **Storage**: TSDB, data retention, remote write
- **PromQL**: rate(), increase(), histogram_quantile()
- **Visualization**: Grafana dashboards, built-in charts

## Prerequisites

- Go 1.21+
- Node.js 20+
- Docker & Docker Compose (optional)

## License

MIT
