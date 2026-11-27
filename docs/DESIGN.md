# Prism — bản thiết kế

Desktop riêng cho Hyprland 0.57 (Lua) + Quickshell. Máy: laptop ASUS (eDP-1 16:10), màn cong 24" HDMI-A-1 (16:9), màn DP-1 xoay dọc.

## 1. Phong cách

| Mục | Quyết định |
|---|---|
| Chất liệu | Kính mờ: tối = "Smoke" (kính khói, chữ trắng), sáng = "Milky" (kính sữa, chữ tối) |
| Màu | Một màu mực cho chữ và icon; màu nhấn lấy từ wallpaper màn chính (tile bật, slider, sóng nhạc) |
| Sáng/tối | Đi theo night light (`~/.cache/.hyprsunset_state`): bật → Smoke, tắt → Milky |
| Font | Inter; icon đơn sắc Material Design Icons (Nerd Font), tray được làm phẳng về cùng màu mực |
| Power menu | Toàn màn hình trên màn đang focus, phím L/E/S/R/P, mũi tên + Enter; Đăng xuất / Khởi động lại / Tắt máy đếm ngược 5 giây, Esc để hủy |
| Ngôn ngữ | Tiếng Anh, giờ 24h (`Fri, Nov 27 · 14:30`) |

## 2. Bar (đổi từ island, 27/11)

- **Hình dáng:** một thanh kính Frost nổi, bo tròn hai đầu, cách mép màn hình 8px. Chỉ có viền mảnh, không có vệt sáng.
- **Mỗi màn một bar**, bố cục theo tỉ lệ và hướng màn hình. Màn dọc thì gọn: ẩn tray và các nhãn số, mỗi workspace chỉ hiện 1 icon.
- **Trái:** chuông thông báo (số chưa đọc; chuột trái mở bảng, chuột phải bật/tắt Không làm phiền), sau đó là workspace của màn đó (số + icon app), bấm để chuyển.
- **Giữa:** đồng hồ có giây (`HH:mm:ss`); khi có nhạc thì thêm sóng âm và tên bài; rê chuột vào thì hiện ngày.
- **Phải:** tray (chuột trái kích hoạt, chuột phải mở menu), mạng, âm lượng, pin, nút sáng/tối (☀/☾: đổi tay, giữ đến khi night light đổi lại), nút ⏻ mở power menu.
- **Thông báo (Prism tự làm, thay swaync):** bảng kính thả xuống dưới chuông, gộp theo app (bấm mũi tên để mở nhóm), nút hành động của thông báo, bấm vào thông báo để mở app, Clear all, Không làm phiền. Popup thông báo mới hiện dưới chuông ~5 giây (giữ chuột thì không tự ẩn; Critical thì ở lại).
- **OSD:** âm lượng, độ sáng, bật/tắt mic hiện thành viên kính dưới giữa bar trên màn đang focus (~1.4s). Thông báo âm lượng/độ sáng của script cũ bị lọc bỏ.
- **Họp (cụm phải):** viên cam hiện khi mic / camera / chia sẻ màn hình đang dùng. Bấm mic để tắt/bật mic, bấm "Sharing" để dừng chia sẻ. Bỏ qua các luồng chỉ nghe loa (cava, EasyEffects).
- **Fullscreen / game:** bar trượt lên và ẩn trên màn đó; OSD và popup vẫn hiện.

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

## 5. Màn hình khóa (Quickshell, `lock/qml`)

- **Chạy:** `prism-lock` (Ctrl+Alt+L, power menu, control center, hypridle). Chụp từng màn trước khi khóa để hiệu ứng vào/ra liền mạch; ảnh chụp xóa sau khi mở. Nếu màn khóa Prism không lên trong 5 giây hoặc crash khi đang khóa, tự chuyển sang hyprlock (cấu hình sinh ra ở `~/.cache/prism/hyprlock.conf`).
- **Hiệu ứng "lăng kính":**
  - Vào: tia sáng trắng kéo theo dải quang phổ quét chéo qua desktop, phía sau là wallpaper mờ + các vầng sáng trôi chậm; nội dung hiện lần lượt.
  - Biểu tượng lăng kính: tia sáng vào, 6 tia màu ra, lấp lánh.
  - Đồng hồ: giờ đậm, `:` màu nhấn nhịp theo giây, phút mảnh, giây nhỏ; mỗi chữ số lăn kiểu đồng hồ cơ khi đổi.
  - Gõ mật khẩu: mỗi ký tự một chấm màu quang phổ nảy lên; đang kiểm tra: chấm gợn sóng + chấm quay quanh avatar.
  - Sai: ô rung + tách màu đỏ/xanh; thông báo của PAM (vd. bị faillock) hiện bên dưới.
  - Mở: nội dung rơi xuống, tia sáng quét ngược trả lại desktop.
