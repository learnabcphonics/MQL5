# Ghi chú phát triển Indicator SMC

## Tổng quan
Tài liệu này ghi lại ý định thiết kế hiện tại, các ràng buộc khi render, và các quy tắc vận hành đã biết của indicator Smart Money Concepts (SMC) trong workspace này.

Dự án có ý định tách rõ logic phân tích khỏi rendering trực quan:
- logic phân tích nằm ở các file engine/state của SMC
- render và vệ sinh object nằm trong `SMC_Draw.mqh`
- bảng màu và phong cách trực quan cố định nằm trong `SMC_Palette.mqh`

Mục tiêu là giữ nguyên logic giao dịch nhưng làm cho biểu đồ ổn định, sạch, và dễ dự đoán khi chuyển timeframe, redraw, hoặc có nhiều vùng chồng lên nhau.

## Nguyên tắc cốt lõi

### 1. Không viết lại logic engine SMC
Engine phân tích chịu trách nhiệm phát hiện:
- swing highs/lows
- structure breaks và CHoCH events
- order blocks
- fair value gaps
- premium/discount zones
- equal highs/lows
- trailing levels và market bias

Các sửa lỗi render không được thay đổi logic giao dịch.

### 2. Tên object phải theo nhóm phân loại
Tên object phải là duy nhất và có ý nghĩa theo nhóm để tránh va chạm với các object khác trên chart hoặc với nhau.

Phân loại tên khuyến nghị:
- `STR_` cho structure lines
- `SW_` cho swing labels/levels
- `PD_` cho premium/discount zones
- `PL_` cho previous period levels
- `FVG_` cho fair value gaps
- `OB_` cho order blocks
- `BIAS` cho label market bias

Tránh dùng tên chung như `D`, `W`, `M`, `H`, `L`, hoặc prefix quá rộng vì dễ trùng với object khác.

### 3. Layering phải rõ ràng
Các vùng fill không được cạnh tranh cùng một layer hình ảnh theo cách mơ hồ.

Thứ tự ưu tiên layer nên là:
- previous levels (thấp nhất)
- premium/discount zones
- FVG zones
- OB zones
- structure lines
- labels và markers (cao nhất)

Như vậy, nến vẫn hiển thị rõ, đồng thời fill nằm phía sau.

### 4. Cleanup phải nhắm mục tiêu
Xoá prefix rộng làm chậm và có thể xoá nhầm các object không liên quan trên chart.

Nên ưu tiên:
- xoá theo tên object cụ thể
- xoá đúng family object đang refresh
- tránh dùng `DeleteObjectsWithPrefix(...)` ở hot path trừ khi thật sự muốn reset cả nhóm

### 5. Object stale là lỗi render
Rectangle hoặc text cũ có thể tồn tại qua nhiều vòng redraw và tạo ra các vệt đen, label cũ, hoặc vùng chồng lấp vô hình.

Trước khi vẽ object mới, mã nên kiểm tra object cũ có tồn tại không, rồi tạo lại hoặc xoá khi hình học hoặc màu thay đổi.

## Quy tắc render

### Chính sách overlap vùng
Nếu nhiều object vùng chồng lên nhau, renderer nên ưu tiên một vùng đang active và có độ ưu tiên cao hơn thay vì chỉ đổi màu đối tượng mới.

Thứ tự ưu tiên hiện tại:
- OB thắng FVG khi hình chữ nhật chồng nhau
- FVG thắng các fill nền chung khi cần thiết
- label bị bỏ vẽ nếu sẽ va chạm với object ưu tiên cao hơn

Điều này giúp ngăn “black band” / “hidden fill” artefact xảy ra khi từng rectangle vẽ mà không có xử lý overlap rõ ràng.

### Vị trí label
Label nên được offset một chút so với hình học fill gốc để giảm chồng nhau.

Helper `SMC_LabelOffsetPrice(...)` offset label theo loại object, nhằm:
- label OB nằm lệch ra khỏi tâm band
- label FVG đặt ở offset vừa đủ
- label PD vẫn dễ đọc khi xếp chồng

### Sử dụng z-order
Mỗi object vùng nên nhận z-order theo lớp của nó:
- `PL_` -> thấp
- `PD_` -> kế tiếp
- `FVG_` -> kế tiếp
- `OB_` -> kế tiếp
- `STR_`/`SW_` -> mid-layer
- labels -> foreground

Như vậy, fill vùng nằm phía sau nến và label vẫn nổi bật.

## Cảnh báo thời gian và runtime

### Chuyển timeframe
Indicator phải rebuild state sạch khi timeframe của chart thay đổi. Với MT5, việc redraw và reload lặp lại init/calculation là bình thường.

Không được để state object cũ tồn tại qua thời điểm chuyển timeframe.

### Loading lịch sử FVG
Nếu runtime log lỗi như:
- `unable to load FVG history for chart timeframe ...`
- `bars=-1, error=4401`

thường nghĩa là request history không hợp lệ hoặc khoảng history không có sẵn cho symbol/timeframe hiện tại.

Indicator phải coi đây là mất dữ liệu runtime mềm, không phải lỗi fatal. Nên bỏ qua update, giữ state hiện tại, và tiếp tục render những gì đã có sẵn.

### Cleanup object đang active
Khi một object không còn hợp lệ, nên xoá cụ thể thay vì để trạng thái stale tồn tại. Nếu không, object có thể nằm trên chart và làm nhiễu cho các lần vẽ sau.

## Các lớp bug đã được xử lý trong phiên bản hiện tại

1. Các đoạn fill OB đen do state rectangle stale hoặc redraw chồng nhau
2. Cleanup theo prefix rộng xoá nhầm object không liên quan do tên quá generic
3. Swing labels collapse thành một nhãn vì xoá cả prefix chứ không xoá từng nhãn riêng
4. Previous period level xoá nhầm market bias label vì tên quá generic
5. Vùng OB/FVG chồng nhau khiến render khó đọc và sai lệch về trực quan
6. Thứ tự layer giữa fill và label không đồng nhất

## Checklist phát triển cho các thay đổi sau
Trước khi thay đổi gì về render hoặc object management, hãy xác nhận:
- không sửa logic engine
- tên object vẫn duy nhất và theo nhóm phân loại
- cleanup object stale rõ ràng
- quy tắc overlap được định nghĩa trước khi vẽ
- z-order theo lớp object
- labels luôn nằm trên fill

## Ghi chú cho maintainer
Dự án này chủ ý về rendering biểu đồ: engine có thể phát hiện đúng cấu trúc SMC, nhưng trải nghiệm người dùng phụ thuộc vào việc biểu đồ không làm mờ hoặc che mờ tín hiệu.

Nếu xuất hiện bug trực quan, hãy kiểm tra theo thứ tự:
1. va chạm tên object
2. cleanup object stale
3. ưu tiên overlap
4. z-order
5. offset label
6. khả dụng dữ liệu history

File này nên được xem như tài liệu tham khảo sống cho các quyết định vệ sinh render và object trong indicator SMC.
