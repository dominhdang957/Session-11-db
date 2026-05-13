DELIMITER //

CREATE PROCEDURE ProcessPrescription(
    IN  p_patient_id    INT,
    IN  p_medicine_id   INT,
    IN  p_quantity      INT,
    IN  p_discount_code VARCHAR(50),
    OUT p_message       VARCHAR(200)
)
BEGIN
    -- LOCAL VARIABLES lưu dữ liệu tạm thời
    DECLARE v_price        DECIMAL(10,2) DEFAULT 0;
    DECLARE v_stock        INT           DEFAULT 0;
    DECLARE v_final_amount DECIMAL(10,2) DEFAULT 0;

    -- Lấy price và stock từ Medicines → lưu vào biến cục bộ
    SELECT price, stock
    INTO   v_price, v_stock
    FROM   Medicines
    WHERE  medicine_id = p_medicine_id
    LIMIT 1;

    -- CHỐT 1: Bẫy Out of Stock
    IF v_stock < p_quantity THEN
        SET p_message = 'Thất bại: Kho không đủ thuốc';

    ELSE
        -- Tính thành tiền → lưu vào biến cục bộ
        SET v_final_amount = p_quantity * v_price;

        -- Áp mã giảm giá: mã rác hoặc NULL tự động tính giá gốc
        IF p_discount_code = 'NV-RIKKEI' THEN
            SET v_final_amount = v_final_amount * 0.5;
        END IF;

        -- Bước 1: Trừ tồn kho
        UPDATE Medicines
        SET    stock = stock - p_quantity
        WHERE  medicine_id = p_medicine_id;

        -- Bước 2: Cộng dồn vào tổng nợ bệnh nhân
        UPDATE Patient_Invoices
        SET    total_due = total_due + v_final_amount
        WHERE  patient_id = p_patient_id;

        SET p_message = 'Thành công: Đã xử lý đơn thuốc';

    END IF;

END //

DELIMITER ;

CALL ProcessPrescription(3, 1, 2, NULL, @msg);
SELECT @msg AS Thong_Bao;
SELECT patient_id, total_due FROM Patient_Invoices WHERE patient_id = 3;
SELECT medicine_id, stock    FROM Medicines         WHERE medicine_id = 1;

CALL ProcessPrescription(1, 2, 2, 'NV-RIKKEI', @msg);
SELECT @msg AS Thong_Bao;
SELECT patient_id, total_due FROM Patient_Invoices WHERE patient_id = 1;
SELECT medicine_id, stock    FROM Medicines         WHERE medicine_id = 2;

CALL ProcessPrescription(2, 2, 10, NULL, @msg);
SELECT @msg AS Thong_Bao;
SELECT patient_id, total_due FROM Patient_Invoices WHERE patient_id = 2;
SELECT medicine_id, stock    FROM Medicines         WHERE medicine_id = 2;