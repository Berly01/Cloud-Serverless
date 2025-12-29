import { useState, useEffect } from 'react';
import {
  Smartphone,
  Wifi,
  WifiOff,
  Battery,
  Clock,
  Activity,
  Plus,
  Settings,
} from 'lucide-react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { getDevices } from '../services/api';

export default function Devices() {
  const [devices, setDevices] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDevices();
  }, []);

  const fetchDevices = async () => {
    try {
      const response = await getDevices();
      // Transform device IDs to device objects with mock data
      // In a real app, you'd fetch full device info from the API
      const deviceList = (response.devices || []).map((deviceId, index) => ({
        id: deviceId,
        name: `Dispositivo ${index + 1}`,
        type: 'BPM Sensor',
        status: Math.random() > 0.3 ? 'online' : 'offline',
        battery: Math.floor(Math.random() * 100),
        lastSeen: new Date(Date.now() - Math.random() * 3600000),
        firmware: '1.2.3',
      }));
      setDevices(deviceList);
    } catch (err) {
      console.error('Error fetching devices:', err);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    return status === 'online' ? 'text-success' : 'text-gray-400';
  };

  const getBatteryColor = (level) => {
    if (level > 50) return 'text-success';
    if (level > 20) return 'text-warning';
    return 'text-critical';
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Dispositivos</h1>
          <p className="text-gray-600">Gestiona tus dispositivos de monitoreo BPM</p>
        </div>
        <button className="btn btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          Agregar Dispositivo
        </button>
      </div>

      {/* Devices Grid */}
      {devices.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {devices.map((device) => (
            <div key={device.id} className="card hover:shadow-lg transition-shadow">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div
                    className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                      device.status === 'online' ? 'bg-success-light' : 'bg-gray-100'
                    }`}
                  >
                    <Smartphone
                      className={`w-6 h-6 ${
                        device.status === 'online' ? 'text-success-dark' : 'text-gray-400'
                      }`}
                    />
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-800">{device.name}</h3>
                    <p className="text-sm text-gray-500">{device.type}</p>
                  </div>
                </div>
                <button className="p-2 hover:bg-gray-100 rounded-lg">
                  <Settings className="w-5 h-5 text-gray-400" />
                </button>
              </div>

              <div className="space-y-3">
                {/* Status */}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Estado</span>
                  <div className={`flex items-center gap-1.5 ${getStatusColor(device.status)}`}>
                    {device.status === 'online' ? (
                      <Wifi className="w-4 h-4" />
                    ) : (
                      <WifiOff className="w-4 h-4" />
                    )}
                    <span className="text-sm font-medium capitalize">{device.status}</span>
                  </div>
                </div>

                {/* Battery */}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Batería</span>
                  <div className={`flex items-center gap-1.5 ${getBatteryColor(device.battery)}`}>
                    <Battery className="w-4 h-4" />
                    <span className="text-sm font-medium">{device.battery}%</span>
                  </div>
                </div>

                {/* Last Seen */}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Última conexión</span>
                  <div className="flex items-center gap-1.5 text-gray-500">
                    <Clock className="w-4 h-4" />
                    <span className="text-sm">
                      {format(device.lastSeen, 'HH:mm', { locale: es })}
                    </span>
                  </div>
                </div>

                {/* Firmware */}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Firmware</span>
                  <span className="text-sm text-gray-500">v{device.firmware}</span>
                </div>
              </div>

              {/* Device ID */}
              <div className="mt-4 pt-4 border-t border-gray-100">
                <p className="text-xs text-gray-400 font-mono truncate">ID: {device.id}</p>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="card text-center py-12">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Smartphone className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-semibold text-gray-800 mb-2">
            No hay dispositivos registrados
          </h3>
          <p className="text-gray-600 mb-6">
            Agrega tu primer dispositivo de monitoreo BPM para comenzar
          </p>
          <button className="btn btn-primary inline-flex items-center gap-2">
            <Plus className="w-4 h-4" />
            Agregar Dispositivo
          </button>
        </div>
      )}

      {/* Help Section */}
      <div className="card bg-primary-50 border-primary-200">
        <div className="flex items-start gap-4">
          <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center flex-shrink-0">
            <Activity className="w-5 h-5 text-primary-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-800 mb-1">¿Cómo conectar un dispositivo?</h3>
            <p className="text-sm text-gray-600 mb-3">
              Los dispositivos BPM se conectan automáticamente a la nube mediante AWS IoT Core.
              Asegúrate de que tu dispositivo tenga los certificados correctos instalados.
            </p>
            <ul className="text-sm text-gray-600 space-y-1">
              <li>1. Enciende tu dispositivo BPM</li>
              <li>2. Conecta el dispositivo a tu red WiFi</li>
              <li>3. El dispositivo aparecerá automáticamente en esta lista</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
