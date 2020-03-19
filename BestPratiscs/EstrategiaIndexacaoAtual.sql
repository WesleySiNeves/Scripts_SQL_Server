



WITH TodosIndices
  AS (SELECT TableName = CONCAT(X.SchemaName, '.', X.TableName),
             X.Create_Statement,
             SUM(X.avg_user_impact) AS avg_user_impact,
             SUM(X.user_seeks) AS user_seeks,
             SUM(X.user_scans) AS user_scans,
             SUM(X.Avg_Estimated_Impact) AS Avg_Estimated_Impact
      FROM (
           SELECT CAST(W.SchemaName AS VARCHAR(200)) AS SchemaName,
                  CAST(W.TableName AS VARCHAR(200)) AS TableName,
                  Helper.RemoveAllSpaces(LTRIM(RTRIM(CAST(W.Create_Statement AS VARCHAR(1000))))) Create_Statement,
                  SUM(CAST(REPLACE(W.avg_user_impact, ',', '.') AS DECIMAL(18, 2))) AS avg_user_impact,
                  SUM(CAST(W.user_seeks AS INT)) AS user_seeks,
                  SUM(CAST(W.user_scans AS INT)) AS user_scans,
                  AVG(CAST(REPLACE(W.Avg_Estimated_Impact, ',', '.') AS DECIMAL(18, 2))) AS Avg_Estimated_Impact
           FROM dbo.ResultHomo AS W
           GROUP BY
               Helper.RemoveAllSpaces(LTRIM(RTRIM(CAST(W.Create_Statement AS VARCHAR(1000))))),
               CAST(W.SchemaName AS VARCHAR(200)),
               CAST(W.TableName AS VARCHAR(200))
           UNION
           SELECT CAST(W.SchemaName AS VARCHAR(200)) AS SchemaName,
                  CAST(W.TableName AS VARCHAR(200)) AS TableName,
                  Helper.RemoveAllSpaces(LTRIM(RTRIM(CAST(W.Create_Statement AS VARCHAR(1000))))) Create_Statement,
                  SUM(CAST(REPLACE(W.avg_user_impact, ',', '.') AS DECIMAL(18, 2))) AS avg_user_impact,
                  SUM(CAST(W.user_seeks AS INT)) AS user_seeks,
                  SUM(CAST(W.user_scans AS INT)) AS user_scans,
                  AVG(CAST(REPLACE(W.Avg_Estimated_Impact, ',', '.') AS DECIMAL(18, 2))) AS Avg_Estimated_Impact
           FROM dbo.ResultDev AS W
           GROUP BY
               Helper.RemoveAllSpaces(LTRIM(RTRIM(CAST(W.Create_Statement AS VARCHAR(1000))))),
               CAST(W.SchemaName AS VARCHAR(200)),
               CAST(W.TableName AS VARCHAR(200))
           --UNION
           --SELECT CAST(W.SchemaName AS VARCHAR(200)) AS SchemaName,
           --       CAST(W.TableName AS VARCHAR(200)) AS TableName,
           --       Helper.RemoveAllSpaces(LTRIM(RTRIM(CAST(W.Create_Statement AS VARCHAR(1000))))) Create_Statement,
           --       SUM(CAST(REPLACE(W.avg_user_impact, ',', '.') AS DECIMAL(18, 2))) AS avg_user_impact,
           --       SUM(CAST(W.user_seeks AS INT)) AS user_seeks,
           --       SUM(CAST(W.user_scans AS INT)) AS user_scans,
           --       AVG(CAST(REPLACE(W.Avg_Estimated_Impact, ',', '.') AS DECIMAL(18, 2))) AS Avg_Estimated_Impact
           --FROM dbo.ResultProd AS W
           --GROUP BY
           --    Helper.RemoveAllSpaces(LTRIM(RTRIM(CAST(W.Create_Statement AS VARCHAR(1000))))),
           --    CAST(W.SchemaName AS VARCHAR(200)),
           --    CAST(W.TableName AS VARCHAR(200))
           ) AS X
      GROUP BY
          X.SchemaName,
          X.TableName,
          X.Create_Statement
     ),
     SegundoResumo
  AS (SELECT R.TableName,
             R.Create_Statement,
             R.avg_user_impact,
             R.user_scans,
             R.user_seeks,
             R.Avg_Estimated_Impact,
             CHARINDEX('(', R.Create_Statement, 0) AS Inicio,
             CHARINDEX(')', R.Create_Statement, 0) AS Termino
      FROM TodosIndices R
      WHERE R.avg_user_impact > 60
     ),
     TerceiroResumo
  AS (
     SELECT R.TableName,
            R.Create_Statement,
            Totaltabela = COUNT(R.TableName) OVER (PARTITION BY R.TableName),
            R.Inicio,
            R.Termino,
            R.avg_user_impact,
            R.user_scans,
            R.user_seeks,
            R.Avg_Estimated_Impact,
            ChavesIndices = RTRIM(LTRIM(REPLACE(
                                                   REPLACE(
                                                              (SUBSTRING(
                                                                            R.Create_Statement,
                                                                            (R.Inicio + 1),
                                                                            (R.Termino - (R.Inicio + 1))
                                                                        )
                                                              ),
                                                              '[',
                                                              SPACE(0)
                                                          ),
                                                   ']',
                                                   SPACE(0)
                                               )
                                       )
                                 ),
            ColunaIncluida = (REPLACE(
                                         REPLACE(
                                                    REPLACE(
                                                               IIF(PATINDEX('%Include%', R.Create_Statement) > 0,
                                                                   (SUBSTRING(
                                                                                 R.Create_Statement,
                                                                                 PATINDEX(
                                                                                             '%Include%',
                                                                                             R.Create_Statement
                                                                                         ),
                                                                                 1000
                                                                             )
                                                                   ),
                                                                   SPACE(0)),
                                                               'INCLUDE',
                                                               SPACE(0)
                                                           ),
                                                    '(',
                                                    SPACE(0)
                                                ),
                                         ')',
                                         SPACE(0)
                                     )
                             ),
            TamanhoIndice = LEN(R.Create_Statement)
     FROM SegundoResumo R
     WHERE R.Termino > 0
     ),
     QuartoResumo
  AS (SELECT R.TableName,
             R.Create_Statement,
             R.avg_user_impact,
             R.user_scans,
             R.user_seeks,
             R.Avg_Estimated_Impact,
             R.Totaltabela,
             R.Inicio,
             R.Termino,
             -- R.NomeIndice,
             ChavesIndices = RTRIM(LTRIM(R.ChavesIndices)),
             TemColunaIncluida = IIF(LEN(R.ColunaIncluida) > 0, 1, 0),
             RN = ROW_NUMBER() OVER (PARTITION BY R.TableName
                                     ORDER BY
                                         R.TamanhoIndice
                                    ),
             ColunaIncluida = LTRIM(RTRIM(R.ColunaIncluida)),
             R.TamanhoIndice
      FROM TerceiroResumo R
     ),
     QuintoResumo
  AS (SELECT R.TableName,
             R.Totaltabela,
             R.avg_user_impact,
             R.user_scans,
             R.user_seeks,
             R.Avg_Estimated_Impact,
             [DevoCriar] = CASE
                               WHEN R.Totaltabela = 1 THEN
                                   'SIM'
                           END,
             TamanhoChave = LEN(R.ChavesIndices),
             MaiorChave = MAX(LEN(R.ChavesIndices)) OVER (PARTITION BY R.TableName),
             -- R.Inicio,
             -- R.Termino,
             -- R.NomeIndice,
             R.ChavesIndices,
             [PrimeiraChave] = (
                               SELECT TOP 1
                                   T.Conteudo
                               FROM Sistema.fnSplitValues(R.ChavesIndices, ',') T
                               ),
             R.TemColunaIncluida,
             R.RN,
             ProximaChave = LEAD(R.ChavesIndices) OVER (PARTITION BY R.TableName
                                                        ORDER BY
                                                            R.RN
                                                       ),
             MesmaChave = CASE
                              WHEN EXISTS (
                                          SELECT 1
                                          FROM QuartoResumo Interno
                                          WHERE Interno.TableName = R.TableName
                                                AND Interno.ChavesIndices = R.ChavesIndices
                                                AND Interno.RN <> R.RN
                                          ) THEN
                                  1
                              ELSE
                                  0
                          END,
             ChaveContem = CASE
                               WHEN EXISTS (
                                           SELECT 1
                                           FROM QuartoResumo Interno
                                           WHERE Interno.TableName = R.TableName
                                                 AND Interno.ChavesIndices LIKE CONCAT('%', R.ChavesIndices, '%')
                                                 AND Interno.RN <> R.RN
                                           ) THEN
                                   1
                               ELSE
                                   0
                           END,
             R.ColunaIncluida,
             R.Create_Statement
      -- R.TamanhoIndice 
      FROM QuartoResumo R
     ),
     SextoResumo
  AS (SELECT R.TableName,
             R.Totaltabela,
             R.TamanhoChave,
             R.avg_user_impact,
             R.user_scans,
             R.user_seeks,
             R.Avg_Estimated_Impact,
             MelhorIndice = MAX(R.Avg_Estimated_Impact) OVER (PARTITION BY R.TableName,
                                                                           R.MesmaChave
                                                             ),
             R.MesmaChave,
             R.TemColunaIncluida,
             R.MaiorChave,
             R.RN,
             R.ChavesIndices,
             R.PrimeiraChave,
             R.ProximaChave,
             R.ColunaIncluida,
             DevoCriar = CASE
                             WHEN R.DevoCriar = 'SIM' THEN
                                 R.DevoCriar
                             WHEN R.Totaltabela = 2
                                  AND R.MesmaChave = 1
                                  AND R.RN = 2 THEN
                                 'SIM'
                         --WHEN R.Totaltabela = 2
                         --     AND R.MesmaChave = 0
                         --     AND R.MesmaChave = 0 THEN
                         --    'SIM'
                         END,
             Create_Statement = CONCAT(R.Create_Statement, ' WITH(ONLINE =ON)'),
             ExisteIndiceChave = (CASE
                                      WHEN EXISTS (
                                                  SELECT I.name,
                                                         IC.column_id,
                                                         C.name
                                                  FROM sys.indexes AS I
                                                       JOIN
                                                       sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                  AND I.index_id = IC.index_id
                                                       JOIN
                                                       sys.columns AS C ON I.object_id = C.object_id
                                                                           AND IC.column_id = C.column_id
                                                  WHERE I.object_id = OBJECT_ID(R.TableName)
                                                        AND C.name = R.PrimeiraChave
                                                        AND IC.is_included_column = 0
                                                  ) THEN
                                          1
                                      ELSE
                                          0
                                  END
                                 )
      FROM QuintoResumo R
     ),
     SetimoResumo
  AS (SELECT R.TableName,
             R.Totaltabela,
             R.TamanhoChave,
             R.avg_user_impact,
             R.user_scans,
             R.user_seeks,
             R.Avg_Estimated_Impact,
             R.MelhorIndice,
             R.MesmaChave,
             R.TemColunaIncluida,
             R.MaiorChave,
             R.RN,
             R.ChavesIndices,
             R.PrimeiraChave,
             R.ProximaChave,
             R.ColunaIncluida,
             R.ExisteIndiceChave,
             IndiceExistente = CASE
                                   WHEN R.ExisteIndiceChave = 1 THEN
                                   (
                                   SELECT TOP 1 I.name
                                   FROM sys.indexes AS I
                                        JOIN
                                        sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                   AND I.index_id = IC.index_id
                                        JOIN
                                        sys.columns AS C ON I.object_id = C.object_id
                                                            AND IC.column_id = C.column_id
                                   WHERE I.object_id = OBJECT_ID(R.TableName)
                                         AND C.name = R.PrimeiraChave
                                         AND IC.is_included_column = 0
										 AND IC.index_column_id =1
                                   )
                                   ELSE
                                       NULL
                               END,
             TotalIdxNoCluster = (
                                 SELECT COUNT(*)
                                 FROM sys.indexes AS I
                                 WHERE I.object_id = OBJECT_ID(R.TableName)
                                       AND I.type_desc <> 'CLUSTERED'
                                 ),
             DevoCriar = CASE
                             WHEN R.DevoCriar = 'SIM' THEN
                                 R.DevoCriar
                             WHEN R.Totaltabela = 3
                                  AND R.MesmaChave = 1
                                  AND R.Avg_Estimated_Impact = R.MelhorIndice THEN
                                 'SIM'
                         END,
             R.Create_Statement
      FROM SextoResumo R
     )
