USE WideWorldImporters;


-- ==================================================================
--Observação: Compara Datetime X DATETIME2
/*
 */
-- ==================================================================
DECLARE @datetime DATETIME = GETDATE();

DECLARE @datetime2 DATETIME2(3) = GETDATE();

SELECT @datetime,
       DATALENGTH(@datetime);

SELECT @datetime2 Dtetime2Suporte3Casas,
       DATALENGTH(@datetime2) AS [Tamanho],
       CAST(@datetime2 AS DATETIME2(2)) AS Dtetime2Suporte2Casas,
       DATALENGTH(CAST(@datetime2 AS DATETIME2(2))) AS [Tamanho];


IF EXISTS (   SELECT *
                FROM sys.tables AS T
               WHERE T.name = OBJECT_NAME(OBJECT_ID('Despesa.Empenhos')))
BEGIN

    SELECT E.IdEmpenho,
           E.Data,
           CAST(E.Data AS DATETIME2(3))
      FROM Despesa.Empenhos AS E
     WHERE CAST(E.Data AS DATETIME) <> CAST(E.Data AS DATETIME2(3));
END;












