'use client'

import { useState, useEffect, useCallback, useRef } from 'react'

interface AppState {
  users: number
  tasks: number
  orders: number
  revenue: number
  cpuLoad: number
  memoryLoad: number
}

interface Toast {
  id: number
  message: string
  emoji: string
}

interface MetricPoint {
  time: number
  value: number
}

interface MetricsHistory {
  users: MetricPoint[]
  cpu: MetricPoint[]
  memory: MetricPoint[]
  requests: MetricPoint[]
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'
const MAX_POINTS = 30 // Keep last 30 data points

// Simple SVG Line Chart Component
function MiniChart({ 
  data, 
  color, 
  label,
  unit = '',
  max = 100 
}: { 
  data: MetricPoint[]
  color: string
  label: string
  unit?: string
  max?: number
}) {
  const width = 280
  const height = 80
  const padding = 5
  
  if (data.length < 2) {
    return (
      <div className="mini-chart">
        <div className="chart-header">
          <span className="chart-label">{label}</span>
          <span className="chart-value" style={{ color }}>--{unit}</span>
        </div>
        <div className="chart-placeholder">Collecting data...</div>
      </div>
    )
  }

  const currentValue = data[data.length - 1]?.value ?? 0
  const dynamicMax = Math.max(max, ...data.map(d => d.value)) * 1.1
  
  const points = data.map((point, i) => {
    const x = padding + (i / (data.length - 1)) * (width - padding * 2)
    const y = height - padding - (point.value / dynamicMax) * (height - padding * 2)
    return `${x},${y}`
  }).join(' ')

  const areaPoints = `${padding},${height - padding} ${points} ${width - padding},${height - padding}`

  return (
    <div className="mini-chart">
      <div className="chart-header">
        <span className="chart-label">{label}</span>
        <span className="chart-value" style={{ color }}>
          {typeof currentValue === 'number' ? currentValue.toFixed(1) : currentValue}{unit}
        </span>
      </div>
      <svg width={width} height={height} className="chart-svg">
        <defs>
          <linearGradient id={`gradient-${label}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor={color} stopOpacity="0.3" />
            <stop offset="100%" stopColor={color} stopOpacity="0.05" />
          </linearGradient>
        </defs>
        <polygon 
          points={areaPoints} 
          fill={`url(#gradient-${label})`}
        />
        <polyline
          points={points}
          fill="none"
          stroke={color}
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        {data.length > 0 && (
          <circle
            cx={width - padding}
            cy={height - padding - (currentValue / dynamicMax) * (height - padding * 2)}
            r="4"
            fill={color}
          />
        )}
      </svg>
    </div>
  )
}

export default function Home() {
  const [state, setState] = useState<AppState>({
    users: 0,
    tasks: 0,
    orders: 0,
    revenue: 0,
    cpuLoad: 20,
    memoryLoad: 35,
  })
  const [connected, setConnected] = useState(false)
  const [loading, setLoading] = useState<string | null>(null)
  const [toasts, setToasts] = useState<Toast[]>([])
  const [history, setHistory] = useState<MetricsHistory>({
    users: [],
    cpu: [],
    memory: [],
    requests: [],
  })
  const requestCountRef = useRef(0)

  const showToast = useCallback((message: string, emoji: string) => {
    const id = Date.now()
    setToasts(prev => [...prev, { id, message, emoji }])
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }, 3000)
  }, [])

  const fetchStatus = useCallback(async () => {
    try {
      const res = await fetch(`${API_URL}/api/status`)
      if (res.ok) {
        const data = await res.json()
        setState(data)
        setConnected(true)
        
        // Update history
        const now = Date.now()
        setHistory(prev => ({
          users: [...prev.users, { time: now, value: data.users }].slice(-MAX_POINTS),
          cpu: [...prev.cpu, { time: now, value: data.cpuLoad }].slice(-MAX_POINTS),
          memory: [...prev.memory, { time: now, value: data.memoryLoad }].slice(-MAX_POINTS),
          requests: [...prev.requests, { time: now, value: requestCountRef.current }].slice(-MAX_POINTS),
        }))
      }
    } catch {
      setConnected(false)
    }
  }, [])

  useEffect(() => {
    fetchStatus()
    const interval = setInterval(fetchStatus, 2000)
    return () => clearInterval(interval)
  }, [fetchStatus])

  const callApi = async (endpoint: string, successMsg: string, emoji: string) => {
    setLoading(endpoint)
    requestCountRef.current++
    try {
      const res = await fetch(`${API_URL}${endpoint}`, { method: 'POST' })
      if (res.ok) {
        const data = await res.json()
        showToast(successMsg, emoji)
        await fetchStatus()
        return data
      }
    } catch (err) {
      showToast('Action failed', '❌')
    } finally {
      setLoading(null)
    }
  }

  return (
    <div className="container">
      <header className="header">
        <h1 className="title">Metrics Dashboard</h1>
        <p className="subtitle">Prometheus Custom Metrics Explorer</p>
        {connected && (
          <div className="status-indicator">
            <span className="status-dot"></span>
            Connected to Backend
          </div>
        )}
      </header>

      <div className="dashboard">
        <div className="stats-grid">
          <div className="stat-card cyan">
            <div className="stat-label">Active Users</div>
            <div className="stat-value">
              {state.users}
              <span className="stat-unit">online</span>
            </div>
          </div>
          
          <div className="stat-card magenta">
            <div className="stat-label">Total Tasks</div>
            <div className="stat-value">
              {state.tasks}
              <span className="stat-unit">created</span>
            </div>
          </div>
          
          <div className="stat-card yellow">
            <div className="stat-label">Orders</div>
            <div className="stat-value">
              {state.orders}
              <span className="stat-unit">placed</span>
            </div>
          </div>
          
          <div className="stat-card green">
            <div className="stat-label">Revenue</div>
            <div className="stat-value">
              ${state.revenue.toFixed(2)}
            </div>
          </div>
        </div>

        <div className="load-bars">
          <div className="load-bar-container">
            <div className="load-bar-header">
              <span className="load-bar-label">
                <span className="emoji">🖥️</span> CPU Load
              </span>
              <span className="load-bar-value" style={{ color: 'var(--accent-cyan)' }}>
                {state.cpuLoad.toFixed(1)}%
              </span>
            </div>
            <div className="load-bar-track">
              <div 
                className="load-bar-fill cpu" 
                style={{ width: `${state.cpuLoad}%` }}
              />
            </div>
          </div>
          
          <div className="load-bar-container">
            <div className="load-bar-header">
              <span className="load-bar-label">
                <span className="emoji">💾</span> Memory Load
              </span>
              <span className="load-bar-value" style={{ color: 'var(--accent-green)' }}>
                {state.memoryLoad.toFixed(1)}%
              </span>
            </div>
            <div className="load-bar-track">
              <div 
                className="load-bar-fill memory" 
                style={{ width: `${state.memoryLoad}%` }}
              />
            </div>
          </div>
        </div>

        <div className="charts-section">
          <h2 className="section-title">Live Metrics (Mini Grafana)</h2>
          <div className="charts-grid">
            <MiniChart 
              data={history.users} 
              color="var(--accent-cyan)" 
              label="Active Users"
              unit=" users"
              max={10}
            />
            <MiniChart 
              data={history.cpu} 
              color="var(--accent-magenta)" 
              label="CPU Load"
              unit="%"
              max={100}
            />
            <MiniChart 
              data={history.memory} 
              color="var(--accent-green)" 
              label="Memory Load"
              unit="%"
              max={100}
            />
            <MiniChart 
              data={history.requests} 
              color="var(--accent-yellow)" 
              label="Total Requests"
              unit=""
              max={50}
            />
          </div>
        </div>

        <div className="actions-section">
          <h2 className="section-title">Generate Metrics</h2>
          <div className="actions-grid">
            <button 
              className={`action-btn user-join ${loading === '/api/user/join' ? 'loading' : ''}`}
              onClick={() => callApi('/api/user/join', 'User joined!', '👋')}
            >
              <span className="emoji">➕</span> User Join
            </button>
            
            <button 
              className={`action-btn user-leave ${loading === '/api/user/leave' ? 'loading' : ''}`}
              onClick={() => callApi('/api/user/leave', 'User left', '👋')}
            >
              <span className="emoji">➖</span> User Leave
            </button>
            
            <button 
              className={`action-btn task-create ${loading === '/api/task/create' ? 'loading' : ''}`}
              onClick={() => callApi('/api/task/create', 'Task created!', '📝')}
            >
              <span className="emoji">📋</span> Create Task
            </button>
            
            <button 
              className={`action-btn task-complete ${loading === '/api/task/complete' ? 'loading' : ''}`}
              onClick={() => callApi('/api/task/complete', 'Task completed!', '✅')}
            >
              <span className="emoji">✓</span> Complete Task
            </button>
            
            <button 
              className={`action-btn order ${loading === '/api/order/place' ? 'loading' : ''}`}
              onClick={() => callApi('/api/order/place', 'Order placed!', '🛒')}
            >
              <span className="emoji">💰</span> Place Order
            </button>
            
            <button 
              className={`action-btn load ${loading === '/api/simulate/load' ? 'loading' : ''}`}
              onClick={() => callApi('/api/simulate/load', 'Load simulated!', '📊')}
            >
              <span className="emoji">⚡</span> Simulate Load
            </button>
            
            <button 
              className={`action-btn reset ${loading === '/api/reset' ? 'loading' : ''}`}
              onClick={() => callApi('/api/reset', 'State reset!', '🔄')}
            >
              <span className="emoji">↺</span> Reset All
            </button>
          </div>
        </div>

        <div className="links-section">
          <a 
            href="http://localhost:9090" 
            target="_blank" 
            rel="noopener noreferrer"
            className="external-link"
          >
            <span className="emoji">🔥</span> Prometheus
          </a>
          <a 
            href="http://localhost:3001" 
            target="_blank" 
            rel="noopener noreferrer"
            className="external-link"
          >
            <span className="emoji">📈</span> Grafana
          </a>
          <a 
            href={`${API_URL}/metrics`}
            target="_blank" 
            rel="noopener noreferrer"
            className="external-link"
          >
            <span className="emoji">📊</span> Raw Metrics
          </a>
        </div>
      </div>

      {toasts.map(toast => (
        <div key={toast.id} className="toast">
          <span className="emoji">{toast.emoji}</span>
          {toast.message}
        </div>
      ))}
    </div>
  )
}

