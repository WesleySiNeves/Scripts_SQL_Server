

CREATE OR ALTER FUNCTION dbo.RetornaSomenteLetrasMaiusculas (@texto VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN

    DECLARE @Valores TABLE (
        indice INT,
        valor VARCHAR(1));


    DECLARE @tabelaAsciiMaiuscula TABLE (
        identificador INT PRIMARY KEY,
        Valor VARCHAR(2));





    DECLARE @tabelaAsciiMinuscula TABLE (
        identificador INT PRIMARY KEY,
        Valor VARCHAR(2));


    DECLARE @resultado VARCHAR(50) = '';

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


    DECLARE @inicio INT = 0;
    DECLARE @letra VARCHAR(1);
    WHILE (@inicio <= LEN('ConfiguracoesTiposRequerimentosConfiguracoesValoresDTFormasEntregas'))
    BEGIN

        SET @inicio += 1;

        SET @letra = SUBSTRING('ConfiguracoesTiposRequerimentosConfiguracoesValoresDTFormasEntregas', @inicio, 1);


        IF (EXISTS (   SELECT 1
                         FROM @tabelaAsciiMaiuscula AS TAM
                        WHERE TAM.identificador = ASCII(@letra)))
        BEGIN
            SET @resultado += @letra;
        END;

    END;

    RETURN LTRIM(RTRIM(@resultado));

END;