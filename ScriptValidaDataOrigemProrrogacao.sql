DECLARE @Exercicio INT = 2021;


IF (OBJECT_ID('TEMPDB..#Prorrogações') IS NOT NULL)
    DROP TABLE #Prorrogações;

CREATE TABLE #Prorrogações (
                           [IdEmpenho]                UNIQUEIDENTIFIER,
                           [IdPessoa]                 UNIQUEIDENTIFIER,
                           [IdPlanoConta]             UNIQUEIDENTIFIER,
                           [Exercicio]                INT,
                           [Numero]                   INT,
                           [Data]                     DATETIME2(2),
						   [DataCorretaEmpenho]       DATETIME2(2) NULL,
                           [RestoAPagar]              BIT,
                           [ProrrogacaoRestoAPagar]   BIT,
                           [RestoAPagarProcessado]    BIT,
                           [ValorInscritoRestoAPagar] DECIMAL(18, 2),
                           [ValorAnulado]             DECIMAL(18, 2),
                           [ValorPago]                DECIMAL(18, 2),
                           [ValorLiquidado]           DECIMAL(18, 2),
                           [Valor]                    DECIMAL(18, 2),
                           [SaldoALiquidar]           DECIMAL(20, 2),
                           [SaldoAPagar]              DECIMAL(20, 2)
                           );

INSERT INTO #Prorrogações (
                          IdEmpenho,
                          IdPessoa,
                          IdPlanoConta,
                          Exercicio,
                          Numero,
                          Data,
                          RestoAPagar,
                          ProrrogacaoRestoAPagar,
                          RestoAPagarProcessado,
                          ValorInscritoRestoAPagar,
                          ValorAnulado,
                          ValorPago,
                          ValorLiquidado,
                          Valor,
                          SaldoALiquidar,
                          SaldoAPagar
                          )
SELECT E.IdEmpenho,
       E.IdPessoa,
       E.IdPlanoConta,
       E.Exercicio,
       E.Numero,
       E.Data,
       E.RestoAPagar,
       E.ProrrogacaoRestoAPagar,
       ERP.RestoAPagarProcessado,
       E.ValorInscritoRestoAPagar,
       E.ValorAnulado,
       E.ValorPago,
       E.ValorLiquidado,
       E.Valor,
       E.SaldoALiquidar,
       SaldoAPagar = (ValorLiquidado - ValorPago)
FROM Despesa.Empenhos E
     LEFT JOIN
     Despesa.EmpenhosRestosAPagar ERP ON E.IdEmpenho = ERP.IdEmpenho
WHERE E.Exercicio = @Exercicio
      AND E.RestoAPagar = 1
      AND E.ProrrogacaoRestoAPagar = 1;





IF (OBJECT_ID('TEMPDB..#EmpenhosOrigens') IS NOT NULL)
    DROP TABLE #EmpenhosOrigens;

CREATE TABLE #EmpenhosOrigens (
                              IdProrrogacao              UNIQUEIDENTIFIER,
                              [IdEmpenho]                UNIQUEIDENTIFIER,
                              [IdPessoa]                 UNIQUEIDENTIFIER,
                              [IdPlanoConta]             UNIQUEIDENTIFIER,
                              [Exercicio]                INT,
                              [Numero]                   INT,
                              [Data]                     DATETIME2(2),
							 
                              [RestoAPagar]              BIT,
                              [ProrrogacaoRestoAPagar]   BIT,
                              [ValorInscritoRestoAPagar] DECIMAL(18, 2),
                              [ValorAnulado]             DECIMAL(18, 2),
                              [ValorPago]                DECIMAL(18, 2),
                              [ValorLiquidado]           DECIMAL(18, 2),
                              [Valor]                    DECIMAL(18, 2),
                              [SaldoALiquidar]           DECIMAL(20, 2),
                              [SaldoAPagar]              DECIMAL(19, 2)
                              );

