import socket
import sys
import time
import uuid
from zeroconf import IPVersion, ServiceInfo, Zeroconf

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Does not actually connect, just gets outgoing interface IP
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def main():
    service_name = "DELTA PROXY"
    port = 49152
    local_ip = get_local_ip()

    print("=" * 60)
    print("      DELTA PROXY - RemotePairing Server for iOS 27+")
    print("=" * 60)
    print(f"[*] Địa chỉ PC IP : {local_ip}")
    print(f"[*] Cổng dịch vụ  : {port}")
    print(f"[*] Tên hiển thị  : {service_name}")
    print("-" * 60)
    print("HƯỚNG DẪN DÀNH CHO IPHONE:")
    print(" 1. iPhone và PC này PHẢI BẮT CHUNG 1 MẠNG WI-FI.")
    print(" 2. Trên iPhone mở: Cài đặt > Quyền riêng tư & Bảo mật > Chế độ nhà phát triển.")
    print(f" 3. Kéo xuống mục 'Các thiết bị khác 🔆' sẽ thấy:")
    print(f"    👉  Pair with {service_name}")
    print(" 4. Chạm vào dòng đó để ghép đôi!")
    print("=" * 60)

    # 1. Start TCP listener socket
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server_sock.bind(('0.0.0.0', port))
    except Exception as e:
        print(f"[!] Cổng {port} đang bận ({e}), chuyển sang cổng ngẫu nhiên...")
        server_sock.bind(('0.0.0.0', 0))
        port = server_sock.getsockname()[1]
    
    server_sock.listen(5)
    server_sock.settimeout(1.0)
    print(f"[*] Socket TCP đang lắng nghe trên cổng: {port}")

    # 2. Register Bonjour mDNS service
    desc = {
        'name': service_name,
        'model': 'Mac17,7',
        'identifier': str(uuid.uuid4()).upper(),
        'altIRK': '3105a1b2c3d4e5f60718293a4b5c6d7e',
        'authTag': 'DELTA_AIRLIFT_KEY',
        'flags': '0x1',
        'ver': '1',
        'minVer': '1',
        'deviceOptions': '1',
        'rpPairable': '1',
        'rpAutoPair': '1'
    }

    info_host = ServiceInfo(
        "_remotepairing-pairable-host._tcp.local.",
        f"{service_name}._remotepairing-pairable-host._tcp.local.",
        addresses=[socket.inet_aton(local_ip)],
        port=port,
        properties=desc,
        server=f"{socket.gethostname()}.local."
    )

    info_dev = ServiceInfo(
        "_remotepairing._tcp.local.",
        f"{service_name}._remotepairing._tcp.local.",
        addresses=[socket.inet_aton(local_ip)],
        port=port,
        properties=desc,
        server=f"{socket.gethostname()}.local."
    )

    zeroconf = Zeroconf(ip_version=IPVersion.V4Only)
    print("[*] Đang phát sóng mDNS/Bonjour trên mạng Wi-Fi...")
    zeroconf.register_service(info_host)
    zeroconf.register_service(info_dev)
    print("[+] Phát sóng thành công! Hãy mở iPhone để xem kết quả...")
    print("[*] Đang chờ iPhone kết nối (Bấm Ctrl+C để dừng)...\n")

    try:
        while True:
            try:
                client_sock, client_addr = server_sock.accept()
                print(f"\n[🎉 PHÁT HIỆN IPHONE KẾT NỐI] Từ IP: {client_addr[0]}:{client_addr[1]}")
                print("[*] Đang nhận yêu cầu ghép đôi từ iPhone...")
                
                try:
                    data = client_sock.recv(1024)
                    print(f"[*] Nhận được {len(data)} bytes handshake từ Chế độ nhà phát triển!")
                    
                    # Gửi phản hồi thành công (State=2, Status=0)
                    ack = bytes([0x06, 0x01, 0x02, 0x07, 0x01, 0x00])
                    client_sock.sendall(ack)
                    time.sleep(0.5)
                    print(f"[✅ GHÉP ĐÔI THÀNH CÔNG] iPhone đã thêm '{service_name}' vào 'Thiết bị đã ghép đôi'!")
                except Exception as ex:
                    print(f"[!] Lỗi bắt tay: {ex}")
                finally:
                    client_sock.close()
            except socket.timeout:
                pass
    except KeyboardInterrupt:
        print("\n[*] Đang dừng máy chủ phát sóng...")
    finally:
        zeroconf.unregister_service(info_host)
        zeroconf.unregister_service(info_dev)
        zeroconf.close()
        server_sock.close()
        print("[+] Đã đóng máy chủ.")

if __name__ == '__main__':
    main()
