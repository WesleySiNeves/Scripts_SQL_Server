DROP TABLE IF EXISTS dbo.CamposDatetime2ForDate;

CREATE TABLE dbo.CamposDatetime2ForDate
(
    SchemaName       VARCHAR(128),
    TableName        VARCHAR(128),
    Coluna           VARCHAR(128),
    QuantidadeLinhas INT
);

/* ==================================================================
--Data: 11/11/2020 
--Autor :Wesley Neves
--Observação: Executar o script em python para CamposDatetime2ForDate.ipynb
 
-- ==================================================================
*/


SELECT DISTINCT CDFD.SchemaName, CDFD.TableName, CDFD.Coluna FROM dbo.CamposDatetime2ForDate AS CDFD
ORDER BY CDFD.SchemaName,CDFD.TableName