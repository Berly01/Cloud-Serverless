"""
Fog Server - Servidor de computación en el borde (fog computing).
Recibe datos de dispositivos IoT, los preprocesa, filtra y decide si enviarlos a la nube.
"""

import json
import time
import socket
import threading
import argparse
from datetime import datetime, timezone
from collections import deque
from typing import Optional
from awscrt import mqtt
from awsiot import mqtt_connection_builder


# Configuración por defecto
DEFAULT_FOG_PORT = 25000
DEFAULT_ENDPOINT = "afpyqiue5b2ii-ats.iot.us-east-1.amazonaws.com"
DEFAULT_THING_NAME = "bpm-device-010"
DEFAULT_CERT = "certs/bpm-device-010/device.pem.crt"
DEFAULT_KEY = "certs/bpm-device-010/private.pem.key"
DEFAULT_ROOT_CA = "certs/bpm-device-010/AmazonRootCA1.pem"

# Umbrales para filtrado
BPM_CRITICAL_LOW = 40
BPM_WARNING_LOW = 50
BPM_WARNING_HIGH = 100
BPM_CRITICAL_HIGH = 150

# Configuración de agregación
AGGREGATION_WINDOW = 5  # Segundos para agregar datos
MIN_SAMPLES_FOR_AGGREGATION = 3


