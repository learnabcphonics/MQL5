# Kế hoạch Multi-Timeframe Analysis (MTF) cho SMC

## 1. Tầm nhìn

Phát triển SMC thành công cụ phân tích nhiều timeframe theo một quy trình rõ
ràng:

**Bối cảnh thị trường → vùng/setup đáng chú ý → tín hiệu kích hoạt**

Người dùng có thể xem bias và cấu trúc ở khung lớn, theo dõi setup ở khung
trung gian, rồi quan sát tín hiệu ở khung nhỏ. Indicator cung cấp dữ liệu và
cách trình bày nhất quán; không tự đưa ra quyết định giao dịch thay người dùng.

MTF là tên của tính năng phân tích nhiều timeframe. HTF, Mid và LTF là vai trò
tương đối được gán trong cấu hình, không phải tên timeframe cố định. Ví dụ
H4/H1/M5 có thể lần lượt là HTF/Mid/LTF trong một cấu hình, nhưng timeframe chart
và chiến lược khác có thể cần bộ khung khác.

## 2. Kết quả người dùng cần đạt được

Khi xem chart, người dùng có thể trả lời:

1. **Bối cảnh:** Bias và cấu trúc ở timeframe lớn đang bullish, bearish hay
   chưa xác định?
2. **Setup:** Giá đang ở vùng SMC nào trên timeframe được chọn để tìm setup
   (ví dụ OB, FVG hoặc vùng liquidity)?
3. **Trigger:** Trên timeframe vào lệnh đã xuất hiện sự kiện nào (ví dụ sweep
   hoặc CHoCH/BOS), và sự kiện đó đã được xác nhận hay chưa?

Ví dụ cấu hình H4/H1/M5:

- H4 cho biết bối cảnh.
- H1 cho biết cấu trúc hoặc vùng setup.
- M5 cho biết trigger để người dùng xem xét.

Ví dụ này chỉ minh họa cách phân vai; không phải mặc định chiến lược hay khuyến
nghị giao dịch.

## 3. Khảo sát hiện trạng

- `Indicators/SMC/SMC.mq5` có `ShowMarketBias` và
  `ShowHigherTimeframeBias`; các timeframe so sánh đang cố định H4, D1, W1.
- `Include/SMC/SMC_TimeframeAnalysis.mqh` tạo snapshot phân tích cho symbol và
  timeframe được truyền vào: Swing/Internal bias, structure events gần nhất,
  OB và FVG theo các cờ bật tương ứng. Module lấy nến đã đóng bằng `CopyRates`
  từ shift 1, tạo `SMC_State` riêng và khởi tạo cache.
- `Include/SMC/SMC_DrawBias.mqh` vẽ nhãn bias timeframe chart và các timeframe
  so sánh. Hàng trùng chart timeframe được bỏ.
- `Include/SMC/SMC_EqualLevels.mqh` phát hiện sự kiện EQH/EQL;
  `Include/SMC/SMC_DrawEqualLevels.mqh` chỉ vẽ sự kiện đó.
- Logic vùng được tách theo loại: `SMC_OrderBlock.mqh` quản lý OB,
  `SMC_FVG.mqh` quản lý FVG. Phần vẽ cũng tách riêng:
  `SMC_DrawOrderBlocks.mqh` phụ trách vẽ/xóa OB;
  `SMC_DrawMTFOrderBlocks.mqh` điều phối overlay OB MTF;
  `SMC_DrawFVG.mqh` phụ trách vẽ/xóa FVG; `SMC_DrawMTFFVG.mqh` điều phối
  overlay FVG MTF. Hai loại vùng dùng chung primitive hình chữ nhật trong
  `SMC_DrawAreas.mqh`; runtime gọi riêng renderer theo từng loại vùng.
- `SMC_Structure.mqh` chỉ phát hiện và trả về structure events; việc lưu OB
  từ các event đó thuộc `SMC_OrderBlock.mqh`. Các renderer levels được chia
  theo swing/trailing levels, previous-period levels và premium/discount zones;
  helper đặc thù vùng nằm trong `SMC_DrawZoneHelpers.mqh`.
- `Include/SMC/SMC_Liquidity.mqh` tiếp nhận sự kiện EQH/EQL và lưu mức
  liquidity gần nhất cho Equal High và Equal Low trong state phân tích. Module
  này chưa xác định hay đánh dấu sweep. Chưa cần module vẽ Liquidity riêng cho
  đến khi có đối tượng Liquidity/Sweep cần vẽ.
