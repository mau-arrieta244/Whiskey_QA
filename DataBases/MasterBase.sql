USE MASTER
GO

CREATE DATABASE MasterBase
GO

USE MasterBase
GO

CREATE TABLE dbo.WhiskeyType(
	ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	TypeName VARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.WhiskeyPresentation(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Presentation VARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.WhiskeyAge(
	ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Age INT NOT NULL
);
GO

CREATE TABLE dbo.Supplier(
	ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Supplier_name VARCHAR(50) NOT NULL,
	Features NVARCHAR(MAX)
);
GO

CREATE TABLE dbo.Club(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Club_name VARCHAR(50) NOT NULL,
	Price MONEY NOT NULL,
	Discount FLOAT NOT NULL,
	HaveExpress BIT NOT NULL,
	Express_discount FLOAT NOT NULL
);
GO

CREATE TABLE dbo.UsersXClub(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	User_identification VARCHAR(50) NOT NULL,
	Active BIT NOT NULL,
	Id_club INT NOT NULL,
	Card VARCHAR(50) NOT NULL,
	Amount INT NOT NULL,
	FOREIGN KEY (Id_club) REFERENCES dbo.Club(Id)
);
GO

CREATE TABLE dbo.Whiskey(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	--Code uniqueidentifier,
	Whiskey_name VARCHAR(50) NOT NULL,
	WhiskeyType_id INT NOT NULL,
	Age_id INT NOT NULL,
	Photo VARBINARY(MAX),
	Price MONEY NOT NULL,
	Supplier_id INT NOT NULL,
	IsSpecial BIT NOT NULL,
	Presentation_id INT ,
	FOREIGN KEY (WhiskeyType_id) REFERENCES dbo.WhiskeyType(Id),
	FOREIGN KEY (Age_id) REFERENCES dbo.WhiskeyAge(Id),
	FOREIGN KEY (Supplier_id) REFERENCES dbo.Supplier(Id)
);
GO

CREATE TABLE dbo.WhiskeyReviews(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	User_id INT NOT NULL,
	Review VARCHAR(50) NOT NULL,
	Whiskey_id INT NOT NULL,
	FOREIGN KEY (Whiskey_id) REFERENCES dbo.Whiskey(Id)
);
GO

CREATE TABLE dbo.Credentials(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Username VARCHAR(50) NOT NULL,
	Pass_word VARBINARY(8000) NOT NULL, --insert into login(IdUsuario, contrasenia) values(‘buhoos’,PWDENCRYPT(‘12345678’))
	User_identification VARCHAR(50)
);
GO

CREATE PROCEDURE InsertCredentials
	@in_identification VARCHAR(50), @in_username VARCHAR(50), @in_password VARCHAR(50)
AS
	BEGIN TRY
		DECLARE @temporal AS TABLE 
		(id_tmp VARCHAR(50))
		DECLARE @tmp_id VARCHAR(50) = 'EMPTY', @tmp_username VARCHAR(50) = 'EMPTY'

		BEGIN TRANSACTION TS;
			INSERT INTO @temporal(id_tmp) SELECT * FROM openquery(SQLSERVER,' SELECT Identification FROM user.UserData;')
			SELECT @tmp_id = id_tmp FROM @temporal WHERE id_tmp = @in_identification
			SELECT @tmp_username = Username FROM dbo.Credentials WHERE User_identification=@tmp_id
			SELECT @tmp_id
			SELECT @tmp_username
			IF @tmp_id != 'EMPTY' AND @tmp_username = 'EMPTY'
			BEGIN
				 INSERT INTO dbo.Credentials(Username, Pass_word, User_identification) VALUES(@in_username, ENCRYPTBYPASSPHRASE('password', @in_password), @in_identification)
			END
			
		COMMIT TRANSACTION TS;
		RETURN 200;
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE SignIn 
	@in_user VARCHAR(64), @in_password VARCHAR(64)
AS
	DECLARE @tmp_username VARCHAR(50) = 'EMPTY',
			@tmp_password VARCHAR(50) = 'EMPTY'
	DECLARE @temporal AS TABLE 
		(pass_temporal VARCHAR(50))

	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_username = Username FROM dbo.Credentials WHERE Username=@in_user
		INSERT INTO @temporal SELECT DECRYPTBYPASSPHRASE('password', pass_word) FROM dbo.Credentials
		--SELECT @password =  ENCRYPTBYPASSPHRASE('password', @in_password)
		SELECT @tmp_password = pass_temporal FROM @temporal WHERE pass_temporal = @in_password
		IF @tmp_username != 'EMPTY' AND @tmp_password != 'EMPTY'
		BEGIN
			SELECT User_identification FROM dbo.Credentials WHERE Username=@in_user
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE IsAdmin
	@in_user VARCHAR(64)
AS
	DECLARE @tmp_username VARCHAR(50) = 'EMPTY', @tmp_identification VARCHAR(50) = 'EMPTY', @tmp_isAdmin BIT
	DECLARE @temporal AS TABLE 
		(identification VARCHAR(50),
		isadmin BIT)

	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_username = Username FROM dbo.Credentials WHERE Username=@in_user
		SELECT @tmp_identification = User_identification FROM dbo.Credentials WHERE Username=@in_user
		INSERT INTO @temporal(identification, isadmin) SELECT * FROM openquery(SQLSERVER,' SELECT Identification, IsAdmin FROM user.UserData;')
		SET @tmp_isAdmin = (SELECT isadmin FROM @temporal WHERE identification = @tmp_identification)
		IF @tmp_username != 'EMPTY' AND @tmp_isAdmin = 1
		BEGIN
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

------------------------------------------------------------------CRUD WHISKEYS------------------------------------------------------------------
CREATE PROCEDURE CreateWhiskey
	@in_name VARCHAR(50), @in_WhiskeyType VARCHAR(50), @in_Age INT, @in_price MONEY, @in_supplier VARCHAR(50), @in_IsSpecial VARCHAR(50), @in_presentation VARCHAR(50) --modificar en el sitio web
AS
	DECLARE @tmp_name VARCHAR(50) = 'EMPTY' 
	DECLARE @tmp_type INT = 0, @tmp_age INT = 0, @tmp_supplier INT = 0, @tmp_club INT = 0, @tmp_IsSpecial INT = 0, @tmp_presentation INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_name = Whiskey_name FROM dbo.Whiskey WHERE Whiskey_name = @in_name
		SELECT @tmp_type = Id FROM dbo.WhiskeyType WHERE TypeName = @in_WhiskeyType
		SELECT @tmp_age = Id FROM dbo.WhiskeyAge WHERE Age = @in_Age
		SELECT @tmp_supplier = Id FROM dbo.Supplier WHERE Supplier_name = @in_supplier
		SELECT @tmp_presentation = Id FROM dbo.WhiskeyPresentation WHERE Presentation = @in_presentation
		SET @tmp_IsSpecial = (SELECT CAST(@in_IsSpecial AS INT))
		IF @tmp_name = 'EMPTY' AND @tmp_type != 0 AND @tmp_age != 0 AND @tmp_supplier != 0 AND @tmp_IsSpecial != 0 AND @tmp_presentation != 0
		BEGIN
			INSERT INTO dbo.Whiskey(Whiskey_name, WhiskeyType_id, Age_id, Price, Supplier_id, IsSpecial, Presentation_id)
			VALUES(@in_name, @tmp_type, @tmp_age, @in_price, @tmp_supplier, 1, @tmp_presentation)
			SELECT 1
		END
		ELSE IF @tmp_name = 'EMPTY' AND @tmp_type != 0 AND @tmp_age != 0 AND @tmp_supplier != 0 AND @tmp_IsSpecial = 0 AND @tmp_presentation != 0
		BEGIN
			INSERT INTO dbo.Whiskey(Whiskey_name, WhiskeyType_id, Age_id, Price, Supplier_id, IsSpecial, Presentation_id)
			VALUES(@in_name, @tmp_type, @tmp_age, @in_price, @tmp_supplier, 0, @tmp_presentation)
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE DeleteWhiskey
	@in_name VARCHAR(50)
AS
	DECLARE @tmp_id INT = 0
	BEGIN TRY
	SET NOCOUNT ON
	SELECT @tmp_id = Id FROM dbo.Whiskey WHERE Whiskey_name = @in_name
	IF @tmp_id != 0
	BEGIN
		DELETE FROM dbo.Whiskey WHERE Whiskey_name = @in_name
		SELECT 1
	END
	ELSE
	BEGIN
		SELECT 0
	END
	RETURN 200;
	SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE ModifyWhiskey
	@in_name VARCHAR(50), @in_WhiskeyType VARCHAR(50), @in_Age INT, @in_price MONEY, @in_supplier VARCHAR(50), @in_IsSpecial VARCHAR(50), @in_presentation VARCHAR(50)
AS
	DECLARE @tmp_name VARCHAR(50) = 'EMPTY' 
	DECLARE @tmp_type INT = 0, @tmp_age INT = 0, @tmp_supplier INT = 0, @tmp_club INT = 0, @tmp_IsSpecial INT = 0, @tmp_presentation INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_name = Whiskey_name FROM dbo.Whiskey WHERE Whiskey_name = @in_name
		SELECT @tmp_type = Id FROM dbo.WhiskeyType WHERE TypeName = @in_WhiskeyType
		SELECT @tmp_age = Id FROM dbo.WhiskeyAge WHERE Age = @in_Age
		SELECT @tmp_supplier = Id FROM dbo.Supplier WHERE Supplier_name = @in_supplier
		SELECT @tmp_presentation = Id FROM dbo.WhiskeyPresentation WHERE Presentation = @in_presentation
		SET @tmp_IsSpecial = (SELECT CAST(@in_IsSpecial AS INT))
		IF @tmp_name != 'EMPTY' AND @tmp_type != 0 AND @tmp_age != 0 AND @tmp_supplier != 0 AND @tmp_presentation != 0
		BEGIN
			UPDATE dbo.Whiskey
			SET WhiskeyType_id = @tmp_type, Age_id = @tmp_age, Price = @in_price, Supplier_id = @tmp_supplier, IsSpecial = @tmp_IsSpecial, Presentation_id = @tmp_presentation
			WHERE Whiskey_name = @in_name --Modify all the registers where the whiskey name is the same of the in whiskey name.
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO
-----------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------CRUD Whiskey Type-----------------------------------------------------------------
CREATE PROCEDURE CreateWhiskeyType
	@in_name VARCHAR(50)
AS
	DECLARE @tmp_type INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_type = Id FROM dbo.WhiskeyType WHERE TypeName = @in_name
		IF @tmp_type = 0
		BEGIN
			INSERT INTO dbo.WhiskeyType(TypeName)
			VALUES(@in_name)
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE DeleteWhiskeyType
	@in_name VARCHAR(50)
AS
	DECLARE @tmp_id INT = 0
	BEGIN TRY
	SET NOCOUNT ON
	SELECT @tmp_id = Id FROM dbo.WhiskeyType WHERE TypeName = @in_name
	IF @tmp_id != 0
	BEGIN
		DELETE FROM dbo.Whiskey WHERE Whiskey_name = @in_name
		SELECT 1
	END
	ELSE
	BEGIN
		SELECT 0
	END
	RETURN 200;
	SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO


-----------------------------------------------------------------------------------------------------------------------------------------


CREATE PROCEDURE CreateSupplier
	@in_name VARCHAR(50)
AS
	DECLARE @tmp_supplier INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_supplier = Id FROM dbo.Supplier WHERE Supplier_name = @in_name
		IF @tmp_supplier = 0
		BEGIN
			INSERT INTO dbo.Supplier(Supplier_name)
			VALUES(@in_name)
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE ModifyWhiskeyAge
	@in_name VARCHAR(50), @in_age INT
AS
	DECLARE @tmp_age INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_age = Id FROM dbo.WhiskeyAge WHERE Age = @in_age
		IF @tmp_age != 0
		BEGIN
			UPDATE dbo.Whiskey
			SET Age_id = @tmp_age
			WHERE Whiskey_name = @in_name
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE ModifyWhiskeySupplier
	@in_name VARCHAR(50), @in_supplier VARCHAR(50)
AS
	DECLARE @tmp_supplier INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_supplier = Id FROM dbo.Supplier WHERE Supplier_name = @in_supplier
		IF @tmp_supplier != 0
		BEGIN
			UPDATE dbo.Whiskey
			SET Supplier_id = @tmp_supplier
			WHERE Whiskey_name = @in_name
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE ModifyWhiskeyType
	@in_name VARCHAR(50), @in_type VARCHAR(50)
AS
	DECLARE @tmp_type INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_type = Id FROM dbo.WhiskeyType WHERE TypeName = @in_type
		IF @tmp_type != 0
		BEGIN
			UPDATE dbo.Whiskey
			SET WhiskeyType_id = @tmp_type 
			WHERE Whiskey_name = @in_name
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE InsertWhiskeyReview
	@in_name VARCHAR(50), @in_review VARCHAR(MAX), @in_clientID VARCHAR(50)
AS
	DECLARE @tmp_whiskeyID INT = 0, @tmp_userID INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_whiskeyID = Id FROM dbo.Whiskey WHERE Whiskey_name = @in_name
		SELECT @tmp_userID = Id FROM dbo.Credentials WHERE User_identification = @in_clientID
		IF @tmp_whiskeyID != 0 AND @tmp_userID != 0
		BEGIN
			INSERT INTO dbo.WhiskeyReviews(Whiskey_id, User_id, Review)
			VALUES(@tmp_whiskeyID, @tmp_userID, @in_review)
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE SendEmail 
	@in_recipient Varchar(64), @in_body Varchar(63)
AS
    BEGIN 
        EXEC msdb.dbo.sp_send_dbmail
        @profile_name='Whiskey Club',
        @recipients=@in_recipient,
        @subject='Whiskey Club Receipt',
        @body =@in_body

	END
GO

CREATE PROCEDURE ObtainClientEmail
	@in_clientID VARCHAR(50)
AS
	DECLARE @temporal AS TABLE 
	(email_tmp VARCHAR(50),
	id_tmp VARCHAR(50))
	DECLARE @tmp_email VARCHAR(50) = 'EMPTY'
	BEGIN TRY
	SET NOCOUNT ON
		INSERT INTO @temporal(email_tmp, id_tmp) SELECT * FROM openquery(SQLSERVER,' SELECT Email, Identification FROM user.UserData;')
		SELECT @tmp_email = email_tmp FROM @temporal WHERE id_tmp = @in_clientID
		IF @tmp_email != 'EMPTY'
		BEGIN
			SELECT @tmp_email
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE productsInfo @in_type VARCHAR(50) = NULL,
                            @in_age INT = NULL,
                            @in_supplier VARCHAR(50) = NULL,
                            @in_price VARCHAR(50) = NULL
AS
    BEGIN TRY
    SET NOCOUNT ON
        SELECT W.Photo, W.Id, W.Whiskey_name, WT.TypeName, WA.Age, W.Price, S.Supplier_name, S.Features FROM dbo.Whiskey W
            INNER JOIN dbo.WhiskeyType WT ON WT.ID = W.WhiskeyType_id
            INNER JOIN dbo.WhiskeyAge WA ON WA.ID = W.Age_id
            INNER JOIN dbo.Supplier S ON S.ID = W.Supplier_id
            WHERE WT.TypeName LIKE ISNULL(@in_type, WT.TypeName)
                AND WA.Age = ISNULL(@in_age, WA.Age)
                AND S.Supplier_name LIKE ISNULL(@in_supplier, S.Supplier_name)
                AND W.Price <= ISNULL(@in_price, W.Price)
        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO

CREATE PROCEDURE SuscribeClub
	@in_clubID VARCHAR(50), @in_card VARCHAR(50), @in_clientID VARCHAR(50)
AS
	BEGIN TRY
	DECLARE @int_clubID INT = 0, @exist VARCHAR(50) = 'EMPTY'
	SET NOCOUNT ON
		SET @int_clubID = (SELECT CAST(@in_clubID AS INT))
		SELECT @exist = User_identification FROM dbo.UsersXClub WHERE User_identification = @in_clientID AND Active = 1
		IF 0 < @int_clubID AND @exist = 'EMPTY'
		BEGIN
			INSERT INTO dbo.UsersXClub(User_identification, Active, Id_club, Card, Amount)
			VALUES(@in_clientID, 1, @in_clubID, @in_card, 0)
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE UserHasClub
	@in_clientID VARCHAR(50), @exist INT OUTPUT
AS
	BEGIN TRY
	--DECLARE @exist INT = 0
	SET NOCOUNT ON
		SELECT @exist = Id_club FROM dbo.UsersXClub WHERE User_identification = @in_clientID -- Returns the club ID where this user is suscripted
		IF @exist != 0
		BEGIN
			SELECT @exist
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE WhiskeyIsSpecial
	@in_whiskeyID INT, @out_result INT OUTPUT
AS
	BEGIN TRY
	DECLARE @exist BIT = 0
	SET NOCOUNT ON
		SELECT @exist = IsSpecial FROM dbo.Whiskey WHERE Id = @in_whiskeyID
		IF @exist = 1
		BEGIN
			SET @out_result = 1
			SELECT @out_result
		END
		ELSE
		BEGIN
			SET @out_result = 0
			SELECT @out_result
		END
		SELECT @exist
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE getTypes
AS
    BEGIN TRY
    SET NOCOUNT ON
        SELECT WT.ID, WT.TypeName FROM dbo.WhiskeyType WT 
        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO


CREATE FUNCTION [dbo].[isAvailableIreland](@in_whisky INT)
RETURNS INT
AS
	BEGIN
		DECLARE @amountIreland INT
		SELECT @amountIreland = SUM(Amount) FROM Ireland.dbo.Stock
		WHERE Whiskey_code = @in_whisky

		RETURN ISNULL(@amountIreland,0);
	END
GO

CREATE FUNCTION [dbo].[isAvailableScotland](@in_whisky INT)
RETURNS INT
AS
	BEGIN
		DECLARE @amountScotland INT
		SELECT @amountScotland = SUM(Amount) FROM Scotland.dbo.Stock
		WHERE Whiskey_code = @in_whisky

		RETURN ISNULL(@amountScotland,0);
	END
GO

CREATE FUNCTION [dbo].[isAvailableUSA](@in_whisky INT)
RETURNS INT
AS
	BEGIN
		DECLARE @amountUSA INT
		SELECT @amountUSA = SUM(Amount) FROM USA.dbo.Stock
		WHERE Whiskey_code = @in_whisky

		RETURN ISNULL(@amountUSA,0);
	END
GO

CREATE FUNCTION [dbo].[getSoldSum](@in_whisky INT)
RETURNS INT
AS
	BEGIN
		DECLARE @amountUSA INT,
				@amountIreland INT,
				@amountScotland INT,
				@total INT
		SELECT @amountUSA = SUM(PP.Amount) FROM USA.dbo.ProductsXPurchase PP
		INNER JOIN USA.dbo.Stock S ON S.Id = PP.Stock_id
		WHERE S.Whiskey_code = @in_whisky

		SELECT @amountIreland = SUM(PP.Amount) FROM Ireland.dbo.ProductsXPurchase PP
		INNER JOIN Ireland.dbo.Stock S ON S.Id = PP.Stock_id
		WHERE S.Whiskey_code = @in_whisky

		SELECT @amountScotland = SUM(PP.Amount) FROM Scotland.dbo.ProductsXPurchase PP
		INNER JOIN Scotland.dbo.Stock S ON S.Id = PP.Stock_id
		WHERE S.Whiskey_code = @in_whisky

		SET @total = ISNULL(@amountUSA, 0) + ISNULL(@amountIreland,0) + ISNULL(@amountScotland,0)

		RETURN @total;
	END
GO

CREATE FUNCTION [dbo].[userClubFunction](@in_user VARCHAR(50))
RETURNS INT
AS
	BEGIN
		DECLARE @exist INT
		SELECT @exist = Id_club FROM dbo.UsersXClub WHERE User_identification = @in_user -- Returns the club ID where this user is suscripted
		IF @exist > 1
		BEGIN
			RETURN 1;
		END
		ELSE
		BEGIN
			RETURN 0;
		END
		RETURN 0;
	END
GO

ALTER PROCEDURE [dbo].[productsInfo] @in_type VARCHAR(50) = NULL,
							@in_age INT = NULL,
							@in_supplier VARCHAR(50) = NULL,
							@in_priceMin MONEY = NULL,
							@in_priceMax MONEY = NULL,
							@in_name VARCHAR(50) = NULL,
							@in_user VARCHAR(50)
AS
    BEGIN TRY
	DECLARE @minPrice MONEY, @maxPrice MONEY, @canWatch BIT
    SET NOCOUNT ON
		SET @canWatch = dbo.userClubFunction(@in_user)
		SELECT @minPrice = MIN(Price), @maxPrice = MAX(Price) FROM dbo.Whiskey
        SELECT W.Photo, 
				W.Id, 
				W.Whiskey_name, 
				WT.TypeName, 
				WA.Age, 
				W.Price, 
				S.Supplier_name, 
				S.Features,
				dbo.isAvailableUSA(W.Id) AS AmountUSA,
				dbo.isAvailableIreland(W.Id) AS AmountIreland,
				dbo.isAvailableScotland(W.Id) AS AmountScotland,
				dbo.getSoldSum(W.Id) AS Sold,
				W.IsSpecial
			FROM dbo.Whiskey W
			INNER JOIN dbo.WhiskeyType WT ON WT.ID = W.WhiskeyType_id
			INNER JOIN dbo.WhiskeyAge WA ON WA.ID = W.Age_id
			INNER JOIN dbo.Supplier S ON S.ID = W.Supplier_id
			WHERE WT.TypeName LIKE ISNULL(@in_type, WT.TypeName)
				AND W.Whiskey_name LIKE ISNULL(@in_name, W.Whiskey_name)
				AND WA.Age >= ISNULL(@in_age, WA.Age)
				AND LOWER(S.Supplier_name) LIKE LOWER(ISNULL(@in_supplier, S.Supplier_name))
				AND W.Price BETWEEN ISNULL(@in_priceMin, @minPrice) AND ISNULL(@in_priceMax, @maxPrice)
				AND W.IsSpecial <= @canWatch
        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO

CREATE PROCEDURE DeleteSuscription @in_ident INT
AS
	BEGIN TRY
	DECLARE @id INT;
	SET NOCOUNT ON

	SET @id = (SELECT Id FROM dbo.UsersXClub WHERE User_identification = @in_ident)

	IF (@id!=0)
	BEGIN
	UPDATE dbo.UsersXClub
	SET Active = 0
	WHERE Id=@id
	SELECT(1)
	END
	ELSE
	BEGIN
	SELECT (0)
	END
	RETURN 200;
	SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO


CREATE PROCEDURE UpdateSuscription
	@in_ident VARCHAR(50),@in_idClub INT
AS
	DECLARE @id INT = 1,@hi INT, @lo INT=1;
	BEGIN TRY
	SET NOCOUNT ON
	
	SET @id=(SELECT id FROM dbo.UsersXClub WHERE User_identification = @in_ident )

	IF @id!=0
	BEGIN
	UPDATE dbo.UsersXClub
	SET Id_club= @in_idClub
	WHERE id=@id
	SELECT(1)

	END
	ELSE
	BEGIN
		SELECT(0)
	END


		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE CreateWhiskeyAged	@in_Aged INT
AS
	DECLARE @tmp_Age INT = 0
	BEGIN TRY
	SET NOCOUNT ON
		SELECT @tmp_Age = Id FROM dbo.WhiskeyAge WHERE Age = @in_Aged
		IF @tmp_Age = 0
		BEGIN
			INSERT INTO dbo.WhiskeyAge(Age)
			VALUES(@in_Aged)
			SELECT 1
		END
		ELSE
		BEGIN
			SELECT 0
		END
		RETURN 200;
		SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO


CREATE PROCEDURE DeleteWhiskeyAge @in_aged INT
AS
	DECLARE @tmp_id INT = 0
	BEGIN TRY
	SET NOCOUNT ON
	SELECT @tmp_id = Id FROM dbo.WhiskeyAge WHERE Age = @in_aged
	IF @tmp_id != 0
	BEGIN
		DELETE FROM dbo.WhiskeyAge WHERE Age = @in_aged
		SELECT 1
	END
	ELSE
	BEGIN
		SELECT 0
	END
	RETURN 200;
	SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH

GO

CREATE PROCEDURE DeleteSupplier
	@in_name VARCHAR(50)
AS
	DECLARE @tmp_id INT = 0
	BEGIN TRY
	SET NOCOUNT ON
	SELECT @tmp_id = Id FROM dbo.Supplier WHERE Supplier_name = @in_name
	IF @tmp_id != 0
	BEGIN
		DELETE FROM dbo.Supplier WHERE Supplier_name = @in_name
		SELECT 1
	END
	ELSE
	BEGIN
		SELECT 0
	END
	RETURN 200;
	SET NOCOUNT OFF
	END TRY
	BEGIN CATCH
		IF @@Trancount>0 BEGIN
			ROLLBACK TRANSACTION TS;
			SELECT
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
			RETURN 500;
		END
	END CATCH
GO

CREATE PROCEDURE CreateWhiskeyPresentation @in_presentation VARCHAR(50)
AS
    BEGIN TRY
	DECLARE @id INT=0;
    SET NOCOUNT ON

	SELECT @id = ID FROM dbo.WhiskeyPresentation WHERE Presentation=@in_presentation
	
	--SELECT(@id)
	IF @id=0
	BEGIN
	INSERT INTO dbo.WhiskeyPresentation(Presentation)
	VALUES(@in_presentation)
	SELECT (1)
	END
	ELSE
	BEGIN
	SELECT(0)
	END

        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH

GO
CREATE PROCEDURE UpdateWhiskeyPresentation @in_presentation VARCHAR(50),@in_new_name VARCHAR(50)
AS
    BEGIN TRY
	DECLARE @id INT=0;
    SET NOCOUNT ON

	SELECT @id = ID FROM dbo.WhiskeyPresentation WHERE Presentation=@in_presentation
	
	--SELECT(@id)
	IF @id!=0
	BEGIN
	UPDATE dbo.WhiskeyPresentation
	SET Presentation=@in_new_name
	WHERE Presentation=@in_presentation
	SELECT (1)
	END
	ELSE
	BEGIN
	SELECT(0)
	END

        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO
CREATE PROCEDURE DeleteWhiskeyPresentation @in_presentation VARCHAR(50)
AS
    BEGIN TRY
	DECLARE @id INT=0;
    SET NOCOUNT ON

	SELECT @id = ID FROM dbo.WhiskeyPresentation WHERE Presentation=@in_presentation
	
	--SELECT(@id)
	IF @id!=0
	BEGIN
	DELETE FROM dbo.WhiskeyPresentation WHERE Presentation = @in_presentation

	SELECT (1)
	END
	ELSE
	BEGIN
	SELECT(0)
	END

        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO

CREATE PROCEDURE [dbo].[productsConsult] @in_type VARCHAR(50) = NULL,
							@in_amountTotal INT = NULL,
							@in_sold INT = NULL
AS
    BEGIN TRY
	DECLARE @minPrice MONEY, @maxPrice MONEY
    SET NOCOUNT ON
		SELECT @minPrice = MIN(Price), @maxPrice = MAX(Price) FROM dbo.Whiskey
        SELECT W.Photo, 
				W.Id, 
				W.Whiskey_name, 
				WT.TypeName, 
				WA.Age, 
				W.Price, 
				S.Supplier_name, 
				S.Features,
				dbo.isAvailableUSA(W.Id) AS AmountUSA,
				dbo.isAvailableIreland(W.Id) AS AmountIreland,
				dbo.isAvailableScotland(W.Id) AS AmountScotland,
				dbo.isAvailableTotal(W.Id) AS AmountTotal,
				dbo.getSoldSum(W.Id) AS Sold
			FROM dbo.Whiskey W
			INNER JOIN dbo.WhiskeyType WT ON WT.ID = W.WhiskeyType_id
			INNER JOIN dbo.WhiskeyAge WA ON WA.ID = W.Age_id
			INNER JOIN dbo.Supplier S ON S.ID = W.Supplier_id
			WHERE WT.TypeName LIKE ISNULL(@in_type, WT.TypeName)
				AND dbo.isAvailableTotal(W.Id) >= ISNULL(@in_amountTotal, dbo.isAvailableTotal(W.Id))
				AND dbo.getSoldSum(W.Id) >= ISNULL(@in_sold, dbo.getSoldSum(W.Id))
        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO

CREATE FUNCTION [dbo].[isAvailableTotal](@in_whisky INT)
RETURNS INT
AS
	BEGIN
		RETURN dbo.isAvailableUSA(@in_whisky) + dbo.isAvailableIreland(@in_whisky) + dbo.isAvailableScotland(@in_whisky);
	END
GO

CREATE FUNCTION [dbo].[allPurchases]()
RETURNS @purchases TABLE (whisky_id INT, datePurchase DATE, country VARCHAR(50))
AS
	BEGIN
		INSERT INTO @purchases(whisky_id, datePurchase, country)
		SELECT S.Whiskey_code, P.Purchase_date, 'Ireland' FROM Ireland.dbo.ProductsXPurchase PP
		INNER JOIN Ireland.dbo.Stock S ON S.Id = PP.Stock_id
		INNER JOIN Ireland.dbo.Purchase P ON P.Id = PP.Purchase_id

		INSERT INTO @purchases(whisky_id, datePurchase, country)
		SELECT S.Whiskey_code, P.Purchase_date, 'Scotland' FROM Scotland.dbo.ProductsXPurchase PP
		INNER JOIN Scotland.dbo.Stock S ON S.Id = PP.Stock_id
		INNER JOIN Scotland.dbo.Purchase P ON P.Id = PP.Purchase_id

		INSERT INTO @purchases(whisky_id, datePurchase, country)
		SELECT S.Whiskey_code, P.Purchase_date, 'USA' FROM USA.dbo.ProductsXPurchase PP
		INNER JOIN USA.dbo.Stock S ON S.Id = PP.Stock_id
		INNER JOIN USA.dbo.Purchase P ON P.Id = PP.Purchase_id

		RETURN;
	END
GO

CREATE PROCEDURE [dbo].[purchasesConsult] @in_country VARCHAR(50) = NULL,
							@in_date1 DATE = NULL,
							@in_date2 DATE = NULL
AS
    BEGIN TRY
	DECLARE @purchases TABLE(whisky_id INT, datePurchase DATE, country VARCHAR(50))
    SET NOCOUNT ON
		INSERT INTO @purchases
		SELECT * FROM dbo.allPurchases()
        SELECT W.Id, 
				W.Whiskey_name,
				P.country,
				P.datePurchase
		FROM @purchases P
		INNER JOIN dbo.Whiskey W ON W.Id = P.whisky_id
		WHERE @in_country = P.country
			AND P.datePurchase BETWEEN ISNULL(@in_date1, P.datePurchase) AND ISNULL(@in_date2, P.datePurchase)
		ORDER BY P.country

        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO

CREATE PROCEDURE getSuscribePrice @in_idSuscription INT 
AS
    BEGIN TRY
    DECLARE @price INT
    SET NOCOUNT ON

    SET @price = (SELECT Price FROM DBO.Club WHERE Id=@in_idSuscription)
    SELECT (@price)
        RETURN 200;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @@Trancount>0 BEGIN
            ROLLBACK TRANSACTION TS;
            SELECT
                SUSER_SNAME(),
                ERROR_NUMBER(),
                ERROR_STATE(),
                ERROR_SEVERITY(),
                ERROR_LINE(),
                ERROR_PROCEDURE(),
                ERROR_MESSAGE(),
                GETDATE()
            RETURN 500;
        END
    END CATCH
GO

INSERT INTO dbo.WhiskeyAge(Age)
VALUES(50)
INSERT INTO dbo.WhiskeyAge(Age)
VALUES(40)
INSERT INTO dbo.WhiskeyAge(Age)
VALUES(30)
INSERT INTO dbo.WhiskeyType(TypeName)
VALUES('Dulce')
INSERT INTO dbo.WhiskeyType(TypeName)
VALUES('Amargo')
INSERT INTO dbo.Supplier(Supplier_name)
VALUES('Florida')
INSERT INTO dbo.Supplier(Supplier_name)
VALUES('Chivas Supplier')
INSERT INTO dbo.Club(Club_name, Price, Discount, HaveExpress, Express_discount)
VALUES('Tier Short Glass', 10, 0.05, 0, 1.0)
INSERT INTO dbo.Club(Club_name, Price, Discount, HaveExpress, Express_discount)
VALUES('Tier Gleincairn', 20, 0.1, 0, 0.2)
INSERT INTO dbo.Club(Club_name, Price, Discount, HaveExpress, Express_discount)
VALUES('Tier Master Distiller', 30, 0.3, 1, 1.0)

INSERT INTO dbo.Whiskey(Whiskey_name, WhiskeyType_id, Age_id, Price, Supplier_id, IsSpecial)
VALUES('Chivas Regal', 1, 1, 30, 1, 1)
INSERT INTO dbo.Whiskey(Whiskey_name, WhiskeyType_id, Age_id, Price, Supplier_id, IsSpecial)
VALUES('Jonny Walker', 2, 2, 15, 2, 1)
INSERT INTO dbo.Whiskey(Whiskey_name, WhiskeyType_id, Age_id, Price, Supplier_id, IsSpecial)
VALUES('Red Label', 2, 2, 10, 2, 0)

EXECUTE InsertCredentials '2019', 'Gmora7', 'ga1301' --IsSpecial
