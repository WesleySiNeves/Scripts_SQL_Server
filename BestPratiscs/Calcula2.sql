

--  SELECT Helper.RemoveAllSpaces('CREATE INDEX [IDX_DespesaPagamentosEventosIdPagamento] ON [Despesa].[PagamentosEventos]     ([IdPagamento])')


;WITH TodosIndices1
   AS (SELECT W.SchemaName,
              W.TableName,
              Helper.RemoveAllSpaces(Helper.RemoveAllSpaces(W.Create_Statement)) Create_Statement
       FROM dbo.Resultado AS W
      ),
      TodosIndices
   AS (SELECT R.SchemaName,
              R.TableName,
              Create_Statement = Helper.RemoveAllSpaces(R.Create_Statement)
       FROM TodosIndices1 R
      ),
      PrimeiroResumo
   AS (SELECT R.SchemaName,
              R.TableName,
              R.Create_Statement,
              TU.TotalTabela
       FROM TodosIndices R
            OUTER APPLY (
                        SELECT X.SchemaName,
                               X.TableName,
                               COUNT(*) AS TotalTabela
                        FROM (
                             SELECT DISTINCT
                                 DTO.SchemaName,
                                 DTO.TableName,
                                 Helper.RemoveAllSpaces(DTO.Create_Statement) Create_Statement
                             FROM TodosIndices AS DTO
                             WHERE DTO.SchemaName = R.SchemaName
                                   AND DTO.TableName = R.TableName
                             ) X
                        GROUP BY
                            X.SchemaName,
                            X.TableName
                        ) AS TU
      ),
      DelimitaInicioTermino
   AS (
      SELECT P1.*,
             (CHARINDEX('(', P1.Create_Statement, 0)) AS Inicio,
             (CHARINDEX(')', P1.Create_Statement, (CHARINDEX('(', P1.Create_Statement, 0)))) AS Termino,
             NomeIndice = SUBSTRING(
                                       P1.Create_Statement,
                                       (CHARINDEX('[', P1.Create_Statement, 0) + 1),
                                       ((CHARINDEX(']', P1.Create_Statement, 0)
                                         - (CHARINDEX('[', P1.Create_Statement, 0) + 1)
                                        )
                                       )
                                   )
      FROM PrimeiroResumo P1
      --WHERE P1.TotalTabela < 4
      ),
      BuscaChave
   AS (
      SELECT R.SchemaName,
             RNIDX = ROW_NUMBER() OVER (PARTITION BY R.SchemaName,
                                                     R.TableName
                                        ORDER BY
                                            R.Create_Statement
                                       ),
             R.TableName,
             R.Create_Statement,
             R.Inicio,
             R.Termino,
             --NomeIndice =
             ChavesIndices = Helper.ufnRemoveEspacosEntrePalavras(SUBSTRING(
                                                                               R.Create_Statement,
                                                                               (R.Inicio + 1),
                                                                               (R.Termino - (R.Inicio + 1))
                                                                           )
                                                                 ),
             ColunaIncluida = Helper.ufnRemoveEspacosEntrePalavras(REPLACE(
                                                                              REPLACE(
                                                                                         REPLACE(
                                                                                                    IIF(
                                                                                                        PATINDEX(
                                                                                                                    '%Include%',
                                                                                                                    R.Create_Statement
                                                                                                                ) > 0,
                                                                                                        (SUBSTRING(
                                                                                                                      R.Create_Statement,
                                                                                                                      PATINDEX(
                                                                                                                                  '%Include%',
                                                                                                                                  R.Create_Statement
                                                                                                                              ),
                                                                                                                      1000
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
                                                                  ),
             TamanhoIndice = LEN(R.Create_Statement),
             R.TotalTabela
      FROM DelimitaInicioTermino R
      ),
      SegundoResumo
   AS (
      SELECT R.SchemaName,
             R.TableName,
             R.Create_Statement,
             R.ChavesIndices,
             TamanhoChaveIndice = LEN(R.ChavesIndices),
             [Mesmachave] = CASE
                                WHEN EXISTS (
                                            SELECT B.TableName,
                                                   B.ChavesIndices,
                                                   Total = COUNT(*)
                                            FROM BuscaChave B
                                            WHERE Helper.ufnRemoveEspacosEntrePalavras(B.TableName) = Helper.ufnRemoveEspacosEntrePalavras(R.TableName)
                                                  AND Helper.ufnRemoveEspacosEntrePalavras(B.ChavesIndices) = Helper.ufnRemoveEspacosEntrePalavras(R.ChavesIndices)
                                            GROUP BY
                                                B.TableName,
                                                B.ChavesIndices
                                            HAVING COUNT(*) > 1
                                            ) THEN
                                    1
                                ELSE
                                    0
                            END,
             ColunaIncluida = IIF(LEN(LTRIM(RTRIM(R.ColunaIncluida))) > 0, R.ColunaIncluida, NULL),
             R.RNIDX,
             [PrimeiraChave] = (
                               SELECT TOP 1
                                   SS.Conteudo
                               FROM Sistema.fnSplitValues(R.ChavesIndices, ',') AS SS
                               ),
             R.TamanhoIndice,
             R.TotalTabela
      FROM BuscaChave R
      ),
      TerceiroResumo
   AS (SELECT R.*,
              TamanhoColunaIncluida = (LEN(LTRIM(RTRIM(R.ColunaIncluida)))),
              Id = ROW_NUMBER() OVER (PARTITION BY R.SchemaName,
                                                   R.TableName
                                      ORDER BY
                                          (LEN(LTRIM(RTRIM(R.ColunaIncluida)))) ASC
                                     ),
              MaiorChave = MAX(R.ChavesIndices) OVER (PARTITION BY R.SchemaName,
                                                                   R.TableName
                                                      ORDER BY
                                                          CAST(R.ChavesIndices AS VARCHAR(800)) DESC
                                                     ),
              ChaveOutroIndice = LEAD(R.ChavesIndices) OVER (PARTITION BY R.SchemaName,
                                                                          R.TableName
                                                             ORDER BY
                                                                 R.RNIDX
                                                            )
       FROM SegundoResumo R
      ),
      QuartoResumo
   AS (
      SELECT *,
             MaiorColunaIncluida = MAX(R.TamanhoColunaIncluida) OVER (PARTITION BY R.SchemaName,
                                                                                   R.TableName
                                                                     ),
             MaiorId = MAX(R.Id) OVER (PARTITION BY R.SchemaName,
                                                    R.TableName
                                      ),
             [IndiceCriar] = CASE
                                 WHEN R.TotalTabela = 1 THEN
                                     'SIM'
                                 WHEN R.TotalTabela = 2
                                      AND R.Mesmachave = 1
                                      AND R.RNIDX = 2 THEN
                                     'SIM'
                             END,
             [PrimeiroCoSeg] = CASE
                                   WHEN R.ChaveOutroIndice IS NULL THEN
                                       0
                                   WHEN PATINDEX(
                                                    CONCAT(
                                                              '%',
                                                              REPLACE(REPLACE(R.PrimeiraChave, ']', ''), '[', ''),
                                                              '%'
                                                          ),
                                                    REPLACE(REPLACE(R.ChaveOutroIndice, ']', ''), '[', '')
                                                ) > 0 THEN
                                       1
                                   ELSE
                                       0
                               END
      FROM TerceiroResumo R
      ),
      ResultA
   AS (
      SELECT R.TotalTabela,
             R.MaiorId,
             IndiceCriar = CASE
                               WHEN R.IndiceCriar = 'SIM' THEN
                                   R.IndiceCriar
                               WHEN R.TotalTabela = 2
                                    AND R.Mesmachave = 0
                                    AND R.PrimeiroCoSeg = 0 THEN
                                   'SIM'
                               WHEN R.TotalTabela = 3
                                    AND R.Mesmachave = 1
                                    AND R.ColunaIncluida IS NOT NULL
                                    AND R.Id = R.MaiorId THEN
                                   'SIM'
                            WHEN R.TotalTabela =3 AND R.IndiceCriar IS NULL AND R.Mesmachave =0  AND R.RNIDX = R.MaiorId THEN 'SIM'
                           -- WHEN r.TotalTabela >=4 AND R.ColunaIncluida IS NOT NULL THEN 'SIM'

                           END,
             R.TamanhoIndice,
             R.PrimeiraChave,
             R.RNIDX,
             R.TamanhoColunaIncluida,
             R.MaiorColunaIncluida,
             R.ColunaIncluida,
             R.Mesmachave,
             R.TamanhoChaveIndice,
             R.ChavesIndices,
             R.Create_Statement,
             R.TableName,
             R.Id,
             R.SchemaName,
             R.MaiorChave,
             R.ChaveOutroIndice,
             R.PrimeiroCoSeg
      FROM QuartoResumo R
      WHERE R.TableName NOT IN ( 'LiquidacoesCentroCustos', 'ProcessamentoArquivosRetornosItens',
                                 'LancamentosCertidoes', 'Movimentos', 'Dotacoes', 'Liquidacoes','CapitaisSociais','PessoasSispad'
                               )
      ),
      ResultB
   AS (SELECT R.TotalTabela,
              R.MaiorId,
              R.TamanhoIndice,
              R.PrimeiraChave,
              R.RNIDX,
              R.TamanhoColunaIncluida,
              R.MaiorColunaIncluida,
              R.ColunaIncluida,
              R.Mesmachave,
              R.TamanhoChaveIndice,
              R.ChavesIndices,
              R.Create_Statement,
              R.TableName,
              R.Id,
              R.SchemaName,
              R.MaiorChave,
              R.ChaveOutroIndice,
              R.PrimeiroCoSeg,
              IndiceCriar = CASE
                                WHEN R.IndiceCriar = 'SIM' THEN
                                    'SIM'
                                WHEN R.IndiceCriar IS NULL AND R.TotalTabela = 3
                                     AND R.RNIDX = R.MaiorId THEN
                                    'SIM' 
								WHEN R.IndiceCriar IS NULL AND R.TotalTabela = 4
                                     AND R.ColunaIncluida IS NOT NULL AND R.Id =R.MaiorId THEN
                                    'SIM' 
                            END
       FROM ResultA R
      ),
      ResultC
   AS (SELECT
           --R.SchemaName,
           R.TableName,
           R.TotalTabela,
           R.RNIDX,
           R.Id,
           R.MaiorId,
           R.Mesmachave,
           R.ChavesIndices,
           R.PrimeiraChave,
           R.MaiorChave,
           R.ColunaIncluida,
           R.TamanhoColunaIncluida,
           R.MaiorColunaIncluida,
          -- R.ChaveOutroIndice,
           IndiceCriar = CASE WHEN IndiceCriar ='SIM' THEN 'SIM' 
		   
		   END,
           R.TamanhoChaveIndice,
           R.PrimeiroCoSeg,
           R.Create_Statement
       FROM ResultB R
      )
SELECT *
FROM ResultC R
--WHERE R.TotalTabela = 5
-- AND R.ColunaIncluida IS NOT NULL AND R.ChavesIndices = R.MaiorChave
--AND R.Id = R.MaiorId
WHERE R.IndiceCriar ='SIM'
ORDER BY
    R.TotalTabela,
    R.TableName,
    R.RNIDX;



	SELECT * FROM dbo.Resultado AS R
	WHERE R.Create_Statement  LIKE '%IDX_DespesaAdiantamentosIdEmpenho%'