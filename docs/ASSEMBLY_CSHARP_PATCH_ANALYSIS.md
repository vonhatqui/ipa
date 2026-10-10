# BÁO CÁO PHÂN TÍCH FILE: Assembly-CSharp-patch.bytes & localConfig.json

---

## 1. TỔNG QUAN FILE NGUỒN

| Thuộc tính | Giá trị kiểm tra thực tế |
| :--- | :--- |
| **Tên file chính xác** | `Assembly-CSharp-patch.bytes` |
| **Dung lượng** | 67,794 bytes (~66.2 KB) |
| **File cấu hình đi kèm** | `localConfig.json` (1,012 bytes) |
| **Header Hex** | `CB A2 B4 0D B2 19 A3 66 64 49 46 69 78 2E 49 4C 46 69 78 49 6E 74 65 72 66 61 63 65 42 72 69 64` |
| **Header ASCII** | `.......fdIFix.ILFixInterfaceBridge...` |

---

## 2. KẾT QUẢ PHÂN TÍCH ĐỊNH DẠNG (FORMAT IDENTIFICATION)

### 2.1. Định dạng file là gì?
- File là định dạng **Tencent InjectFix (IFix / ILFix)** binary patch.
- Header chứa chuỗi nhận diện: `IFix.ILFixInterfaceBridge`.
- Đây là định dạng bản vá C# bytecode runtime của giải pháp InjectFix (do Tencent phát triển dành cho Unity Engine). Mục đích ban đầu của InjectFix là cho phép các nhà phát triển game hot-fix (sửa lỗi nóng) mã nguồn C# trên iOS mà không cần đóng gói lại toàn bộ ứng dụng hay vượt qua khâu kiểm duyệt của Apple.

### 2.2. Dữ liệu nhị phân, assembly đã biên dịch hay định dạng tùy chỉnh?
- **Không phải** là mã máy nhị phân native (Mach-O ARM64 hay x86_64).
- **Không phải** là một file .NET PE assembly hoàn chỉnh (`.dll` có header MZ/PE).
- **Đây là định dạng bytecode thông dịch tùy chỉnh (Interpreted Bytecode Data Format)** của máy ảo InjectFix (IFix Virtual Machine).
- File chứa danh sách các method đã được thay thế (hook/redirect), bảng ánh xạ ID các lớp/phương thức trong game gốc, cùng với khối lệnh IL ảo được thực thi thông qua bridge `IFix.ILFixInterfaceBridge`.

---

## 3. CÁC PHẦN ĐÃ PHÂN TÍCH & GIẢI MÃ

Qua việc quét chuỗi nhị phân (binary strings scanning) và bảng siêu dữ liệu (metadata tables), các phần sau đã được xác minh chính xác:

1. **Assembly mục tiêu (Target Assembly):**
   - Tên: `Assembly-CSharp`
   - Phiên bản: `0.86.0.518`
   - Culture: `neutral`
   - PublicKeyToken: `null`
   - Runtime cơ sở: `mscorlib 4.0.0.0`, `UnityEngine.CoreModule 0.0.0.0`

2. **Các lớp đối tượng bị can thiệp (Patched Target Classes):**
   - `COW.GamePlay.Player`: Đối tượng nhân vật trong game (xử lý di chuyển, vị trí, ngắm bắn). *(Lưu ý: `COW` - City of War là mã dự án nội bộ của Free Fire).*
   - `COW.UIModelLogin`: Giao diện và logic liên quan đến tài khoản/đăng nhập.
   - `COW.GameConfig` & `COW.GameVarDef`: Bảng biến số và cấu hình tham số trận đấu.
   - `COW.GamePlay.SceneEditBoxSelectTool`

3. **Các hook/method đặc trưng:**
   - `get_AimStartPostion`
   - `set_LockedAimingCollider`
   - `__esp_driver`
   - `__esp_fov`
   - `ESP_AimLockX10`
   - `ESP_CamXaFloat`
   - `recoil`

---

## 4. MỐI QUAN HỆ TRỰC TIẾP GIỮA Assembly-CSharp-patch.bytes VÀ localConfig.json

