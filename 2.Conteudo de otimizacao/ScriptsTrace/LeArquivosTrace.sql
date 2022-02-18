

DECLARE @Arquivo VARCHAR(MAX) ='F:\1.Sql Server Tunning\SISPAD\Busca Processos SispaD\BuscaProcessosAntesRefatoração.trc';

SELECT  
		--TextData = SUBSTRING(TextData,0, CHARINDEX('  ',TextData,0)),
		--[Maquina] = ServerName ,
--[Duracao em Ms] = Duration,
        [Duracao em Seg] = DATEDIFF(SECOND, StartTime, EndTime) ,
        [Duracao em Minutos] = CONVERT(CHAR(8), DATEADD(ss,
                                                        DATEDIFF(ss, StartTime,
                                                              EndTime),
                                                        CAST(0 AS DATETIME)), 108) ,
        [Total Leituras] = Reads ,
        [Total Leituras MB] = CAST(( ( Reads * 8 ) / 1024 ) AS VARCHAR(10)),
        [Total Leituras GB] = CONCAT(CAST(( ( ( Reads * 8 ) / 1024 )
                                                 / 1024 ) AS VARCHAR(10)),
                                          ' GB') ,
        [Total Escrita] = Writes ,
        [Total Escrita MB] = CONCAT(CAST(( ( Writes * 8 ) / 1024 ) AS VARCHAR(10)),
                                           ' MB') ,
        CPU_Segundos = cast(CPU/1000.0 as Dec(10,1)) ,
        [Linhas Afetadas] = RowCounts
    FROM :: fn_trace_gettable(@Arquivo,
                              DEFAULT) AS FT
							  WHERE TextData IS NOT NULL;






SELECT
      --TextData = SUBSTRING(TextData,0, CHARINDEX('  ',TextData,0)),
	   --[Maquina] = ServerName ,
         
        [Duracao em Seg] = DATEDIFF(SECOND, StartTime, EndTime) ,
        [Duracao em Minutos] = CONVERT(CHAR(8), DATEADD(ss,
                                                        DATEDIFF(ss, StartTime,
                                                              EndTime),
                                                        CAST(0 AS DATETIME)), 108) ,
        [Total Leituras] = Reads ,
        [Total Leituras MB] = CAST(( ( Reads * 8 ) / 1024 ) AS VARCHAR(10)),
        [Total Leituras GB] = CONCAT(CAST(( ( ( Reads * 8 ) / 1024 )
                                                 / 1024 ) AS VARCHAR(10)),
                                          ' GB') ,
        [Total Escrita] = Writes ,
        [Total Escrita MB] = CONCAT(CAST(( ( Writes * 8 ) / 1024 ) AS VARCHAR(10)),
                                           ' MB') ,
        CPU_Segundos = cast(CPU/1000.0 as Dec(10,1)) ,
        [Linhas Afetadas] = RowCounts
    FROM :: fn_trace_gettable('C:\Users\wesley.neves\Desktop\Refatoração Balanco Financeiro\Documento\2.BalancoFinanceiroMaquinaAnaExercicioCompleto.trc',
                              DEFAULT) AS FT
							  WHERE TextData IS NOT NULL;


SELECT  
		--TextData = SUBSTRING(TextData,0, CHARINDEX('  ',TextData,0)),
	--[Maquina] = ServerName ,
--[Duracao em Ms] = Duration,
        [Duracao em Seg] = DATEDIFF(SECOND, StartTime, EndTime) ,
        [Duracao em Minutos] = CONVERT(CHAR(8), DATEADD(ss,
                                                        DATEDIFF(ss, StartTime,
                                                              EndTime),
                                                        CAST(0 AS DATETIME)), 108) ,
        [Total Leituras] = Reads ,
        [Total Leituras MB] = CAST(( ( Reads * 8 ) / 1024 ) AS VARCHAR(10)),
        [Total Leituras GB] = CONCAT(CAST(( ( ( Reads * 8 ) / 1024 )
                                                 / 1024 ) AS VARCHAR(10)),
                                          ' GB') ,
        [Total Escrita] = Writes ,
        [Total Escrita MB] = CONCAT(CAST(( ( Writes * 8 ) / 1024 ) AS VARCHAR(10)),
                                           ' MB') ,
        CPU_Segundos = cast(CPU/1000.0 as Dec(10,1)) ,
        [Linhas Afetadas] = RowCounts
    FROM :: fn_trace_gettable('C:\Users\wesley.neves\Desktop\Refatoração Balanco Financeiro\Documento\BalancoAnoTodoPublicado.trc',
                              DEFAULT) AS FT
							  WHERE TextData IS NOT NULL;


SELECT  
		--TextData = SUBSTRING(TextData,0, CHARINDEX('  ',TextData,0)),
	--[Maquina] = ServerName ,
--[Duracao em Ms] = Duration,
        [Duracao em Seg] = DATEDIFF(SECOND, StartTime, EndTime) ,
        [Duracao em Minutos] = CONVERT(CHAR(8), DATEADD(ss,
                                                        DATEDIFF(ss, StartTime,
                                                              EndTime),
                                                        CAST(0 AS DATETIME)), 108) ,
        [Total Leituras] = Reads ,
        [Total Leituras MB] = CAST(( ( Reads * 8 ) / 1024 ) AS VARCHAR(10)),
        [Total Leituras GB] = CONCAT(CAST(( ( ( Reads * 8 ) / 1024 )
                                                 / 1024 ) AS VARCHAR(10)),
                                          ' GB') ,
        [Total Escrita] = Writes ,
        [Total Escrita MB] = CONCAT(CAST(( ( Writes * 8 ) / 1024 ) AS VARCHAR(10)),
                                           ' MB') ,
        CPU_Segundos = cast(CPU/1000.0 as Dec(10,1)) ,
        [Linhas Afetadas] = RowCounts
    FROM :: fn_trace_gettable('C:\Users\wesley.neves\Desktop\Refatoração Balanco Financeiro\Documento\BalancoAnoTodoPublicadoVersaoFinal.trc',
                              DEFAULT) AS FT
							  WHERE TextData IS NOT NULL;
