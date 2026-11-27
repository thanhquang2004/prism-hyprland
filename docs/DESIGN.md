# Prism — bản thiết kế

Desktop riêng cho Hyprland 0.57 (Lua) + Quickshell. Máy: laptop ASUS (eDP-1 16:10), màn cong 24" HDMI-A-1 (16:9), màn DP-1 xoay dọc.

## 1. Phong cách

| Mục | Quyết định |
|---|---|
| Chất liệu | Kính mờ nhẹ: nền ~70–80%, blur vừa, chữ luôn dễ đọc |
| Màu | Tự sinh từ wallpaper (wallust) |
| Sáng/tối | Đi theo night light: bật hyprsunset → tối, tắt → sáng |
| Font | Sans hiện đại (Inter / Geist), icon Nerd Font |
| Ngôn ngữ | Tiếng Anh, giờ 24h (`Fri, Nov 27 · 14:30`) |

## 2. Bar (đổi từ island, 27/11)

- **Hình dáng:** một thanh kính Frost nổi, bo tròn hai đầu, cách mép màn hình 8px. Chỉ có viền mảnh, không có vệt sáng.
- **Mỗi màn một bar**, bố cục theo tỉ lệ và hướng màn hình. Màn dọc thì gọn: ẩn tray và các nhãn số, mỗi workspace chỉ hiện 1 icon.
- **Trái:** workspace của màn đó, luôn hiện (số + icon app), bấm để chuyển.
- **Giữa:** đồng hồ; khi có nhạc thì thêm sóng âm và tên bài; rê chuột vào thì hiện ngày.
- **Phải:** tray (chuột trái kích hoạt, chuột phải mở menu), mạng, âm lượng, pin.
- **Sự kiện** (trước đây do island nở ra), dự kiến:
  - Âm lượng/độ sáng và thông báo ngắn: popup kính nhỏ ngay dưới giữa bar
  - Họp: chấm mic/camera và "đang chia sẻ" nằm ở cụm phải của bar
- **Fullscreen / game:** bar ẩn, popup sự kiện vẫn hiện.

## 3. Control center

- **Kiểu:** panel kính thả xuống từ cụm phải của bar.
- **Mở trên:** màn hình đang focus.
- **Cách mở:** bấm vào cụm trạng thái bên phải, phím tắt (SUPER+SHIFT+E), vuốt touchpad xuống.
- **Nội dung:**
  - Kết nối: wifi (chọn mạng), bluetooth (kết nối thiết bị), VPN, chế độ máy bay
  - Âm thanh: âm lượng, mic, chọn thiết bị ra/vào, âm lượng từng app
  - Hiển thị & nguồn: độ sáng, night light (kéo theo sáng/tối), pin, profile asusctl, game mode
  - Tiện ích: wallpaper, dwindle/master, bật/tắt blur, không làm phiền, chụp màn hình, menu nguồn
- **Họp:** phím tắt mute/unmute mic toàn hệ thống, island báo trạng thái.

## 4. Cửa sổ

| Mục | Quyết định |
|---|---|
| Khoảng cách | Rộng rãi: gaps ~10–14px |
| Bo góc | ~16px, viền mảnh theo màu nhấn |
| Cửa sổ không focus | Hơi trong suốt (thấy blur phía sau) |
| Hiệu ứng | Mượt, nhanh (~200ms, spring) + wobble khi kéo (0.57) |

## 5. Màn hình khóa (hyprlock)

- **Mỗi màn hình đều đầy đủ**, bố cục theo tỉ lệ từng màn (màn dọc xếp theo chiều dọc).
- **Nội dung:**
  - Đồng hồ lớn + ngày
  - Avatar + tên
  - Nhạc đang phát
  - Pin, thời tiết, layout bàn phím
- **Phong cách:** kính mờ đồng bộ với island, wallpaper hiện tại được làm mờ.
- **Idle (hypridle):** khóa sau 15 phút, tắt màn sau 30 phút.

## 6. Wallpaper

- **Chu kỳ:** tự đổi mỗi tuần.
- **Mỗi màn một ảnh khác nhau:** 2 màn ngang dùng 2 ảnh khác nhau; màn dọc DP-1 lấy từ bộ ảnh dọc riêng.
- **Phong cách:** abstract/gradient, illustration/anime, kiến trúc/đô thị.
- **Màu hệ thống:** lấy từ wallpaper màn chính (eDP-1).
- **Nguồn ảnh:** sẽ tìm bộ ảnh có giấy phép rõ ràng; xin phép trước khi tải.

## 7. Giữ nguyên

- Keybinds (`~/.config/hypr/keybinds.lua`, đã qua kiểm tra của 0.57.2)
- rofi (launcher), swaync (lịch sử thông báo), `monitors.lua`
- Công việc chính: lập trình + họp/chia sẻ màn hình

## 8. Lộ trình

1. Repo `~/.config/prism` (git). Bar cho 3 màn trên 0.56, chạy song song waybar.
2. Popup sự kiện (OSD, thông báo), chỉ báo họp, ẩn khi fullscreen.
3. Control center (thả xuống từ bar) + hệ màu wallust + sáng/tối theo night light.
4. Wallpaper: bộ ảnh, đổi hằng tuần theo từng màn.
5. hyprlock + hypridle.
6. Lên 0.57: `hyprland.lua` hoàn chỉnh, wobble, tắt waybar/JaKooLit (giữ bản sao lưu).
