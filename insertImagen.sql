UPDATE Whiskey
SET Photo = (SELECT BulkColumn FROM OPENROWSET(BULK 'C:\Users\gmora\Downloads\whiskey.jpg', SINGLE_BLOB) AS A)
WHERE id = 1 or id=2 or id=3;



SELECT * FROM Shop

SELECT * FROM Stock
