CREATE DATABASE Employee; -- MYSQL

USE Employee;

CREATE TABLE EmployeePosition(
	Id INT PRIMARY KEY NOT NULL auto_increment,
	Name VARCHAR(50) NOT NULL
);

CREATE TABLE EmployeesData(
	Id INT PRIMARY KEY NOT NULL auto_increment,	-- VERTICAL FRAGMENTATION 1
	Name VARCHAR(50) NOT NULL,
	Adress VARCHAR(50) NOT NULL,
	Identification VARCHAR(50) NOT NULL,
	Phone VARCHAR(50) NOT NULL,
	Email VARCHAR(50) NOT NULL
); 

CREATE TABLE ShopCountry(
	Id INT PRIMARY KEY NOT NULL auto_increment,
	Country VARCHAR(50) NOT NULL
);

CREATE TABLE EmployeesInfo(
	Id INT PRIMARY KEY NOT NULL auto_increment, -- VERTICAL FRAGMENTATION 2
	Identification VARCHAR(50) NOT NULL,
	Shop_id INT NOT NULL,
	Country_id INT NOT NULL,
	Salary DECIMAL NOT NULL,
	Position_id INT NOT NULL,
	Calification_average FLOAT,
	FOREIGN KEY (Country_id) REFERENCES ShopCountry(Id),
	FOREIGN KEY (Position_id) REFERENCES EmployeePosition(Id)
);

CREATE TABLE EmployeesReviews(
	Id INT PRIMARY KEY NOT NULL auto_increment,
	User_id INT NOT NULL,
	Review VARCHAR(100) NOT NULL,
	Employee_id INT NOT NULL,
	Calification INT NOT NULL,
	FOREIGN KEY (Employee_id) REFERENCES EmployeesData(Id)
);

-- ------------------------------------------CRUD EMPLOYEE-----------------------------------------------

USE Employee;

DELIMITER //
CREATE PROCEDURE InsertEmployee(
	IN in_name VARCHAR(50),
	IN in_adress VARCHAR(50),
	IN in_identification VARCHAR(50),
	IN in_phone VARCHAR(50),
	IN in_email VARCHAR(50),
	IN in_shop INT,
	IN in_country INT,
	IN in_salary DECIMAL, 
	IN position_id INT)
BEGIN

    Start Transaction;
    SET @tmp_id = 'NULL';
    SET @exist = 0;
    SET @tmp_id2 = 'NULL';
    SET @exist2 = 'NULL';

	SET @tmp_id = (select Id FROM employeeposition WHERE Id = position_id);
    SET @exist = (SELECT ISNULL(@tmp_id));
    -- SELECT @tmp_id;
    SET @tmp_id2 = (select Id FROM ShopCountry WHERE Id = in_country);
    SET @exist2 = (SELECT ISNULL(@tmp_id2));

	IF @exist = 0 AND @exist2 = 0 THEN
		INSERT INTO EmployeesData(Name, Adress, Identification, Phone, Email)
		VALUES(in_name, in_adress, in_identification, in_phone, in_email);
		INSERT INTO EmployeesInfo(Shop_id, Country_id, Salary, Position_id, Identification)
		VALUES(in_shop, in_country, in_salary, position_id, in_identification);
        SELECT 0;

   ELSE
      SELECT 1;
	END IF;
	Commit;

END//

	
DELIMITER ;

USE Employee;

DELIMITER //
CREATE PROCEDURE ModifyEmployee( -- Change configuration in the preferences of mysql in the safe mode of updates
	IN in_name VARCHAR(50),
	IN in_adress VARCHAR(50),
	IN in_identification VARCHAR(50),
	IN in_phone VARCHAR(50),
	IN in_email VARCHAR(50),
	IN in_salary DECIMAL, 
	IN in_position_id INT)
BEGIN

    Start Transaction;
    SET @tmp_id = 'NULL';
    SET @exist = 0;

	SET @tmp_id = (select Id FROM employeeposition WHERE Id = in_position_id);
    SET @exist = (SELECT ISNULL(@tmp_id));
    -- SELECT @tmp_id;

	IF @exist = 0 THEN
		UPDATE EmployeesData
		SET Name = in_name, Adress = in_adress, Phone = in_phone, Email = in_email
		WHERE Identification = in_identification;

		UPDATE EmployeesInfo
		SET Salary = in_salary, Position_id = in_position_id
		WHERE Identification = in_identification;
        SELECT 0;

   ELSE
      SELECT 1;
	END IF;
	Commit;

END//

	
DELIMITER ;

USE Employee;

DELIMITER //
CREATE PROCEDURE DeleteEmployee(
	IN in_identification VARCHAR(50))
BEGIN
	Start Transaction;
	SET @tmp_id = 'NULL';
    SET @exist = 0;
    
    SET @tmp_id = (select Identification FROM employeesdata WHERE Identification = in_identification);
    SET @exist = (SELECT ISNULL(@tmp_id));
    
    DELETE FROM employeesinfo WHERE Identification = in_identification AND @exist = 0;
    DELETE FROM employeesdata WHERE Identification = in_identification AND @exist = 0;
    
    SELECT @exist;
	Commit;

END//

	
DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE InsertEmployeeReview( 
	IN in_user VARCHAR(50),
    IN in_employee VARCHAR(50), 
    IN in_review VARCHAR(100),
    IN in_calification INT)
BEGIN
	DROP TABLE IF EXISTS temporal;
	CREATE TEMPORARY TABLE temporal(
		in_user2 VARCHAR(50),
		in_employee2 VARCHAR(50),
		in_review2 VARCHAR(100),
		in_exist1 INT,
        in_exist2 INT
    );
    Start Transaction;
    SET @tmp_id = 'NULL';
    SET @exist = 0;
    SET @tmp_id2 = 0;
    SET @exist2 = 0;

	SET @tmp_id = (select Identification FROM user.userdata WHERE Identification = in_user);
    SET @exist = (SELECT ISNULL(@tmp_id));
    
    
    SET @tmp_id2 = (select Id FROM employeesdata WHERE Identification = in_employee);
    SET @exist2 = (SELECT ISNULL(@tmp_id2));
    
    IF @exist = 0 AND @exist2 = 0 AND in_calification < 6 THEN
		INSERT INTO employeesreviews(User_id, Review, Employee_id, Calification)
		VALUES(in_user, in_review, @tmp_id2, in_calification);
        SELECT 0;

   ELSE
      SELECT 1;
	END IF;
	Commit;

END//
	
DELIMITER ;

-- CALL InsertEmployee('Horacio', 1, 'Washington', '2030', '12344321', 'horacio@gmail.com', 50, 1);
-- CALL ModifyEmployee('Horacio', 1, 'Washington', '2030', '12344321', 'horacio@gmail.com', 50, 2);
-- CALL DeleteEmployee('2030')