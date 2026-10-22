# GDQP Motion Studio — README

## Trạng thái kiểm tra hiện tại · 0.7.1

Bản vá logic cho 0.7.0: **hàng 3 tăng từ 0 lên 1**; hàng 1 và hàng 2 giữ nguyên theo quy ước version của người dùng.

### Bản hiện tại — Đồng bộ webcam/video và ổn định dữ liệu đa người

- Chế độ webcam + video mẫu giờ lấy frame video theo thời gian thực đã trôi qua, không còn đọc một frame mẫu cho mỗi lần tick camera; FPS camera đã chọn được áp dụng cho cả nhận diện độc lập lẫn so sánh trực tiếp. Khi quay lại tab đa so sánh, timer được tính lại theo cấu hình FPS mới.
- Đồng hồ phiên camera loại trừ khoảng thời gian tab bị tạm dừng, vì vậy video mẫu và timestamp không nhảy cóc khi người dùng chuyển sang Cài đặt rồi quay lại.
- Chu kỳ lưu mẫu video-video dựa trên các frame đã được căn chỉnh và thực sự xử lý (không dựa trực tiếp vào index nguồn có thể bị bỏ qua khi hai video khác FPS); chu kỳ webcam dựa trên lần suy luận pose mới, không bị lệch vì frame camera được vẽ lại giữa hai lần inference.
- ID theo dõi người được hết hạn theo thời gian thực (mặc định 1 giây), thay vì theo số lần suy luận; đổi cài đặt pose FPS không còn âm thầm kéo dài/ngắn thời gian giữ ID.
- JSON/CSV giữ đúng nguồn của phiên đã ghi ngay cả khi người dùng thay đổi lựa chọn tệp sau khi dừng; CSV có thêm tên nguồn tham chiếu và nguồn nhiều người để tự truy vết.
- Bổ sung regression tests cho căn frame theo elapsed time, tuổi track, chu kỳ lấy mẫu, metadata xuất, dừng theo ngưỡng căn video và loại trừ thời gian tạm dừng tab.
- Giới hạn số frame video mẫu được đọc bù trong mỗi tick; nếu vẫn tụt sau một nhịp chậm, tạm bỏ ghi mẫu thay vì so sánh với frame tham chiếu cũ hoặc giữ UI trong vòng lặp dài.
- Sửa đường chuyển workspace bằng `content_stack`: khi trang Đa so sánh bị che bởi So sánh/Báo cáo cơ thể, timer webcam được tạm dừng; quay lại Đa so sánh sẽ tiếp tục đúng phiên mà không cần đổi tab bên trong để kích hoạt lại.

### Các tính năng 0.7.0 — Nhận diện nhiều người trực tiếp bằng webcam

- Tab **Đa so sánh** có nút **Nhận diện bằng webcam**. Người dùng chọn camera trong danh sách thiết bị có sẵn; không phải chọn video nhóm để chạy chế độ camera nữa.
- Chế độ webcam có thể chạy độc lập để phát hiện nhiều người, vẽ bộ xương và gắn ID theo dõi mà **không cần video mẫu**. Số người tối đa được điều khiển bằng thiết lập hiện có (2–12).
- Nếu đã chọn video mẫu một người, webcam sẽ trở thành nguồn nhiều người trực tiếp và ứng dụng so sánh góc từng người với video mẫu. Phiên so sánh dừng khi video mẫu tới cuối; chế độ nhận diện độc lập có thể chạy đến khi người dùng bấm Dừng.
- Webcam dùng FPS camera đã cài đặt; tần suất suy luận pose được giới hạn theo FPS refresh khung xương. Trong các frame không chạy suy luận mới, hình camera vẫn cập nhật và bộ xương gần nhất được vẽ lại nhằm giảm tải. Đây là mục tiêu thực tế, còn phụ thuộc driver và thời gian suy luận.
- Nếu chọn đúng webcam đang mở ở tab Phân tích, ứng dụng mượn handle hiện có trong lúc timer nguồn chính được tạm dừng, tránh mở trùng camera. Webcam đang chạy ở chế độ So sánh được từ chối rõ ràng để tránh hai timer đọc chung một thiết bị.
- Khi rời tab **Đa so sánh**, xử lý trực tiếp được tạm dừng; quay lại tab thì tiếp tục nếu phiên vẫn chạy. Dừng phiên không đóng webcam chính nếu đó là handle được mượn.
- JSON xuất ra giờ ghi rõ chế độ nguồn, chỉ số webcam và việc phiên có phải nhận diện độc lập hay không. Video và ảnh camera được xử lý cục bộ; model MediaPipe đa người có thể cần Internet tải lần đầu và được cache cục bộ.

### Kiểm chứng bản vá 0.7.1

- `python -m compileall -q gdqp_motion_studio tests`: passed.
- `python -m pytest -p no:cacheprovider -q tests`: **135 passed, 2 skipped** trên source đã vá. Regression tests bao gồm tuổi ID theo thời gian, đồng bộ reference theo elapsed time, cadence lấy mẫu, metadata xuất, giới hạn đọc bù và đường chuyển workspace.
- Hai test có thể bị skip trong môi trường không có PyQt6 hoặc không phải Windows; điều này không chứng minh giao diện native hay webcam thật đã được kiểm tra.
- Nhận diện nhiều người vẫn phụ thuộc ánh sáng, kích thước người trong khung, che khuất và năng lực máy. Tracker theo tâm skeleton vẫn có thể đổi ID khi người đi cắt nhau hoặc che nhau. Chỉ số tương đồng góc là quan sát hình học, không phải điểm kỹ thuật đã được kiểm chứng.

**Quy tắc cập nhật:** ghi tóm tắt thay đổi mới ở đầu README. Không tạo patch note dài bên ngoài; không tăng major nếu chưa có xác nhận của người dùng.

---

## 0.1.0 — Prototype ban đầu

- Dựng ứng dụng desktop Python/PyQt6.
- Mở video/webcam, nhận diện pose 2D khi MediaPipe sẵn sàng, hiển thị bộ xương.
- Tính một số góc khớp, ghi mẫu theo frame và xuất dữ liệu.
- Giới hạn: chưa có tiêu chí chuyên môn được xác nhận; không được xem là hệ thống chấm đúng/sai GDQP&AN.

## 0.1.1 — PATCH NOTES

- Đóng gói lại cấu trúc thư mục để `run.py` có thể tìm thấy package `gdqp_motion_studio` khi chạy từ thư mục project.
- Hướng dẫn giải nén toàn bộ ZIP; không chạy một file `run.py` đã tách riêng khỏi thư mục package.
- Lỗi người dùng từng gặp: `ModuleNotFoundError: No module named 'gdqp_motion_studio'` khi chỉ chạy file entrypoint rời. Cách chạy đúng là giải nén đầy đủ project.

## 0.1.2 — PATCH NOTES

- Chỉnh launcher Windows để thiết lập môi trường Python riêng cho project.
- Làm rõ lỗi do Python Launcher đời cũ: `py install` không phải lệnh hợp lệ với launcher cũ. Cách cài Python phụ thuộc cấu hình Windows; không yêu cầu gỡ Python 3.14 hiện có.
- Môi trường mục tiêu của các bộ thư viện ban đầu là Python 3.10–3.12, không phải Python 3.14.

## 0.2.0 — Thêm so sánh động tác

- Thêm tab so sánh video tham chiếu với webcam.
- Thêm đếm ngược, tạm dừng/tiếp tục và reset mẫu của phiên so sánh.
- Hiển thị sai lệch góc và chỉ số tương đồng hình học thử nghiệm; xuất JSON/CSV.

**PATCH ISSUE được xác nhận ở bản này:** thiếu import `QSpinBox` có thể làm UI lỗi khi khởi tạo. Bố cục bảng và các điều khiển so sánh cũng còn chật.

## 0.2.1 — PATCH NOTES

- Bổ sung import còn thiếu và nút điều hướng trực tiếp đến tab So sánh.
- Lỗi UI chen chúc chưa được giải quyết triệt để ở nhánh này; vẫn cần chỉnh lại bố cục và hành vi khi đổi kích thước cửa sổ.

## 0.2.2 — PATCH NOTES

- Bắt đầu chuyển các điều khiển sang bố cục thích ứng, tránh dồn mọi nút trên một hàng.
- Một số tình huống UI vẫn tràn/chen lấn; bản này không được xem là đã khắc phục hoàn toàn.

## 0.2.4 — PATCH NOTES

- Tách khu vực điều khiển phiên so sánh và bảng frame sang hai trang con.
- Thêm vùng cuộn cho nội dung dài và cải thiện phản ứng với cửa sổ nhỏ.
- Lỗi còn sót: có lời gọi `setSizeGripEnabled()` không hợp lệ trên `QMainWindow`, khiến ứng dụng có thể dừng khi khởi tạo.

## 0.2.5 — PATCH NOTES

- Loại bỏ lời gọi API Qt không hợp lệ.
- Bổ sung kiểm tra trước khi mở app: biên dịch cú pháp, chạy unit test và smoke test UI khi môi trường có PyQt6.
- Lưu ý: smoke test bị bỏ qua trên môi trường không cài PyQt6 không chứng minh cửa sổ thật đã được kiểm thử.

## 0.3.0 — Bổ sung đo đạc và khởi chạy tự thiết lập

- Thêm bảng thông số phiên, góc khuỷu tay 3D ước lượng và ước lượng khoảng cách camera từ giả định chiều cao/FOV.
- Bổ sung metadata độ phân giải, FPS và tọa độ khớp để hỗ trợ phân tích sau này.
- Thêm launcher tự tạo `.venv` và cài dependencies trên máy Windows.
- Khoảng cách là ước lượng một camera, không phải ground truth. Tương đồng góc không phải phần trăm đúng động tác.

## 0.3.1 — PATCH NOTES / ổn định UI

- Nới giới hạn cửa sổ theo diện tích desktop; hạ chiều cao nút và bố trí thanh công cụ theo lưới.
- Thêm vùng cuộn cho trang so sánh và riêng trang bảng frame.
- Launcher kiểm tra phiên bản Python, chữ ký trình cài đặt tải về và hash `requirements.txt` để tránh cài lại dependencies khi không đổi.
- Chia sẻ màn hình **chưa có** ở bản này.

