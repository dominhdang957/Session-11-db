DELIMITER //
CREATE PROCEDURE 
		 sp_count_customers_by_city(IN city_in VARCHAR(100),OUT total_out INT)
         
         BEGIN
         DECLARE total INT;
         SELECT COUNT(customer) INTO total_out FROM Customers WHERE city = city_in;
         
         END //
DELIMITER ;

CALL sp_count_customers_by_city('NYC',@total);
SELECT @total;
DELIMITER //
CREATE PROCEDURE
		sp_logic_test()
	BEGIN
		DECLARE v_score DOUBLE;
        SET v_score = 8.5;
        IF v_score < 5 THEN SET ranked = 'Yếu';
        ELSEIF v_score < 8 THEN SET ranked = 'Khá';
        ELSE SET ranked = 'Giỏi';
        END IF;
        SELECT ranked AS XepHang;
	END //
DELIMITER ;