Bản vá `Assembly-CSharp-patch.bytes` **liên quan trực tiếp 100%** đến file `localConfig.json`. Khi runtime của InjectFix nạp bản vá này vào tiến trình game, các phương thức được thay thế sẽ đọc các khóa cấu hình từ `localConfig.json` để quyết định hành vi:

| Khóa trong `localConfig.json` | Kiểu dữ liệu | Giá trị hiện tại | Ý nghĩa trong bản vá |
| :--- | :--- | :--- | :--- |
| `FovSize` | Int (Number) | `314` | Bán kính vòng tròn ngắm FOV |
| `AimTarget` | Int (Enum) | `0` | Mục tiêu ngắm (0: Đầu, 1: Cổ, 2: Ngực) |
| `AimEnabled` | Bool | `true` | Bật/tắt tính năng khóa ngắm |
| `AimSystemEnabled` | Bool | `true` | Công tắc tổng hệ thống ngắm |
| `HeadshotRate` | Int | `60` | Tỉ lệ ưu tiên kéo tâm vào đầu (%) |
| `EspMaster` | Bool | `true` | Công tắc tổng hệ thống ESP |
| `EspName` | Bool | `true` | Hiển thị tên người chơi |
| `EspDistance` | Bool | `true` | Hiển thị khoảng cách theo mét |
| `EspBox` | Bool | `true` | Hiển thị khung định vị quanh nhân vật |
| `EspHealth` | Bool | `true` | Hiển thị lượng máu HP |
| `EspSkeleton` | Bool | `true` | Hiển thị khung xương |
| `EspTracer` | Bool | `false` | Hiển thị tia định hướng |
| `EspLine` | Bool | `true` | Hiển thị đường kẻ |
| `EspFov` | Bool | `true` | Hiển thị vòng tròn FOV |
| `NoRecoil` | Bool | `false` | Giảm độ giật vũ khí |
| `CamXaFloat` | Double (Float) | `1.4` | Hệ số phóng xa khoảng cách camera |
| `SpeedHack` | Int | `2` | Hệ số tốc độ di chuyển |
| `GhostMode` | Bool | `true` | Chế độ bóng ma/tàng hình |
| `FastParachute` | Bool | `false` | Nhảy dù tốc độ cao |

Các trường máy chủ / xác thực được bảo toàn nguyên vẹn:
- `sig`: `"afb3b132ca3c183c6d336da69d14f697"` (chữ ký MD5/HMAC)
- `token`: `"5b9631466c114ca3a51ca22b15de67b5"` (token xác thực)
- `ts`: `1791539526` (timestamp)
- `meomeo`: `"21f64182074ef818582c0e0bb9597a8e"` (hash nội bộ)
- Các cờ máy chủ: `server_esp`, `server_aim`, `server_headshot`, `server_distance`, `server_skeleton`, `server_line`, `server_box`, `server_health`, `server_name`.

---

## 5. CÁC PHỤ THUỘC & THÀNH PHẦN CÒN THIẾU

Để `Assembly-CSharp-patch.bytes` có thể hoạt động thực tế trong game, cần các điều kiện sau:

1. **Unity Engine với InjectFix Runtime:**
   - Trong game gốc phải có sẵn module `IFix.Core.dll` hoặc Unity IL2CPP runtime đã được tiêm mã hỗ trợ InjectFix Bridge.
2. **Cơ chế nạp Patch (Patch Loader):**
   - Bản thân file `.bytes` chỉ là file dữ liệu thụ động (passive data asset). Nó **không thể tự nạp** vào game nếu không có một loader (Dylib hoặc tweak) gọi hàm `IFix.PatchManager.Load(bytes)` bên trong game.
3. **Ứng dụng 3105-New:**
   - Đóng vai trò là **Trình Quản Lý Cấu Hình (Configuration Manager)**: Tạo, chỉnh sửa, xác thực, sao lưu và đồng bộ `localConfig.json` an toàn.
   - Ứng dụng **không thể và không được phép** tự can thiệp bộ nhớ hoặc vượt qua hệ thống chống gian lận từ xa nếu không có thành phần injection được cấp phép trên thiết bị.