## 0.4.0 — Thêm lựa chọn nguồn và chia sẻ màn hình/cửa sổ

- Đổi nút nguồn chính thành **Nguồn chuyển động**. Khi bấm, người dùng chọn một trong hai luồng: **Chọn tệp video** hoặc **Chia sẻ màn hình**.
- Thêm hộp chọn nguồn theo kiểu trình chọn nội dung: tab **Màn hình** để chọn màn hình vật lý và tab **Cửa sổ** để chọn một ứng dụng/cửa sổ nhìn thấy, có khung xem trước và nút **Bắt đầu chia sẻ**. Capture cửa sổ đang lấy vùng hình chữ nhật trên desktop; nếu cửa sổ bị một ứng dụng khác che, vùng bị che có thể ghi nhận ứng dụng phía trước thay vì nội dung riêng bên dưới như một số API capture chuyên dụng.
- Dùng `mss` để chụp màn hình/cửa sổ trực tiếp vào pipeline pose hiện có. Việc chụp là cục bộ, không phát nội dung ra mạng.
- Khi lấy toàn màn hình, vùng cửa sổ GDQP Motion Studio được che khỏi frame phân tích để tránh hiệu ứng gương lặp. Nếu cửa sổ được chọn bị thu nhỏ/biến mất, ứng dụng hiển thị khung thông báo và không coi frame đó là dữ liệu pose hợp lệ.
- Nguồn màn hình có thể làm nguồn tham chiếu trong tab So sánh với webcam. Timestamp theo số frame/FPS mục tiêu để thời gian không tăng trong lúc timer bị tạm dừng.
- Cập nhật metadata JSON về loại nguồn và cập nhật launcher kiểm tra/import `mss`.

### Lưu ý kỹ thuật cho 0.4.0

- Đây là capture cục bộ dựa trên MSS, không phải tính năng truyền màn hình kiểu Discord qua mạng. Hộp chọn có hành vi tương tự ở mức chọn màn hình/cửa sổ và xem trước nguồn.
- Vùng cửa sổ ứng dụng bị che đen trong frame phân tích tại phần giao nhau. Nên chọn riêng cửa sổ video/trình duyệt khi phù hợp để tránh các thành phần giao diện khác gây nhiễu nhận diện. Với chế độ cửa sổ, tránh để các cửa sổ khác che nội dung cần phân tích.
- Độ chính xác pose phụ thuộc video nguồn, độ phân giải, ánh sáng, kích thước người trong khung hình và khả năng của MediaPipe. Không tạo điểm đúng/sai GDQP&AN nếu chưa có tiêu chí đã được giáo viên xác nhận.
- Chia sẻ màn hình cần Windows 10/11 và thư viện `mss` được cài bởi `run.bat`. Lần thiết lập đầu cần Internet. Python mục tiêu: 3.10–3.12 64-bit.

## Quy trình cài/chạy của 0.4.0 (lịch sử; đã được thay thế ở 0.4.2)

1. Giải nén **toàn bộ ZIP** vào một thư mục riêng.
2. Nhấp đúp `run.bat`. Launcher tìm Python 3.12/3.11/3.10 sẵn có; nếu không có, sẽ tải Python 3.12.10 từ python.org, kiểm tra chữ ký Authenticode và cài cho tài khoản Windows hiện tại.
3. Launcher tạo `.venv`, cài requirements, kiểm tra cú pháp và chạy tests trước khi mở UI.
4. Bấm **Nguồn chuyển động** → chọn **Chọn tệp video** hoặc **Chia sẻ màn hình**. Với màn hình, chọn tab **Màn hình** hoặc **Cửa sổ**, chọn nguồn rồi bấm **Bắt đầu chia sẻ**.
5. Tab Phân tích hiển thị video/frame với pose; tab Thông số hiển thị góc và các ước lượng; tab So sánh có thể dùng nguồn tham chiếu đang mở với webcam thứ hai.

## Kiểm thử

```bat
.venv\Scripts\python.exe -m compileall -q gdqp_motion_studio run.py tests
.venv\Scripts\python.exe -m pytest -q
```

Các bài test đơn vị bao phủ hình học, trạng thái thiếu dữ liệu, JSON/CSV, logic so sánh, launcher và các regression UI. UI smoke test chạy khi PyQt6 sẵn có; kiểm tra camera/chụp màn hình thực tế vẫn cần thực hiện trên Windows vì phụ thuộc driver, quyền và cấu hình màn hình của máy người dùng.


## 0.4.1 — PATCH NOTES / Tách launcher khỏi mã nguồn

- Chuyển `run.bat` ra thư mục ngoài cùng để tạo điểm khởi chạy duy nhất, tránh nhầm với `run.py`.
- Đổi thư mục trong thành `GDQP_Motion_Studio_App/`, chỉ chứa mã nguồn, requirements, cấu hình và bài test; `run.py` không còn nằm cạnh launcher.
- Làm mới giao diện dòng lệnh: tiêu đề cửa sổ riêng, màu cyan tối giản, banner phiên bản, các giai đoạn thiết lập rõ ràng, dấu trạng thái `[ OK ]` / `[ .. ]` / `[FAIL]` và thông báo xử lý lỗi.
- Launcher chuyển vào thư mục ứng dụng trước khi thực hiện mọi lệnh tương đối; do đó vẫn tìm đúng `requirements.txt`, `tests/` và package sau khi tách thư mục.
- Môi trường ảo riêng nằm tại `GDQP_Motion_Studio_App/.venv`. Do vị trí dự án đã thay đổi, launcher tạo môi trường mới ở vị trí này; không di chuyển hoặc sao chép thủ công `.venv` cũ.
- Giữ cơ chế tự tìm Python 3.10–3.12, tải Python 3.12.10 chính thức nếu không tìm thấy bản tương thích, kiểm tra chữ ký, cài dependency theo manifest, kiểm tra cú pháp và chạy test trước khi mở UI.
- Cập nhật phiên bản trong package và regression tests lên 0.4.1.

### Cấu trúc gói phát hành 0.4.1

```text
GDQP_Motion_Studio_0.4.1/
├── run.bat                         # Điểm khởi chạy duy nhất
├── README.md                       # Update Logs / Patch Notes
└── GDQP_Motion_Studio_App/         # Mã nguồn và manifest thư viện
    ├── run.py
    ├── requirements.txt
    ├── criteria_template.json
    ├── gdqp_motion_studio/
    └── tests/
```

### Quy trình cài/chạy của 0.4.1 (lịch sử; đã được thay thế ở 0.4.2)

1. Giải nén toàn bộ ZIP vào một thư mục riêng; không kéo `run.py` ra ngoài.
2. Chỉ nhấp đúp `run.bat` ở thư mục ngoài cùng. Không cần mở Thonny để chạy ứng dụng.
3. Lần đầu cần Internet để thiết lập Python/dependencies nếu máy chưa có môi trường phù hợp. Sau khi thiết lập thành công, launcher tái sử dụng `.venv` và bỏ qua cài lại dependencies nếu hash requirements không đổi và các thư viện vẫn import được.
4. Launcher kiểm tra cú pháp và chạy pytest trước khi mở giao diện. Nếu một bước thất bại, cửa sổ giữ nguyên thông báo lỗi để người dùng sao chép.

> **Lưu ý về portable:** đây là gói tự thiết lập môi trường theo thư mục dự án, không phải bản offline hoàn toàn. Python được cài ở mức tài khoản Windows khi cần và môi trường ứng dụng nằm trong `GDQP_Motion_Studio_App/.venv`. Cần giữ nguyên cả thư mục ngoài và thư mục ứng dụng bên trong.


## 0.4.2 — PATCH NOTES / Runtime và dependency tự tải hoàn toàn vào thư mục dự án

