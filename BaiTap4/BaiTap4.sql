DELIMITER //
CREATE PROCEDURE get_patient_debt (
    IN  id_patient   INT,
    IN  phone_in     VARCHAR(11),
    OUT total_due_in DECIMAL(10,0),
    OUT message      VARCHAR(100)
)
BEGIN

    DECLARE v_patient_id  INT          DEFAULT NULL;
    DECLARE v_total_due   DECIMAL(10,0) DEFAULT 0;

    IF id_patient IS NULL AND phone_in IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Vui lòng nhập ID hoặc Số điện thoại';

    ELSE
        SELECT PI.patient_id, Pi.total_due
        INTO   v_patient_id, v_total_due
        FROM   Patient_Invoices PI
        JOIN  Patients P ON P.patient_id = PI.patient_id 
        WHERE  Pi.patient_id = id_patient
           OR  P.phone      = phone_in
        LIMIT 1;

        IF v_patient_id IS NULL THEN
            SET total_due_in = 0;
            SET message      = 'Không tìm thấy ID hoặc số điện thoại';

	
        ELSE
            SET total_due_in = v_total_due;
            SET message      = 'Truy xuất thành công - Tổng nợ của bệnh nhân';
        END IF;

    END IF;

END //
DELIMITER ;

DROP PROCEDURE get_patient_debt;

CALL get_patient_debt(1,'0000000000',@total_due, @message);
SELECT @total_due Tong_no ,@message Thong_Bao;

