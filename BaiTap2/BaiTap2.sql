
SELECT * FROM Inventory;
DELIMITER //
CREATE PROCEDURE 
		AddInventory (IN p_item_id INT, IN p_quantity INT)
	BEGIN 
		UPDATE Inventory
        SET stock_quantity = stock_quantity + p_quantity
		WHERE item_id = p_item_id;
        
	END //
    DELIMITER ;
    
    CALL AddInventory(10,-400);
    -- lệnh này gây mất hàng trong kho vì không kiểm tra điều kiện 
    -- số lượng nhập kho phải lớn hơn không 
    
    DROP PROCEDURE AddInventory;
    
DELIMITER //

CREATE PROCEDURE AddInventory (IN p_item_id INT, IN p_quantity INT)
BEGIN
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than 0';
    END IF;

    UPDATE Inventory
    SET stock_quantity = stock_quantity + p_quantity
    WHERE item_id = p_item_id;
END //

DELIMITER ;