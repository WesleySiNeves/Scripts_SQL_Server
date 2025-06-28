/* ==================================================================
--Data: 20/11/2018 
--Autor :Wesley Neves
--Observação: Use a seguinte consulta para identificar os dados e uso de e/s de log. Se a e/s de dados
 ou de log estiver acima de 80%, isso significa que os usuários usaram a e/s disponível para a camada d
e serviço do banco de dados SQL
 
 Se tiver sido atingido o limite de e/s, você tem duas opções:
Opção 1: Atualizar o tamanho de computação ou camada de serviço
Opção 2: Identificar e ajustar as consultas que consomem a maioria das e/s.
-- ==================================================================
*/

SELECT TOP 100 end_time, avg_data_io_percent, avg_log_write_percent
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC;