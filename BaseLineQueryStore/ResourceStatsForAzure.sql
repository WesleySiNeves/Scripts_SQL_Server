/* ==================================================================
--Data: 20/11/2018 
--Autor :Wesley Neves
--Observa��o: Use a seguinte consulta para identificar os dados e uso de e/s de log. Se a e/s de dados
 ou de log estiver acima de 80%, isso significa que os usu�rios usaram a e/s dispon�vel para a camada d
e servi�o do banco de dados SQL
 
 Se tiver sido atingido o limite de e/s, voc� tem duas op��es:
Op��o 1: Atualizar o tamanho de computa��o ou camada de servi�o
Op��o 2: Identificar e ajustar as consultas que consomem a maioria das e/s.
-- ==================================================================
*/

SELECT TOP 100 end_time, avg_data_io_percent, avg_log_write_percent
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC;