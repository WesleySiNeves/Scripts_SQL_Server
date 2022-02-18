
DECLARE @Quantidade INT = 0;

WITH Dados
    AS
    (
        SELECT AE.IdArquivoExtrato,
               AE.DataImportacao,
               AE.Nome,
               AE.Conteudo,
               AE.DataInicio,
               AE.DataFim,
               X = HASHBYTES('MD2', AE.Conteudo)
          FROM Despesa.ArquivosExtrato AS AE
         WHERE
            YEAR(AE.DataImportacao) = 2020
    )
SELECT COUNT(*)
  FROM Dados R
 WHERE
    R.X IN(
              SELECT HASHBYTES('MD2', AE.Conteudo) AS HAS
                FROM Despesa.ArquivosExtrato AS AE
               WHERE
                  YEAR(AE.DataImportacao) = 2020
               GROUP BY
                  HASHBYTES('MD2', AE.Conteudo)
              HAVING
                  COUNT(*) > 1
          );
