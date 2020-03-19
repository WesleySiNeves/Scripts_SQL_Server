	-- ==================================================================
	--Observação:Cria o banco de dados com as tabelas para exemplo
	-- ==================================================================

	CREATE DATABASE ExemploViewParticionada;

	GO

	USE ExemploViewParticionada;

	IF ( OBJECT_ID('ContaBancaria', 'U') IS NULL )
		BEGIN

			CREATE TABLE ContaBancaria
				(
				  idContaBancaria UNIQUEIDENTIFIER NOT NULL
												   PRIMARY KEY
												   ROWGUIDCOL
												   DEFAULT ( NEWSEQUENTIALID() ) ,
				  NomeConta VARCHAR(30)
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
				  idContaBancaria UNIQUEIDENTIFIER NOT NULL
					FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
				  Historico VARCHAR(100) NOT NULL DEFAULT ( 'Histórico padrão para lançamentos bancários.' ) ,
				  NumeroLancamento INT NOT NULL ,
				  Data DATETIME ,
				  Valor DECIMAL(18, 2) ,
				  Credito BIT NOT NULL,
				  CONSTRAINT PKLancamentos PRIMARY KEY(idLancamento,Data)
				);

		END;

	
-- ==================================================================
--Observação:faz insert dos dados com valoes aleatorios
-- ==================================================================


DECLARE @dataInicio DATETIME = '2011-01-01';
DECLARE @IsCredito BIT = 1;
DECLARE @IdContaBancariaCEF UNIQUEIDENTIFIER  = ( SELECT TOP 1
                                                            CB.idContaBancaria
                                                  FROM      dbo.ContaBancaria
                                                            AS CB
                                                  WHERE     CB.NomeConta = 'CEF'
                                                );
DECLARE @IdContaBancariaBB UNIQUEIDENTIFIER  = ( SELECT TOP 1
                                                        CB.idContaBancaria
                                                 FROM   dbo.ContaBancaria AS CB
                                                 WHERE  CB.NomeConta = 'BB'
                                               );

 
WITH    CTE
          AS ( SELECT   1 AS NumeroLancamento
               UNION ALL
               SELECT   CTE.NumeroLancamento + 1
               FROM     CTE
               WHERE    CTE.NumeroLancamento < 1000000
             ),
        Query
          AS ( SELECT   CTE.NumeroLancamento ,
                        TA.IdConta ,
                        TA.Data ,
                        TA.Valor ,
                        TA.Credito
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
                                                IIF(( CTE.NumeroLancamento <= 600000 ), 0, 1) AS Credito
                                    ) AS TA
             )
    INSERT  INTO dbo.Lancamentos WITH ( TABLOCK )
            ( idContaBancaria ,
              NumeroLancamento ,
              Data ,
              Valor ,
              Credito
            )
            SELECT  Q.IdConta ,
                    Q.NumeroLancamento ,
                    Q.Data ,
                    Q.Valor ,
                    Q.Credito
            FROM    Query Q
    OPTION  ( MAXRECURSION 0 );
    
 
 
 -- ==================================================================
 -- Vamos analisar a quantidade de dados que temos por ano
 -- ==================================================================
 
SELECT  Ano = YEAR(L.Data) ,
        QuantidadeLancamento = FORMAT(COUNT(*), 'N', 'pt-Br')
FROM    dbo.Lancamentos AS L
GROUP BY YEAR(L.Data)
ORDER BY YEAR(L.Data);


 --- ==================================================================
 -- Agora vamos criar uma tabela para cada ano
 -- ==================================================================
 		

CREATE TABLE LancamentosAno2011
    (
      idLancamento UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL ,
      idContaBancaria UNIQUEIDENTIFIER NOT NULL
       FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
      Historico VARCHAR(100) NOT NULL ,
	 NumeroLancamento INT NOT NULL ,
      Data DATETIME NOT NULL  ,
      Valor DECIMAL(18, 2) ,
      Credito BIT NOT NULL ,
      CONSTRAINT PKidLancamento2011 PRIMARY KEY CLUSTERED ( idLancamento ,Data),
	  CONSTRAINT CkDataAno2011 CHECK ( Data >='2011-01-01 00:00:00' AND Data <='2011-12-31 23:59:57')
	  
    );

		