- `Include/SMC/SMC_IndicatorMTF.mqh` điều phối tính toán lại snapshot theo nến
  đóng, xử lý slot trùng và cập nhật panel/overlay MTF.
- `Include/SMC/SMC_TimeframeSlots.mqh` dùng chung quy tắc nhận diện slot
  timeframe đang bật và bỏ qua slot trùng cho panel, phân tích và overlay.
- `Include/SMC/SMC_IndicatorRuntime.mqh` nối cấu hình và state của indicator
  chart với các adapter/runtime chuyên trách.
- `Include/SMC/SMC_IndicatorFVG.mqh` xử lý vòng đời FVG chart timeframe:
  tải lịch sử, cập nhật ngưỡng/phân tích, xử lý mitigation và gọi renderer;
  phần logic nhận diện vẫn nằm trong `SMC_FVG.mqh`.
- `Include/SMC/SMC_Draw.mqh` gom các module vẽ; `SMC.mq5` kết nối input,
  runtime và các module tính toán.
- Giai đoạn 1 đã thêm ba slot timeframe so sánh, mặc định H4/D1/W1; mỗi slot
  bật/tắt và chọn timeframe độc lập. Các slot hiện chưa được gán vai trò
  HTF/Mid/LTF theo lựa chọn của người dùng.
- Giai đoạn 2 bổ sung sự kiện Swing/Internal BOS/CHoCH gần nhất vào dòng panel
  riêng của mỗi timeframe đã chọn. Phân tích dùng nến đã đóng và cập nhật khi
  nến timeframe đó đóng, kể cả khi timeframe nhỏ hơn chart.
- Có các input `ShowMTFOrderBlocks` và `ShowMTFFairValueGaps` để bật overlay
  vùng MTF; cả hai mặc định tắt để tránh làm rối chart. Overlay dùng prefix và
  nhãn timeframe riêng; OB dùng bộ lọc/giới hạn OB hiện tại, FVG dùng threshold
  và số lượng FVG hiện tại.
- Slot trùng nhau chỉ được tính/vẽ một lần; timeframe trùng chart không tạo
  thêm hàng. Khi phép tính cho nến đóng mới thất bại, bias cache cũ không được
  tiếp tục trình bày như dữ liệu mới.
- Phần BOS/CHoCH và OB/FVG MTF hiện tính riêng theo timeframe so sánh; EQH/EQL
  và Liquidity Sweep hiện chỉ chạy trong state chart. EQH/EQL MTF, sweep MTF,
  trigger cấu trúc LTF và liên kết setup-trigger chưa triển khai.
- Module tính và module vẽ Bias đã được tách riêng. Giai đoạn 1 compile thành
  công với 0 lỗi và 0 cảnh báo; giai đoạn 2 cũng compile thành công với 0 lỗi
  và 0 cảnh báo. Cần kiểm tra trực quan trên chart; MTF chưa có bộ test tự động
  chuyên biệt.

## 4. Nguyên tắc thiết kế

### 4.1 Phân vai do người dùng cấu hình

- Cho người dùng chọn timeframe và gán vai trò HTF, Mid, LTF.
- Mid là tùy chọn; cấu hình hai khung HTF/LTF vẫn hợp lệ.
- Không tự suy đoán một timeframe là HTF chỉ vì nó lớn hơn chart, hoặc tự gán
  vai trò chiến lược chỉ dựa vào thứ tự timeframe.
- Có thể dùng timeframe chart làm một trong các vai trò, thường là khung quan
  sát/trigger; không bắt buộc chart phải là LTF.
- Mỗi vai trò phải có timeframe hợp lệ. Không cho phép cấu hình mơ hồ như cùng
  một timeframe được gán hai vai trò nếu chưa định nghĩa rõ cách xử lý.

### 4.2 Tính toán độc lập theo symbol/timeframe

- Mỗi timeframe cần dữ liệu, trạng thái cấu trúc và cache riêng.
- Không tái sử dụng pivot, bias, OB hoặc FVG của chart timeframe cho timeframe
  khác.
- Các bộ tính toán nên trả về dữ liệu/kết quả có cấu trúc; không tự tạo object
  chart bên trong logic phân tích.
- Runtime chịu trách nhiệm điều phối cập nhật; module vẽ nhận kết quả và cấu
  hình hiển thị, không tự tính lại tín hiệu.

### 4.3 Thời điểm xác nhận dữ liệu

- Mặc định dùng nến đã đóng cho bias, cấu trúc và tín hiệu MTF được coi là đã
  xác nhận.
