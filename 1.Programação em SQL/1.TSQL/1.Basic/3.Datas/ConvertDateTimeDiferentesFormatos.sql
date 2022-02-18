ALTER DATABASE [15-implanta] SET COMPATIBILITY_LEVEL = 120;



DECLARE @inicio INT =1;

DECLARE @termino INT =120;


DECLARE @hoje DATETIME =GETDATE();

--forma1
 SELECT CONCAT(@hoje,'');


 WHILE(@inicio <= @termino)
 BEGIN
       
	   SELECT  CONCAT( @inicio,'===>',TRY_CONVERT(VARCHAR(30),@hoje,@inicio));

	 SET @inicio +=1;
 END
 --forma1
 

 SELECT TRY_CONVERT(VARCHAR(22),GETDATE(),20);