class FogProcessor:
    """
    Procesador Fog que implementa:
    1. Preprocesamiento de datos
    2. Filtrado inteligente
    3. Agregación de datos
    4. Decisión de envío a la nube
    """
    
    def __init__(self, send_all: bool = False, critical_only: bool = False):
        self.send_all = send_all
        self.critical_only = critical_only
        self.device_buffers = {}  # Buffer por dispositivo para agregación
        self.device_stats = {}  # Estadísticas por dispositivo
        self.lock = threading.Lock()
        
    def preprocess(self, data: dict) -> dict:
        """
        Preprocesa los datos del sensor IoT.
        - Valida datos
        - Normaliza formatos
        - Calcula métricas derivadas
        """
        processed = data.copy()
        
        # Validar BPM
        bpm = processed.get('bpm', 0)
        if not isinstance(bpm, (int, float)) or bpm < 0 or bpm > 300:
            processed['valid'] = False
            processed['error'] = 'BPM fuera de rango válido'
            return processed
        
        processed['valid'] = True
        
        # Calcular categoría de riesgo
        if bpm < BPM_CRITICAL_LOW:
            processed['risk_level'] = 'critical_low'
            processed['risk_score'] = 10
        elif bpm < BPM_WARNING_LOW:
            processed['risk_level'] = 'warning_low'
            processed['risk_score'] = 5
        elif bpm <= BPM_WARNING_HIGH:
            processed['risk_level'] = 'normal'
            processed['risk_score'] = 0
        elif bpm <= BPM_CRITICAL_HIGH:
            processed['risk_level'] = 'warning_high'
            processed['risk_score'] = 5
        else:
            processed['risk_level'] = 'critical_high'
            processed['risk_score'] = 10
        
        # Añadir timestamp de procesamiento
        processed['fog_timestamp'] = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
        
        # Calcular calidad de señal normalizada
        signal_quality = processed.get('signal_quality', 100)
        processed['signal_quality_normalized'] = min(100, max(0, signal_quality)) / 100.0
        
        return processed
    
    def update_device_stats(self, device_id: str, data: dict):
        """Actualiza estadísticas del dispositivo para agregación."""
        with self.lock:
            if device_id not in self.device_buffers:
                self.device_buffers[device_id] = deque(maxlen=100)
                self.device_stats[device_id] = {
                    'total_received': 0,
                    'total_sent_to_cloud': 0,
                    'last_sent_time': 0,
                    'avg_bpm': 0,
                    'min_bpm': float('inf'),
                    'max_bpm': 0
                }
            
            self.device_buffers[device_id].append(data)
            stats = self.device_stats[device_id]
            stats['total_received'] += 1
            
            bpm = data.get('bpm', 0)
            stats['min_bpm'] = min(stats['min_bpm'], bpm)
            stats['max_bpm'] = max(stats['max_bpm'], bpm)
            
            # Calcular promedio móvil
            buffer = self.device_buffers[device_id]
            if buffer:
                stats['avg_bpm'] = sum(d.get('bpm', 0) for d in buffer) / len(buffer)
    
    def should_send_to_cloud(self, data: dict) -> tuple[bool, str]:
        """
        Decide si un mensaje debe enviarse a la nube.
        Retorna (should_send, reason)
        """
        if not data.get('valid', False):
            return False, "Datos inválidos"
        
        # Modo: enviar todo
        if self.send_all:
            return True, "Modo enviar todo"
        
        risk_level = data.get('risk_level', 'normal')
        device_id = data.get('device_id', 'unknown')
        
        # Siempre enviar eventos críticos
        if risk_level in ['critical_low', 'critical_high']:
            return True, f"Evento crítico: {risk_level}"
        
        # Modo: solo críticos
        if self.critical_only:
            return False, "Modo solo críticos - evento no crítico"
        
        # Enviar advertencias
        if risk_level in ['warning_low', 'warning_high']:
            return True, f"Evento de advertencia: {risk_level}"
        
        # Para eventos normales, agregar y enviar periódicamente
        with self.lock:
            stats = self.device_stats.get(device_id, {})
            last_sent = stats.get('last_sent_time', 0)
            current_time = time.time()
            
            # Enviar resumen cada AGGREGATION_WINDOW segundos
            if current_time - last_sent >= AGGREGATION_WINDOW:
                buffer = self.device_buffers.get(device_id, [])
                if len(buffer) >= MIN_SAMPLES_FOR_AGGREGATION:
                    stats['last_sent_time'] = current_time
                    return True, f"Agregación periódica ({len(buffer)} muestras)"
        
        return False, "Agregando datos normales"
    
    def create_cloud_message(self, data: dict) -> dict:
        """Crea el mensaje optimizado para enviar a la nube."""
        device_id = data.get('device_id', 'unknown')
        
        with self.lock:
            stats = self.device_stats.get(device_id, {})
            stats['total_sent_to_cloud'] = stats.get('total_sent_to_cloud', 0) + 1
        
        # Crear mensaje compacto para la nube
        cloud_message = {
            'user_id': data.get('user_id'),
            'device_id': device_id,
            'timestamp': data.get('timestamp'),
            'bpm': data.get('bpm'),
            'risk_level': data.get('risk_level'),
            'risk_score': data.get('risk_score'),
            'fog_processed': True,
            'fog_timestamp': data.get('fog_timestamp'),
            'signal_quality': data.get('signal_quality_normalized'),
        }
        
        # Añadir estadísticas agregadas si están disponibles
        with self.lock:
            if device_id in self.device_stats:
                s = self.device_stats[device_id]
                cloud_message['aggregated_stats'] = {
                    'avg_bpm': round(s.get('avg_bpm', 0), 1),
                    'min_bpm': s.get('min_bpm') if s.get('min_bpm') != float('inf') else None,
                    'max_bpm': s.get('max_bpm') if s.get('max_bpm') > 0 else None,
                    'samples_received': s.get('total_received', 0)
                }
        
        return cloud_message
    
    def get_stats_summary(self) -> dict:
        """Retorna resumen de estadísticas de todos los dispositivos."""
        with self.lock:
            return {
                device_id: {
                    'received': stats.get('total_received', 0),
                    'sent_to_cloud': stats.get('total_sent_to_cloud', 0),
                    'filtered': stats.get('total_received', 0) - stats.get('total_sent_to_cloud', 0),
                    'avg_bpm': round(stats.get('avg_bpm', 0), 1)
                }
                for device_id, stats in self.device_stats.items()
            }


