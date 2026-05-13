DELIMITER //
CREATE PROCEDURE calculate_patient(
    IN  total_price    DECIMAL(10,2),
    IN  patient_object VARCHAR(50),
    OUT total_amount   DECIMAL(10,2),
    OUT message        VARCHAR(100)
)
BEGIN
    -- Kiểm tra NULL hoặc số âm
    IF total_price IS NULL OR total_price < 0 THEN
        SET total_amount = 0;
        SET message = 'Lỗi: Chi phí không hợp lệ';

    ELSEIF patient_object = 'BHYT' THEN
        SET total_amount = total_price * 0.2;
        SET message = 'Đã tính toán xong';

    ELSEIF patient_object = 'VIP' THEN
        SET total_amount = total_price * 0.9;
        SET message = 'Đã tính toán xong';

    ELSE
        SET total_amount = total_price;
        SET message = 'Đã tính toán xong';

    END IF;
END //
DELIMITER ;
CALL calculate_patient(-400000,'BHYT',@sotien,@thongbao);
SELECT @sotien AS total_amount ,@thongbao AS status;