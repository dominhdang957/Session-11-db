
DELIMITER //

-- ============================================
-- 1. PROCEDURE: Tính tiền theo diện bệnh nhân
-- ============================================
CREATE PROCEDURE calculate_patient(
    IN  p_total_price    DECIMAL(10,2),
    IN  p_patient_object VARCHAR(50),
    OUT p_total_amount   DECIMAL(10,2),
    OUT p_message        VARCHAR(100)
)
BEGIN
    -- Kiểm tra NULL hoặc số âm
    IF p_total_price IS NULL OR p_total_price < 0 THEN
        SET p_total_amount = 0;
        SET p_message      = 'Lỗi: Chi phí không hợp lệ';

    ELSEIF p_patient_object = 'BHYT' THEN
        SET p_total_amount = p_total_price * 0.2;
        SET p_message      = 'Đã tính toán xong';

    ELSEIF p_patient_object = 'VIP' THEN
        SET p_total_amount = p_total_price * 0.9;
        SET p_message      = 'Đã tính toán xong';

    ELSE
        SET p_total_amount = p_total_price;
        SET p_message      = 'Đã tính toán xong';

    END IF;
END //


-- ============================================
-- 2. PROCEDURE: Tra cứu công nợ bệnh nhân
-- Bảng: Patient_Invoices (patient_id, total_due)
-- Bảng: Patients (patient_id, full_name, phone)
-- ============================================
CREATE PROCEDURE get_patient_debt(
    IN  p_patient_id  INT,
    IN  p_phone       VARCHAR(11),
    OUT p_total_due   DECIMAL(10,2),
    OUT p_message     VARCHAR(100)
)
BEGIN
    DECLARE v_patient_id INT           DEFAULT NULL;
    DECLARE v_total_due  DECIMAL(10,2) DEFAULT 0;

    -- Chốt kiểm tra 1: Cả hai đều NULL
    IF p_patient_id IS NULL AND p_phone IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Vui lòng nhập ID hoặc số điện thoại';

    ELSE
        -- Tìm patient_id qua ID hoặc phone
        SELECT pt.patient_id, pi.total_due
        INTO   v_patient_id, v_total_due
        FROM   Patients        pt
        JOIN   Patient_Invoices pi ON pt.patient_id = pi.patient_id
        WHERE  pt.patient_id = p_patient_id
           OR  pt.phone      = p_phone
        LIMIT 1;

        -- Chốt kiểm tra 2: Không tìm thấy
        IF v_patient_id IS NULL THEN
            SET p_total_due = 0;
            SET p_message   = 'Không tìm thấy ID hoặc số điện thoại';

        ELSE
            SET p_total_due = v_total_due;
            SET p_message   = 'Truy xuất thành công - Tổng nợ của bệnh nhân';
        END IF;

    END IF;
END //


-- ============================================
-- 3. PROCEDURE PHỤ: Dò tìm giường trống
-- Bảng: Beds (bed_id, dept_id, patient_id)
-- Giường trống = patient_id IS NULL
-- ============================================
CREATE PROCEDURE find_available_bed(
    IN  p_dept_id    INT,
    OUT p_bed_id     INT,
    OUT p_dept_name  VARCHAR(100)
)
BEGIN
    -- Lấy tên khoa
    SELECT dept_name
    INTO   p_dept_name
    FROM   Departments
    WHERE  dept_id = p_dept_id
    LIMIT 1;

    -- Tìm giường trống: patient_id IS NULL
    SELECT bed_id
    INTO   p_bed_id
    FROM   Beds
    WHERE  dept_id    = p_dept_id
      AND  patient_id IS NULL
    ORDER BY bed_id
    LIMIT 1;

END //


