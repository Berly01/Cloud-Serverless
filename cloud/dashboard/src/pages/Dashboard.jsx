import { useState, useEffect, useCallback } from 'react';
import {
  Heart,
  Activity,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  Clock,
  RefreshCw,
} from 'lucide-react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { getCurrentStatus, getBpmHistory, getBpmStatistics } from '../services/api';

export default function Dashboard() {
  const [currentStatus, setCurrentStatus] = useState(null);
  const [history, setHistory] = useState([]);
  const [statistics, setStatistics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdate, setLastUpdate] = useState(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchData = useCallback(async () => {
    try {
      const [statusRes, historyRes, statsRes] = await Promise.all([
        getCurrentStatus(),
        getBpmHistory({ limit: 50 }),
        getBpmStatistics('day'),
      ]);

      setCurrentStatus(statusRes);
      setHistory(historyRes.measurements || []);
      setStatistics(statsRes);
      setLastUpdate(new Date());
      setError(null);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Error al cargar los datos');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Auto-refresh every 10 seconds
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(fetchData, 10000);
    return () => clearInterval(interval);
  }, [autoRefresh, fetchData]);

  const getStatusColor = (status) => {
    switch (status) {
      case 'critical':
        return 'text-critical';
      case 'warning':
        return 'text-warning';
      case 'normal':
        return 'text-success';
      default:
        return 'text-gray-500';
    }
  };

  const getStatusBg = (status) => {
    switch (status) {
      case 'critical':
        return 'bg-critical-light border-critical';
      case 'warning':
        return 'bg-warning-light border-warning';
      case 'normal':
        return 'bg-success-light border-success';
      default:
        return 'bg-gray-100 border-gray-300';
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'critical':
        return 'Crítico';
      case 'warning':
        return 'Advertencia';
      case 'normal':
        return 'Normal';
      default:
        return 'Sin datos';
    }
  };

  // Prepare chart data
  const chartData = history
    .slice()
    .reverse()
    .map((item) => ({
      time: format(new Date(item.timestamp), 'HH:mm', { locale: es }),
      bpm: Number(item.bpm),
      status: item.status,
    }));

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Cargando datos...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>
          <p className="text-gray-600">Monitoreo en tiempo real de tus latidos cardíacos</p>
        </div>
        <div className="flex items-center gap-3">
          <label className="flex items-center gap-2 text-sm text-gray-600">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              className="rounded text-primary-600 focus:ring-primary-500"
            />
            Auto-actualizar
          </label>
          <button
            onClick={fetchData}
            className="btn btn-secondary flex items-center gap-2"
          >
            <RefreshCw className="w-4 h-4" />
            Actualizar
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-critical-light rounded-lg flex items-center gap-3 text-critical-dark">
          <AlertTriangle className="w-5 h-5" />
          {error}
        </div>
      )}

      {/* Current Status Card */}
      <div className={`card border-2 ${getStatusBg(currentStatus?.status)}`}>
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
          <div className="flex items-center gap-6">
            <div
              className={`w-24 h-24 rounded-full flex items-center justify-center ${
                currentStatus?.status === 'critical'
                  ? 'bg-critical'
                  : currentStatus?.status === 'warning'
                  ? 'bg-warning'
                  : 'bg-success'
              }`}
            >
              <Heart
                className={`w-12 h-12 text-white ${
                  currentStatus?.status !== 'no_data' ? 'animate-pulse-heart' : ''
                }`}
              />
            </div>
            <div>
              <p className="text-sm text-gray-600 mb-1">BPM Actual</p>
              <div className="flex items-baseline gap-2">
                <span className={`text-5xl font-bold ${getStatusColor(currentStatus?.status)}`}>
                  {currentStatus?.current_bpm || '--'}
                </span>
                <span className="text-gray-500">BPM</span>
              </div>
              <div
                className={`inline-flex items-center gap-1 mt-2 px-3 py-1 rounded-full text-sm font-medium ${getStatusBg(
                  currentStatus?.status
                )}`}
              >
                <Activity className="w-4 h-4" />
                {getStatusLabel(currentStatus?.status)}
              </div>
            </div>
          </div>
          <div className="text-sm text-gray-600">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4" />
              Última actualización:{' '}
              {lastUpdate ? format(lastUpdate, 'HH:mm:ss', { locale: es }) : '--'}
            </div>
            {currentStatus?.device_id && (
              <p className="mt-1">Dispositivo: {currentStatus.device_id}</p>
            )}
          </div>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-success-light flex items-center justify-center">
              <TrendingDown className="w-6 h-6 text-success-dark" />
            </div>
            <div>
              <p className="text-sm text-gray-600">BPM Mínimo (24h)</p>
              <p className="text-2xl font-bold text-gray-800">
                {statistics?.min_bpm || '--'}
              </p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-primary-100 flex items-center justify-center">
              <Activity className="w-6 h-6 text-primary-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">BPM Promedio (24h)</p>
              <p className="text-2xl font-bold text-gray-800">
                {statistics?.avg_bpm || '--'}
              </p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-warning-light flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-warning-dark" />
            </div>
            <div>
              <p className="text-sm text-gray-600">BPM Máximo (24h)</p>
              <p className="text-2xl font-bold text-gray-800">
                {statistics?.max_bpm || '--'}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="card">
        <h2 className="card-header">Historial de BPM</h2>
        <div className="h-80">
          {chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="time" stroke="#6b7280" fontSize={12} />
                <YAxis domain={[40, 160]} stroke="#6b7280" fontSize={12} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#fff',
                    border: '1px solid #e5e7eb',
                    borderRadius: '8px',
                  }}
                />
                <ReferenceLine y={50} stroke="#eab308" strokeDasharray="5 5" />
                <ReferenceLine y={100} stroke="#eab308" strokeDasharray="5 5" />
                <ReferenceLine y={40} stroke="#ef4444" strokeDasharray="5 5" />
                <ReferenceLine y={150} stroke="#ef4444" strokeDasharray="5 5" />
                <Line
                  type="monotone"
                  dataKey="bpm"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  dot={{ fill: '#3b82f6', strokeWidth: 0 }}
                  activeDot={{ r: 6, fill: '#2563eb' }}
                />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-full flex items-center justify-center text-gray-500">
              No hay datos disponibles
            </div>
          )}
        </div>
        <div className="mt-4 flex flex-wrap gap-4 text-sm">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-success rounded-full"></div>
            <span className="text-gray-600">Normal (50-100 BPM)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-warning rounded-full"></div>
            <span className="text-gray-600">Advertencia</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-critical rounded-full"></div>
            <span className="text-gray-600">Crítico</span>
          </div>
        </div>
      </div>
    </div>
  );
}