CREATE TABLE LancamentosAno2012
    (
      idLancamento UNIQUEIDENTIFIER NOT NULL
                                    ROWGUIDCOL ,
      idContaBancaria UNIQUEIDENTIFIER
        NOT NULL
        FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
      Historico VARCHAR(100) NOT NULL ,
	  NumeroLancamento INT NOT NULL ,
      Data DATETIME  NOT NULL,
      Valor DECIMAL(18, 2) ,
      Credito BIT NOT NULL ,
      CONSTRAINT PKidLancamento2012 PRIMARY KEY CLUSTERED ( idLancamento,Data),
	  CONSTRAINT CkDataAno2012 CHECK ( Data >='2012-01-01 00:00:00' AND Data <='2012-12-31 23:59:57')
    );

CREATE TABLE LancamentosAno2013
    (
      idLancamento UNIQUEIDENTIFIER NOT NULL
                                    ROWGUIDCOL ,
      idContaBancaria UNIQUEIDENTIFIER
        NOT NULL
        FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
      Historico VARCHAR(100) NOT NULL ,
	  NumeroLancamento INT NOT NULL ,
      Data DATETIME NOT NULL ,
      Valor DECIMAL(18, 2) ,
      Credito BIT NOT NULL ,
      CONSTRAINT PKidLancamento2013 PRIMARY KEY CLUSTERED ( idLancamento,Data),
	  CONSTRAINT CkDataAno2013 CHECK ( Data >='2013-01-01 00:00:00' AND Data <='2013-12-31 23:59:57')
    );

CREATE TABLE LancamentosAno2014
    (
      idLancamento UNIQUEIDENTIFIER NOT NULL
                                    ROWGUIDCOL ,
      idContaBancaria UNIQUEIDENTIFIER
        NOT NULL
        FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
      Historico VARCHAR(100) NOT NULL ,
	  NumeroLancamento INT NOT NULL ,
      Data DATETIME NOT NULL ,
      Valor DECIMAL(18, 2) ,
      Credito BIT NOT NULL ,
      CONSTRAINT PKidLancamento2014 PRIMARY KEY CLUSTERED ( idLancamento,Data ),
	  CONSTRAINT CkDataAno2014 CHECK ( Data >='2014-01-01 00:00:00' AND Data <='2014-12-31 23:59:57')
    );

CREATE TABLE LancamentosAno2015
    (
      idLancamento UNIQUEIDENTIFIER NOT NULL
                                    ROWGUIDCOL ,
      idContaBancaria UNIQUEIDENTIFIER
        NOT NULL
        FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
      Historico VARCHAR(100) NOT NULL ,
	  NumeroLancamento INT NOT NULL ,
      Data DATETIME ,
      Valor DECIMAL(18, 2) ,
      Credito BIT NOT NULL ,
      CONSTRAINT PKidLancamento2015 PRIMARY KEY CLUSTERED ( idLancamento ,Data),
	   CONSTRAINT CkDataAno2015 CHECK ( Data >='2015-01-01 00:00:00' AND Data <='2015-12-31 23:59:57')
    );

CREATE TABLE LancamentosAno2016
    (
      idLancamento UNIQUEIDENTIFIER NOT NULL
                                    ROWGUIDCOL ,
      idContaBancaria UNIQUEIDENTIFIER
        NOT NULL
        FOREIGN KEY ( idContaBancaria ) REFERENCES dbo.ContaBancaria ( idContaBancaria ) ,
      Historico VARCHAR(100) NOT NULL ,
	  NumeroLancamento INT NOT NULL ,
      Data DATETIME  NOT NULL,
      Valor DECIMAL(18, 2) ,
      Credito BIT NOT NULL ,
      CONSTRAINT PKidLancamento2016 PRIMARY KEY CLUSTERED ( idLancamento,Data),
	     CONSTRAINT CkDataAno2016 CHECK ( Data >='2016-01-01 00:00:00' AND Data <='2016-12-31 23:59:57')
    );

-- ==================================================================
--Agora vamos executar o insert nessas tabelas, cada tabela criada 
-- terá os lançamentos do seu ano
-- ==================================================================

INSERT  INTO dbo.LancamentosAno2011
        ( idLancamento ,
          idContaBancaria ,
          Historico ,
		  NumeroLancamento,
          Data ,
          Valor ,
          Credito
	    )
        SELECT  L.idLancamento ,
                L.idContaBancaria ,
                L.Historico ,
				L.NumeroLancamento,
                L.Data ,
                L.Valor ,
                L.Credito
        FROM    dbo.Lancamentos AS L
        WHERE   YEAR(L.Data) = 2011;

