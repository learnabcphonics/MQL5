# Tóm tắt phát triển SMC cho team dev

## Mục tiêu
Giữ nguyên logic phân tích SMC, nhưng sửa các vấn đề hiển thị trên chart: chồng vùng, label va chạm, object stale, và layer render không rõ ràng.

## Nguyên tắc chính
- Không thay đổi logic engine SMC.
- Tên object phải theo nhóm rõ ràng: `STR_`, `SW_`, `PD_`, `PL_`, `FVG_`, `OB_`, `BIAS`.
- Không dùng cleanup theo prefix rộng nếu không cần thiết.
- Fill vùng phải nằm sau nến; label phải nằm trên cùng.
- Xoá object stale trước khi redraw.

## Vấn đề đã gặp và xử lý
- Black fill trong OB: do rectangle cũ/chồng redraw.
- Vùng FVG/OB chồng nhau: cần ưu tiên OB / suppress FVG khi overlap.
- Prefix cleanup gây xoá nhầm object: ví dụ `MarketBias`, swing labels, previous levels.
- Label bị trượt hoặc chồng do offset không đủ.
- Layer z-order không rõ ràng giữa fill, line, label.

## Quy tắc render hiện tại
- `PL_` thấp nhất
- `PD_` tiếp theo
- `FVG_` tiếp theo
- `OB_` tiếp theo
- `STR_` / `SW_` ở giữa
- Label ở mức trên cùng

## Quy tắc overlap hiện tại
- Nếu OB và FVG chồng nhau thì OB giữ ưu tiên.
- FVG sẽ bị bỏ khi đang nằm trong vùng OB active.
- Label bị bỏ nếu trùng vùng ưu tiên cao hơn.

## Lưu ý kỹ thuật
- `SMC_LabelOffsetPrice(...)` dùng để dịch label ra khỏi tâm vùng.
- `SMC_ZoneZOrder(...)` dùng để phân tầng rõ ràng.
- `DrawZoneBox(...)` phải xoá stale rectangle nếu màu hoặc fill/back không đúng.
- Mọi thay đổi render phải không tương tác với logic phát hiện SMC.

## Kiểm tra khi phát triển tiếp
- Tên object không trùng.
- Không xoá nhầm label hay bias.
- Không để object cũ tồn tại qua redraw.
- Không chồng vùng không có rule ưu tiên.
- Labels không che nến và không chồng lên nhau quá mức.
