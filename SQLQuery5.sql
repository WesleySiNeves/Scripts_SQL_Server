DECLARE @Efetivar BIT = 0;
DECLARE @VisualizarMissing BIT = 1;
DECLARE @VisualizarCreate BIT = 1;
DECLARE @VisualizarAlteracoes BIT = 1;
DECLARE @defaultTunningPerform SMALLINT = 100;


DECLARE @tableObjectsIds AS TableIntegerIds;
DECLARE @QuantidadeMaximaIndiceTabela TINYINT = 5; --(1 PK + 4 NonCluster);
IF(OBJECT_ID('TEMPDB..#SchemasExcessao') IS NOT NULL)
    DROP TABLE #SchemasExcessao;



CREATE TABLE #SchemasExcessao
(
    SchemaName VARCHAR(128) NOT NULL
);



INSERT INTO #SchemasExcessao(SchemaName)VALUES('%HangFire%');

IF(OBJECT_ID('TEMPDB..#MissingIndex') IS NOT NULL)
    DROP TABLE #MissingIndex;

CREATE TABLE #MissingIndex
(
    ObjectId                    INT,
    [TotalObjetcId]             INT,
    SchemaName                  VARCHAR(140),
    TableName                   VARCHAR(140),
    [IndexName]                 VARCHAR(200),
    [Chave]                     VARCHAR(200),
    [PrimeiraChave]             VARCHAR(200),
    [ExisteIndiceNaChave]       INT,
    [ChavePertenceAOutroIndice] INT,
    [ColunaIncluida]            VARCHAR(1000),
    AvgEstimatedImpact          REAL,
    MagicBenefitNumber          REAL,
    PotentialReadOp             INT,
    [reads]                     INT,
    PercCusto                   DECIMAL(10, 2),
    [CreateIndex]               VARCHAR(8000)
);

IF(OBJECT_ID('TEMPDB..#ManutencaoIndices') IS NOT NULL)
    DROP TABLE #ManutencaoIndices;

CREATE TABLE #ManutencaoIndices
(
    ObjectId                    INT,
    [TotalObjetcId]             INT,
    SchemaName                  VARCHAR(140),
    TableName                   VARCHAR(140),
    [IndexName]                 VARCHAR(200),
    [Chave]                     VARCHAR(200),
    [PrimeiraChave]             VARCHAR(200),
    [ExisteIndiceNaChave]       INT,
    [ChavePertenceAOutroIndice] INT,
    [ColunaIncluida]            VARCHAR(1000),
    AvgEstimatedImpact          REAL,
    MagicBenefitNumber          REAL,
    PotentialReadOp             INT,
    [reads]                     INT,
    PercCusto                   DECIMAL(10, 2),
    [CreateIndex]               VARCHAR(8000),
    Acao                        CHAR(1) CONSTRAINT CHECK_Acao CHECK(Acao IN ('I', 'D'))
);


IF(OBJECT_ID('TEMPDB..#ResultAllIndex') IS NOT NULL)
                DROP TABLE #ResultAllIndex;

            CREATE TABLE #ResultAllIndex
            (
                [ObjectId]           INT,
                [ObjectName]         VARCHAR(300),
                [RowsInTable]        INT,
                [IndexName]          VARCHAR(128),
                [Usado]              BIT,
                [UserSeeks]          INT,
                [UserScans]          INT,
                [UserLookups]        INT,
                [UserUpdates]        INT,
                [Reads]              BIGINT,
                [Write]              INT,
                [CountPageSplitPage] INT,
                [PercAproveitamento] DECIMAL(18, 2),
                [PercCustoMedio]     DECIMAL(18, 2),
                [IsBadIndex]         INT,
                [IndexId]            SMALLINT,
                [IndexsizeKB]        BIGINT,
                [IndexsizeMB]        DECIMAL(18, 2),
                [IndexSizePorTipoMB] DECIMAL(18, 2),
                [Chave]              VARCHAR(899),
                PrimeiraChave        AS (IIF(CHARINDEX(',', [Chave], 0) > 0, SUBSTRING([Chave], 0, CHARINDEX(',', [Chave], 0)), [Chave])),
                [ColunasIncluidas]   VARCHAR(899),
                [IsUnique]           BIT,
                [IgnoreDupKey]       BIT,
                [IsprimaryKey]       BIT,
                [IsUniqueConstraint] BIT,
                [FillFact]           TINYINT,
                [AllowRowLocks]      BIT,
                [AllowPageLocks]     BIT,
                [HasFilter]          BIT,
                [TypeIndex]          TINYINT
            );