class CloudConnector:
    """Maneja la conexión con AWS IoT Core (nube)."""
    
    def __init__(self, endpoint: str, cert: str, key: str, root_ca: str, thing_name: str):
        self.endpoint = endpoint
        self.cert = cert
        self.key = key
        self.root_ca = root_ca
        self.thing_name = thing_name
        self.connection: Optional[mqtt.Connection] = None
        self.connected = False
    
    def connect(self) -> bool:
        """Establece conexión con AWS IoT Core."""
        try:
            print("Conectando a AWS IoT Core...")
            
            self.connection = mqtt_connection_builder.mtls_from_path(
                endpoint=self.endpoint,
                cert_filepath=self.cert,
                pri_key_filepath=self.key,
                ca_filepath=self.root_ca,
                client_id=self.thing_name,
                clean_session=True,
                keep_alive_secs=60,
                on_connection_interrupted=self._on_interrupted,
                on_connection_resumed=self._on_resumed
            )
            
            connect_future = self.connection.connect()
            connect_future.result(timeout=10)
            self.connected = True
            print("Conectado a AWS IoT Core!")
            return True
            
        except Exception as e:
            print(f"Error conectando a la nube: {e}")
            self.connected = False
            return False
    
    def _on_interrupted(self, connection, error, **kwargs):
        print(f"Conexión a la nube interrumpida: {error}")
        self.connected = False
    
    def _on_resumed(self, connection, return_code, session_present, **kwargs):
        print(f"Conexión a la nube restaurada")
        self.connected = True
    
    def publish(self, user_id: str, device_id: str, message: dict) -> bool:
        """Publica un mensaje a la nube."""
        if not self.connected or not self.connection:
            print("No hay conexión a la nube")
            return False
        
        try:
            topic = f"bpm/{user_id}/{device_id}/measurements"
            self.connection.publish(
                topic=topic,
                payload=json.dumps(message),
                qos=mqtt.QoS.AT_MOST_ONCE
            )
            return True
        except Exception as e:
            print(f"Error publicando a la nube: {e}")
            return False
    
    def disconnect(self):
        """Desconecta de AWS IoT Core."""
        if self.connection:
            try:
                disconnect_future = self.connection.disconnect()
                disconnect_future.result(timeout=5)
                print("Desconectado de AWS IoT Core")
            except:
                pass
            self.connected = False


class FogServer:
    """Servidor Fog que recibe datos de dispositivos IoT."""
    
    def __init__(self, port: int, processor: FogProcessor, cloud: Optional[CloudConnector]):
        self.port = port
        self.processor = processor
        self.cloud = cloud
        self.running = False
        self.server_socket = None
        self.clients = []
    
    def handle_client(self, client_socket: socket.socket, address: tuple):
        """Maneja la conexión de un cliente IoT."""
        print(f"Dispositivo conectado: {address}")
        buffer = ""
        
        try:
            while self.running:
                data = client_socket.recv(4096)
                if not data:
                    break
                
                buffer += data.decode('utf-8')
                
                # Procesar líneas completas
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    if line.strip():
                        self.process_message(line.strip())
                        
        except ConnectionResetError:
            pass
        except Exception as e:
            print(f"Error con cliente {address}: {e}")
        finally:
            print(f"Dispositivo desconectado: {address}")
            client_socket.close()
            if client_socket in self.clients:
                self.clients.remove(client_socket)
    
    def process_message(self, raw_message: str):
        """Procesa un mensaje recibido del dispositivo IoT."""
        try:
            data = json.loads(raw_message)
            device_id = data.get('device_id', 'unknown')
            bpm = data.get('bpm', 0)
            
            # 1. Preprocesar
            processed = self.processor.preprocess(data)
            
            # 2. Actualizar estadísticas
            self.processor.update_device_stats(device_id, processed)
            
            # 3. Decidir si enviar a la nube
            should_send, reason = self.processor.should_send_to_cloud(processed)
            
            # 4. Mostrar estado
            status_icon = self._get_status_icon(processed.get('risk_level', 'normal'))
            cloud_icon = " - " if should_send else " + "
            
            print(f"  {status_icon} BPM: {bpm:3d} | {cloud_icon} {reason}")
            
            # 5. Enviar a la nube si corresponde
            if should_send and self.cloud and self.cloud.connected:
                cloud_message = self.processor.create_cloud_message(processed)
                user_id = data.get('user_id', 'unknown')
                if self.cloud.publish(user_id, device_id, cloud_message):
                    print(f"     Enviado a la nube")
                else:
                    print(f"     Error enviando a la nube")
                    
        except json.JSONDecodeError as e:
            print(f"Mensaje inválido: {e}")
        except Exception as e:
            print(f"Error procesando mensaje: {e}")
    
    def _get_status_icon(self, risk_level: str) -> str:
        """Retorna el icono según el nivel de riesgo."""
        icons = {
            'critical_low': 'ROJO',
            'warning_low': 'AMARILLO',
            'normal': 'VERDE',
            'warning_high': 'AMARILLO',
            'critical_high': 'ROJO'
        }
        return icons.get(risk_level, 'BLANCO')
    
    def start(self):
        """Inicia el servidor fog."""
        self.running = True
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind(('0.0.0.0', self.port))
        self.server_socket.listen(5)
        self.server_socket.settimeout(1.0)
        
        print(f"\n Fog Server escuchando en puerto {self.port}...")
        print("Esperando dispositivos IoT...\n")
        
        try:
            while self.running:
                try:
                    client_socket, address = self.server_socket.accept()
                    self.clients.append(client_socket)
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, address),
                        daemon=True
                    )
                    client_thread.start()
                except socket.timeout:
                    continue
                    
        except KeyboardInterrupt:
            print("\n\nDeteniendo servidor...")
        finally:
            self.stop()
    
    def stop(self):
        """Detiene el servidor fog."""
        self.running = False
        
        # Mostrar estadísticas finales
        print("\nEstadísticas finales:")
        stats = self.processor.get_stats_summary()
        for device_id, device_stats in stats.items():
            print(f"      {device_id}:")
            print(f"      Recibidos: {device_stats['received']}")
            print(f"      Enviados a nube: {device_stats['sent_to_cloud']}")
            print(f"      Filtrados: {device_stats['filtered']}")
            print(f"      BPM promedio: {device_stats['avg_bpm']}")
        
        # Cerrar clientes
        for client in self.clients:
            try:
                client.close()
            except:
                pass
        
        # Cerrar servidor
        if self.server_socket:
            self.server_socket.close()
        
        # Desconectar de la nube
        if self.cloud:
            self.cloud.disconnect()