SELECT R.TableName,
       R.Totaltabela AS TT,
       --R.TamanhoChave,
       R.avg_user_impact,
       R.user_scans,
       R.user_seeks,
       R.Avg_Estimated_Impact,
       R.MelhorIndice,
       R.TotalIdxNoCluster,
       R.ExisteIndiceChave AS ExistsIDX,
       R.IndiceExistente,
       R.MesmaChave,
       R.TemColunaIncluida,
       R.PrimeiraChave,
       --R.ch,
       R.RN,
       R.ChavesIndices,
       -- R.PrimeiraChave,
       -- R.ProximaChave,
       R.ColunaIncluida,
       R.DevoCriar,
       R.Create_Statement,
       Script = CASE
                    WHEN R.ExisteIndiceChave = 1 THEN
                        CONCAT(
                                  'IF(  EXISTS( SELECT  1 FROM sys.indexes AS I JOIN sys.index_columns AS IC ON I.object_id = IC.object_id',
                                  SPACE(1),
                                  'AND I.index_id = IC.index_id JOIN sys.columns AS C ON I.object_id = C.object_id AND IC.column_id = C.column_id',
                                  SPACE(1),
                                  'WHERE I.object_id = OBJECT_ID(''',
                                  R.TableName,
                                  ''')',
                                  SPACE(1),
                                  'AND I.type = 2 AND IC.index_column_id =1 AND C.name =''',
                                  R.PrimeiraChave,
                                  ''')) 
		  BEGIN',
                                  SPACE(1),
                                  CONCAT(
                                            'Drop index',
                                            SPACE(1),
                                            R.IndiceExistente,
                                            SPACE(1),
                                            ' ON',
                                            SPACE(1),
                                            R.TableName
                                        ),
                                  SPACE(1),
                                  R.Create_Statement,
                                  ' END'
                              )
                    ELSE
                        CONCAT(
                                  'IF( NOT EXISTS( SELECT  1 FROM sys.indexes AS I JOIN sys.index_columns AS IC ON I.object_id = IC.object_id',
                                  SPACE(1),
                                  'AND I.index_id = IC.index_id JOIN sys.columns AS C ON I.object_id = C.object_id AND IC.column_id = C.column_id',
                                  SPACE(1),
                                  'WHERE I.object_id = OBJECT_ID(''',
                                  R.TableName,
                                  ''')',
                                  SPACE(1),
                                  'AND I.type = 2 AND IC.index_column_id =1 AND C.name =''',
                                  R.PrimeiraChave,
                                  ''')) 
		  BEGIN',
                                  SPACE(1),
                                  R.Create_Statement,
                                  ' END'
                              )
                END
FROM SetimoResumo R
WHERE
    --R.TableName NOT IN ( 'LiquidacoesCentroCustos')
    --AND 
    --R.DevoCriar = 'SIM'

    --AND R.ExisteIndiceChave =0
    R.Totaltabela = 2
--AND R.ChavesIquais =1
-- AND R.TableName = 'ProcessosAndamentosDocumentos'

--AND R.Totaltabela = 2
ORDER BY
    R.Totaltabela,
    R.TableName;

	