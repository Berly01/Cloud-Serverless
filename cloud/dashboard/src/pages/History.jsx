import { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import {
  Calendar,
  Clock,
  Activity,
  Download,
  Filter,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { getBpmHistory, getBpmStatistics } from '../services/api';

export default function History() {
  const [measurements, setMeasurements] = useState([]);
  const [statistics, setStatistics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState('day');
  const [deviceFilter, setDeviceFilter] = useState('');
  const [page, setPage] = useState(1);
  const pageSize = 20;

  useEffect(() => {
    fetchData();
  }, [period, deviceFilter]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [historyRes, statsRes] = await Promise.all([
        getBpmHistory({
          device_id: deviceFilter || undefined,
          limit: 200,
        }),
        getBpmStatistics(period),
      ]);

      setMeasurements(historyRes.measurements || []);
      setStatistics(statsRes);
    } catch (err) {
      console.error('Error fetching history:', err);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'critical':
        return 'alert-badge bg-critical-light text-critical-dark';
      case 'warning':
        return 'alert-badge bg-warning-light text-warning-dark';
      case 'normal':
        return 'alert-badge bg-success-light text-success-dark';
      default:
        return 'alert-badge bg-gray-100 text-gray-600';
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
        return 'Desconocido';
    }
  };

  // Chart data
  const chartData = measurements
    .slice()
    .reverse()
    .slice(0, 50)
    .map((item) => ({
      time: format(new Date(item.timestamp), 'dd/MM HH:mm', { locale: es }),
      bpm: Number(item.bpm),
    }));

  // Paginated data
  const paginatedData = measurements.slice((page - 1) * pageSize, page * pageSize);
  const totalPages = Math.ceil(measurements.length / pageSize);

  const exportCSV = () => {
    const headers = ['Fecha', 'Hora', 'BPM', 'Estado', 'Dispositivo'];
    const rows = measurements.map((m) => [
      format(new Date(m.timestamp), 'dd/MM/yyyy'),
      format(new Date(m.timestamp), 'HH:mm:ss'),
      m.bpm,
      getStatusLabel(m.status),
      m.device_id,
    ]);

    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bpm-history-${format(new Date(), 'yyyy-MM-dd')}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6 animate-fadeIn">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Historial</h1>
          <p className="text-gray-600">Revisa tus mediciones anteriores</p>
        </div>
        <button onClick={exportCSV} className="btn btn-secondary flex items-center gap-2">
          <Download className="w-4 h-4" />
          Exportar CSV
        </button>
      </div>

      {/* Filters */}
      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex items-center gap-2">
            <Filter className="w-5 h-5 text-gray-400" />
            <span className="text-sm font-medium text-gray-700">Filtros:</span>
          </div>
          <div className="flex flex-wrap gap-2">
            {['day', 'week', 'month'].map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  period === p
                    ? 'bg-primary-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {p === 'day' ? 'Hoy' : p === 'week' ? 'Semana' : 'Mes'}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Statistics Summary */}
      {statistics && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="card">
            <p className="text-sm text-gray-600">Mediciones</p>
            <p className="text-2xl font-bold text-gray-800">{statistics.count || 0}</p>
          </div>
          <div className="card">
            <p className="text-sm text-gray-600">BPM Mínimo</p>
            <p className="text-2xl font-bold text-success">{statistics.min_bpm || '--'}</p>
          </div>
          <div className="card">
            <p className="text-sm text-gray-600">BPM Promedio</p>
            <p className="text-2xl font-bold text-primary-600">
              {statistics.avg_bpm || '--'}
            </p>
          </div>
          <div className="card">
            <p className="text-sm text-gray-600">BPM Máximo</p>
            <p className="text-2xl font-bold text-warning">{statistics.max_bpm || '--'}</p>
          </div>
        </div>
      )}

      {/* Chart */}
      <div className="card">
        <h2 className="card-header">Gráfico de tendencia</h2>
        <div className="h-64">
          {loading ? (
            <div className="h-full flex items-center justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            </div>
          ) : chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="time" stroke="#6b7280" fontSize={11} />
                <YAxis domain={[40, 160]} stroke="#6b7280" fontSize={12} />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="bpm"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-full flex items-center justify-center text-gray-500">
              No hay datos para el período seleccionado
            </div>
          )}
        </div>
      </div>

      {/* Table */}
      <div className="card">
        <h2 className="card-header">Listado de mediciones</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4" />
                    Fecha
                  </div>
                </th>
                <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4" />
                    Hora
                  </div>
                </th>
                <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">
                  <div className="flex items-center gap-2">
                    <Activity className="w-4 h-4" />
                    BPM
                  </div>
                </th>
                <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">
                  Estado
                </th>
                <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">
                  Dispositivo
                </th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-gray-500">
                    Cargando...
                  </td>
                </tr>
              ) : paginatedData.length > 0 ? (
                paginatedData.map((item, index) => (
                  <tr
                    key={`${item.timestamp}-${index}`}
                    className="border-b border-gray-100 hover:bg-gray-50"
                  >
                    <td className="py-3 px-4 text-sm text-gray-800">
                      {format(new Date(item.timestamp), 'dd/MM/yyyy', { locale: es })}
                    </td>
                    <td className="py-3 px-4 text-sm text-gray-600">
                      {format(new Date(item.timestamp), 'HH:mm:ss', { locale: es })}
                    </td>
                    <td className="py-3 px-4 text-sm font-semibold text-gray-800">
                      {item.bpm}
                    </td>
                    <td className="py-3 px-4">
                      <span className={getStatusBadge(item.status)}>
                        {getStatusLabel(item.status)}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-gray-600">{item.device_id}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-gray-500">
                    No hay mediciones disponibles
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-200">
            <p className="text-sm text-gray-600">
              Mostrando {(page - 1) * pageSize + 1} -{' '}
              {Math.min(page * pageSize, measurements.length)} de {measurements.length}
            </p>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <span className="text-sm text-gray-600">
                Página {page} de {totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
