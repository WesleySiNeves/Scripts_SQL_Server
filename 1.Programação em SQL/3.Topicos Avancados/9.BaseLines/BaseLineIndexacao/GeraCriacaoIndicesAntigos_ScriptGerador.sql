IF (OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
    DROP TABLE #Dados;

CREATE TABLE #Dados (
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

INSERT INTO #Dados
EXEC HealthCheck.uspAllIndex @typeIndex = 'NONCLUSTERED'; -- varchar(40)

;

WITH Dados
  AS (
     SELECT D.ObjectId,
            D.ObjectName,
            D.RowsInTable,
            D.IndexName,
            D.ColunasIncluidas,
            D.IsUnique,
            D.IgnoreDupKey,
            D.IsprimaryKey,
            D.IsUniqueConstraint,
            D.FillFact,
            D.AllowRowLocks,
            D.AllowPageLocks,
            D.HasFilter,
            D.TypeIndex,
            PrimeiraChave = (IIF(CHARINDEX(',', D.Chave, 0) > 0,
                                 SUBSTRING(D.Chave, 0, CHARINDEX(',', D.Chave, 0)),
                                 D.Chave)
                            ),
            X = CONCAT(
                          'CREATE NONCLUSTERED INDEX  ',
                          QUOTENAME(D.IndexName),
                          ' ON ',
                          D.ObjectName,
                          ' (',
                          D.Chave,
                          ')',
                          IIF((D.ColunasIncluidas IS NULL), '', 'INCLUDE(' + D.ColunasIncluidas + ')')
                      )
     FROM #Dados AS D
     )
SELECT R.ObjectId,
       R.ObjectName,
       R.RowsInTable,
       R.IndexName,
       R.ColunasIncluidas,
       R.IsUnique,
       R.IgnoreDupKey,
       R.IsprimaryKey,
       R.IsUniqueConstraint,
       R.FillFact,
       R.AllowRowLocks,
       R.AllowPageLocks,
       R.HasFilter,
       R.TypeIndex,
       R.PrimeiraChave,
       R.X,
       Script = CONCAT(
                          ' IF(NOT EXISTS(SELECT I.name,C.* FROM sys.indexes AS I JOIN sys.index_columns AS IC ON I.object_id = IC.object_id AND
	    I.index_id = IC.index_id ',
                          'JOIN sys.columns AS C ON I.object_id = C.object_id  WHERE I.object_id =',
                          OBJECT_ID(R.ObjectName),
                          '  AND c.name = ',
                          CHAR(39),
                          R.PrimeiraChave,
                          CHAR(39),
                          ' AND I.type >1  AND IC.key_ordinal =1)) BEGIN ',
                          R.X,
                          ' END'
                      )
FROM Dados R
WHERE R.ObjectName NOT LIKE '%Hangfire%';
