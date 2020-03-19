

--DECLARE @Idcliente INT = 0;
--DECLARE @Data DATETIME = '2013-09-07 00:00:00';


IF (EXISTS (   SELECT 1
                 FROM sys.procedures AS P
                WHERE P.name = 'GetLancamentos'))
BEGIN
    DROP PROCEDURE Bancario.GetLancamentos;
END;
GO

EXEC Bancario.GetLancamentos @Idcliente = 0, -- int
                             @Data =NULL -- datetime


CREATE PROCEDURE Bancario.GetLancamentos (
    @Idcliente INT,
    @Data DATETIME)
AS
BEGIN
    BEGIN TRY
        /*Region Logical Querys*/

        IF (@Idcliente IS NULL OR @Idcliente = 0)
        BEGIN
            THROW 50000, 'O paramentro @Idcliente é Obrigátorio', 1;
        END;

        IF (@Data IS NULL)
        BEGIN
            THROW 50000, 'O paramentro @Data é Obrigátorio', 1;
        END;

        WITH Dados
          AS (SELECT --L.idLancamento,
                     B.NomeBanco,
                     C.Nome,
                     L.Historico,
                     L.NumeroLancamento,
                     L.Data,
                     Valor = IIF(L.Credito = 1, L.Valor, L.Valor * -1),
                     L.Credito
                FROM Bancario.Lancamentos AS L
                JOIN Cadastro.Clientes AS C
                  ON L.IdCliente = C.IdCliente
                JOIN Bancario.Bancos AS B
                  ON L.idBanco   = B.idBanco
               WHERE L.IdCliente = @Idcliente
                 AND L.Data      <= @Data)
        SELECT R.NomeBanco,
               R.Nome,
               R.Historico,
               R.NumeroLancamento,
               R.Data,
               R.Valor,
               TotalAcumulado = SUM(R.Valor) OVER (PARTITION BY R.NomeBanco,
                                                                R.Nome
                                                       ORDER BY R.Data,
                                                                R.NumeroLancamento)
          FROM Dados R
         ORDER BY R.Data,
                  R.NomeBanco,
                  R.NumeroLancamento;

    /*End region */



    END TRY
    BEGIN CATCH
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorPROCEDURE NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
        PRINT '@ErrorSeverity: ' + CAST(@ErrorSeverity AS VARCHAR(MAX));
        PRINT '@ErrorState: ' + CAST(@ErrorState AS VARCHAR(MAX));
        PRINT '@PROCEDURE: ' + CAST(@ErrorPROCEDURE AS VARCHAR(MAX));

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);


        PRINT 'Error detected, all changes reversed.';
    END CATCH;

END;