- **Theme cyberpunk** (`lock/qml/cyber`, mặc định; đổi trong `lock/theme` hoặc `prism-lock --theme prism|cyberpunk`): HUD tối, một màu neon vàng, cyan rất ít, đỏ chỉ cho lỗi; font JetBrains Mono.
  - Vào: desktop glitch (cắt lát lệch ngang + vệt màu) → tắt kiểu CRT thành một đường → đường neon mở ra HUD → tia quét vẽ HUD từ trên xuống, mọi nhãn tự "giải mã".
  - Chờ: đồng hồ thỉnh thoảng glitch tách RGB, dải sáng mờ trôi xuống, vạch giây chạy trên thước, uptime đếm.
  - Gõ: mỗi ký tự là katakana/ký hiệu nhấp nháy rồi thành khối vàng, khung sáng lên, mã hex đổi theo; con trỏ khối nhấp nháy.
  - Kiểm tra: khung cyan, thanh đoạn chạy. Sai: khung đỏ, rung, tách RGB, `ACCESS DENIED // <lý do>`. Đúng: `ACCESS GRANTED`, HUD tắt kiểu CRT, desktop bật lại.
- **Mỗi màn đều đầy đủ,** bố cục theo tỉ lệ: màn ngang thẻ nhạc góc trái dưới + chip góc phải dưới; màn dọc xếp giữa.
- **Xem thử không cần mật khẩu:** `prism-lock --preview`, mở bằng `quickshell ipc -p ~/.config/prism/lock/qml call lock testUnlock` (chế độ này không gọi PAM nên không bao giờ tính là đăng nhập sai).
- **Idle (hypridle):** tối màn ở phút 14, khóa ở phút 15, tắt màn ở phút 30; khóa trước khi suspend.
- **Lưu ý faillock:** 3 lần sai liên tiếp khóa 10 phút (mặc định Arch). Không mở khóa test bằng `pkill -USR1 hyprlock`: hyprlock tính đó là một lần sai.

## 6. Wallpaper

- **Chu kỳ:** tự đổi mỗi ngày (lúc qua ngày mới). Đổi ngẫu nhiên ngay: `Ctrl+Alt+W` (màn đang focus), `Ctrl+Alt+Shift+W` (mọi màn), lệnh `prism-wall [all|<output>]`, hoặc nút wallpaper trong control center (chuột phải: mọi màn).
- **Mỗi màn một ảnh khác nhau,** ưu tiên mỗi màn một phong cách, không lặp lại 40 ảnh gần nhất.
- **Màn dọc DP-1:** bộ ảnh dọc riêng + ảnh ngang được cắt dọc tự động theo vùng nhiều chi tiết nhất.
- **Phong cách:** illustration/anime, kiến trúc/đô thị (đã bỏ gradient tự sinh theo ý bạn).
- **Màu hệ thống:** lấy từ wallpaper màn chính (eDP-1).
- **Bộ ảnh** (`~/Pictures/wallpapers/prism/`, nguồn ghi trong `SOURCES.md` ở đó):
  - `ghibli-*`: 31 still chính thức từ ghibli.jp (dùng cá nhân "trong phạm vi lẽ thường").
  - `unsplash-*`: 22 ngang + 20 dọc kiến trúc/đô thị (Unsplash License).
  - `wallhaven-*`: 21 ngang + 5 dọc anime đa dạng (wallhaven.cc, bản quyền không rõ: chỉ dùng cá nhân, không phát tán).

## 7. Giữ nguyên

- Keybinds (`~/.config/hypr/keybinds.lua`, đã qua kiểm tra của 0.57.2)
- rofi (launcher), swaync (lịch sử thông báo), `monitors.lua`
- Công việc chính: lập trình + họp/chia sẻ màn hình

## 8. Lộ trình

1. ✅ Repo `~/.config/prism` (git). Bar cho 3 màn trên 0.56, chạy song song waybar.
2. ✅ OSD, chỉ báo họp, ẩn khi fullscreen, thông báo riêng (27/11).
3. ✅ Control center (thả xuống từ cụm trạng thái) + màu nhấn từ wallpaper (27/11). Chưa có: vuốt touchpad (làm ở bước 0.57).
4. ✅ Wallpaper: bộ ảnh riêng, đổi mỗi ngày, mỗi màn một ảnh, màn dọc có ảnh cắt (27/11).
5. ✅ hyprlock + hypridle (27/11).
6. Lên 0.57: `hyprland.lua` hoàn chỉnh, wobble, tắt waybar/JaKooLit (giữ bản sao lưu).
