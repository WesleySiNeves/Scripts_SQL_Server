--SELECT MAX(N) +1 FROM dbo.Nums AS N

--DECLARE @inicio INT =141801 ,@termino INT  =141840;

--WHILE (@inicio <= @termino)
--BEGIN
--INSERT INTO dbo.Nums
--        ( n )VALUES ( @inicio  )
		
--		SELECT @inicio +=1;		
--END

		
		 

/*https://msdn.microsoft.com/pt-br/library/ms188917.aspx*/


--TSQL2012	Nums	CLUSTERED INDEX	228	141290	99,5059179639239
--TSQL2012	Nums	CLUSTERED INDEX	228	141350	99,5481838398814

/*Verifica quantas paginas estão alocadas para uma tabela*/
SELECT [Banco] = DB_NAME(database_id) ,
        [Tabela] = OBJECT_NAME(object_id) ,
        [Tipo de Indice] = index_type_desc ,
        [Qauntidade Paginas Alocadas] = page_count ,
        [Quantidade Linhas] = record_count ,
        [% de registros dentro da ultima pagina]= avg_page_space_used_in_percent 
		--/*Número de fragmentos no nível folha de uma unidade de alocação IN_ROW_DATA. */
		--fragment_count,
  --      alloc_unit_type_desc ,
  --      [Nivel] = CASE WHEN index_level = 0 THEN 'Nivel Folha'
  --                     ELSE 'Nonleaf'
  --                END ,
		--/*
		--Fragmentação lógica para índices ou fragmentação de extensão para heaps na unidade de alocação IN_ROW_DATA.
		--O valor é medido como uma porcentagem e leva em consideração vários arquivos.
		-- Para definições de fragmentação lógica e de extensão, consulte Comentários.
		--0 para unidades de alocação LOB_DATA e ROW_OVERFLOW_DATA.
		--NULL para heaps quando modo = SAMPLED.
		--*/
  --      avg_fragmentation_in_percent ,
  --      avg_fragment_size_in_pages ,
  --      min_record_size_in_bytes ,
  --      max_record_size_in_bytes ,
  --      avg_record_size_in_bytes
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL,
                                        'DETAILED')
    ORDER BY [Qauntidade Paginas Alocadas] DESC;


--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;