INSERT  INTO dbo.LancamentosAno2012
        ( idLancamento ,
          idContaBancaria ,
          Historico ,
		  NumeroLancamento,
          Data ,
          Valor ,
          Credito
	    )
         SELECT  L.idLancamento ,
                L.idContaBancaria ,
                L.Historico ,
				L.NumeroLancamento,
                L.Data ,
                L.Valor ,
                L.Credito
        FROM    dbo.Lancamentos AS L
        WHERE   YEAR(L.Data) = 2012;



INSERT  INTO dbo.LancamentosAno2013
        ( idLancamento ,
          idContaBancaria ,
          Historico ,
		  NumeroLancamento,
          Data ,
          Valor ,
          Credito
	    )
         SELECT  L.idLancamento ,
                L.idContaBancaria ,
                L.Historico ,
				L.NumeroLancamento,
                L.Data ,
                L.Valor ,
                L.Credito
        FROM    dbo.Lancamentos AS L
        WHERE   YEAR(L.Data) = 2013;        



INSERT  INTO dbo.LancamentosAno2014
        ( idLancamento ,
          idContaBancaria ,
          Historico ,
		  NumeroLancamento,
          Data ,
          Valor ,
          Credito
	    )
         SELECT  L.idLancamento ,
                L.idContaBancaria ,
                L.Historico ,
				L.NumeroLancamento,
                L.Data ,
                L.Valor ,
                L.Credito
        FROM    dbo.Lancamentos AS L
        WHERE   YEAR(L.Data) = 2014;



INSERT  INTO dbo.LancamentosAno2015
        ( idLancamento ,
          idContaBancaria ,
          Historico ,
		  NumeroLancamento,
          Data ,
          Valor ,
          Credito
	    )
         SELECT  L.idLancamento ,
                L.idContaBancaria ,
                L.Historico ,
				L.NumeroLancamento,
                L.Data ,
                L.Valor ,
                L.Credito
        FROM    dbo.Lancamentos AS L
        WHERE   YEAR(L.Data) = 2015;



INSERT  INTO dbo.LancamentosAno2016
        ( idLancamento ,
          idContaBancaria ,
          Historico ,
		  NumeroLancamento,
          Data ,
          Valor ,
          Credito
	    )
        SELECT  L.idLancamento ,
                L.idContaBancaria ,
                L.Historico ,
				L.NumeroLancamento,
                L.Data ,
                L.Valor ,
                L.Credito
        FROM    dbo.Lancamentos AS L
        WHERE   YEAR(L.Data) = 2016;

-- ==================================================================
-- Deleta os lançamentos que foram migrados para as outras tabelas
-- ==================================================================

DELETE  L
FROM    dbo.Lancamentos AS L
        JOIN ( SELECT   LA.idLancamento
               FROM     dbo.LancamentosAno2011 AS LA
               UNION ALL
               SELECT   LA.idLancamento
               FROM     dbo.LancamentosAno2012 AS LA
               UNION ALL
               SELECT   LA.idLancamento
               FROM     dbo.LancamentosAno2013 AS LA
               UNION ALL
               SELECT   LA.idLancamento
               FROM     dbo.LancamentosAno2014 AS LA
               UNION ALL
               SELECT   LA.idLancamento
               FROM     dbo.LancamentosAno2015 AS LA
               UNION ALL
               SELECT   LA.idLancamento
               FROM     dbo.LancamentosAno2016 AS LA
             ) AS LANAntigo ON LANAntigo.idLancamento = L.idLancamento;


-- ==================================================================
--Cria a chave de particionamento da tabela
-- ==================================================================
ALTER TABLE dbo.Lancamentos ADD CONSTRAINT CkDataLancamento2017 CHECK ( Data >= '2017-01-01 00:00:00');


-- ==================================================================
--Aqui temos um ponto de atenção , 
--acabamos de rodar um DELETE em mais ou menos (786530 row(s) affected)
--logo veja isso 
-- ==================================================================


SET STATISTICS IO ON; 
SELECT  *
FROM    dbo.Lancamentos AS L;
SET STATISTICS IO OFF;
 
 GO

 
ALTER INDEX PKLancamentos ON dbo.Lancamentos REBUILD

/*Rode novamente o scrip para ver a quantidade de paginas agora*/

SET STATISTICS IO ON; 
SELECT  *
FROM    dbo.Lancamentos AS L;
SET STATISTICS IO OFF;
GO

