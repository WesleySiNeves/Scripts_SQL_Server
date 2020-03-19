DECLARE @Waits AS TABLE ( ordem INT, Nome VARCHAR(30));
INSERT INTO @Waits ( Ordem,
                   Nome
                   )
VALUES
 ( 1,'LCK_M_'),(2,'ASYNC_NETWORK'),(3,'SOS_SCHEDULER_YIELD')
 ;

SELECT W.ordem,
        wait.*
FROM sys.dm_os_wait_stats wait
     JOIN
     (
     SELECT W.ordem, W.Nome
     FROM @Waits AS W
     ) W ON wait.wait_type LIKE CONCAT(W.Nome, '%') COLLATE DATABASE_DEFAULT
WHERE wait.wait_time_ms > 0
ORDER BY
   W.ordem,   wait.wait_time_ms DESC;


/* ==================================================================
--Data: 05/10/2018 
--Autor :Wesley Neves
--Observação: Scrip Abaixo Cria uma estrategia de monitoramento de waits
 
-- ==================================================================
*/


DROP TABLE IF EXISTS MonitorarWaits.WaitsMonitorados;
DROP TABLE IF EXISTS MonitorarWaits.WaitAcoes;

CREATE TABLE MonitorarWaits.WaitsMonitorados (
                                             Id               SMALLINT IDENTITY(1, 1) PRIMARY KEY,
                                             Wait_type        VARCHAR(30),
                                             MotivoOcorrencia VARCHAR(300)
                                             );

CREATE TABLE MonitorarWaits.WaitAcoes (
                                      Id     SMALLINT IDENTITY(1, 1),
                                      IdWait SMALLINT,
                                      Dica   VARCHAR(100)
                                      );

INSERT INTO MonitorarWaits.WaitsMonitorados (
                         
                           Wait_type,
                           MotivoOcorrencia
                           )
VALUES (
        'ASYNC_NETWORK_IO', -- Wait_type - varchar(30)
        'Esse tipo de espera indica que o SQL Server está respondendo para a aplicação, porém a mesma não está conseguindo processar no tempo correto.'  -- MotivoOcorrencia - varchar(100)
       )



INSERT INTO MonitorarWaits.WaitAcoes (
                      
                       IdWait,
                       Dica
                       )
VALUES (
        1, -- IdWait - smallint
        'https://www.sqlskills.com/help/waits/async_network_io/' -- Dica - varchar(100)
       )


	   
CREATE TABLE MonitorarWaits.AnalisesWait (
                                         Id                    INT IDENTITY(1, 1),
                                         [DataAnalise]         SMALLDATETIME,
                                         [wait_type]           VARCHAR(60),
                                         [waiting_tasks_count] BIGINT,
                                         [wait_time_ms]        BIGINT,
                                         [max_wait_time_ms]    BIGINT,
                                         [signal_wait_time]    BIGINT,
                                         CONSTRAINT PKAnaliseWait
                                             PRIMARY KEY (DataAnalise, Id)
                                         );

/* ==================================================================
--Data: 05/10/2018 
--Autor :Wesley Neves
--Observação: Aqui temos os Scripts Completos
 
-- ==================================================================
*/

GO


;WITH Dados
  AS ( SELECT R.wait_type,
       SUM(R.waiting_tasks_count) waiting_tasks_count,
       SUM(R.wait_time_ms) wait_time_ms,
       SUM(R.max_wait_time_ms) max_wait_time_ms,
       SUM(R.signal_wait_time_ms) signal_wait_time
      FROM sys.dm_os_wait_stats AS R
	  GROUP BY R.wait_type
   
     )
	 INSERT INTO MonitorarWaits.AnalisesWait 
	 SELECT CAST(GETDATE() AS SMALLDATETIME) AS DataAnalise, 
			 R.wait_type,
             R.waiting_tasks_count,
             R.wait_time_ms,
             R.max_wait_time_ms,
             R.signal_wait_time
			  FROM Dados R
	 ORDER BY R.wait_time_ms DESC
	 OFFSET 0 ROWS  FETCH NEXT 20 ROWS ONLY 

	 /*Monitor : Faz seek*/
	 SELECT AW.Id,
            AW.DataAnalise,
            AW.wait_type,
            AW.waiting_tasks_count,
            AW.wait_time_ms,
            AW.max_wait_time_ms,
            AW.signal_wait_time,
			WM.MotivoOcorrencia,
			WA.Dica FROM MonitorarWaits.AnalisesWait AS AW
	 LEFT JOIN MonitorarWaits.WaitsMonitorados AS WM ON AW.wait_type = WM.Wait_type
	 LEFT JOIN MonitorarWaits.WaitAcoes AS WA ON WM.Id = WA.Id
	-- WHERE AW.DataAnalise >= GETDATE()