/* declare variables */
DECLARE @IdEmpenho UNIQUEIDENTIFIER,
        @IdPessoa UNIQUEIDENTIFIER,
        @IdPlanoConta UNIQUEIDENTIFIER,
        @Exercicio_Cursor INT,
        @Numero INT,
        @Data DATETIME2(2),
        @RestoAPagar BIT,
        @ProrrogacaoRestoAPagar BIT,
        @RestoAPagarProcessado BIT,
        @ValorInscritoRestoAPagar DECIMAL(18, 2),
        @ValorAnulado DECIMAL(18, 2),
        @ValorPago DECIMAL(18, 2),
        @ValorLiquidado DECIMAL(18, 2),
        @Valor DECIMAL(18, 2),
        @SaldoALiquidar DECIMAL(20, 2),
        @SaldoAPagar DECIMAL(20, 2);


DECLARE cursor_ValidaData CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT P.IdEmpenho,
           P.IdPessoa,
           P.IdPlanoConta,
           P.Exercicio,
           P.Numero,
           P.Data,
           P.RestoAPagar,
           P.ProrrogacaoRestoAPagar,
           P.RestoAPagarProcessado,
           P.ValorInscritoRestoAPagar,
           P.ValorAnulado,
           P.ValorPago,
           P.ValorLiquidado,
           P.Valor,
           P.SaldoALiquidar,
           P.SaldoAPagar
    FROM #Prorrogações AS P
    --WHERE IdEmpenho = '1DABCA2F-062E-4BB8-A00E-EB097B188BA4';

OPEN cursor_ValidaData;

FETCH NEXT FROM cursor_ValidaData
INTO @IdEmpenho,
     @IdPessoa,
     @IdPlanoConta,
     @Exercicio_Cursor,
     @Numero,
     @Data,
     @RestoAPagar,
     @ProrrogacaoRestoAPagar,
     @RestoAPagarProcessado,
     @ValorInscritoRestoAPagar,
     @ValorAnulado,
     @ValorPago,
     @ValorLiquidado,
     @Valor,
     @SaldoALiquidar,
     @SaldoAPagar;

WHILE @@FETCH_STATUS = 0
BEGIN


   


   INSERT INTO #EmpenhosOrigens
    SELECT @IdEmpenho AS IdProrrogacao,
           E.IdEmpenho,
           E.IdPessoa,
           E.IdPlanoConta,
           E.Exercicio,
           E.Numero,
           E.Data,
           E.RestoAPagar,
           E.ProrrogacaoRestoAPagar,
           E.ValorInscritoRestoAPagar,
           E.ValorAnulado,
           E.ValorPago,
           E.ValorLiquidado,
           E.Valor,
           E.SaldoALiquidar,
           SaldoAPagar = (E.ValorLiquidado  - E.ValorPago)
    FROM Despesa.Empenhos AS E
    WHERE E.RestoAPagar = 0
          AND E.Numero = @Numero
          AND E.IdPessoa = @IdPessoa
          AND (
              E.IdPlanoConta = @IdPlanoConta
              OR EXISTS (
                        SELECT TOP 1
                            1
                        FROM Contabilidade.PlanoContasAssociacoes AS PCA
                        WHERE PCA.IdPlanoContaPCASP = @IdPlanoConta
                        )
              )

        AND (
        /* regra para trazer empenhos que foram inscritos portanto devem ter ou saldo a pagar ou saldo a liquidar */
        (
        E.SaldoALiquidar > 0
        OR (E.ValorLiquidado - E.ValorPago) > 0
        ));
       

    DECLARE @DataCorretaOrigem DATETIME2(2) = (
                                              SELECT EO.Data
                                              FROM #EmpenhosOrigens AS EO
                                              WHERE EO.IdProrrogacao = @IdEmpenho
                                              );


		update #Prorrogações set DataCorretaEmpenho = @DataCorretaOrigem
		where IdEmpenho = @IdEmpenho



    FETCH NEXT FROM cursor_ValidaData
    INTO @IdEmpenho,
         @IdPessoa,
         @IdPlanoConta,
         @Exercicio_Cursor,
         @Numero,
         @Data,
         @RestoAPagar,
         @ProrrogacaoRestoAPagar,
         @RestoAPagarProcessado,
         @ValorInscritoRestoAPagar,
         @ValorAnulado,
         @ValorPago,
         @ValorLiquidado,
         @Valor,
         @SaldoALiquidar,
         @SaldoAPagar;
END;

CLOSE cursor_ValidaData;
DEALLOCATE cursor_ValidaData;



select * from #Prorrogações P
where P.Data <> P.DataCorretaEmpenho