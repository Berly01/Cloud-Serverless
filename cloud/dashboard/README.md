# 🫀 BPM Monitoring Dashboard

Dashboard web en tiempo real para visualización de datos de frecuencia cardíaca, construido con React y Vite.

## 📋 Descripción

Aplicación SPA (Single Page Application) que permite a usuarios monitorear sus mediciones de frecuencia cardíaca, ver historial, estadísticas y recibir alertas visuales cuando los valores están fuera de rango.

## ✨ Características

- 🔐 **Autenticación segura** con Amazon Cognito
- 📊 **Visualización en tiempo real** del último BPM registrado
- 📈 **Gráficos históricos** con Recharts
- 📱 **Diseño responsive** con Tailwind CSS
- 🚨 **Indicadores de estado** (Normal, Warning, Critical)
- 📉 **Estadísticas** (mínimo, máximo, promedio)
- 🌙 **Tema oscuro** moderno

## 🛠️ Tecnologías

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| React | 18.x | Framework UI |
| Vite | 5.x | Build tool |
| Tailwind CSS | 3.x | Estilos |
| Recharts | 2.x | Gráficos |
| React Router | 6.x | Navegación |
| amazon-cognito-identity-js | 6.x | Autenticación |

## 📁 Estructura del Proyecto

```
dashboard/
├── public/
│   └── vite.svg
├── src/
│   ├── components/
│   │   ├── Header.jsx           # Barra de navegación
│   │   ├── Layout.jsx           # Layout principal con auth check
│   │   ├── LoadingSpinner.jsx   # Spinner de carga
│   │   └── ProtectedRoute.jsx   # Rutas protegidas
│   ├── pages/
│   │   ├── Dashboard.jsx        # Vista principal con BPM actual
│   │   ├── History.jsx          # Historial con gráficos
│   │   ├── Statistics.jsx       # Estadísticas y análisis
│   │   └── Login.jsx            # Página de login
│   ├── services/
│   │   ├── auth.js              # Servicio de autenticación Cognito
│   │   └── api.js               # Cliente API REST
│   ├── App.jsx                  # Rutas principales
│   ├── main.jsx                 # Entry point
│   └── index.css                # Estilos globales
├── index.html
├── package.json
├── tailwind.config.js
├── postcss.config.js
└── vite.config.js
```

## 🚀 Desarrollo Local

### Requisitos

- Node.js 18+
- npm o yarn

### Instalación

```bash
cd dashboard
npm install
```

### Configuración

Crear archivo `.env.local`:

```env
VITE_API_URL=https://tu-api-gateway.execute-api.us-east-1.amazonaws.com/dev
VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_AWS_REGION=us-east-1
```

> ⚠️ Obtener estos valores de `tofu output` en la carpeta infrastructure

### Ejecución

```bash
npm run dev
```

El dashboard estará disponible en `http://localhost:5173`

## 📦 Build de Producción

```bash
npm run build
```

Los archivos se generan en `dist/`

## 🚀 Despliegue

El dashboard se despliega automáticamente a S3 + CloudFront con OpenTofu:

```bash
cd infrastructure
tofu apply
```

Esto:
1. Crea bucket S3 privado para hosting
2. Configura CloudFront con HTTPS
3. Sube los archivos del build

### Actualizar Dashboard

Después de cambios, reconstruir y subir:

```bash
# Build
cd dashboard
npm run build

# Subir a S3
aws s3 sync dist/ s3://bpm-monitoring-dev-dashboard-XXXXXX --delete

# Invalidar cache de CloudFront
aws cloudfront create-invalidation --distribution-id XXXXXX --paths "/*"
```

## 🔐 Autenticación

### Flujo de Login

1. Usuario ingresa email y contraseña
2. Cognito valida credenciales
3. Se obtienen tokens (ID, Access, Refresh)
4. Tokens se almacenan en localStorage
5. Requests a API incluyen token en header Authorization

### Grupos de Usuarios

| Grupo | Permisos |
|-------|----------|
| patients | Ver sus propios datos |
| doctors | Ver datos de pacientes asignados |
| administrators | Acceso completo |

## 📊 Páginas

### Dashboard (/)

Vista principal con:
- Valor actual de BPM en tiempo real
- Indicador visual de estado (color)
- Últimas 10 mediciones
- Información del dispositivo activo

### Historial (/history)

- Gráfico de líneas con mediciones
- Selector de rango de fechas
- Tabla detallada de mediciones
- Exportar datos (próximamente)

### Estadísticas (/statistics)

- BPM mínimo, máximo y promedio
- Distribución por estado
- Tendencias semanales/mensuales
- Alertas recientes

## 🎨 Personalización

### Colores de Estado

```javascript
// En componentes
const statusColors = {
  normal: 'bg-green-500',
  warning: 'bg-yellow-500', 
  critical: 'bg-red-500'
};
```

### Umbrales BPM

Los umbrales se configuran en la infraestructura y se reflejan automáticamente:

| Estado | Rango BPM |
|--------|-----------|
| Critical Low | ≤ 40 |
| Warning Low | 41-50 |
| Normal | 51-99 |
| Warning High | 100-149 |
| Critical High | ≥ 150 |

## 🧪 Testing

```bash
npm run test        # Unit tests
npm run test:e2e    # E2E tests (próximamente)
```

## 📱 Responsive Design

El dashboard está optimizado para:
- 📱 Mobile (320px+)
- 📱 Tablet (768px+)
- 💻 Desktop (1024px+)

## 🐛 Troubleshooting

### Error de CORS

Verificar que API Gateway tenga CORS configurado:
```bash
cd infrastructure
tofu apply -target=module.api_gateway
```

### Token expirado

El sistema intenta refresh automático. Si falla:
1. Logout manual
2. Login nuevamente

### Datos no actualizan

Verificar:
1. Dispositivo está enviando datos
2. Lambda processor sin errores (CloudWatch)
3. Network tab en DevTools

## 📄 Licencia

MIT License
