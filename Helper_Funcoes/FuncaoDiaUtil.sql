DECLARE @dataInicio SMALLDATETIME = DATEADD(MONTH, -1, GETDATE());
DECLARE @dataTermino SMALLDATETIME = GETDATE();

DECLARE @DataParametro SMALLDATETIME = CONVERT(SMALLDATETIME, GETDATE(), 103);
SELECT @DataParametro;


SET LANGUAGE 'portuguese'
;WITH Datas
   AS (SELECT DATEADD(DAY, -5, @DataParametro) AS Data,
              DATEPART(WEEKDAY, DATEADD(DAY, -5, @DataParametro)) AS DiaSemana
       UNION ALL
       SELECT DATEADD(DAY, 1, D.Data),
              DATEPART(WEEKDAY, DATEADD(DAY, 1, D.Data)) AS DiaSemana
         FROM Datas D
        WHERE D.Data < DATEADD(DAY, 5, @DataParametro)),
      Formatados
   AS (SELECT D.Data,
              D.DiaSemana,
              DiaSemanaExtenso = DATENAME(WEEKDAY, D.Data)
         FROM Datas D)
SELECT Formatados.Data,
       Formatados.DiaSemana,
       Formatados.DiaSemanaExtenso,
       DiaUtilAnterior = (   SELECT MAX(F.Data)
                               FROM Formatados F
                              WHERE F.DiaSemana NOT IN ( 7, 1 )
                                AND F.Data < @DataParametro),
       ProximoDiaUtil = (   SELECT MIN(F.Data)
                              FROM Formatados F
                             WHERE F.DiaSemana NOT IN ( 7, 1 )
                               AND F.Data > @DataParametro)
  FROM Formatados
 WHERE Formatados.Data = @DataParametro;

