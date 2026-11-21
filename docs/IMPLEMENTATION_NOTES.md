# BongbongAI v0.1 — các rủi ro còn mở

1. CarPlayApp có thể không cung cấp external UIWindowScene. Overlay fail-closed thay vì tự vẽ lên iPhone.
2. Windows khác process có thể che bong bóng trên hosted UI; chưa xác minh z-order.
3. Một số giao diện CarPlay khóa bàn phím. v0.1 cho phép nhấn Hỏi AI với câu mẫu khi trống; không dùng khi xe đang chạy.
4. Cấu hình key lưu CFPreferences; chưa chứng minh đọc chéo process/sandbox hay an toàn. Chỉ dùng key thử nghiệm có giới hạn. Cần cơ chế Keychain + IPC riêng trước phát hành.
5. Direct Interactions API non-streaming, store=false; parser đòi status=completed. Không cắt câu trên 500 ký tự: trả lỗi.
6. Gemini TTS có thể trả audio thiếu dù HTTP 200. Prototype buộc một block PCM 24 kHz, không chứng minh nội dung ngữ âm chỉ bằng duration. DEVICE nghe đủ chữ cuối.
7. Không đổi AVAudioSession toàn process ở v0.1. Apple TTS chỉ là diagnostic, không fallback giấu lỗi.
8. Môi trường viết mã chưa có Theos/iOS SDK, do đó chưa có compile/lint với iOS headers hoặc .deb hợp lệ.