IF(OBJECT_ID('TEMPDB..#NovosIndices') IS NOT NULL)
    DROP TABLE #NovosIndices;

CREATE TABLE #NovosIndices
(
    [ObjectId]                  INT,
    [TotalObjetcId]             INT,
    [SchemaName]                VARCHAR(140),
    [TableName]                 VARCHAR(140),
    [IndexName]                 VARCHAR(200),
    [Chave]                     VARCHAR(200),
    [PrimeiraChave]             VARCHAR(200),
    [ExisteIndiceNaChave]       INT,
    [ChavePertenceAOutroIndice] INT,
    [ColunaIncluida]            VARCHAR(1000),
    [AvgEstimatedImpact]        REAL,
    [MagicBenefitNumber]        REAL,
    [PotentialReadOp]           INT,
    [reads]                     INT,
    [PercCusto]                 DECIMAL(10, 2),
    [CreateIndex]               VARCHAR(8000)
  
);

INSERT INTO #MissingIndex
EXEC HealthCheck.uspMissingIndex @defaultTunningPerform = @defaultTunningPerform;

DELETE S
  FROM #MissingIndex S
       INNER JOIN(SELECT SSE.SchemaName FROM #SchemasExcessao AS SSE)Filtro ON S.SchemaName LIKE Filtro.SchemaName;

DELETE MI
  FROM #MissingIndex AS MI
 WHERE
    EXISTS (
               SELECT *
                 FROM sys.indexes AS I
                WHERE
                   I.object_id = MI.ObjectId
                   AND I.type_desc = 'CLUSTERED COLUMNSTORE'
           );

/* ==================================================================
--Data: 03/02/2021 
--Autor :Wesley Neves
--Observação: Tratamento para ObjectId duplicado
 
-- ==================================================================
*/
IF(OBJECT_ID('TEMPDB..#QuantidadeIndicesPorTabela') IS NOT NULL)
    DROP TABLE #QuantidadeIndicesPorTabela;



CREATE TABLE #QuantidadeIndicesPorTabela
            (
                ObjectId                 BIGINT,
                [QuantidadeIndiceTabela] TINYINT
            );

INSERT INTO #QuantidadeIndicesPorTabela
SELECT T.object_id,
       IX.TotalIndiceTabela
  FROM sys.tables T
       JOIN(
               SELECT IX.object_id,
                      TotalIndiceTabela = COUNT(*)
                 FROM sys.indexes IX
                WHERE
                   IX.is_disabled = 0
                   AND IX.is_hypothetical = 0
                   AND IX.type > 0
                GROUP BY
                   IX.object_id
           )IX ON T.object_id = IX.object_id
 WHERE
    EXISTS (
               SELECT * FROM #MissingIndex I WHERE I.ObjectId = IX.object_id
           );



INSERT INTO @tableObjectsIds(
                                Id
                            )
SELECT DISTINCT NI.ObjectId FROM #MissingIndex AS NI
 




INSERT INTO #ResultAllIndex
EXEC HealthCheck.uspAllIndex @TableObjectIds = @tableObjectsIds;






;WITH MelhorIndice
    AS
    (
        SELECT MI.ObjectId,
               MI.TotalObjetcId,
               MI.SchemaName,
               MI.TableName,
               MI.IndexName,
               MI.Chave,
               MI.PrimeiraChave,
               MI.ExisteIndiceNaChave,
               MI.ChavePertenceAOutroIndice,
               MI.ColunaIncluida,
               MI.AvgEstimatedImpact,
               MI.MagicBenefitNumber,
               MI.PotentialReadOp,
               MI.reads,
               MI.PercCusto,
               MI.CreateIndex,
               CountObjectId = COUNT(MI.ObjectId) OVER (PARTITION BY MI.ObjectId),
               MaxMagicBenefitNumber = MAX(MI.MagicBenefitNumber) OVER (PARTITION BY MI.ObjectId, MI.PrimeiraChave)
          FROM #MissingIndex AS MI
    )
INSERT INTO #NovosIndices(
                             ObjectId,
                             TotalObjetcId,
                             SchemaName,
                             TableName,
                             IndexName,
                             Chave,
                             PrimeiraChave,
                             ExisteIndiceNaChave,
                             ChavePertenceAOutroIndice,
                             ColunaIncluida,
                             AvgEstimatedImpact,
                             MagicBenefitNumber,
                             PotentialReadOp,
                             reads,
                             PercCusto,
                             CreateIndex
                         )
