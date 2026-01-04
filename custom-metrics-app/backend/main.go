package main

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Custom metrics
var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "app_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "app_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	activeUsers = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "app_active_users",
			Help: "Number of currently active users",
		},
	)

	taskCounter = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "app_tasks_total",
			Help: "Total number of tasks by type and status",
		},
		[]string{"type", "status"},
	)

	orderValue = prometheus.NewHistogram(
		prometheus.HistogramOpts{
			Name:    "app_order_value_dollars",
			Help:    "Order values in dollars",
			Buckets: []float64{10, 25, 50, 100, 250, 500, 1000},
		},
	)

	systemLoad = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "app_system_load",
			Help: "Simulated system load metrics",
		},
		[]string{"component"},
	)
)

// In-memory state
type AppState struct {
	sync.RWMutex
	Users      int     `json:"users"`
	Tasks      int     `json:"tasks"`
	Orders     int     `json:"orders"`
	Revenue    float64 `json:"revenue"`
	CPULoad    float64 `json:"cpuLoad"`
	MemoryLoad float64 `json:"memoryLoad"`
}

var state = &AppState{
	Users:      0,
	Tasks:      0,
	Orders:     0,
	Revenue:    0,
	CPULoad:    20,
	MemoryLoad: 35,
}

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
	prometheus.MustRegister(activeUsers)
	prometheus.MustRegister(taskCounter)
	prometheus.MustRegister(orderValue)
	prometheus.MustRegister(systemLoad)
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func metricsMiddleware(next http.HandlerFunc, endpoint string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next(w, r)
		duration := time.Since(start).Seconds()
		
		httpRequestsTotal.WithLabelValues(r.Method, endpoint, "200").Inc()
		httpRequestDuration.WithLabelValues(r.Method, endpoint).Observe(duration)
	}
}

func jsonResponse(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func handleStatus(w http.ResponseWriter, r *http.Request) {
	state.RLock()
	defer state.RUnlock()
	jsonResponse(w, state)
}

func handleUserJoin(w http.ResponseWriter, r *http.Request) {
	state.Lock()
	state.Users++
	activeUsers.Set(float64(state.Users))
	state.Unlock()
	
	state.RLock()
	defer state.RUnlock()
	jsonResponse(w, map[string]interface{}{
		"message": "User joined",
		"users":   state.Users,
	})
}

func handleUserLeave(w http.ResponseWriter, r *http.Request) {
	state.Lock()
	if state.Users > 0 {
		state.Users--
	}
	activeUsers.Set(float64(state.Users))
	state.Unlock()
	
	state.RLock()
	defer state.RUnlock()
	jsonResponse(w, map[string]interface{}{
		"message": "User left",
		"users":   state.Users,
	})
}

func handleCreateTask(w http.ResponseWriter, r *http.Request) {
	taskTypes := []string{"feature", "bug", "improvement", "documentation"}
	taskType := taskTypes[rand.Intn(len(taskTypes))]
	
	state.Lock()
	state.Tasks++
	state.Unlock()
	
	taskCounter.WithLabelValues(taskType, "created").Inc()
	
	state.RLock()
	defer state.RUnlock()
	jsonResponse(w, map[string]interface{}{
		"message":  "Task created",
		"taskType": taskType,
		"tasks":    state.Tasks,
	})
}

func handleCompleteTask(w http.ResponseWriter, r *http.Request) {
	taskTypes := []string{"feature", "bug", "improvement", "documentation"}
	taskType := taskTypes[rand.Intn(len(taskTypes))]
	
	taskCounter.WithLabelValues(taskType, "completed").Inc()
	
	jsonResponse(w, map[string]interface{}{
		"message":  "Task completed",
		"taskType": taskType,
	})
}

func handlePlaceOrder(w http.ResponseWriter, r *http.Request) {
	// Generate random order value between $5 and $1500
	value := 5 + rand.Float64()*1495
	
	state.Lock()
	state.Orders++
	state.Revenue += value
	state.Unlock()
	
	orderValue.Observe(value)
	
	state.RLock()
	defer state.RUnlock()
	jsonResponse(w, map[string]interface{}{
		"message": "Order placed",
		"value":   value,
		"orders":  state.Orders,
		"revenue": state.Revenue,
	})
}

func handleSimulateLoad(w http.ResponseWriter, r *http.Request) {
	// Simulate varying system load
	state.Lock()
	state.CPULoad = 10 + rand.Float64()*80
	state.MemoryLoad = 20 + rand.Float64()*70
	
	systemLoad.WithLabelValues("cpu").Set(state.CPULoad)
	systemLoad.WithLabelValues("memory").Set(state.MemoryLoad)
	systemLoad.WithLabelValues("network").Set(rand.Float64() * 100)
	systemLoad.WithLabelValues("disk").Set(rand.Float64() * 100)
	state.Unlock()
	
	state.RLock()
	defer state.RUnlock()
	jsonResponse(w, map[string]interface{}{
		"message":    "Load simulated",
		"cpuLoad":    state.CPULoad,
		"memoryLoad": state.MemoryLoad,
	})
}

func handleReset(w http.ResponseWriter, r *http.Request) {
	state.Lock()
	state.Users = 0
	state.Tasks = 0
	state.Orders = 0
	state.Revenue = 0
	state.CPULoad = 20
	state.MemoryLoad = 35
	
	activeUsers.Set(0)
	systemLoad.WithLabelValues("cpu").Set(20)
	systemLoad.WithLabelValues("memory").Set(35)
	systemLoad.WithLabelValues("network").Set(0)
	systemLoad.WithLabelValues("disk").Set(0)
	state.Unlock()
	
	jsonResponse(w, map[string]interface{}{
		"message": "State reset",
	})
}

func main() {
	rand.Seed(time.Now().UnixNano())
	
	// Initialize system load metrics
	systemLoad.WithLabelValues("cpu").Set(20)
	systemLoad.WithLabelValues("memory").Set(35)
	systemLoad.WithLabelValues("network").Set(0)
	systemLoad.WithLabelValues("disk").Set(0)
	
	mux := http.NewServeMux()
	
	// API endpoints
	mux.HandleFunc("/api/status", metricsMiddleware(handleStatus, "/api/status"))
	mux.HandleFunc("/api/user/join", metricsMiddleware(handleUserJoin, "/api/user/join"))
	mux.HandleFunc("/api/user/leave", metricsMiddleware(handleUserLeave, "/api/user/leave"))
	mux.HandleFunc("/api/task/create", metricsMiddleware(handleCreateTask, "/api/task/create"))
	mux.HandleFunc("/api/task/complete", metricsMiddleware(handleCompleteTask, "/api/task/complete"))
	mux.HandleFunc("/api/order/place", metricsMiddleware(handlePlaceOrder, "/api/order/place"))
	mux.HandleFunc("/api/simulate/load", metricsMiddleware(handleSimulateLoad, "/api/simulate/load"))
	mux.HandleFunc("/api/reset", metricsMiddleware(handleReset, "/api/reset"))
	
	// Prometheus metrics endpoint
	mux.Handle("/metrics", promhttp.Handler())
	
	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		jsonResponse(w, map[string]string{"status": "healthy"})
	})
	
	handler := corsMiddleware(mux)
	
	log.Println("🚀 Server starting on :8080")
	log.Println("📊 Metrics available at /metrics")
	log.Println("💚 Health check at /health")
	
	if err := http.ListenAndServe(":8080", handler); err != nil {
		log.Fatal(err)
	}
}