-- ==================================================================
--Observação:Agora vamos criar a View Particionada
-- ==================================================================

CREATE VIEW VwBuscaLancamentos
WITH SCHEMABINDING
AS
    SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.LancamentosAno2011 AS LA -- logical reads 1566,
    UNION ALL
    SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.LancamentosAno2012 AS LA --logical reads 1564
    UNION ALL
    SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.LancamentosAno2013 AS LA -- logical reads 1554
    UNION ALL
   SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.LancamentosAno2014 AS LA --logical reads 1550
    UNION ALL
    SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.LancamentosAno2015 AS LA --logical reads 1556
    UNION ALL
   SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.LancamentosAno2016 AS LA --logical reads 2919
    UNION ALL
    SELECT  LA.idLancamento ,
            LA.idContaBancaria ,
            LA.Historico ,
			La.NumeroLancamento,
            LA.Data ,
            LA.Valor ,
            LA.Credito
    FROM    dbo.Lancamentos AS LA; -- logical reads 3022	



  GO
  
 SET STATISTICS IO ON;
SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2011-01-01' AND Data <='2011-12-31'

SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2012-01-01' AND Data <='2012-12-31'

SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2013-01-01' AND Data <='2013-12-31'

SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2014-01-01' AND Data <='2014-12-31'

SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2015-01-01' AND Data <='2015-12-31'

SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2016-01-01' AND Data <='2016-12-31'

SELECT  *
FROM    dbo.VwBuscaLancamentos AS VBL
WHERE   VBL.Data  >='2017-01-01'
SET STATISTICS IO OFF;

SELECT MAX(VBL.NumeroLancamento) FROM dbo.VwBuscaLancamentos AS VBL



TRUNCATE TABLE dbo.LancamentosAno2011
TRUNCATE TABLE dbo.LancamentosAno2012
TRUNCATE TABLE dbo.LancamentosAno2013
TRUNCATE TABLE dbo.LancamentosAno2014
TRUNCATE TABLE dbo.LancamentosAno2015
TRUNCATE TABLE dbo.LancamentosAno2016
TRUNCATE TABLE dbo.Lancamentos


-- ==================================================================
--Com as tabelas vazias vamos fazer os Inserts
--Primeira observação , a view só podera responder por insert se todos os campos das tabelas forem retornada por ela
--ou seja se vc omitir um campo das tabelas a view não poderá sofrer inserts ,
-- ==================================================================
SELECT * FROM dbo.VwBuscaLancamentos AS VBL

--Recuperar a chave gerada
DECLARE @idconta  UNIQUEIDENTIFIER=(SELECT TOP 1 CB.idContaBancaria FROM dbo.ContaBancaria AS CB)

INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(), @idconta ,'Lancamento 2011' ,1,'2011-02-10', 100,1 );

INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(),@idconta,'Lancamento 2012' ,1,'2012-05-10', 100,1 );

INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(),@idconta ,'Lancamento 2013' ,1,'2013-05-10', 100,1 );

INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(),@idconta ,'Lancamento 2014' ,1,'2014-05-10', 100,1 );

INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(),@idconta ,'Lancamento 2015' ,1,'2015-05-10', 100,1 );

INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(),@idconta ,'Lancamento 2016' ,1,'2016-10-10', 100,1 );


INSERT INTO dbo.VwBuscaLancamentos
        ( idLancamento ,idContaBancaria , Historico ,NumeroLancamento ,Data , Valor ,Credito)
VALUES  (  NEWID(),@idconta ,'Lancamento 2019' ,1,'2019-10-10', 100,1 );


-- ==================================================================
-- rode esses dois selects primeiro , apos rode o update
-- ==================================================================
SELECT * FROM dbo.LancamentosAno2011 AS LA
SELECT * FROM dbo.Lancamentos AS L


UPDATE dbo.VwBuscaLancamentos SET Data ='2019-10-10' WHERE  Historico ='Lancamento 2011'

SELECT * FROM dbo.LancamentosAno2011 AS LA
SELECT * FROM dbo.Lancamentos AS L
SELECT * FROM dbo.VwBuscaLancamentos AS VBL

SET STATISTICS IO ON
DELETE  VBL FROM dbo.VwBuscaLancamentos AS VBL
WHERE VBL.Data = '2014-05-10 00:00:00.000'
SET STATISTICS IO OFF