-- ============================================
-- 4. PROCEDURE MASTER: Chuyển giường 1 chạm
-- Bảng: Beds        (bed_id, dept_id, patient_id)
-- Bảng: Patients    (patient_id, full_name, phone)
-- Bảng: Appointments(appointment_id, patient_id, status)
-- ============================================
CREATE PROCEDURE move_bed_patient(
    IN  p_patient_id  INT,
    IN  p_dept_id     INT,
    OUT p_new_bed_id  INT,
    OUT p_message     VARCHAR(200)
)
proc_label: BEGIN
    DECLARE v_current_bed_id  INT          DEFAULT NULL;
    DECLARE v_appt_status     VARCHAR(50)  DEFAULT NULL;
    DECLARE v_new_bed_id      INT          DEFAULT NULL;
    DECLARE v_dept_name       VARCHAR(100) DEFAULT NULL;
    DECLARE v_patient_exists  INT          DEFAULT 0;

    -- Bắt lỗi rollback toàn bộ
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_new_bed_id = NULL;
        SET p_message    = 'Lỗi hệ thống: Giao dịch đã bị huỷ';
    END;

    -- Chốt kiểm tra 1: Validate đầu vào
    IF p_patient_id IS NULL OR p_dept_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Mã bệnh nhân và mã khoa không được để trống';
    END IF;

    START TRANSACTION;

        -- Kiểm tra bệnh nhân tồn tại không
        SELECT COUNT(*)
        INTO   v_patient_exists
        FROM   Patients
        WHERE  patient_id = p_patient_id;

        -- Chốt kiểm tra 2: Bệnh nhân không tồn tại
        IF v_patient_exists = 0 THEN
            ROLLBACK;
            SET p_new_bed_id = NULL;
            SET p_message    = 'Từ chối: Không tìm thấy bệnh nhân';
            LEAVE proc_label;
        END IF;

        -- Lấy giường hiện tại của bệnh nhân (LOCK tránh race condition)
        SELECT bed_id
        INTO   v_current_bed_id
        FROM   Beds
        WHERE  patient_id = p_patient_id
        LIMIT 1
        FOR UPDATE;

        -- Lấy trạng thái lịch khám gần nhất
        SELECT status
        INTO   v_appt_status
        FROM   Appointments
        WHERE  patient_id = p_patient_id
        ORDER BY appointment_date DESC
        LIMIT 1;

        -- Chốt kiểm tra 3: Bẫy bệnh nhân đã xuất viện (Completed)
        IF v_appt_status = 'Completed' THEN
            ROLLBACK;
            SET p_new_bed_id = NULL;
            SET p_message    = 'Từ chối: Bệnh nhân đã xuất viện, không thể chuyển giường';
            LEAVE proc_label;
        END IF;

        -- Gọi Procedure phụ dò tìm giường trống
        CALL find_available_bed(p_dept_id, v_new_bed_id, v_dept_name);

        -- Chốt kiểm tra 4: Bẫy Overbooking — KHÔNG giải phóng giường cũ
        IF v_new_bed_id IS NULL THEN
            ROLLBACK;
            SET p_new_bed_id = NULL;
            SET p_message    = CONCAT('Từ chối: Khoa ', IFNULL(v_dept_name,'không tồn tại'), ' đã hết giường');
            LEAVE proc_label;
        END IF;

        -- Bước 1: Giải phóng giường cũ
        UPDATE Beds
        SET    patient_id = NULL
        WHERE  bed_id     = v_current_bed_id;

        -- Bước 2: Gán bệnh nhân vào giường mới
        UPDATE Beds
        SET    patient_id = p_patient_id
        WHERE  bed_id     = v_new_bed_id
          AND  patient_id IS NULL;  -- Double-check tránh race condition

    COMMIT;

    SET p_new_bed_id = v_new_bed_id;
    SET p_message    = CONCAT('Thành công: Đã chuyển sang giường ', v_new_bed_id, ' - Khoa ', v_dept_name);

END proc_label //

DELIMITER ;
-- Test 1: Tính tiền BHYT
CALL calculate_patient(500000, 'BHYT', @amount, @msg);
SELECT @amount AS So_Tien, @msg AS Thong_Bao;
-- Kết quả: 100000 | Đã tính toán xong

-- Test 2: Chi phí âm
CALL calculate_patient(-100000, 'THUONG', @amount, @msg);
SELECT @amount, @msg;
-- Kết quả: 0 | Lỗi: Chi phí không hợp lệ

-- Test 3: Tra nợ bằng ID (bệnh nhân 1 nợ 1.5tr)
CALL get_patient_debt(1, NULL, @due, @msg);
SELECT @due AS Tong_No, @msg AS Thong_Bao;
-- Kết quả: 1500000 | Truy xuất thành công

-- Test 4: Tra nợ bằng phone
CALL get_patient_debt(NULL, '0912222333', @due, @msg);
SELECT @due, @msg;
-- Kết quả: 0 | Truy xuất thành công (bệnh nhân 2 không nợ)

-- Test 5: Chuyển bệnh nhân 1 (Khoa Ngoại) sang Khoa Nội (có giường 201 trống)
CALL move_bed_patient(1, 2, @new_bed, @msg);
SELECT @new_bed AS Giuong_Moi, @msg AS Thong_Bao;
-- Kết quả: 201 | Thành công: Đã chuyển sang giường 201 - Khoa Nội

-- Test 6: Bẫy hết giường (Khoa ICU chỉ có giường 301 đang bị chiếm)
CALL move_bed_patient(1, 3, @new_bed, @msg);
SELECT @new_bed, @msg;
-- Kết quả: NULL | Từ chối: Khoa ICU đã hết giường

-- Test 7: Bẫy bệnh nhân 2 đã Completed (lịch khám 105)
CALL move_bed_patient(2, 1, @new_bed, @msg);
SELECT @new_bed, @msg;
-- Kết quả: NULL | Từ chối: Bệnh nhân đã xuất viện