- Nếu sau này hỗ trợ nến đang chạy, phải là tùy chọn riêng, ghi rõ tính chất
  tạm thời và không trộn lẫn với trạng thái đã xác nhận.
- Panel/overlay cần phân biệt được trạng thái đang tải, không đủ lịch sử, chưa
  xác nhận và đã xác nhận.
- Không tiếp tục hiển thị giá trị cache cũ như dữ liệu mới nếu symbol, timeframe
  hoặc lịch sử đã thay đổi mà chưa tính lại thành công.

### 4.4 Hiển thị rõ nguồn timeframe

- Mọi hàng panel và vùng vẽ MTF phải ghi timeframe thực tế.
- Bias, vùng và trigger phải được phân biệt theo vai trò/timeframe; tránh để
  người dùng nhầm tín hiệu H4 với tín hiệu chart.
- Có thể bật/tắt riêng panel và overlay từng thành phần.
- Khi tắt tính năng, đổi slot hoặc gỡ indicator, phải dọn các object do MTF tạo.

### 4.5 MTF không đồng nghĩa với tín hiệu giao dịch

- Hiển thị nhiều bias không tự động tạo trạng thái đồng thuận mua/bán.
- Không phát cảnh báo hoặc kết luận “vào lệnh” nếu chưa có quy tắc chiến lược
  cụ thể do người dùng chấp thuận.
- Cảnh báo, bộ lọc và confluence là phạm vi riêng, phải có điều kiện kiểm thử
  rõ ràng.

## 5. Kết quả và giao diện mục tiêu

### Panel phân tích

Panel tóm tắt các timeframe đã cấu hình, tối thiểu gồm:

- Vai trò và timeframe thực tế.
- Swing bias và Internal bias.
- Trạng thái dữ liệu/tín hiệu: đang tải, chưa đủ dữ liệu, trung tính/chưa xác
  định hoặc hợp lệ.
- Các sự kiện cấu trúc gần nhất khi giai đoạn tương ứng được triển khai.

Panel không thay thế các đường, vùng hoặc nhãn chi tiết trên chart; nó là phần
tóm tắt đa khung.

### Overlay trên chart

- Cho phép chọn thành phần MTF nào được vẽ lên chart; không mặc định vẽ mọi thứ.
- Nhãn phải chứa timeframe nguồn và loại thành phần, ví dụ `H1 OB` hoặc `H4
  FVG`.
- Dùng chung hệ thống quản lý object/canvas hiện có khi phù hợp, nhưng tách
  namespace theo timeframe để tránh đè/xóa nhầm object chart hoặc timeframe
  khác.
- Quy định rõ cách xử lý vùng chồng lấn, vùng hết hiệu lực và giới hạn số object.
- Dữ liệu MTF được đặt theo thời gian/giá của timeframe nguồn, không dịch tọa
  độ để giả vờ là dữ liệu chart timeframe.

### Kết quả phân tích nội bộ

Mỗi timeframe nên cung cấp một snapshot độc lập, có thể mở rộng theo giai đoạn:

- Symbol, timeframe, thời điểm dữ liệu đã xác nhận và trạng thái hợp lệ.
- Swing/Internal bias.
- BOS/CHoCH gần nhất.
- Các vùng OB/FVG cần hiển thị, kèm thời gian tạo, biên giá, hướng và trạng thái.
- EQH/EQL, liquidity sweep và trạng thái xác nhận khi được triển khai.

Chỉ thêm trường dữ liệu khi có nơi tiêu thụ rõ ràng; tránh xây framework tổng
quát không cần thiết.

## 6. Lộ trình triển khai

### Giai đoạn 1 — Nền tảng MTF bias cấu hình được

Mục tiêu: biến các timeframe bias so sánh cố định thành tối đa ba slot có thể
cấu hình, chưa gán vai trò chiến lược HTF/Mid/LTF.

1. Ba slot H4/D1/W1 mặc định; từng slot có input bật/tắt và chọn timeframe.
2. Giữ input `ShowHigherTimeframeBias` để tương thích thiết lập hiện tại.
3. Dùng `SMC_TimeframeAnalysis.mqh` để phân tích từng symbol/timeframe độc lập.
4. Dùng `SMC_DrawBias.mqh` để hiển thị; runtime chỉ điều phối, quản lý vòng đời
   và trạng thái từng slot.
5. Bỏ qua slot trùng, không vẽ timeframe đã có hàng bias chart và từ chối
   timeframe không hợp lệ khi slot được bật.
