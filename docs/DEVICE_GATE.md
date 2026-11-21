# BongbongAI — nghiệm thu bắt buộc trên thiết bị

**Status: SOURCE PROTOTYPE; BUILD PENDING; DEVICE PENDING.**

- Chỉ kiểm thử khi xe đang đỗ. Không can thiệp điều hướng, gọi điện, âm thanh an toàn.

## G0 — gói và cô lập
- Theos/rootless compile và ký thật. ID duy nhất com.chuong.bongbongai.
- Filter chỉ com.apple.CarPlayApp; không sửa package/preferences/Worker/DEB DuoCar.
- Config app trên iPhone lưu khóa thử, CarPlay process có thể đọc key? Nếu chưa xác minh thì BLOCK.
- CFPreferences không phải Keychain, chưa đủ an toàn để phát hành; cần IPC/credential store được thẩm định.

## G1 — scene/overlay
- CarPlayApp có UIWindowScene ngoài thực? Không có thì báo BLIND/NO SURFACE, không tạo popup trên iPhone.
- Home, native, hosted solo/split, reconnect x5. Touch passthrough; không che Maps/dock.
- WindowLevelAlert không đảm bảo nổi trên hosted window ở tiến trình khác.

## G2 — văn bản và âm thanh
- Nút Đọc thử Apple TTS, nghe đủ chữ cuối khi không có API key.
- Nhập key thử với quota thấp; Gemini HTTP 200 + status=completed, nhận đủ text.
- TTS nhận nguyên văn, kiểm đủ WAV/PCM; không auto trim, không bỏ qua lỗi 503/silence.
- Ghi số ký tự, byte PCM, WAV duration, elapsed, AVAudioPlayer didFinish. Người dùng phải xác minh nghe chữ cuối; callback không đủ chứng minh loa đã phát.

## G3 — môi trường thật
- iCarCast This iPhone, iCarCast Connect và xe CarPlay thật là ba profile riêng.
- Mỗi profile ba câu ngắn, ba câu dài 300–450 ký tự; không cắt, không chồng giọng, không tự phát lại.
- Chỉ sau G0–G3 mới được làm mic/STT, kiểm quyền TCC và đường mic; không bypass.

Không tuyên bố DEVICE PASS chỉ từ unit test hoặc build thành công.
