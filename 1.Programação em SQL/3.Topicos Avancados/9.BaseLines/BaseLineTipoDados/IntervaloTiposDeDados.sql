
/* ==================================================================
--Data: 13/11/2018 
--Autor :Wesley Neves
--Observação: Intervalo Inteiro  ( 0 a  2147483647) 4 Bytes
 
-- ==================================================================
*/

DECLARE @numero INT = 0;


--2.147.483.647
SET @numero = 2147483647;

SELECT CONCAT(DATALENGTH(@numero),' Bytes'), FORMAT(@numero,'N','Pt-Br')




/* ==================================================================
--Data: 13/11/2018 
--Autor :Wesley Neves
--Observação: Intervalo tinyint  ( tinyint	0 a 255	1 byte )
 
-- ==================================================================
*/
 
 --255
DECLARE @tinyint TINYINT  = 255;


SELECT CONCAT(DATALENGTH(@tinyint),' Bytes'), FORMAT(@tinyint,'D','Pt-Br')



/* ==================================================================
--Data: 27/11/2018 
--Autor :Wesley Neves
--Observação:  DataTime X
 Formato Usado por nos 2017-02-13 16:54:55.000
-- ==================================================================
*/


DECLARE @DATETIME DATETIME = GETDATE();
DECLARE @DATETIME2 DATETIME2(3) = GETDATE();
DECLARE @SMALLDATETIME SMALLDATETIME = GETDATE();

SELECT TRY_CAST(@SMALLDATETIME AS SMALLDATETIME  )
SELECT 'DATETIME:', CONCAT(DATALENGTH(@DATETIME),' Bytes'), @DATETIME
UNION
SELECT 'DATETIME2', CONCAT(DATALENGTH(@DATETIME2),' Bytes'), @DATETIME2
UNION
SELECT 'SMALLDATETIME', CONCAT(DATALENGTH(@SMALLDATETIME),' Bytes'), @SMALLDATETIME


