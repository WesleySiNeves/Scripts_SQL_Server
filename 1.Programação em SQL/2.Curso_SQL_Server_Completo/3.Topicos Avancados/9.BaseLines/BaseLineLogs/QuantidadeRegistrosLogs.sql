SELECT C.Configuracao,
       C.Valor,
	   Q.*
FROM Sistema.Configuracoes AS C
OUTER APPLY (
SELECT ' Log.Logs' AS Tabela, COUNT(*) AS Total FROM  Log.Logs AS L WITH (NOLOCK)
UNION
SELECT ' Log.LogsDetalhes' AS Tabela, COUNT(*) AS Total FROM  Log.LogsDetalhes AS LD  WITH (NOLOCK)
UNION
SELECT ' Expurgo.Logs' AS Tabela, COUNT(*) AS Total FROM  Expurgo.Logs AS L  WITH (NOLOCK)
UNION
SELECT ' Expurgo.LogsDetalhes' AS Tabela, COUNT(*) AS Total FROM  Expurgo.LogsDetalhes AS L  WITH (NOLOCK)

)AS Q
WHERE C.Configuracao = 'ExecutouMigracaoLogsJson';
