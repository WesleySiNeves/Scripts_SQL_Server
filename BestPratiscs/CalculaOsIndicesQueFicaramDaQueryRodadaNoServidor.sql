IF (OBJECT_ID('TEMPDB..#DefinicaoIndex') IS NOT NULL)
    DROP TABLE #DefinicaoIndex;


IF (OBJECT_ID('TEMPDB..#TabelasEChavesCriadas') IS NOT NULL)
    DROP TABLE #TabelasEChavesCriadas;

CREATE TABLE #TabelasEChavesCriadas (
                                    [TableName] NVARCHAR(255),
                                    ColunaChave VARCHAR(255)
                                    );

CREATE TABLE #DefinicaoIndex (
                             [TableName]             NVARCHAR(255),
                             [SchemaName]            NVARCHAR(255),
                             [Comando]               VARCHAR(1000),
                             [TamanhoIndice]         INT,
                             [MenorTamanho]          INT,
                             [MaiorTamanho]          INT,
                             [Chave]                 VARCHAR(8000),
                             [ColunaIncluida]        VARCHAR(8000),
                             [TamanhoColunaIncluida] INT,
                             [Mesmachave]            INT,
                             [QuantidadeTabela]      INT,
                             [Agregador]             VARCHAR(MAX),
                             [NovoConteudoInclude]   VARCHAR(MAX),
                             [IndiceEscolhido]       VARCHAR(3)
                             );


;WITH Dados
   AS (SELECT DISTINCT 
           C.TableName,
           C.SchemaName,
           CAST(C.Create_Statement AS VARCHAR(max)) AS Comando
       FROM dbo.DadosTemporariosOPENROWSET2 C
      ),
      BuscaChaves
   AS (
      SELECT R.SchemaName,
			 RN = ROW_NUMBER() OVER(ORDER BY R.TableName),
             R.TableName,
             R.Comando,
             LEN(R.Comando) AS TamanhoIndice,
             CHARINDEX('(', R.Comando, 0) AS Inicio,
             CHARINDEX(')', R.Comando, CHARINDEX('(', R.Comando, 0)) AS Termino,
             (SUBSTRING(
                           R.Comando,
                           (CHARINDEX('(', R.Comando, 0)) + 1,
                           (CHARINDEX(')', R.Comando, CHARINDEX('(', R.Comando, 0) + 1) - CHARINDEX('(', R.Comando, 0)
                            - 1
                           )
                       )
             ) AS Chave,
      ColunaIncluida = REPLACE(
                                  REPLACE(
                                             REPLACE(
                                                        IIF(PATINDEX('%Include%', R.Comando) > 0,
                                                            (SUBSTRING(
                                                                          R.Comando,
                                                                          PATINDEX('%Include%', R.Comando),
                                                                          300
                                                                      )
                                                            ),
                                                            ''),
                                                        'INCLUDE',
                                                        ''
                                                    ),
                                             '(',
                                             ''
                                         ),
                                  ')',
                                  ''
                              )
      FROM Dados R
      ),
	  Filtro AS (
	  SELECT *
FROM BuscaChaves
WHERE BuscaChaves.RN < 150

	  ),

 

      AlgoritimoDeBusca
   AS (
      SELECT R.TableName,
			 R.SchemaName,
             R.Comando,
             R.TamanhoIndice,
             R.Inicio,
             R.Termino,
             MenorTamanho = MIN(R.TamanhoIndice) OVER (PARTITION BY R.TableName),
             MaiorTamanho = MAX(R.TamanhoIndice) OVER (PARTITION BY R.TableName),
             R.Chave,
             R.ColunaIncluida,
             [TamanhoColunaIncluida] = LEN(R.ColunaIncluida),
             [Mesmachave] = CASE
                                WHEN EXISTS (
                                            SELECT B.TableName,
                                                   B.Chave,
                                                   Total = COUNT(*)
                                            FROM Filtro B
                                            WHERE Helper.ufnRemoveEspacosEntrePalavras(B.TableName) = Helper.ufnRemoveEspacosEntrePalavras(R.TableName)
                                                  AND Helper.ufnRemoveEspacosEntrePalavras(B.Chave) = Helper.ufnRemoveEspacosEntrePalavras(R.Chave)
                                            GROUP BY
                                                B.TableName,
                                                B.Chave
                                            HAVING COUNT(*) > 1
                                            ) THEN
                                    1
                                ELSE
                                    0
                            END,
             TR.Total AS QuantidadeTabela
      FROM Filtro R
           OUTER APPLY (
                       SELECT X.TableName,
                              COUNT(*) AS Total
                       FROM (
                            SELECT DISTINCT
                                C.TableName,
                                CAST(C.Create_Statement AS VARCHAR(1000)) AS Comando
                            FROM dbo.DadosTemporariosOPENROWSET C
                            ) X
                       WHERE CAST(X.TableName AS VARCHAR(250)) = CAST(R.TableName AS VARCHAR(250))
                       GROUP BY
                           X.TableName
                       ) TR
					   WHERE TR.Total IS NOT NULL
      ),
      AgregadorColunasIncluidas
   AS (SELECT *,
              Agregador = (
                          SELECT string_agg(X.Conteudo, ',')
                          FROM (
                               SELECT DISTINCT
                                   LE.Conteudo
                               FROM (
                                    SELECT B2.ColunaIncluida
                                    FROM BuscaChaves B2
                                    WHERE B2.TableName = R.TableName
                                    ) AS T
                                    CROSS APPLY (
                                                SELECT V.Conteudo
                                                FROM Sistema.fnSplitValues(T.ColunaIncluida, ',') V
                                                ) LE
                               ) X
                          )
       FROM AlgoritimoDeBusca R
      ),
	Final 
   AS (
      SELECT R.TableName,
			 R.SchemaName,
             R.Comando,
             R.TamanhoIndice,
             R.MenorTamanho,
             R.MaiorTamanho,
             R.Chave,
             R.ColunaIncluida,
             R.[TamanhoColunaIncluida],
             R.Mesmachave,
             R.QuantidadeTabela,
             R.Agregador,
             NovoConteudoInclude = CONCAT(
                                             REPLACE(
                                                        R.Comando,
                                                        SUBSTRING(
                                                                     R.Comando,
                                                                     CHARINDEX(
                                                                                  '(',
                                                                                  R.Comando,
                                                                                  PATINDEX('%INCLUDE%', R.Comando)
                                                                              ),
                                                                     500
                                                                 ),
                                                        ''
                                                    ),
                                             '(',
                                             R.Agregador,
                                             ')'
                                         ),
             IndiceEscolhido = CASE
                                   WHEN R.QuantidadeTabela = 1 THEN
                                       'SIM'
                                   --WHEN R.QuantidadeTabela = 2
                                   --     AND R.Mesmachave = 0 THEN
                                   --    'SIM'
                                   --WHEN R.QuantidadeTabela = 2
                                   --     AND R.Mesmachave = 1
                                   --     AND R.TamanhoIndice = R.MaiorTamanho THEN
                                   --    'SIM'
                                   --WHEN R.QuantidadeTabela > 2
                                   --     AND R.Mesmachave = 1
                                   --     AND R.TamanhoIndice = R.MaiorTamanho
                                   --     AND LEN(R.ColunaIncluida) > 0 THEN
                                   --    'SIM'
                               END
      FROM AgregadorColunasIncluidas R
      )
	  SELECT * FROM Final