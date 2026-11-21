# BongbongAI — AI bubble độc lập trên CarPlay

**v0.1.0 / SOURCE PROTOTYPE. Chưa có BUILD PASS, DEVICE PASS hoặc DEB hợp lệ.**

Dự án riêng hoàn toàn với DuoCar/OmniCar/DuoNavi. Mục tiêu: bong bóng tím trên CarPlay, người dùng nhập **Gemini API key** trên iPhone, hỏi AI rồi nghe câu trả lời đủ ý. Không dùng Cloudflare Worker hoặc Gemini Live.

## Thiết kế đã chốt

1. Tweak Theos rootless, package `com.chuong.bongbongai`; injection chỉ trong `com.apple.CarPlayApp`, chỉ hiện bong bóng trên external `UIWindowScene`.
2. **BYOK trực tiếp Google**: API HTTPS `https://generativelanguage.googleapis.com/v1beta/interactions`, header `x-goog-api-key`; mỗi request `store:false`.
3. **Hai bước tách biệt**: Gemini văn bản `gemini-3.5-flash-lite` hoàn tất rồi mới Gemini TTS `gemini-3.1-flash-tts-preview`; nhận PCM 24 kHz, tạo WAV đầy đủ và phát qua một AVAudioPlayer. Không tự cắt câu dài hoặc phát audio thiếu.
4. Nút **Đọc thử** với Apple TTS riêng để xác định đường âm thanh khi Gemini chưa có API key. Nút Dừng hủy request/âm thanh.
5. Bản đầu thử nhập chữ hoặc câu mẫu (khi keyboard không khả dụng). Micro/STT là giai đoạn sau khi đường audio đã DEVICE PASS.

## Nguyên tắc nghiệm thu

- `STATIC PASS`: kiểm tra nguồn với fixture hoặc script **không đồng nghĩa** với compile hay CarPlay hoạt động.
- `BUILD PASS`: Theos đóng gói đúng rootless và kiểm tra DEP/filters.
- `DEVICE PASS`: xác nhận trực tiếp UI/touch, API, lời cuối câu nghe trên loa, các profile iCarCast/xe thật. Callback phát xong không chứng minh người dùng nghe đủ.

## Quyền riêng tư và cảnh báo

**Không hardcode hoặc commit API key.** Trong bản prototype, chia sẻ key giữa app Config và CarPlayApp qua CFPreferences còn chưa được thử trên thiết bị và **không phải bảo mật Keychain**. Chỉ dùng key thử nghiệm hạn mức thấp; trước phát hành phải có cơ chế lưu trữ/IPC an toàn hơn. Trên thiết bị jailbreak, mọi client-side key đều có rủi ro bị trích xuất.

Không triển khai bất kỳ Worker hay thay đổi nào lên DuoCar. Chỉ kiểm tra trên xe khi **đang đỗ**.

## Tài liệu kỹ thuật

- [Google Gemini Interactions](https://ai.google.dev/gemini-api/docs/get-started)
- [Gemini TTS](https://ai.google.dev/gemini-api/docs/speech-generation)
- [Theos rootless](https://theos.dev/docs/rootless)

Các file source và phép kiểm tra sẽ được bổ sung trong những commit riêng, để không đánh đồng bản thiết kế với ứng dụng đã chạy.