6. Giữ nến đã đóng làm nguồn mặc định; không hiển thị bias cũ như mới nếu tính
   lại cho nến đã đóng mới thất bại.
7. Không thay đổi cách tính/vẽ các thành phần SMC đang chạy trên chart.

**Trạng thái:** đã triển khai và compile thành công. Defaults hiện tại vẫn là
H4/D1/W1; timeframe trùng chart không có hàng lặp. Chưa xác minh trực quan trên
chart MT5.

**Lựa chọn đã chốt:** giữ H4/D1/W1 là các khung so sánh, chưa gán HTF/Mid/LTF.
Việc gán vai trò theo workflow người dùng có thể được thiết kế ở bước riêng;
không suy ra vai trò chỉ từ timeframe chart.

### Giai đoạn 2 — MTF cấu trúc và vùng setup

Mục tiêu: cho người dùng biết sự kiện cấu trúc gần nhất và (nếu bật) vùng setup
nằm ở đâu, ngoài việc biết bias.

1. Tính Swing/Internal BOS/CHoCH riêng trên từng timeframe được bật, lưu sự
   kiện gần nhất và hiển thị trong dòng cấu trúc có nhãn timeframe.
2. Tính OB và FVG từ lịch sử nến đã đóng của timeframe nguồn; quản lý mitigated/
   invalidated theo logic phân tích tương ứng.
3. Có input riêng để bật overlay MTF OB/FVG; mặc định tắt. Nhãn/vùng dùng
   timeframe nguồn và namespace riêng.
4. Dùng logic hiển thị OB/FVG hiện tại khi phù hợp; giữ số lượng, threshold và
   quy tắc extension đang có.
5. Cập nhật timeframe độc lập khi nến của chính timeframe đó đóng; không đợi
   chart timeframe đóng nếu khung MTF nhỏ hơn chart.
6. Không thay đổi ý nghĩa hoặc logic của thành phần SMC chart timeframe.

**Trạng thái:** đã triển khai. Dòng panel chứa sự kiện cấu trúc gần nhất; overlay
OB/FVG tắt mặc định, có thể bật trong input. Compile đạt 0 lỗi, 0 cảnh báo;
chưa kiểm tra trực quan trên chart MT5.

**Lưu ý:** phase này chưa thêm EQH/EQL MTF, liquidity sweep, quan hệ setup-trigger,
cảnh báo hoặc quy tắc vào lệnh.

### Giai đoạn 3 — Liquidity và trigger LTF

Mục tiêu: nhận biết sự kiện trigger mà không biến nó thành lệnh tự động.

Nền tảng phân tách đã có: EQH/EQL được phát hiện trong
`SMC_EqualLevels.mqh`, các mức gần nhất được lưu qua `SMC_Liquidity.mqh`, còn
vẽ EQH/EQL thuộc `SMC_DrawEqualLevels.mqh`. Logic sweep ban đầu chạy trên
timeframe chart; EQH/EQL MTF và sweep MTF chưa triển khai.

1. Chỉ dùng EQH/EQL đã xác nhận làm pool; một pool phía trên (EQH/BSL) lấy
   cạnh ngoài cao hơn của hai pivot, pool phía dưới (EQL/SSL) lấy cạnh ngoài
   thấp hơn. Theo detector hiện tại, chỉ giữ pool mới nhất mỗi loại.
2. Chỉ xét nến đóng xảy ra sau thời điểm pool được xác nhận. EQH bị sweep khi
   high vượt pool và close quay xuống dưới pool; EQL bị sweep khi low xuyên
   pool và close quay lên trên pool. Buffer bằng 0.
3. Mỗi pool chỉ tạo một sweep. Nếu close đóng hẳn ngoài pool mà không reclaim,
   pool bị invalidated và không phát sweep. Không kết luận đảo chiều hay lệnh.
4. Vẽ nhãn BSL/SSL Sweep có timeframe và cho phép tắt hiển thị bằng input
   `ShowLiquiditySweeps`; logic trạng thái vẫn được cập nhật.
5. Mở rộng EQH/EQL và sweep sang các timeframe MTF được cấu hình.
6. Tính BOS/CHoCH hoặc trigger cấu trúc LTF độc lập.
7. Phân biệt sự kiện đang hình thành với sự kiện đã xác nhận bằng nến đóng.
8. Liên kết trigger với bối cảnh/vùng ở timeframe khác chỉ để trình bày quan hệ;
   chưa kết luận giao dịch nếu chưa có rule.

