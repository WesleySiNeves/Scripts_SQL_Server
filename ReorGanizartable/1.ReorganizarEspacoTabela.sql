SELECT physical.alloc_unit_type_desc,
       physical.page_count,
	   --physical.index_type_desc,
	   physical.index_level,
       physical.avg_page_space_used_in_percent,
	   physical.avg_fragmentation_in_percent,
       record_count,
	   TotalPaginas =  SUM(physical.page_count) OVER(),
	   TotalLinhas = SUM(physical.record_count) OVER(),
	   TamanhoEmMB = FORMAT( CAST((( CAST(SUM(physical.page_count) OVER() AS DECIMAL(18,2)) * 8 ) / 1024) AS DECIMAL(18,2)),'N','pt-BR')
FROM sys.dm_db_index_physical_stats
(DB_ID('Teste'), OBJECT_ID('[dbo].[Lancamentos]'), NULL, NULL, 'Detailed') AS physical
WHERE physical.index_type_desc ='CLUSTERED INDEX'
ORDER BY page_count




/*

alloc_unit_type_desc	page_count	index_level	avg_page_space_used_in_percent	avg_fragmentation_in_percent	record_count	TotalPaginas TotalLinhas	TamanhoEmMB
IN_ROW_DATA				1			2			23,6224363726217				0								58				13949			1013946		108,98
IN_ROW_DATA				58			1			97,6146775389177				6,89655172413793				13890			13949			1013946		108,98
IN_ROW_DATA				13890		0			98,7070051890289				0,0215982721382289				999998			13949			1013946		108,98
*/

/*########################
# OBS: Definição da tabela
*/

/*
idLancamento	uniqueidentifier	not null
idContaBancaria	uniqueidentifier	not null
Historico	varchar(100)	not null
NumeroLancamento	int	not null
Data	datetime	not null
Valor	decimal(18, 2)	null
Credito	bit	not null
*/


/*########################
# OBS: Alteracao do tipo do campo
*/



ALTER TABLE dbo.Lancamentos ALTER COLUMN NumeroLancamento BIGINT NOT NULL

/*########################
# OBS: Diferença no que ocorreu na tabela apos a modificacao
*/
SELECT FORMAT( CAST((( CAST( 13949 AS DECIMAL(18,2)) * 8 ) / 1024) AS DECIMAL(18,2)),'N','pt-BR')

SELECT FORMAT( CAST((( CAST( 14349 AS DECIMAL(18,2)) * 8 ) / 1024) AS DECIMAL(18,2)),'N','pt-BR')


/*########################
# OBS: Voltar o que era
*/
--ALTER TABLE dbo.Lancamentos ALTER COLUMN NumeroLancamento INT NOT NULL


--Desalocando Espacos nao usados
DBCC CLEANTABLE (Teste, 'dbo.Lancamentos');

ALTER TABLE dbo.Lancamentos REBUILD