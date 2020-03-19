DECLARE @ROLLBACK BIT = 0;

SET XACT_ABORT ON;

BEGIN TRANSACTION SCHEDULE;

BEGIN TRY
    /*Region Logical Querys*/
    IF(OBJECT_ID('TEMPDB..#PessoasAlteradas') IS NOT NULL)
        DROP TABLE #PessoasAlteradas;

    CREATE TABLE #PessoasAlteradas
    (
        [NomeRazaoSocial]      VARCHAR(250),
        [CPFCNPJ]              VARCHAR(20),
        [IdPessoa]             UNIQUEIDENTIFIER,
        [TipoPessoaFisica]     BIT,
        [VisivelSomenteSiscaf] BIT,
        [Ativo]                BIT,
        [RN]                   BIGINT
    );

    WITH DadosDuplicados
        AS
         (
             SELECT P.NomeRazaoSocial,
                    P.CPFCNPJ,
                    P.IdPessoa,
                    P.TipoPessoaFisica,
                    P.VisivelSomenteSiscaf,
                    P.Ativo,
                    RN = ROW_NUMBER() OVER (PARTITION BY P.CPFCNPJ, P.NomeRazaoSocial ORDER BY P.IdPessoa)
               FROM Cadastro.Pessoas AS P
              WHERE P.Ativo = 1
         ),
         IdsPessoasSiscaf
        AS
         (
             SELECT D.IdPessoa FROM Financeiro.Debitos AS D
             UNION
             SELECT P.IdPessoa FROM Financeiro.Parcelamentos AS P
             UNION
             SELECT P.IdPessoa FROM Financeiro.Pagamentos AS P
         ),
         IdsPessoasSiscont
        AS
         (
             SELECT DISTINCT SF.IdPessoa AS PessoaSiscont
               FROM Despesa.SaidasFinanceiras AS SF
         )
    INSERT INTO #PessoasAlteradas(
                                     NomeRazaoSocial,
                                     CPFCNPJ,
                                     IdPessoa,
                                     TipoPessoaFisica,
                                     VisivelSomenteSiscaf,
                                     Ativo,
                                     RN
                                 )
    SELECT P.NomeRazaoSocial,
           P.CPFCNPJ,
           P.IdPessoa,
           P.TipoPessoaFisica,
           P.VisivelSomenteSiscaf,
           P.Ativo,
           P.RN
      FROM DadosDuplicados P
     WHERE EXISTS (
                      SELECT 1
                        FROM DadosDuplicados P2
                       WHERE P2.NomeRazaoSocial = P.NomeRazaoSocial
                             AND P.CPFCNPJ = P2.CPFCNPJ
                             AND P.RN > P2.RN
                  )
           --AND p.NomeRazaoSocial LIKE '%global%'
           AND P.VisivelSomenteSiscaf = 0
           AND EXISTS (
                          SELECT 1 FROM IdsPessoasSiscaf Sis WHERE Sis.IdPessoa = P.IdPessoa
                      )
           AND NOT EXISTS (
                              SELECT * FROM IdsPessoasSiscont sisc WHERE sisc.PessoaSiscont = P.IdPessoa
                          )
     ORDER BY
        P.NomeRazaoSocial,
        P.CPFCNPJ;

    UPDATE P
       SET P.VisivelSomenteSiscaf = 1
    OUTPUT Deleted.IdPessoa,
           Deleted.NomeRazaoSocial,
           Deleted.CPFCNPJ,
           Deleted.VisivelSomenteSiscaf AS OldValue,
           Inserted.VisivelSomenteSiscaf AS NewValue
      FROM Cadastro.Pessoas P
           JOIN #PessoasAlteradas PA ON P.IdPessoa = PA.IdPessoa;

    /*End region */
    IF @ROLLBACK = 0
        BEGIN
            COMMIT TRANSACTION SCHEDULE;
        END;
    ELSE
        BEGIN
            ROLLBACK TRANSACTION SCHEDULE;
        END;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION SCHEDULE;

    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
    PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    PRINT 'Error detected, all changes reversed.';
END CATCH;


--MARIA DO SOCORRO PANTOJA RIBEIRO