**Kết quả chấp nhận:** người dùng thấy trigger xảy ra ở timeframe nào, tại vùng
nào và đã xác nhận hay chưa.

### Giai đoạn 4 — Quy tắc confluence và cảnh báo (tùy chọn)

Chỉ triển khai nếu người dùng yêu cầu chốt quy tắc. Trước khi code cần mô tả
được bằng điều kiện kiểm thử, ví dụ:

- HTF bias nào được chấp nhận?
- Mid cần có setup/vùng gì?
- LTF cần sweep, CHoCH/BOS hay điều kiện nào?
- Xử lý bias trung tính, timeframe trái chiều, vùng đã mitigated và tín hiệu
  xuất hiện cùng lúc ra sao?
- Cảnh báo phát một lần khi điều kiện chuyển trạng thái hay phát lặp?

**Không** mặc định dùng “tất cả timeframe cùng bullish/bearish” làm tín hiệu vào
lệnh.

## 7. Yêu cầu vòng đời và hiệu năng

- Tính lại theo thời điểm nến đóng của từng timeframe; không chạy lại toàn bộ
  phân tích MTF trên mỗi tick nếu dữ liệu đầu vào chưa thay đổi.
- Làm mới đúng khi đổi symbol, timeframe, input, tải lịch sử hoặc khởi tạo lại
  indicator.
- Giới hạn số timeframe, lịch sử và object ở mức người dùng có thể kiểm soát;
  đo hiệu năng trước khi mở rộng giới hạn.
- Không dùng lỗi tải dữ liệu làm kết quả trung tính giả.
- Log lỗi đủ để chẩn đoán nhưng tránh log lặp mỗi tick.
- Dọn object theo đúng prefix/symbol/timeframe, không xóa object do người dùng
  hoặc thành phần khác tạo.

## 8. Kiểm thử và tiêu chí nghiệm thu

### Kiểm tra mã

- Compile `Indicators/SMC/SMC.mq5`: 0 lỗi, 0 cảnh báo.
- Chạy `git diff --check`.
- Xác nhận các timeframe độc lập, không làm thay đổi kết quả phân tích chart
  hiện tại.
- Với mỗi pha, kiểm tra đúng output/sự kiện cụ thể thay vì chỉ xác nhận compile.

### Ma trận chart tối thiểu

| Tình huống | Kết quả mong đợi |
|---|---|
| Chart M30, slot H4/D1/W1 | Bias và cấu trúc riêng cho từng khung; không có hàng trùng |
| Chart H4, bật slot M5 | Cấu trúc M5 và snapshot M5 cập nhật khi nến M5 đóng, không đợi H4 đóng |
| Tắt một slot hoặc chọn trùng slot | Không vẽ/tính lặp; slot khác cùng timeframe vẫn hoạt động |
| Bật overlay OB | Vùng có nhãn Swing/Internal, hướng và timeframe nguồn |
| Bật overlay FVG | Vùng có nhãn timeframe; biên giá đúng và FVG nến đóng mới nhất được nhận |
| OB/FVG chồng lấn | FVG được xử lý theo quy tắc overlap hiện tại của module vẽ |
| Thiếu/đang tải lịch sử | Báo trạng thái rõ; không dùng bias/vùng cũ như dữ liệu mới |
| Nến MTF đang chạy | Kết quả xác nhận không đổi trước khi nến MTF đóng |
| Đổi symbol/chart timeframe | Tính lại đúng, không giữ nhãn hoặc object MTF cũ |
| Tắt overlay/gỡ indicator | Dọn object MTF, không ảnh hưởng object khác |
| Bias trái chiều hoặc trung tính | Hiển thị trung thực; không tự phát tín hiệu mua/bán |

Kiểm thử thủ công trên chart MT5 là bắt buộc cho vị trí panel, vùng overlay,
nhãn timeframe, khả năng đọc khi nhiều vùng chồng lấn và hành vi khi kéo chart
về quá khứ. Các kiểm tra gán vai trò HTF/Mid/LTF chỉ áp dụng sau khi phần cấu
hình vai trò được triển khai; hiện các slot chỉ là timeframe so sánh.

## 9. Phạm vi chưa cam kết

Tài liệu này xác định hướng kiến trúc và lộ trình, không có nghĩa mọi giai đoạn
đều được triển khai cùng lúc. Giai đoạn 1 tạo nền tảng bias MTF; các vùng setup,
liquidity, trigger, confluence và cảnh báo cần được thực hiện/duyệt riêng sau
khi xác nhận kết quả của giai đoạn trước.
