#!/usr/bin/env python3
"""TCP relay: :8443 -> bntpool.com:3333.

Forwarder stratum mentah dua arah (bukan HTTP proxy). Tidak membaca/mencatat
isi stratum. TANPA allowlist: nerima koneksi dari IP mana pun (open semua).

Perbaikan penting (25 Okt 2026): socket.create_connection(timeout=15)
menempel timeout baca 15 dtk di socket ke pool. Pool bisa diam >15 dtk
antar job, jadi ubah ke blocking (settimeout(None)) setelah connect.
"""
import socket
import threading

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 8443
TARGET_HOST = "bntpool.com"
TARGET_PORT = 3333


def pump(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        try:
            dst.shutdown(socket.SHUT_WR)
        except OSError:
            pass


def handle(client):
    try:
        upstream = socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=15)
        upstream.settimeout(None)
    except OSError:
        client.close()
        return
    t1 = threading.Thread(target=pump, args=(client, upstream), daemon=True)
    t2 = threading.Thread(target=pump, args=(upstream, client), daemon=True)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    client.close()
    upstream.close()


def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((LISTEN_HOST, LISTEN_PORT))
    srv.listen(64)
    print(f"relay listening {LISTEN_HOST}:{LISTEN_PORT} -> {TARGET_HOST}:{TARGET_PORT}", flush=True)
    while True:
        client, addr = srv.accept()
        print(f"relay conn from {addr[0]}:{addr[1]}", flush=True)
        threading.Thread(target=handle, args=(client,), daemon=True).start()


if __name__ == "__main__":
    main()