- **Thay cách thiết lập Python:** không dùng `py`, Python 3.14 của máy hoặc bản Python trong Thonny. Khi thiếu runtime cục bộ, `run.bat` gọi `bootstrap.ps1`, tải trình cài đặt CPython Windows x64 chính thức, kiểm tra chữ ký Authenticode rồi cài Python vào `GDQP_Motion_Studio_App/_runtime/python`.
- **Không cài Python vào `%LOCALAPPDATA%`**, không thêm Python vào `PATH`, không cài Python Launcher, không tạo file association và không tạo shortcut. Runtime cùng các thư viện Python được đặt trong thư mục dự án; toàn bộ cây thư mục được thiết kế để di chuyển như một đơn vị trên Windows x64 tương thích. Trình cài đặt có thể tạo một ít metadata đăng ký ở cấp tài khoản Windows; bản này không tuyên bố hoàn toàn không đụng đến registry. Việc chuyển sang máy Windows sạch chưa được chạy thử trực tiếp trong môi trường tạo mã hiện tại.
- **Tự tải dependency:** cài `pip`, sau đó cài toàn bộ `requirements.txt` bằng wheel nhị phân (`--only-binary=:all:`) để tránh phụ thuộc vào trình biên dịch C/C++ trên máy người dùng. Kiểm tra import và tính tương thích bằng `pip check` sau khi cài.
- **Tự phục hồi dependency:** hash SHA-256 của `requirements.txt` được lưu cùng runtime. Nếu hash không đổi và các import còn hoạt động, launcher bỏ qua việc cài lại; nếu import hỏng hoặc manifest thay đổi thì cài/sửa lại dependencies.
- **Preflight có cache:** hash các tệp mã nguồn, JSON cấu hình và tests. Lần đầu hoặc sau khi có thay đổi mã sẽ chạy `compileall` và `pytest`; chỉ lưu dấu preflight sau khi toàn bộ test thành công. Khi mã nguồn không đổi, launcher bỏ qua test suite nặng ở các lần mở tiếp theo để giảm thời gian chờ trên máy CPU yếu.
- **Launcher được tách trách nhiệm:** `run.bat` giữ vai trò cửa vào/hiển thị lỗi; `bootstrap.ps1` chịu trách nhiệm tải runtime, kiểm tra chữ ký, cài dependencies, kiểm thử và khởi chạy. Log nằm trong `_logs/launcher.log` và `_logs/python-install.log`.
- **Không dùng cache cài đặt hệ thống làm nguồn đáng tin:** thư viện được kiểm tra theo runtime dự án và không dựa vào site-packages người dùng (`PYTHONNOUSERSITE=1`).
- **Tương thích:** tiếp tục dùng bộ MediaPipe 0.10.21 và NumPy 1.26.4 hiện tại, nên runtime được khóa ở Python 3.12 x64. Python 3.12.10 là bản cuối của nhánh 3.12 có Windows installer thông thường; các bản 3.12 mới hơn được phát hành dạng source-only trong giai đoạn security-fixes. Xem [Python 3.12.10](https://www.python.org/downloads/release/python-31210/) và [tài liệu cài Python trên Windows](https://docs.python.org/3.12/using/windows.html).
- **Giới hạn có chủ đích:** ZIP tải về ban đầu chưa chứa Python và các wheel; lần đầu chạy bắt buộc có Internet và cần dung lượng trống đáng kể (Qt, OpenCV, MediaPipe và các dependency đi kèm có tổng kích thước lớn). Đây là *download-on-first-run portable project*, không phải ZIP offline hoàn chỉnh hoặc một EXE độc lập. Sau khi thiết lập thành công, runtime và packages đều được giữ trong cây thư mục ứng dụng.

### Cấu trúc phát hành 0.4.2

```text
GDQP_Motion_Studio_0.4.2/
├── run.bat                         # Điểm vào duy nhất; launcher console hiện đại
├── bootstrap.ps1                   # Tự tải/cài runtime, dependencies, tests và chạy app
├── README.md                       # Update Logs / Patch Notes
├── _logs/                          # Tự tạo: log setup/runtime
└── GDQP_Motion_Studio_App/
    ├── run.py
    ├── requirements.txt
    ├── criteria_template.json
    ├── _runtime/python/             # Tự tải và cài lần đầu; không nằm sẵn trong ZIP
    ├── gdqp_motion_studio/
    └── tests/
```

### Cách chạy bản 0.4.2

1. Giải nén **toàn bộ** ZIP vào thư mục có quyền ghi, ví dụ `Downloads\GDQP_Motion_Studio_0.4.2`. Không chạy trong cửa sổ xem trước ZIP.
2. Chỉ nhấp đúp `run.bat` ở thư mục ngoài cùng. Không cần cài Python trước, không cần mở Thonny và không cần gõ `py install`.
3. Lần đầu, launcher tải Python 3.12.10 x64 từ `python.org`, xác minh chữ ký, cài runtime vào `GDQP_Motion_Studio_App\_runtime\python`, rồi tải/cài mọi package trong `requirements.txt`. Nếu Windows SmartScreen/antivirus cảnh báo, hãy xác minh nguồn tệp và chữ ký; không tắt bảo vệ Windows để cố chạy.
4. Sau đó launcher kiểm tra import; khi requirements hoặc mã nguồn thay đổi, nó chạy lại cài đặt/preflight phù hợp. Nếu lỗi, giữ cửa sổ mở và xem `_logs\launcher.log`; chi tiết trình cài Python nằm trong `_logs\python-install.log`.
5. Để chuyển dự án đã thiết lập sang một máy khác, sao chép **toàn bộ thư mục** gồm launcher, app và `_runtime`; cần Windows x64 tương thích. Nếu sao chép trước lần chạy đầu, máy đích vẫn phải có Internet để tải runtime và dependencies.

### Kiểm tra trên máy phát triển

```bat
GDQP_Motion_Studio_App\_runtime\python\python.exe -m compileall -q GDQP_Motion_Studio_App\gdqp_motion_studio GDQP_Motion_Studio_App\run.py GDQP_Motion_Studio_App\tests
GDQP_Motion_Studio_App\_runtime\python\python.exe -m pytest -q GDQP_Motion_Studio_App\tests
```

> **Kiểm thử launcher:** môi trường tạo mã hiện tại không có Windows PowerShell/Windows installer, vì vậy `bootstrap.ps1` được kiểm tra bằng regression tests tĩnh, còn download, xác minh chữ ký và cài đặt cục bộ vẫn cần được xác nhận trên Windows thật. Không coi test cú pháp Python là bằng chứng đã chạy thành công toàn bộ trình cài đặt.


## 0.4.3 — PATCH NOTES / Camera picker, window capture và hiệu năng

### Camera

- **Không còn mở cứng `VideoCapture(0)` khi bấm nút webcam.** Nút Mở webcam và Mở webcam so sánh đều mở hộp chọn camera.
- Hộp chọn quét các index camera, chỉ đánh dấu khả dụng khi thiết bị mở được và trả về frame thực; hiển thị index/backend/độ phân giải đọc được.
- Cho chỉnh khoảng index cần quét (0–16), khoảng tự làm mới (2–60 giây, mặc định 10 giây) và có nút Làm mới ngay.
- Việc quét camera chạy trên worker thread để không đóng băng giao diện. Khi đang quét, các lần refresh trùng bị bỏ qua; khi đóng dialog, yêu cầu hủy vòng quét tiếp theo.
- Trên Windows ưu tiên DirectShow rồi Media Foundation; không dùng `CAP_ANY` trong quét tự động vì nó có thể chọn backend OBSENSOR và log `Camera index out of range` cho index trống. Việc dò được giữ trong worker thread, không thay đổi mức log toàn cục trong lúc AI đang xử lý. Camera đang được app sử dụng sẽ bị bỏ qua khi quét lại và vẫn hiển thị như thiết bị hiện tại. Camera mở thật được kiểm tra bằng frame đầu trước khi thay nguồn đang chạy.
- Camera được yêu cầu chạy ở 640×480 và buffer một frame nhằm giảm độ trễ/bộ nhớ. Webcam chính giới hạn chu kỳ xử lý khoảng 20 Hz; camera so sánh xem trước khoảng 30 Hz, chạy pose mỗi ba frame.

### Chia sẻ màn hình/cửa sổ

- **PATCH:** bản 0.4.2 chụp cửa sổ bằng MSS theo vùng desktop rồi che toàn bộ cửa sổ GDQP. Khi app đang maximize, vùng bị che chiếm gần hết màn hình nên người dùng chỉ thấy taskbar và mảng đen.
- Với nguồn **Cửa sổ**, bản 0.4.3 dùng Win32 `PrintWindow` để yêu cầu Windows render HWND được chọn vào bitmap ngoài màn hình. Cách này có thể lấy cửa sổ bị che bởi app GDQP mà không chụp nhầm giao diện của GDQP.
- Nếu ứng dụng nguồn dùng lớp video/GPU được bảo vệ và Windows trả về ảnh gần như đen, nguồn sẽ đưa ra thông báo giải thích thay vì âm thầm phân tích ảnh đen. Một số ứng dụng tăng tốc phần cứng có thể không hỗ trợ PrintWindow; thử tắt hardware acceleration hoặc dùng nguồn Màn hình với nội dung không bị che.
- Với nguồn **Màn hình**, chỉ vùng preview đang phát hình của GDQP được che; không còn che cả cửa sổ ứng dụng. Các phần còn lại của màn hình vẫn được capture. Tuy nhiên, app vẫn có thể che một cửa sổ nguồn phía sau nó: muốn phân tích nội dung đó, ưu tiên chọn đúng cửa sổ ở tab Cửa sổ.
- Khung hình lỗi từ screen capture vẫn tạo trạng thái `SOURCE UNAVAILABLE` và không được ghi thành phép đo pose hợp lệ.

### Hiệu năng và log

- MediaPipe chạy inference trên ảnh thu nhỏ với cạnh lớn nhất mặc định 960 px, nhưng vẫn vẽ kết quả lên frame thu nhỏ phù hợp giao diện. Điều này giảm đáng kể lượng pixel cho inference khi nguồn là desktop 1080p/4K; tọa độ pose chuẩn hóa vẫn dùng được cho góc khớp.
- Bỏ một số bản sao full-resolution không cần thiết và chỉ lưu shape cuối cùng của frame màn hình để dựng trạng thái lỗi, giảm áp lực RAM trên máy yếu.
- Thiết lập mức log TensorFlow Lite/Abseil trước khi import MediaPipe để giảm log startup không cần thiết. Lỗi thực của ứng dụng vẫn cần được xem trong log.
- `DeprecationWarning` từ `google._upb._message` nói rằng kiểu nội bộ protobuf/MediaPipe dùng có thể không còn được chấp nhận trong Python 3.14; câu này không tự chứng minh interpreter hiện tại là Python 3.14. Đây là cảnh báo upstream, không phải exception làm test thất bại. Runtime đi kèm launcher của project tiếp tục dùng Python 3.12 x64; nên chạy app/test bằng `GDQP_Motion_Studio_App\_runtime\python\python.exe` chứ không dùng Python 3.14/Thonny để kiểm chứng runtime portable.
- Dòng `Created TensorFlow Lite XNNPACK delegate for CPU` thông báo backend CPU đã bật; warning `inference_feedback_manager` về feedback tensor không phải lỗi pose. Cảnh báo camera index trước đây xuất phát từ việc mở cứng index 0 và các backend probe không có thiết bị; bản này dùng picker/probe.

### Kiểm thử 0.4.3

- Bổ sung unit tests cho dò camera, kiểm tra frame, thiết lập buffer/độ phân giải và phản hồi hủy quét.
- Bổ sung regression tests xác nhận camera không còn hard-code index 0, cửa sổ dùng đường capture native, monitor chỉ che preview và inference giảm kích thước ảnh nguồn lớn.
- Đã chạy compileall và bộ test trong môi trường tạo mã; UI smoke test chỉ thực sự chạy khi PyQt6 được cài trong môi trường kiểm thử. `PrintWindow`, driver camera và chia sẻ màn hình thực tế vẫn cần được xác nhận trên Windows của người dùng vì phụ thuộc ứng dụng/driver.


## 0.4.4 — PATCH NOTES / Screen capture frame normalization

- Normalized Windows Graphics Capture frames to owned `uint8` BGR data before OpenCV processing; avoids invalid float16/four-channel input being misread as black.
- Added a conservative initial-frame check for Windows Graphics Capture and a `PrintWindow` fallback with a visible error when both backends return a nearly black window.
- Kept MediaPipe optional so video playback remains usable if pose initialization fails.
- **Known issue fixed in 0.4.5:** whole-monitor capture could still show the Studio window covering the content being analyzed, with the preview masked black.

## 0.4.5 — PATCH NOTES / Camera diagnostics, screen-share visibility and performance

### Camera and warning logs

- Camera probing now suppresses only OpenCV's noisy native log output while testing empty indexes, restoring the previous log level immediately afterward. The chosen camera is still opened and verified with a real frame outside the suppression context.
- Camera picker keeps automatic refresh, manual refresh, selected device metadata and real-frame availability checks. If refresh is requested while a scan is running, one follow-up scan is queued rather than silently dropped.
- Fixed two camera unit tests whose monkeypatched helper did not accept the keyword arguments used by the current implementation.

### Screen capture: black / taskbar-only fix

- **PATCH:** in 0.4.4 and earlier, whole-monitor capture kept the large maximized Studio window on top and masked its preview widget. This could leave most useful source content covered by the app and make the capture appear mostly black.
- **0.4.5 fix:** whole-monitor capture hides the main Studio window and displays a compact always-on-top control with frame count, pause and Stop & Return. Only this small controller rectangle is masked from the frame. Stopping, losing the source or closing the app releases capture resources and restores the main window when appropriate.
- The selected-window path still uses Windows Graphics Capture first and `PrintWindow` as fallback. Protected surfaces, some GPU accelerated apps, minimized windows or content rendered using incompatible hardware-acceleration paths may still return black; use the monitor option with the source visible when that happens.

### Performance and data quality

- Monitor frames are downscaled before allocating a separate BGR copy; window-capture frames are bounded to 1280 pixels on the long side by default. Pose inference remains capped at 720 pixels on its long side. This reduces peak RAM and pixel work on 1080p/4K sources.
- The latest Windows Graphics Capture frame is immutable once published; `read()` can return the latest reference without making a new full-frame copy on every Qt timer tick.
- Monitor-exclusion coordinates now account for the scale between native desktop pixels and downsampled frame pixels, so the floating control mask stays correctly positioned.
- Camera scan test doubles now match the backend-selection keyword arguments. README history and launcher version assertions are kept in sync.

### Interpreting the supplied logs

- `google._upb._message.* DeprecationWarning` is an upstream protobuf/MediaPipe warning that often appears under Python 3.14. It is not a Python syntax error. For the portable build, run through the outer `run.bat`; it uses its own project-local CPython 3.12.10 runtime.
- `Created TensorFlow Lite XNNPACK delegate for CPU` is informational: the CPU delegate initialized.
- `inference_feedback_manager ... Disabling support for feedback tensors` means an optional feedback optimization is disabled for this model; it is not by itself a pose failure.
- OpenCV's `obsensor_uvc_stream_channel.cpp ... Camera index out of range` usually comes from probing an index/backend with no device. The camera scanner now uses explicit backends and suppresses that low-level noise only during availability probing. A camera that cannot return a real frame is not marked available.

### Verification status

- Added tests for scaled monitor captures, scaled exclusion rectangles and WGC frame normalization.
- Compile and unit tests are run in the development environment; runtime behavior of MediaPipe, real cameras, Windows Graphics Capture and `PrintWindow` remains hardware/Windows-dependent and must be confirmed on the target machine.
- The UI smoke test is skipped in environments without PyQt6; this release has not been interactively exercised on the user's Windows desktop from the build environment.


### Kiểm thử bản 0.4.5 trong môi trường xây dựng

- `python -m compileall -q gdqp_motion_studio run.py tests`: đạt.
- `python -m pytest -q`: bản 0.4.5 đạt **64 passed, 1 skipped**. Bài bị skip là UI smoke test do môi trường xây dựng không có PyQt6; trên máy cài đủ requirements, bài kiểm tra cả cửa sổ chính lẫn bảng điều khiển nổi sẽ được chạy.
- Chưa thể xác minh vật lý webcam hoặc Desktop Duplication/Windows Graphics Capture từ môi trường này; phần đó vẫn cần thử trên Windows thật.

## 0.4.6 — Báo cáo tổng thể cơ thể / PATCH NOTES

### Báo cáo nhiều frame từ bộ xương 3D

- Thêm nút **Đánh giá tổng thể** ở tab **Bộ xương 3D** và tab riêng **Báo cáo cơ thể**. Phiên có thể cấu hình đếm ngược 1–60 giây và thời gian thu 3–60 giây. Trong đếm ngược, nguồn được giữ lại; sau đó app thu nhiều frame pose-world, kết thúc thì tạm dừng nguồn để xem báo cáo.
- Báo cáo dùng trung vị của các frame hợp lệ, kèm min/max, khoảng biến thiên, số mẫu cho từng chỉ số và các giới hạn diễn giải. Có xuất báo cáo JSON và CSV. Không đủ landmark thì để trống, không tự điền số 0.
- Thông số gồm chiều dài cánh tay trên/cẳng tay/tổng đoạn tay, đùi/cẳng chân/chuỗi chân, bề rộng vai/hông, thân mình, sải tay cấu trúc ước lượng, chiều cao cấu trúc ước lượng và khoảng cách camera nếu nguồn là video/webcam, toàn thân hiển thị và cấu hình hiệu chuẩn cho phép.
- Tab **Bộ xương 3D** nay hiển thị thêm các ước lượng hiện tại theo frame và nút nhảy tới báo cáo. Nguồn desktop capture có thể khởi chạy phiên báo cáo từ bộ điều khiển nổi khi cửa sổ chính đang ẩn; sau đó chọn **Dừng & trở về Studio** để xem kết quả và xuất tệp.

### Phương pháp và giới hạn

- Độ dài chi dùng khoảng cách Euclid giữa các landmark 3D pose-world do mô hình ước lượng, với ngưỡng visibility tối thiểu. Đây là số ước lượng theo thang tọa độ mô hình, không phải số đo nhân trắc học chuẩn hoặc phép đo y khoa.
- Chiều cao được tính bằng tổng các đoạn ước lượng: mũi-giữa vai proxy + hiệu chỉnh đỉnh đầu giả định 0,10 m + thân mình + đùi + cẳng chân + bàn chân proxy. Sai số của các đoạn có thể cộng dồn; báo cáo ghi rõ phương pháp này.
- Khoảng cách camera vẫn là ước lượng một camera từ chiều cao người nhập, FOV giả định và độ cao pose trên ảnh; nó bị đánh dấu **không áp dụng** cho screen capture. Không tạo điểm sức khỏe, điểm vóc dáng hay chẩn đoán.
- Các thống kê median/min/max mô tả các mẫu đo trong phiên; khoảng biến thiên không phải độ chính xác so với sự thật. Visibility là chỉ số khả năng nhìn thấy khớp, không phải độ đúng của kết luận.

### Luồng điều khiển và PATCH NOTES

- Thêm nút **Đánh giá cơ thể** vào bộ điều khiển nổi khi capture toàn màn hình để người dùng có thể khởi chạy đếm ngược mà không cần đưa cửa sổ Studio phủ lên nội dung desktop.
- Khi đếm ngược, tạm khóa tạm dừng thông thường để không làm lệch đồng hồ phiên; có thể hủy đếm ngược hoặc dừng phiên đánh giá. Khi nguồn dừng, báo cáo đang chạy được chốt ở trạng thái một phần nếu có mẫu; không làm mất dữ liệu đã thu.
- **PATCH:** bản đầu của tính năng thêm báo cáo phải đồng bộ index tab/kiểm thử UI và tránh trộn thời gian timestamp nguồn với thời gian thu phiên. Bản 0.4.6 thêm kiểm thử đơn vị cho segment lengths, thiếu landmark, median aggregation và giới hạn screen capture; kiểm thử UI sẽ chạy khi PyQt6 hiện diện.

### Kiểm thử 0.4.6

- Bổ sung `tests/test_body_report.py` cho khoảng cách 3D, chiều dài các đoạn, không tạo số đo khi landmark bị che, không báo khoảng cách camera từ desktop capture và tổng hợp median.
- Chạy `python -m compileall -q gdqp_motion_studio run.py tests` và `python -m pytest -q` trên gói sau khi giải nén. UI smoke test vẫn có thể bị skip trong môi trường không có PyQt6; kiểm tra vật lý camera và screen capture cần chạy trên Windows thật.



### Kiểm thử bản 0.4.6 sau khi tích hợp báo cáo cơ thể

- Thêm regression tests cho tính chiều dài segment, chiều cao cấu trúc proxy, đo góc 3D trung vị, không đo khoảng cách camera từ screen capture và xuất JSON/CSV của báo cáo.
- Kết quả trong môi trường xây dựng: `python -m compileall -q gdqp_motion_studio run.py tests` đạt; `python -m pytest -q`: **70 passed, 1 skipped** (UI smoke test bỏ qua vì môi trường này chưa có PyQt6).
- Chưa trực tiếp kiểm thử camera thật, desktop capture hoặc layout Qt trên Windows người dùng; cần xác nhận bằng runtime thật trước khi coi đây là phát hành đã được xác minh toàn diện.


## 0.4.7 — PATCH NOTES / Sửa lỗi pytest thu thập test trong runtime

### Lỗi được xác nhận từ log chạy trên Windows

- Ở bản 0.4.6, launcher chạy `python -m pytest -q` tại thư mục app. Vì runtime Python được đặt dưới `_runtime/`, pytest duyệt sâu vào `Lib/site-packages` và cố thu thập bộ test nội bộ của NumPy, Matplotlib, SciPy và MediaPipe. Những test package này cần test data hoặc dependency phát triển không nằm trong requirements của ứng dụng, dẫn tới 23 lỗi collection và launcher không mở UI. Đây không phải lỗi pose model hay lỗi cú pháp của source app.
- **PATCH:** launcher gọi `python -m pytest -q tests` để chỉ chạy test của dự án. Thêm `pytest.ini` với `testpaths = tests` và `norecursedirs` cho `_runtime`, `.venv` và các thư mục build/cache làm lớp bảo vệ thứ hai.
- Thêm `pytest.ini`, `run.bat` và `bootstrap.ps1` vào hash preflight; thay đổi launcher/config sẽ làm preflight cache mất hiệu lực thay vì âm thầm dùng kết quả cũ.

### Cải thiện thiết lập dependency

- Pin đồng thời `opencv-python==4.11.0.86` và `opencv-contrib-python==4.11.0.86`: log của người dùng cho thấy `windows-capture` yêu cầu wheel chuẩn trong khi MediaPipe yêu cầu wheel contrib. Giữ cả hai ở cùng phiên bản để giảm việc resolver thử nhiều bản khác nhau; hai wheel dùng chung namespace `cv2`, nên đây là thỏa hiệp theo dependency upstream, cần được duy trì cùng phiên bản.
- Pin `jax==0.7.1`, `jaxlib==0.7.1`, `scipy==1.17.1` và `ml-dtypes==0.5.4`, là bộ đã xuất hiện tương thích trong log cài Python 3.12.10 với `numpy==1.26.4`. Mục đích là giảm resolver backtracking dài của các dependency MediaPipe không được giới hạn phiên bản.
- Giữ `pip check` và import preflight sau cài đặt. Không tự cài `torch`, `tensorflow`, `hypothesis` hoặc test-data của thư viện vì chúng thuộc các bộ test phát triển upstream và không cần để chạy ứng dụng này.

### Hướng dẫn kiểm thử

Chạy từ thư mục `GDQP_Motion_Studio_App`:

```bat
_runtime\python\python.exe -m compileall -q gdqp_motion_studio run.py tests
_runtime\python\python.exe -m pytest -q tests
```

Kỳ vọng: pytest chỉ thu thập các tệp `tests/test_*.py` của GDQP Motion Studio, không đi vào `_runtime/python/Lib/site-packages`. Cảnh báo upstream protobuf/MediaPipe có thể vẫn xuất hiện nhưng khác với lỗi collection làm dừng launcher.


## 0.4.8 — PATCH NOTES / Khắc phục vòng lặp cài Python cục bộ

### Lỗi được xác nhận từ log chạy trên Windows

- Ở các lần chạy của người dùng, full installer CPython trả về nhưng kiểm tra `python.exe` trong runtime dự án thất bại. Lượt chạy tiếp theo xóa runtime rồi gọi lại installer thường; nếu lần trước đã đăng ký sản phẩm Python trong Windows Installer, lần sau có thể vào maintenance mode và kết thúc mà không tạo lại file. Bản 0.4.7 không phân biệt tình huống này, dẫn đến vòng lặp “installer finished, local python.exe failed version/architecture check”.
- **PATCH:** runtime probe phát ra một dòng có tag `GDQP_RUNTIME_PROBE`, ghi exit code và toàn bộ output. Không còn dựa vào indexing `$details[0]`/`$details[1]`, vốn dễ cho chẩn đoán sai khi PowerShell trả output dạng scalar/array hoặc có dòng phụ.
- **PATCH:** tra `InstallPath` đã đăng ký cho Python 3.12 trên các hive HKCU/HKLM. Nếu đường dẫn trùng chính xác runtime của project, launcher gọi `/repair /quiet` thay vì xóa file rồi chạy cài đặt mới. Nếu Python 3.12 đăng ký ở đường dẫn khác, launcher dừng an toàn, ghi vị trí phát hiện được và không gỡ/sửa một Python không thuộc project.
- **PATCH:** lỗi kiểm tra runtime sẽ ghi rõ `python.exe` có tồn tại không, output kiểm tra, các mục đầu runtime folder và 50 dòng cuối của `python-install.log`. Launcher không còn tự xóa runtime đã đăng ký khi phép kiểm tra thất bại.
- **PATCH:** bản mới giữ nguyên target runtime của phiên bản hiện tại để có thể repair đúng đường dẫn đã đăng ký; không tự chuyển runtime sang đường dẫn khác giữa các lần chạy.

### Vì sao phải xử lý như vậy?

Tài liệu CPython nói full installer đi vào maintenance mode sau khi Python đã cài; một số tùy chọn như thư mục cài không thể thay đổi trong chế độ này. Vì vậy launcher phải phân biệt cài mới với repair và không được xóa thư mục đã đăng ký một cách mù quáng. Tài liệu: <https://docs.python.org/3.12/using/windows.html#modifying-an-install>.

### Kiểm thử

- Thêm regression tests cho probe một dòng, log chẩn đoán, phát hiện registry path và nhánh repair chỉ khi target trùng runtime của project.
- Trên môi trường dựng mã, chạy `compileall` và `pytest tests` sau khi giải nén ZIP. Installer/registry thật chỉ có thể được xác minh trên Windows người dùng; nếu repair còn thất bại, log `python-install.log` và đoạn diagnostic mới sẽ chỉ ra mã lỗi thực tế mà bản 0.4.7 đã che khuất.


### Bổ sung khắc phục khi thư mục ZIP được đổi phiên bản

- Nếu người dùng giải nén 0.4.8 vào thư mục phiên bản mới, launcher dò các registry InstallPath của Python 3.12 và chỉ nhận các đường dẫn có cấu trúc rõ ràng `GDQP_Motion_Studio*\GDQP_Motion_Studio_App\_runtime\python` làm runtime cũ của chính project.
- Nếu runtime GDQP cũ còn hợp lệ, ứng dụng mới dùng runtime đó và cập nhật dependency/preflight theo hash. Nếu runtime đó thiếu file, launcher gọi chế độ repair của đúng installation đã đăng ký. Nó không tự gỡ Python thông thường của người dùng.
- Nếu registry chỉ ra một Python 3.12 ở vị trí không liên quan, launcher dừng an toàn và ghi rõ đường dẫn thay vì cài chồng/xóa runtime đó.
- Bản 0.4.7 có thể tạo vòng lặp vì xóa `python.exe` trong khi Windows Installer vẫn giữ đăng ký sản phẩm; bản 0.4.8 không lặp lại việc xóa mù quáng đó.

### Kiểm thử 0.4.8 trong môi trường xây dựng

- `python -m compileall -q gdqp_motion_studio run.py tests`: đạt.
- `python -m pytest -q tests`: **76 passed, 1 skipped** trong lần kiểm tra bản 0.4.8; bài UI bị bỏ qua khi môi trường không có PyQt6.
- Windows Installer/registry thật không thể mô phỏng hoàn toàn trên Linux; nếu repair trên Windows vẫn thất bại, bản mới ghi probe output và 50 dòng cuối `python-install.log` để không còn một thông báo chung thiếu nguyên nhân.


## 0.4.9 — PATCH NOTES / Tái sử dụng Python 3.12 có sẵn an toàn

### Lỗi được xác nhận từ log người dùng

- Ở bản 0.4.8, launcher phát hiện `C:\Users\...\AppData\Local\Programs\Python\Python312` đã đăng ký nhưng kết thúc bằng lỗi: `Python 3.12 is already registered at an unrelated location`. Điều này quá cứng nhắc: đường dẫn đó là một bản Python hợp lệ có thể dùng làm nền tạo môi trường ảo, không phải xung đột cần dừng.
- **PATCH:** khi tìm thấy Python 3.12 x64 khả dụng (qua registry PythonCore, đường dẫn cài đặt phổ biến hoặc `python.exe` trên PATH), launcher xác minh phiên bản, kiến trúc và `sys.executable`; nếu đạt, nó tạo/tái sử dụng `GDQP_Motion_Studio_App/_runtime/venv` bằng `python -m venv`.
- Mọi dependency của GDQP Motion Studio được cài và kiểm tra bằng `venv/Scripts/python.exe`; không cài package vào Python nền, không thay đổi PATH, không gỡ Python hiện có và không cần quyền admin cho việc tạo venv.
- Nếu không tìm thấy Python 3.12 x64 khả dụng và không có đăng ký Python 3.12 đang chặn cài mới, launcher vẫn tải installer CPython chính thức, kiểm tra Authenticode và cài runtime riêng vào `_runtime/python` như phương án dự phòng.
- Nếu Python 3.12 đã đăng ký nhưng file thực thi không dùng được, launcher dừng với thông báo chẩn đoán thay vì gỡ/sửa một Python bên ngoài hoặc tạo vòng lặp installer.

### Cách chạy 0.4.9

1. Giải nén toàn bộ ZIP vào thư mục riêng rồi nhấp đúp `run.bat`.
2. Nếu đã có Python 3.12 x64, launcher dùng nó làm **base interpreter** nhưng dựng môi trường ảo bên trong project; Python 3.14 và Thonny không bị động tới.
3. Nếu chưa có Python 3.12 tương thích, launcher thử thiết lập runtime riêng theo cơ chế tải/cài chính thức.
4. Dependency, preflight marker, logs và ứng dụng đều được xử lý bằng interpreter đang hoạt động (`_runtime/venv/Scripts/python.exe` hoặc `_runtime/python/python.exe`).

### Kiểm thử 0.4.9

- Thêm regression tests để khóa hành vi: Python 3.12 đã cài ở vị trí người dùng không bị từ chối chỉ vì nằm ngoài thư mục dự án; nó chỉ được dùng để tạo venv riêng.
- Kết quả trên source tree đã giải nén: `compileall` đạt; `python -m pytest -q tests`: **78 passed, 1 skipped** (UI smoke test bỏ qua vì môi trường dựng mã không có PyQt6).
- Kiểm thử registry/`venv` thật cần xác nhận trên Windows; môi trường dựng mã không thể tái tạo Windows Installer và registry thật của người dùng.


## 0.4.10 — PATCH NOTES / Tiến độ tổng và tối ưu CPU yếu

### Launcher và cài dependency

- **PATCH:** PowerShell không còn in lại banner hay từng dòng trạng thái thông thường. `run.bat` giữ một tiêu đề gọn; trong khi thiết lập, người dùng theo dõi một thanh tiến độ tổng duy nhất. Lỗi vẫn được in rõ để có thể sao chép; chi tiết lệnh và đầu ra package tiếp tục được lưu trong `_logs`.
- Thanh tổng dùng các mốc thực: tải Python theo số byte đã nhận khi server cung cấp dung lượng; tải dependency theo số wheel đã hoàn tất trên tổng số gói được resolve; cài dependency theo số package đã cài thành công; cuối cùng là kiểm tra import, cú pháp và test. Không dùng animation theo thời gian để giả vờ tiến độ.
- Mỗi wheel/package được chia đều trong phần trăm của giai đoạn tải/cài tương ứng. Khi pip đang resolver hoặc đang xử lý một package lớn, thanh có thể đứng yên cho đến khi milestone thật hoàn tất; điều này có chủ ý để phần trăm không nhảy giả.
- Output stdout/stderr của pip và tạo venv được chuyển vào log; console chỉ in hướng dẫn khởi động và thông báo lỗi thật sự.

### Tối ưu khung xương trên CPU yếu

- **PATCH:** bản phát hành cuối dùng cạnh dài 320 pixel cho inference mặc định (đã giảm từ 384 ở vòng chỉnh sửa ban đầu), vẫn giữ tọa độ chuẩn hóa và world landmarks do MediaPipe trả về. Đây là đánh đổi hiệu năng/chi tiết; nếu động tác nhỏ hoặc người ở xa, nhận diện có thể kém hơn.
- Bộ điều tiết inference thích ứng từ 1–8 frame, bắt đầu mỗi 3 frame: trên 100 ms tăng nhanh 2 frame, từ 65 ms tăng 1 frame, và chỉ giảm khoảng cách sau 10 inference liên tiếp có độ trễ dưới 30 ms. Sườn xương được vẽ lại lên frame mới giữa các lần inference, nhưng dữ liệu đo/timeline chỉ ghi kết quả inference mới — không nhân bản phép đo đã cache.
- Webcam dùng trong so sánh xử lý pose mỗi 6 frame để hai mô hình không tranh CPU quá thường xuyên. Preview được giới hạn 18 FPS; đồ thị Matplotlib 3D chỉ cập nhật tối đa khoảng 3 Hz khi tab 3D đang hiển thị. OpenCV được giới hạn một thread để giảm tranh chấp luồng trên máy cũ.
- Metadata JSON lưu cạnh dài inference và khoảng cách inference để có thể phân tích hiệu năng thực tế. Không cam kết một FPS cố định cho mọi máy; hiệu năng còn phụ thuộc CPU, driver, độ phân giải và việc đồng thời chạy 2 luồng pose.

### PATCH bổ sung sau log Windows của người dùng

- **PATCH — version test:** bài UI trước đây hard-code title `0.4.8`, nên fail khi app lên `0.4.10`; test nay tham chiếu `gdqp_motion_studio.__version__` để phát hiện lệch version thật thay vì lỗi do expectation cũ.
- **PATCH — Qt font warning:** launcher đặt `QT_QPA_FONTDIR` tới `%WINDIR%\Fonts` khi thư mục tồn tại; `run.py` có fallback tương tự cho trường hợp chạy trực tiếp. Không sao chép/bundling font vào project.
- **PATCH — launcher im lặng:** `Invoke-Python` không trả `True` ra pipeline sau khi thành công, tránh các dòng `True` xen vào thanh tiến độ. Thanh tổng được đóng ngay trước khi app GUI mở, không nằm trên màn hình suốt thời gian người dùng sử dụng app.
- **PATCH — máy CPU yếu:** mặc định pose inference giảm xuống cạnh dài 320 px; lịch suy luận bắt đầu mỗi 3 frame và tự điều chỉnh tối đa mỗi 8 frame khi latency cao. Webcam so sánh suy luận mỗi 6 frame; đồ thị 3D cập nhật tối đa khoảng 3 Hz. Những đánh đổi này giảm tải nhưng có thể giảm chi tiết pose khi người ở xa.

### Kiểm tra

- Regression tests kiểm tra version UI lấy từ package metadata, thanh tiến độ không phát output lệnh pip và thiết lập inference tiết kiệm CPU.
- Sau log Windows 0.4.9, test UI đã bỏ so sánh version hard-code `0.4.8`; title lấy trực tiếp từ `gdqp_motion_studio.__version__`, nên không còn fail chỉ vì tăng version.
- Kết quả kiểm tra source tree 0.4.10 trong môi trường đóng gói: `python -m compileall -q gdqp_motion_studio run.py tests` đạt; `python -m pytest -q tests`: **92 passed, 1 skipped**. Bài UI smoke test bị skip ở môi trường đóng gói vì không cài PyQt6; trên máy cài đủ requirements, launcher sẽ chạy bài đó thật.
- Một bài bị skip không được tính như một test pass. Việc test suite đạt trên source tree không thay thế kiểm thử trực tiếp camera, cửa sổ chụp màn hình và UI Windows của người dùng.


## 0.4.11 — PATCH NOTES / PowerShell probe quoting

- **PATCH:** bản 0.4.10 gặp lỗi parser trong `bootstrap.ps1` ở hai lệnh kiểm tra Python (`Test-LocalPython` và `Test-CompatiblePythonPath`). Code Python nhúng trong chuỗi PowerShell dạng dấu ngoặc kép khiến Windows PowerShell phân tích sai và báo hàng loạt lỗi ngoặc/`try-catch`.
- Đổi cả hai probe sang PowerShell single-quoted literal; code Python bên trong dùng chuỗi dấu ngoặc kép, không nội suy `$`, nên PowerShell chỉ chuyển nguyên văn cho `python.exe -c`.
- Thêm regression test kiểm tra cả hai probe dùng dạng quoting an toàn để lỗi này không quay lại khi chỉnh launcher.
- Giữ nguyên một thanh tiến độ tổng và các cập nhật tiến độ theo dữ liệu thật trong giai đoạn tải/cài. Không biến đầu ra pip thành nhiều dòng console.
- Kiểm tra source tree: `compileall` đạt; `pytest tests`: **93 passed, 1 skipped** (UI smoke test bỏ qua trong môi trường tạo mã do chưa có PyQt6).
- **Giới hạn kiểm tra:** môi trường xây dựng hiện không chạy Windows PowerShell 5.1 trực tiếp. Đã thêm regression test cho dạng quoting và kiểm tra cấu trúc script, nhưng lần chạy đầu trên Windows vẫn là bước xác nhận runtime cuối cùng.


## 0.4.12 — PATCH NOTES / Loại bỏ inline Python khỏi PowerShell probe

- **PATCH:** bản 0.4.11 vẫn lỗi parser trên Windows PowerShell 5.1 ở hai lệnh probe tại `Test-LocalPython` và `Test-CompatiblePythonPath`. Dù chuỗi được đổi sang single-quoted literal, log của người dùng cho thấy PowerShell vẫn phân tích cú pháp sai trên máy thật; vì vậy không tiếp tục dựa vào quoting inline.
- Thêm `GDQP_Motion_Studio_App/runtime_probe.py`, một script chỉ dùng standard library. PowerShell gọi trực tiếp script này với `-I` và tag `GDQP_RUNTIME_PROBE` / `GDQP_BASE_PROBE`; output vẫn một dòng có tag, version, architecture và `sys.executable`.
- Bổ sung kiểm tra `runtime_probe.py` trong layout preflight và thêm helper vào source manifest để thay đổi file này sẽ làm mới preflight cache.
- **PATCH:** thêm regression test xác nhận cả hai probe dùng helper file, không nhúng code Python có quote/pipe/brace bên trong PowerShell string.
- Giữ nguyên tổng tiến độ cài đặt, progress theo package đã tải/cài thật và các tối ưu inference dành cho CPU yếu.

### Kiểm tra 0.4.12

- `compileall` cho package, helper và test: đạt.
- Regression tests launcher kiểm tra cấu trúc helper: đạt.
- PowerShell 5.1 không có sẵn trong môi trường xây dựng; vì thế cần xác nhận lại script trên Windows của người dùng. Thay đổi này loại bỏ nguyên nhân quoting inline ở dòng báo lỗi, nhưng chưa được tuyên bố là đã chạy thật trên Windows.


## 0.4.13 — PATCH NOTES / Parse guard và phát hiện thư mục trộn phiên bản

- **PATCH:** log lỗi được gửi cho 0.4.12 chứa lệnh inline Python probe trùng với bootstrap 0.4.11, dù mã nguồn 0.4.12 phát hành có `runtime_probe.py` riêng. Đây là dấu hiệu file chạy thực tế không khớp hoàn toàn hoặc các file từ nhiều phiên bản bị trộn trong thư mục giải nén.
- Thêm `launcher_guard.ps1`, được gọi bởi `run.bat` trước `bootstrap.ps1`. Guard kiểm tra version của bootstrap và package, kiểm tra `runtime_probe.py`, phát hiện inline-probe cũ và gọi `[System.Management.Automation.Language.Parser]::ParseFile()` để phân tích `bootstrap.ps1` trước khi thực thi.
- Khi file thiếu, sai version hoặc sai cú pháp, launcher dừng trước bootstrap và ghi lỗi có dòng/cột vào `_logs/launcher_guard.log`.
- Thêm guard vào manifest hash và regression test cho parse check/version check.
- **Cách cài:** giải nén ZIP 0.4.13 vào thư mục mới; không chép đè từng file lên 0.4.12. Chạy `run.bat` ở thư mục ngoài cùng.

### Kiểm thử 0.4.13

- Chạy `compileall` và test trong `GDQP_Motion_Studio_App/tests/`.
- Parse check thực tế của `bootstrap.ps1` được thực hiện bằng Windows PowerShell ngay khi khởi chạy; môi trường dựng mã hiện không có Windows PowerShell 5.1 để chạy trực tiếp parser này, nên không tuyên bố đã kiểm tra end-to-end trên Windows.


## 0.4.14 — PATCH NOTES / PowerShell UTF-8 encoding and parser regression tests

- **PATCH:** 0.4.13 shipped `bootstrap.ps1` as UTF-8 without a BOM while it contains Unicode punctuation (em dash). Windows PowerShell 5.1 can interpret BOM-less UTF-8 as the active ANSI code page; the bytes for an em dash can become a curly-quote character and break a quoted string, causing cascading parser errors that look like missing `catch`, braces, or a final quote.
- Save `bootstrap.ps1` and `launcher_guard.ps1` with a UTF-8 BOM, and keep PowerShell source ASCII-only as a second layer of protection. Replace the non-ASCII em dash/status text in PowerShell strings with plain ASCII hyphens and words.
- Add regression tests that require BOM-prefixed, ASCII-only PowerShell entrypoints. Add a Windows-only test that invokes the native PowerShell parser on both `bootstrap.ps1` and `launcher_guard.ps1`; it is skipped on non-Windows build hosts, not counted as a pass.
- The launcher guard continues parsing `bootstrap.ps1` before executing it, so an actual parse error stops setup with line/column diagnostics.

### Kiểm tra 0.4.14

- `python -m compileall -q gdqp_motion_studio run.py runtime_probe.py tests`: passed.
- `python -m pytest -q tests`: **96 passed, 2 skipped**.
- PowerShell encoding regression: UTF-8 BOM + ASCII-only checks passed on the build host.
- Native Windows PowerShell parser test: intentionally skipped on this Linux build host; it will run on Windows where `powershell.exe` is present. A skipped native-parser test is not counted as a pass and does not prove the Windows runtime was exercised.


## 0.4.15 — PATCH NOTES / Explicit progress percentage and reliable CMD pause

- **PATCH:** the 0.4.14 `run.bat` launched `launcher_guard.ps1`, and the guard launched `bootstrap.ps1` inside the same PowerShell process. This made failure-code propagation harder to observe and the user's CMD could close on some failure paths. The guard is now validation-only; `run.bat` invokes guard and bootstrap as separate PowerShell processes and captures each `%ERRORLEVEL%`.
- **PATCH:** every non-zero exit from project validation, bootstrap, dependency setup, source preflight, or application launch goes to one `:failed` label. That label prints the exit code and performs `pause >nul`, so a double-clicked CMD stays open until the user reviews the error. Missing files and missing PowerShell use the same failure path.
- **PATCH:** `Set-OverallProgress` now includes an explicit numeric status such as ` 42% | Downloading packages (17/43 package wheels ready)` in addition to `Write-Progress -PercentComplete`, so the percentage is visible rather than only implied by the bar. Progress still advances on downloaded bytes, completed wheels/packages, and finished validation stages; it does not use elapsed-time animation.
- **PATCH:** the bootstrap catch clears the transient progress bar, records the error location/command and formatted error details in `_logs/launcher.log`, prints a clear failure message, and exits non-zero. The batch launcher keeps the console open for copying the error.
- **PATCH:** `launcher_guard.ps1` now ends with `exit 0` after validation instead of starting the bootstrap itself. This makes process boundaries and exit codes deterministic.
- Added regression tests for explicit percent text, separate guard/bootstrap calls, pause-on-failure behavior, failure exit codes, and guard-only operation.

### Verification 0.4.15

- `compileall` across the application, runtime probe, and tests: passed.
- `pytest -q tests`: **99 passed, 2 skipped** in the build environment. One skip is the Qt UI smoke test because PyQt6 is not installed on this host; the other is the native Windows PowerShell parser test because this host is not Windows.
- Static regression tests inspect both `%ERRORLEVEL%` captures, the unified batch failure label and `pause`, explicit numeric progress status, and that the guard does not invoke bootstrap itself.
- ZIP was extracted into a fresh verification directory and the project test suite was run from that extracted copy.
- **Limit:** this build environment has no Windows PowerShell 5.1 parser, so the native parse test is skipped here. On Windows, `launcher_guard.ps1` parses `bootstrap.ps1` before bootstrap executes, and `run.bat` keeps the CMD open for any non-zero result.


## 0.4.16 — PATCH NOTES / pip download option compatibility

- **PATCH:** log từ máy người dùng cho thấy bước `pip download` thoát mã 2 với `no such option: --no-warn-script-location`. Tùy chọn này không được `pip download` hỗ trợ (nó thuộc lệnh `pip install`), nên toàn bộ giai đoạn tải wheel bị dừng trước khi cài package.
- Loại bỏ `--no-warn-script-location` riêng khỏi lệnh `pip download`. Biến môi trường `PIP_NO_WARN_SCRIPT_LOCATION=1` vẫn được thiết lập ở đầu bootstrap và tiếp tục được kế thừa bởi tiến trình pip; các lệnh `pip install` giữ nguyên tùy chọn hợp lệ này.
- Thêm regression test trích riêng lời gọi `pip download`, xác nhận không truyền tùy chọn không được hỗ trợ, đồng thời xác nhận biến môi trường thay thế vẫn tồn tại.
- Tăng version nhất quán lên 0.4.16 trong launcher, bootstrap, guard, package metadata và test lịch sử version.

### Kiểm tra 0.4.16

- `compileall`: passed.
- `python -m pytest -q tests`: **100 passed, 2 skipped** trong môi trường dựng mã. Một test UI được skip vì môi trường này chưa có PyQt6; một test parser PowerShell native được skip vì môi trường không phải Windows.
- ZIP: giải nén thử và chạy lại test từ bản đã giải nén.
- **Lưu ý:** nếu log vẫn hiển thị đường dẫn thư mục `GDQP_Motion_Studio_0.4.6`, người dùng có thể đang chạy bản cũ hoặc đã chép file mới vào thư mục cũ. Nên giải nén toàn bộ ZIP 0.4.16 vào một thư mục mới, không trộn file qua các phiên bản.


## 0.4.17 — PATCH NOTES / Main workspace navigation cleanup

- Bỏ tab So sánh khỏi thanh tab chính; vẫn giữ một nút So sánh trong nhóm Điều khiển phiên. Nút này mở trang So sánh và đổi thành nút quay lại khi đang ở trang So sánh.
- Đưa tab Bộ xương 3D lên vị trí thứ 2, trước Thông số.
- Đưa Timeline lên vị trí tab hiển thị thứ 4, thay cho tab Báo cáo cơ thể.
- Giữ chức năng báo cáo cơ thể bằng nút Đánh giá tổng thể trong tab Bộ xương 3D; trang báo cáo có nút quay lại bộ xương 3D, không còn chiếm chỗ trên thanh tab.
- Đưa So sánh thành một workspace riêng bên cạnh QTabWidget chính để không cần dùng tab ẩn có thể gây hành vi điều hướng không rõ ràng.
- Bổ sung regression tests cho thứ tự tab, nút điều hướng so sánh và đường quay lại báo cáo cơ thể.
- Cập nhật nội dung hướng dẫn để nhắc mở Trang So sánh qua nút trong nhóm Điều khiển phiên, không còn gọi đó là tab chính.

### Kiểm tra 0.4.17

- Python syntax check và bộ test trong thư mục `tests/` được chạy trước khi đóng gói.
- Kiểm thử UI sẽ tự chạy trên máy có PyQt6; nếu môi trường dựng gói không có PyQt6, bài UI bị skip và cần xác nhận thêm trên Windows thật.


## 0.4.18 — PATCH NOTES / Lỗi chuyển phiên So sánh và cadence khi lỗi pose

- **Lỗi logic nghiêm trọng của 0.4.17:** `_comparison_countdown_tick()` tham chiếu tên `is_camera` không được khai báo trong hàm. Khi countdown về 0, callback có thể ném `NameError` sau khi đặt trạng thái `running`, làm phiên So sánh bị kẹt và không khởi động timer nguồn tham chiếu. Bản vá loại bỏ nhánh camera không hợp lệ ở callback; nguồn webcam chính đã bị chặn ngay trong `start_comparison()`, vì vậy timer tham chiếu chỉ cần dùng FPS nguồn video/màn hình.
- **Lỗi nhãn điều khiển sau khi hủy đếm ngược Báo cáo cơ thể:** nguồn được chạy lại nhưng nút chung vẫn hiển thị "Tiếp tục". Bản vá trả nhãn về "Tạm dừng" khi timer nguồn được khởi động lại và thêm regression test cho nhánh hủy.
- **Lỗi đồng bộ UI khi webcam so sánh mất tín hiệu:** với nguồn chính là màn hình, timer tham chiếu bị dừng nhưng bộ điều khiển nổi có thể vẫn hiển thị "ĐANG CHỤP MÀN HÌNH". Bản vá gọi `screen_capture_controller.set_paused(True)` khi `_pause_reference_and_comparison()` tạm dừng nguồn do lỗi webcam, để nhãn và nút phản ánh đúng trạng thái timer. Thêm regression test cho trạng thái đồng bộ này.
- **Lỗi cadence dữ liệu:** khi xử lý pose ném exception, bộ đếm `_pose_fresh_frame_count` trước đây không tăng. Nếu bộ đếm nằm đúng bội số của `sample_every`, các frame lỗi liên tiếp có thể được lưu thành các dòng lỗi dày đặc. Bản vá tăng bộ đếm ở nhánh lỗi để vẫn tuân thủ cadence lấy mẫu.
- Thêm static scope regression test cho unresolved globals trong `main_window.py`; test hồi quy AST xác nhận cadence được tăng trong nhánh pose error; thêm UI runtime test thực thi trực tiếp callback đếm ngược trên máy có PyQt6.
- Đồng bộ package version, `run.bat`, bootstrap, guard và test lịch sử phiên bản lên 0.4.18.

### Kiểm tra 0.4.18

- `compileall`: passed.
- `python -m pytest -q`: **107 passed, 2 skipped** trên source tree sau khi sửa regression test về nhánh hủy đếm ngược. Hai test bị skip là UI runtime (PyQt6 không có trên máy dựng gói) và parser PowerShell native (host không phải Windows).
- Kiểm tra `symtable` trên `main_window.py`: không còn global chưa được khai báo.
- Các test nguồn kiểm tra điều hướng tab, callback countdown, đồng bộ trạng thái capture và cadence lấy mẫu khi pose lỗi. Callback UI có test runtime tương ứng nhưng cần chạy trên máy Windows/PyQt6 để thực thi thật.
- Giới hạn: chưa thực hiện kiểm thử end-to-end trên Windows cùng camera/video thật; kết quả trên không chứng minh mọi widget đã được quan sát trực quan.


## 0.4.19 — PATCH NOTES / Floating screen controls during comparison countdown

- **Logic/UI bug:** when the primary source was a whole-monitor capture, `start_comparison()` stopped the source timer during countdown but left the floating controller's Pause button enabled. Clicking it could restart the reference source before the countdown ended, violating the requirement that the reference and comparison begin together.
- Add `_sync_screen_controller_comparison_state()` to synchronize the floating controller with comparison `countdown`, `running`, and `paused` states. During countdown, Pause and body-report controls are disabled and the floating heading displays the remaining seconds; when comparison starts, controls are restored; on pause/failure, the controller reflects the paused state and still allows the user to resume the source.
- Update the floating controller on every countdown tick, comparison start, comparison pause, and auto-resume.
- Add a regression test ensuring the countdown locks the floating controls and the three state branches remain present.

### Verification 0.4.19

- `compileall`: passed on the extracted release archive.
- `pytest -p no:cacheprovider -q tests`: **108 passed, 2 skipped** on the extracted release archive.
- The UI smoke test is skipped because PyQt6 is unavailable on the build host. The native Windows PowerShell parser test is skipped because this host is not Windows.
- ZIP integrity check: passed; release archive excludes `__pycache__`, `.pyc`, and `.pytest_cache` artifacts.
- This fix is based on code-path review and regression tests. A native GUI end-to-end test with real screen capture and webcam is still required on Windows.

## 0.4.20 — PATCH NOTES / UI thích ứng, so sánh hai video và đa so sánh

### 1. Sửa lỗi thanh trên cùng chiếm quá nhiều chiều cao

- **Co giãn toolbar theo chiều rộng thực tế:** thay ngưỡng cũ khiến thanh điều khiển rơi xuống 2 cột từ 900 logical px. Bản mới ưu tiên 4 cột / 2 hàng trên màn hình đủ rộng, 3 cột ở kích thước trung bình và chỉ dùng 2 cột khi cửa sổ rất hẹp.
- Giới hạn chiều cao nhãn trạng thái ở đầu cửa sổ; phần chữ đầy đủ có thể xem qua tooltip thay vì làm header phình to.
- Theo dõi `screenChanged`, vùng desktop khả dụng và DPI logic/vật lý. Khi Windows đổi độ phân giải hoặc cửa sổ chuyển màn hình, ứng dụng tính lại kích thước, lề và vị trí dựa trên vùng desktop hiện có.
- Giảm lề/khoảng cách khi chiều cao cửa sổ thấp; tab Đa so sánh có vùng cuộn dọc để nội dung không bị mất ngoài khung.

### 2. Chế độ So sánh video ↔ video

- Trong trang **So sánh**, chọn chế độ **Video tham chiếu ↔ Video thứ hai**. Video đang mở làm nguồn tham chiếu, còn nút chọn video thứ hai dùng làm nguồn quan sát.
- Video thứ hai được căn theo timestamp của frame tham chiếu đang được phân tích; không dùng hai timer chạy độc lập để hạn chế trôi nhịp khi FPS khác nhau. Nếu video thứ hai ngắn hơn mốc cần chấm, phiên dừng và giữ kết quả đã ghi.
- Sử dụng lại phép đo góc khớp và chỉ số tương đồng hình học của phiên so sánh hiện có. Chỉ số vẫn là **chỉ số hình học thử nghiệm**, không phải xác suất hoặc điểm đúng/sai động tác đã được kiểm chứng khoa học.
- Chế độ hai video yêu cầu nguồn tham chiếu là tệp video. So sánh video tham chiếu với webcam vẫn còn; nguồn chia sẻ màn hình tiếp tục được hỗ trợ trong chế độ webcam.

### 3. Tab Đa so sánh

- Thêm tab **👥 Đa so sánh**: chọn video mẫu một người và video thực hiện có nhiều người, đặt số pose tối đa (2–12), rồi chạy so sánh và xuất kết quả CSV/JSON.
- Thư viện được chọn là **MediaPipe Tasks Pose Landmarker**. Tham số `num_poses` cho phép giới hạn số pose có thể phát hiện trong một frame; model Lite được tải một lần và lưu cache cục bộ nếu chưa có. Video được phân tích trên máy, không tải video lên máy chủ. Tài liệu chính thức: [Pose Landmarker Python guide](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker/python).
- Ghép ID người qua các frame bằng vị trí tâm khung xương, sau đó dùng cùng phép so sánh góc với phiên đơn. Chỉ ghi điểm khi có ít nhất hai cặp góc hợp lệ; dữ liệu thiếu không bị biến thành điểm giả.
- **Giới hạn cần biết:** cách ghép ID hiện là tracker nhẹ theo vị trí, không phải nhận dạng danh tính. Khi nhiều người cắt ngang nhau, che khuất lâu hoặc rời/đi vào khung hình, ID có thể đổi. Ánh sáng, độ phân giải, góc quay và việc thấy đủ cơ thể ảnh hưởng đến chất lượng pose. Kết quả là prototype hỗ trợ phân tích, chưa phải hệ thống chấm động tác được xác nhận khoa học.

### Kiểm tra 0.4.20

- `python -m compileall -q gdqp_motion_studio run.py runtime_probe.py tests`: passed.
- `python -m pytest -p no:cacheprovider -q tests`: **118 passed, 2 skipped**.
- ZIP integrity check (`unzip -t`): passed on the release archive.
- Hai test bị skip: UI runtime smoke test do môi trường dựng gói không có PyQt6; native PowerShell parser test do môi trường không phải Windows. Vì vậy, dù có regression tests cho co giãn và sự kiện DPI, vẫn cần mở bản này trên Windows/màn hình đã gặp lỗi để xác nhận UI thật, đồng thời kiểm tra model MediaPipe trên video thực tế.


## 0.5.0 — Cài đặt người dùng, điều khiển FPS và kiểu khung xương

- Bổ sung tab Cài đặt với lưu tùy chọn qua các lần chạy, áp dụng tức thì và khôi phục mặc định. Camera FPS (5–60) độc lập với FPS mục tiêu pose/khung xương (3–30).
- Bổ sung preset Tiết kiệm CPU / Cân bằng / Ưu tiên mượt, màu đường xương, màu điểm khớp, độ dày đường, bán kính điểm khớp và tùy chọn bật/tắt phần vẽ mà vẫn tiếp tục tính phép đo.
- Giữ adaptive scheduler để hạ tải trên máy yếu; camera driver có thể không đáp ứng FPS được yêu cầu. Đa so sánh giữ màu riêng theo ID để phân biệt người.
- Bộ kiểm thử được cập nhật cho cadence tùy chỉnh, thông số vẽ và phiên bản launcher.
- `compileall`: passed; `pytest -p no:cacheprovider -q tests`: **120 passed, 2 skipped**. Skip: UI smoke test (không có PyQt6) và kiểm tra native PowerShell parser (môi trường không phải Windows).
- Kiểm thử webcam thật, tốc độ frame thực tế và GUI trên Windows vẫn cần được xác nhận trên máy đích.


## 0.6.0 — Cải thiện thao tác Cài đặt và tạm dừng theo tab

- FPS camera và FPS pose hiển thị bằng ô số thuần; nâng giới hạn FPS pose lên 60. Cân bằng = khoảng một nửa FPS camera; Ưu tiên mượt = bằng FPS camera; Tiết kiệm CPU giữ preset 15/6. Preset liên kết được duy trì khi chỉnh FPS camera, còn chỉnh FPS pose thủ công chuyển về tùy chỉnh.
- Thay dropdown màu cố định bằng hộp chọn màu có bảng HSV kéo/chọn, preview trực quan và mã HEX.
- Timer nguồn chính tạm dừng khi rời nhóm tab dữ liệu sang Cài đặt/Giới thiệu/Tiêu chí; timer Đa so sánh tạm dừng khi rời tab riêng, tiếp tục khi quay lại nếu đang chạy trước đó; không giải phóng capture hoặc xóa dữ liệu. Lệnh dừng và tạm dừng thủ công được tôn trọng.
- `compileall`: passed. `pytest -p no:cacheprovider -q tests`: **123 passed, 2 skipped** trên source đã giải nén. GUI PyQt6/camera thật và PowerShell native vẫn cần kiểm tra trên Windows nếu môi trường test không có các thành phần đó.


## 0.7.0 — Nhận diện nhiều người trực tiếp bằng webcam

- Bổ sung nguồn webcam trong tab Đa so sánh. Có thể phát hiện nhiều người và hiển thị ID/bộ xương trực tiếp mà không cần video mẫu; video mẫu là tùy chọn để so sánh động tác.
- Tận dụng camera đang mở ở tab Phân tích khi trùng index, tránh mở camera hai lần và không giải phóng nhầm handle dùng chung. Cấm dùng song song camera đang được chế độ So sánh chiếm dụng.
- Camera nhận diện đọc frame theo mục tiêu FPS camera và chỉ suy luận theo FPS refresh bộ xương; giữa các lần suy luận, hình camera vẫn cập nhật với pose gần nhất.
- Khi rời tab Đa so sánh, timer tạm dừng; quay lại tiếp tục nếu phiên chưa dừng. JSON ghi rõ nguồn là webcam hay video, index camera và chế độ phát hiện độc lập.
- Kiểm thử source: compileall passed; bộ test dự án gồm regression cho nhánh webcam trực tiếp. Kiểm thử webcam thực tế cần chạy trên Windows với PyQt6, MediaPipe và camera sẵn có.

## 0.7.1 — PATCH: ổn định luồng webcam và dữ liệu

- Sửa nhịp video mẫu trong so sánh webcam để bám thời gian thực, không chạy nhanh/chậm theo FPS timer camera.
- Sửa cadence lấy mẫu và tuổi ID tracker theo timestamp; giữ metadata nguồn của phiên cho JSON/CSV.
- Bổ sung regression tests cho các đường logic nêu trên.

