"""
Reenvía mediciones BPM reales al servidor Fog
Origen: MKR WiFi 1010 → TCP → este script
"""

import json
import time
import socket
import argparse
from datetime import datetime, timezone


# ---------------- CONFIG DEFAULT ----------------
DEFAULT_FOG_HOST = "10.7.134.140"
DEFAULT_FOG_PORT = 25000

DEFAULT_LOCAL_HOST = "0.0.0.0"
DEFAULT_LOCAL_PORT = 5000   # donde llega el MKR

DEFAULT_USER_ID = "c4d8f488-50c1-7057-ff7f-d5a364540807"
DEFAULT_DEVICE_ID = "bpm-device-010"


# ---------------- MENSAJE ----------------
def create_message(user_id: str, device_id: str, bpm: int) -> dict:
    return {
        "user_id": user_id,
        "device_id": device_id,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "bpm": bpm
    }


def get_bpm_status(bpm: int) -> str:
    if bpm < 40:
        return " CRÍTICO BAJO"
    elif bpm < 50:
        return " Advertencia baja"
    elif bpm <= 100:
        return " Normal"
    elif bpm <= 150:
        return " Advertencia alta"
    else:
        return " CRÍTICO ALTO"


# ---------------- FOG ----------------
def connect_to_fog(host: str, port: int, max_retries: int = 5) -> socket.socket:
    retries = 0
    while retries < max_retries:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((host, port))
            return sock
        except Exception:
            retries += 1
            print(f"⚠️  Fog no disponible ({retries}/{max_retries})")
            time.sleep(2)
    raise ConnectionError("No se pudo conectar al Fog Server")


def send_to_fog(sock: socket.socket, message: dict) -> bool:
    try:
        sock.sendall((json.dumps(message) + "\n").encode())
        return True
    except Exception:
        return False


# ---------------- MAIN ----------------
def main():
    parser = argparse.ArgumentParser(description="IoT Sender BPM REAL")
    parser.add_argument("--fog-host", default=DEFAULT_FOG_HOST)
    parser.add_argument("--fog-port", type=int, default=DEFAULT_FOG_PORT)
    parser.add_argument("--local-port", type=int, default=DEFAULT_LOCAL_PORT)
    parser.add_argument("--user-id", default=DEFAULT_USER_ID)
    parser.add_argument("--device-id", default=DEFAULT_DEVICE_ID)
    args = parser.parse_args()

    print("=" * 60)
    print("🫀 IoT Sender BPM REAL")
    print("=" * 60)

    # Fog
    print("🔌 Conectando al Fog Server...")
    fog_sock = connect_to_fog(args.fog_host, args.fog_port)
    print(" Conectado al Fog Server")

    # TCP local
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((DEFAULT_LOCAL_HOST, args.local_port))
    server.listen(1)

    print(f" Esperando datos del MKR en puerto {args.local_port}...")
    conn, addr = server.accept()
    print(f"🔗 MKR conectado desde {addr}")

    buffer = ""
    count = 0

    try:
        while True:
            data = conn.recv(1024).decode()
            if not data:
                continue

            buffer += data

            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()

                if not line:
                    continue

                # Esperado: timestamp,bpm
                parts = line.split(",")
                if len(parts) != 2:
                    continue

                _, bpm_raw = parts

                try:
                    bpm = int(bpm_raw)
                except ValueError:
                    continue

                if bpm < 30 or bpm > 200:
                    continue

                message = create_message(args.user_id, args.device_id, bpm)

                if send_to_fog(fog_sock, message):
                    count += 1
                    status = get_bpm_status(bpm)
                    print(f"[{count}] {message['timestamp'][:19]} | BPM {bpm:3d} | {status} | 📤 Fog")
                else:
                    print("❌ Error enviando al Fog, reconectando...")
                    fog_sock.close()
                    fog_sock = connect_to_fog(args.fog_host, args.fog_port)

    except KeyboardInterrupt:
        print("\n⏹  Finalizado por usuario")

    finally:
        conn.close()
        fog_sock.close()
        server.close()
        print(" Conexiones cerradas")


if __name__ == "__main__":
    main()
