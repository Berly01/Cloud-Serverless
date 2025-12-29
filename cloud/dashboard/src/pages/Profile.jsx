import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { getUserProfile } from '../services/api';
import {
  User,
  Mail,
  Shield,
  Bell,
  Key,
  Save,
  Check,
} from 'lucide-react';

export default function Profile() {
  const { user } = useAuth();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  
  const [notifications, setNotifications] = useState({
    email: true,
    sms: false,
    critical: true,
    warning: true,
  });

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const response = await getUserProfile();
      setProfile(response);
    } catch (err) {
      console.error('Error fetching profile:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveNotifications = async () => {
    setSaving(true);
    // Simulated save - in real app, call API
    await new Promise((resolve) => setTimeout(resolve, 1000));
    setSaving(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  const getRoleName = (role) => {
    switch (role) {
      case 'administrator':
      case 'admin':
        return 'Administrador';
      case 'doctor':
        return 'Médico';
      case 'patient':
      default:
        return 'Paciente';
    }
  };

  const getRoleDescription = (role) => {
    switch (role) {
      case 'administrator':
      case 'admin':
        return 'Acceso completo al sistema y configuración';
      case 'doctor':
        return 'Acceso a pacientes asignados y sus datos';
      case 'patient':
      default:
        return 'Acceso a tus propios datos de salud';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn max-w-3xl">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-800">Perfil</h1>
        <p className="text-gray-600">Gestiona tu información personal y preferencias</p>
      </div>

      {/* Profile Info */}
      <div className="card">
        <h2 className="card-header flex items-center gap-2">
          <User className="w-5 h-5" />
          Información Personal
        </h2>

        <div className="flex items-center gap-6 mb-6">
          <div className="w-20 h-20 bg-primary-100 rounded-full flex items-center justify-center">
            <User className="w-10 h-10 text-primary-600" />
          </div>
          <div>
            <h3 className="text-xl font-semibold text-gray-800">
              {user?.name || profile?.email || 'Usuario'}
            </h3>
            <p className="text-gray-600">{user?.email || profile?.email}</p>
          </div>
        </div>

        <div className="grid gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nombre completo
            </label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={user?.name || ''}
                readOnly
                className="input pl-10 bg-gray-50"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Correo electrónico
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="email"
                value={user?.email || profile?.email || ''}
                readOnly
                className="input pl-10 bg-gray-50"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Role Info */}
      <div className="card">
        <h2 className="card-header flex items-center gap-2">
          <Shield className="w-5 h-5" />
          Rol y Permisos
        </h2>

        <div className="flex items-center gap-4 p-4 bg-primary-50 rounded-lg">
          <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
            <Shield className="w-6 h-6 text-primary-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-800">
              {getRoleName(user?.role || profile?.role)}
            </h3>
            <p className="text-sm text-gray-600">
              {getRoleDescription(user?.role || profile?.role)}
            </p>
          </div>
        </div>

        {(user?.groups?.length > 0 || []).length > 0 && (
          <div className="mt-4">
            <p className="text-sm font-medium text-gray-700 mb-2">Grupos</p>
            <div className="flex flex-wrap gap-2">
              {user.groups.map((group) => (
                <span
                  key={group}
                  className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm"
                >
                  {group}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Notification Preferences */}
      <div className="card">
        <h2 className="card-header flex items-center gap-2">
          <Bell className="w-5 h-5" />
          Preferencias de Notificación
        </h2>

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-800">Notificaciones por Email</p>
              <p className="text-sm text-gray-600">Recibir alertas por correo electrónico</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={notifications.email}
                onChange={(e) =>
                  setNotifications({ ...notifications, email: e.target.checked })
                }
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:ring-2 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600"></div>
            </label>
          </div>

          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-800">Notificaciones por SMS</p>
              <p className="text-sm text-gray-600">Recibir alertas por mensaje de texto</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={notifications.sms}
                onChange={(e) =>
                  setNotifications({ ...notifications, sms: e.target.checked })
                }
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:ring-2 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600"></div>
            </label>
          </div>

          <hr className="border-gray-200" />

          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-800">Alertas Críticas</p>
              <p className="text-sm text-gray-600">
                BPM muy alto (&gt;150) o muy bajo (&lt;40)
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={notifications.critical}
                onChange={(e) =>
                  setNotifications({ ...notifications, critical: e.target.checked })
                }
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:ring-2 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-critical"></div>
            </label>
          </div>

          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-800">Alertas de Advertencia</p>
              <p className="text-sm text-gray-600">BPM fuera del rango normal (50-100)</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={notifications.warning}
                onChange={(e) =>
                  setNotifications({ ...notifications, warning: e.target.checked })
                }
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:ring-2 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-warning"></div>
            </label>
          </div>
        </div>

        <button
          onClick={handleSaveNotifications}
          disabled={saving}
          className="mt-6 btn btn-primary flex items-center gap-2"
        >
          {saving ? (
            <>
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              Guardando...
            </>
          ) : saved ? (
            <>
              <Check className="w-4 h-4" />
              Guardado
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              Guardar Preferencias
            </>
          )}
        </button>
      </div>

      {/* Security */}
      <div className="card">
        <h2 className="card-header flex items-center gap-2">
          <Key className="w-5 h-5" />
          Seguridad
        </h2>

        <div className="space-y-4">
          <button className="btn btn-secondary w-full sm:w-auto">
            Cambiar Contraseña
          </button>
          <p className="text-sm text-gray-500">
            La contraseña debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas,
            números y símbolos.
          </p>
        </div>
      </div>
    </div>
  );
}
