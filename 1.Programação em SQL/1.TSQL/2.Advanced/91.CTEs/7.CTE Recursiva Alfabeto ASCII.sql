

DECLARE @tabelaAsciiMaiuscula TABLE (
    identificador INT PRIMARY KEY,
    Valor VARCHAR(2))





DECLARE @tabelaAsciiMinuscula TABLE (
    identificador INT PRIMARY KEY,
    Valor VARCHAR(2));




WITH CTEDados
  AS (SELECT 65 AS Identificador,
             CHAR(65) AS Valor
      UNION ALL
      SELECT CTE.Identificador + 1,
             Valor = CHAR(CTE.Identificador + 1)
        FROM CTEDados CTE
       WHERE (CTE.Identificador + 1) <= 90)
INSERT INTO @tabelaAsciiMaiuscula 
SELECT R.Identificador,
       R.Valor
  FROM CTEDados R;



  WITH CTEDados2
  AS (SELECT 97 AS Identificador,
             CHAR(97) AS Valor
      UNION ALL
      SELECT CTE.Identificador + 1,
             Valor = CHAR(CTE.Identificador + 1)
        FROM CTEDados2 CTE
       WHERE (CTE.Identificador + 1) <= 122)
INSERT INTO @tabelaAsciiMinuscula 
SELECT R.Identificador,
       R.Valor
  FROM CTEDados2 R;


  SELECT * FROM @tabelaAsciiMaiuscula AS TAM
  UNION
  SELECT * FROM @tabelaAsciiMinuscula AS TAM