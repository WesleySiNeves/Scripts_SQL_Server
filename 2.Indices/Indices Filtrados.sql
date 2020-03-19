

    IF ( OBJECT_ID('ContaBancaria', 'U') IS NULL )
        BEGIN

            CREATE TABLE ContaBancaria
                (
                  idContaBancaria INT IDENTITY(1, 1) ,
                  NomeConta VARCHAR(30) ,
                  CONSTRAINT PKContaBancaria PRIMARY KEY ( idContaBancaria )
                );

            INSERT  dbo.ContaBancaria
                    ( NomeConta )
            VALUES  ( 'CEF' ),
                    ( 'BB' );

        END;

    IF ( OBJECT_ID('Lancamentos', 'U') IS NULL )
        BEGIN

            CREATE TABLE Lancamentos
                (
                  idLancamento UNIQUEIDENTIFIER NOT NULL
                                                ROWGUIDCOL
                                                DEFAULT ( NEWSEQUENTIALID() ) ,
                  idContaBancaria INT FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
                  Historico VARCHAR(100)
                    NOT NULL
                    DEFAULT ( 'Histórico padrão para lançamentos bancários.' ) ,
                  NumeroLancamento INT NOT NULL ,
                  Data DATETIME ,
                  Valor DECIMAL(18, 2) ,
                  Receita BIT NOT NULL ,
                  CONSTRAINT PKLancamentos PRIMARY KEY ( idLancamento )
                );

        END;

	
-- ==================================================================
--Observação:faz insert dos dados com valoes aleatorios
-- ==================================================================


    DECLARE @dataInicio DATETIME = '2011-01-01';
    DECLARE @IsCredito BIT = 1;
    DECLARE @QuantidadeRegistrosAGerar INT = 1000000;
    DECLARE @IdContaBancariaCEF INT  = ( SELECT TOP 1
                                                              CB.idContaBancaria
                                                      FROM    dbo.ContaBancaria
                                                              AS CB
                                                      WHERE   CB.NomeConta = 'CEF'
                                                    );
    DECLARE @IdContaBancariaBB INT  = ( SELECT TOP 1
                                                            CB.idContaBancaria
                                                     FROM   dbo.ContaBancaria
                                                            AS CB
                                                     WHERE  CB.NomeConta = 'BB'
                                                   );

 
    WITH    CTE
              AS ( SELECT   1 AS NumeroLancamento
                   UNION ALL
                   SELECT   CTE.NumeroLancamento + 1
                   FROM     CTE
                   WHERE    CTE.NumeroLancamento < @QuantidadeRegistrosAGerar
                 ),
            Query
              AS ( SELECT   CTE.NumeroLancamento ,
                            TA.IdConta ,
                            TA.Data ,
                            TA.Valor ,
                            TA.Receita
                   FROM     CTE
                            CROSS APPLY ( SELECT    CASE WHEN ( CTE.NumeroLancamento
                                                              % 2 = 0 )
                                                         THEN @IdContaBancariaCEF
                                                         ELSE @IdContaBancariaBB
                                                    END AS IdConta ,
                                                    CAST(DATEADD(DAY,
                                                              ABS(CHECKSUM(NEWID())
                                                              % IIF(( CTE.NumeroLancamento <= 800000 ), 2555, 730)),
                                                              IIF(( CTE.NumeroLancamento <= 800000 ), '2011-01-01', '2016-01-01')) AS DATE) AS Data ,
                                                    CAST(ABS(CAST(( CAST(CHECKSUM(NEWID()) AS DECIMAL(18,
                                                              2)) / 1000000 ) AS DECIMAL(18,
                                                              2))) AS DECIMAL(18,
                                                              2)) AS Valor ,
                                                    IIF(( CTE.NumeroLancamento <= 600000 ), 0, 1) AS Receita
                                        ) AS TA
                 )
        INSERT  INTO dbo.Lancamentos WITH ( TABLOCK )
                ( idContaBancaria ,
                  NumeroLancamento ,
                  Data ,
                  Valor ,
                  Receita
                )
                SELECT  Q.IdConta ,
                        Q.NumeroLancamento ,
                        Q.Data ,
                        Q.Valor ,
                        Q.Receita
                FROM    Query Q
        OPTION  ( MAXRECURSION 0 );
    
	
	
	

--SELECT * FROM dbo.Lancamentos AS L

--ALTER TABLE dbo.Lancamentos ADD IdSIstemaGerador INT 


;
WITH    DadosUpdate
          AS ( SELECT TOP 50 PERCENT
                        L.idLancamento ,
                        L.Valor ,
                        L.Data ,
                        L.IdSIstemaGerador
               FROM     dbo.Lancamentos AS L
             )
    UPDATE  DadosUpdate
    SET     IdSIstemaGerador = 1
    WHERE   DAY(Data) % 2 = 0; 


SELECT IdSIstemaGerador,Quantidade =COUNT(*) FROM Lancamentos
GROUP BY IdSIstemaGerador


SET STATISTICS IO ON 
SELECT L.idLancamento ,
       L.idContaBancaria ,
       L.NumeroLancamento ,
       L.Valor ,
       L.IdSIstemaGerador FROM Lancamentos L  --leituras lógicas 18603,
SET STATISTICS IO OFF


SET STATISTICS IO ON; 
SELECT  L.idLancamento ,
        L.idContaBancaria ,
        L.NumeroLancamento ,
        L.Valor ,
        L.IdSIstemaGerador
FROM    Lancamentos L
WHERE   L.IdSIstemaGerador = 1;
 --Número de verificações 1, leituras lógicas 18769,
SET STATISTICS IO OFF


SET STATISTICS IO ON 
SELECT L.idLancamento ,
       L.idContaBancaria ,
       L.NumeroLancamento ,
       L.Valor ,
       L.IdSIstemaGerador FROM Lancamentos L
WHERE IdSIstemaGerador IS NULL --Número de verificações 1,leituras lógicas 18603,
SET STATISTICS IO OFF



--CREATE NONCLUSTERED INDEX IdxFilterIndexIdSIstemaGerador ON dbo.Lancamentos(IdSIstemaGerador)
--INCLUDE(idLancamento,idContaBancaria,NumeroLancamento,Valor)
--WHERE IdSIstemaGerador IS NOT NULL 




SET STATISTICS IO ON 
SELECT L.idLancamento ,
       L.idContaBancaria ,
       L.NumeroLancamento ,
       L.Valor ,
       L.IdSIstemaGerador FROM Lancamentos L  --leituras lógicas 18603,
SET STATISTICS IO OFF


SET STATISTICS IO ON; 
SELECT  L.idLancamento ,
        L.idContaBancaria ,
        L.NumeroLancamento ,
        L.Valor ,
        L.IdSIstemaGerador
FROM    Lancamentos L
WHERE   L.IdSIstemaGerador = 1;
 --Número de verificações 1, Número de verificações 1, leituras lógicas 1311,,
SET STATISTICS IO OFF


SET STATISTICS IO ON 
SELECT L.idLancamento ,
       L.idContaBancaria ,
       L.NumeroLancamento ,
       L.Valor ,
       L.IdSIstemaGerador FROM Lancamentos L
WHERE IdSIstemaGerador IS NULL --Número de verificações 1,leituras lógicas 18603,
SET STATISTICS IO OFF

