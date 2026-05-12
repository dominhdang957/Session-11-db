
CREATE TABLE Persons (
    id INT PRIMARY KEY,
    last_name VARCHAR(20),
    first_name VARCHAR(20),
    email VARCHAR(100)
);
INSERT INTO Persons (id, last_name, first_name, email) VALUES
(1,  'Nguyen',  'An',      'an.nguyen@gmail.com'),
(2,  'Tran',    'Binh',    'binh.tran@yahoo.com'),
(3,  'Le',      'Chi',     'chi.le@outlook.com'),
(4,  'Pham',    'Dung',    'dung.pham@gmail.com'),
(5,  'Hoang',   'Em',      'em.hoang@hotmail.com'),
(6,  'Vo',      'Phuong',  'phuong.vo@gmail.com'),
(7,  'Dang',    'Giang',   'giang.dang@yahoo.com'),
(8,  'Bui',     'Hoa',     'hoa.bui@outlook.com'),
(9,  'Do',      'Khanh',   'khanh.do@gmail.com');


DELIMITER //
CREATE PROCEDURE 
get_all_persons()
BEGIN 
SELECT * FROM Persons;
END// 
 DELIMITER ;

CALL get_all_persons();

DELIMITER //
CREATE PROCEDURE 
     insert_person(id_in INT,last_name_in VARCHAR(20),first_name_in VARCHAR(20),email_in VARCHAR(100) )
BEGIN
	INSERT INTO Persons (id,last_name,first_name,email)
    VALUES
    (id_in,last_name_in,first_name_in,email_in);
END //
DELIMITER ;

DROP PROCEDURE insert_person;

CALL insert_person(10, 'Le', 'Hoang', 'hoangle@gmail.com');