def main():
    parser = argparse.ArgumentParser(description='Fog Server - Servidor de borde para IoT')
    parser.add_argument('--port', type=int, default=DEFAULT_FOG_PORT,
                        help='Puerto para recibir datos IoT')
    parser.add_argument('--endpoint', default=DEFAULT_ENDPOINT,
                        help='AWS IoT Core endpoint')
    parser.add_argument('--cert', default=DEFAULT_CERT,
                        help='Ruta al certificado del dispositivo')
    parser.add_argument('--key', default=DEFAULT_KEY,
                        help='Ruta a la clave privada')
    parser.add_argument('--root-ca', default=DEFAULT_ROOT_CA,
                        help='Ruta al certificado raíz CA')
    parser.add_argument('--thing-name', default=DEFAULT_THING_NAME,
                        help='Nombre del Thing IoT')
    parser.add_argument('--no-cloud', action='store_true',
                        help='No conectar a la nube (solo procesar localmente)')
    parser.add_argument('--send-all', action='store_true',
                        help='Enviar todos los mensajes a la nube (sin filtrar)')
    parser.add_argument('--critical-only', action='store_true',
                        help='Enviar solo eventos críticos a la nube')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("🌫️  Fog Server - Computación en el Borde")
    print("=" * 60)
    print(f"Puerto local: {args.port}")
    print(f"Conexión a nube: {'Deshabilitada' if args.no_cloud else 'Habilitada'}")
    print(f"Modo filtrado: ", end="")
    if args.send_all:
        print("Enviar todo")
    elif args.critical_only:
        print("Solo críticos")
    else:
        print("Inteligente (críticos + advertencias + agregación)")
    print("=" * 60)
    
    # Crear procesador
    processor = FogProcessor(
        send_all=args.send_all,
        critical_only=args.critical_only
    )
    
    # Crear conector de nube (opcional)
    cloud = None
    if not args.no_cloud:
        cloud = CloudConnector(
            endpoint=args.endpoint,
            cert=args.cert,
            key=args.key,
            root_ca=args.root_ca,
            thing_name=args.thing_name
        )
        if not cloud.connect():
            print("Continuando sin conexión a la nube...")
            cloud = None
    
    # Crear y ejecutar servidor
    server = FogServer(args.port, processor, cloud)
    server.start()


if __name__ == "__main__":
    main()