SELECT R.ObjectId,
       R.TotalObjetcId,
       R.SchemaName,
       R.TableName,
       R.IndexName,
       R.Chave,
       R.PrimeiraChave,
       R.ExisteIndiceNaChave,
       R.ChavePertenceAOutroIndice,
       R.ColunaIncluida,
       R.AvgEstimatedImpact,
       R.MagicBenefitNumber,
       R.PotentialReadOp,
       R.reads,
       R.PercCusto,
       R.CreateIndex
      
  FROM MelhorIndice R
 WHERE
    R.CountObjectId > 1
    AND R.MagicBenefitNumber = R.MaxMagicBenefitNumber;




/* ==================================================================
--Data: 03/02/2021 
--Autor :Wesley Neves
--Observação: Remove os indices não bons , pois os demais foram migrados para a tabela de  #NovosIndices
 
-- ==================================================================
*/
DELETE target
  FROM #MissingIndex AS target
       JOIN #NovosIndices AS NI ON target.ObjectId = NI.ObjectId
                                   AND NI.TotalObjetcId > 1;

SELECT * FROM #NovosIndices AS NI

SELECT * FROM #MissingIndex AS MI

SELECT * FROM #NovosIndices AS NI
--INSERT INTO #NovosIndices 
SELECT MI.ObjectId,
       MI.TotalObjetcId,
       MI.SchemaName,
       MI.TableName,
       MI.IndexName,
       MI.Chave,
       MI.PrimeiraChave,
       MI.ExisteIndiceNaChave,
       MI.ChavePertenceAOutroIndice,
       MI.ColunaIncluida,
       MI.AvgEstimatedImpact,
       MI.MagicBenefitNumber,
       MI.PotentialReadOp,
       MI.reads,
       MI.PercCusto,
       MI.CreateIndex FROM #MissingIndex AS MI
WHERE MI.TotalObjetcId =1
AND MI.ExisteIndiceNaChave = 0
AND MI.ChavePertenceAOutroIndice = 0

WHERE MI.ObjectId ='1357612275'
SELECT * FROM #NovosIndices AS NI
WHERE NI.ObjectId ='1357612275'

SELECT NI.ObjectId,
       NI.TotalObjetcId,
       NI.SchemaName,
       NI.TableName,
       NI.IndexName,
       NI.Chave,
       NI.PrimeiraChave,
       NI.ExisteIndiceNaChave,
       NI.ChavePertenceAOutroIndice,
       NI.ColunaIncluida,
       NI.AvgEstimatedImpact,
       NI.MagicBenefitNumber,
       NI.PotentialReadOp,
       NI.reads,
       NI.PercCusto,
       NI.CreateIndex,
       NI.CountObjectId,
       NI.MaxMagicBenefitNumber,
	   QIPT.QuantidadeIndiceTabela FROM #NovosIndices AS NI
JOIN #QuantidadeIndicesPorTabela AS QIPT ON QIPT.ObjectId = NI.ObjectId
SELECT * FROM #QuantidadeIndicesPorTabela AS QIPT
JOIN #NovosIndices
 

SELECT RAI.ObjectId,
       RAI.ObjectName,
       RAI.RowsInTable,
       RAI.IndexName,
       RAI.Usado,
       RAI.UserSeeks,
       RAI.UserScans,
       RAI.UserLookups,
       RAI.UserUpdates,
       RAI.Reads,
       RAI.Write,
       RAI.CountPageSplitPage,
       RAI.PercAproveitamento,
       RAI.PercCustoMedio,
       RAI.IsBadIndex,
       RAI.IndexId,
       RAI.IndexsizeKB,
       RAI.IndexsizeMB,
       RAI.Chave,
       RAI.PrimeiraChave,
       RAI.ColunasIncluidas,
       RAI.IsUnique,
       RAI.IsprimaryKey,
       RAI.FillFact,
       RAI.TypeIndex FROM #ResultAllIndex AS RAI
WHERE  RAI.ObjectId ='1357612275'
AND RAI.TypeIndex > 1



