DECLARE @variavel_TINYINT TINYINT =255;
DECLARE @variavel_SMALLINT SMALLINT =255;
DECLARE @variavel_INT INT =255;
DECLARE @variavel_BIGINT BIGINT =255;

SELECT 'TINYINT' [Data Type] , DATALENGTH(@variavel_TINYINT) AS [Quantidade Bytes TINYINT]
UNION
SELECT 'SMALLINT' [Data Type] , DATALENGTH(@variavel_SMALLINT) AS [Quantidade Bytes SMALLINT]
UNION
SELECT 'INT' [Data Type] , DATALENGTH(@variavel_INT) AS [Quantidade Bytes INT]
UNION
SELECT 'BIGINT' [Data Type] , DATALENGTH(@variavel_BIGINT) AS [Quantidade Bytes BIGINT]