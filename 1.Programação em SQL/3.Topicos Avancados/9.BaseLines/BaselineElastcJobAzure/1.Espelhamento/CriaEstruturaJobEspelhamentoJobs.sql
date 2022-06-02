SELECT D.database_id,D.name FROM sys.databases AS D
WHERE D.name LIKE '%espelho%'
ORDER BY D.name

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o:Tirados do https://docs.microsoft.com/pt-br/azure/azure-sql/database/elastic-jobs-tsql-create-manage#create-a-target-group-servers
						https://www.sqlshack.com/automating-azure-sql-database-index-maintenance-using-elastic-job-agents/
						https://www.sqlshack.com/overview-of-create-database-statement-in-azure-sql-server/#:~:text=Navigate%20to%20SQL%20databases%20and,and%20service%20objective%20as%20S0.
						
-- ==================================================================
--*/

/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observa��o: Passo 3) Criar os Logins Necess�rios nos bancos de dados master e os targets

--AGORA, VAMOS CRIAR UM LOGIN SQL NO BANCO DE DADOS MESTRE. O NOME DE LOGIN E A SENHA DEVEM SER OS MESMOS
 QUE USAMOS COMO IDENTIDADE PARA CRIAR UMA CREDENCIAL 


-- ==================================================================
*/
/*This script will be executed on master (System database) database */
--CREATE LOGIN JobExecuter WITH PASSWORD = 'Dev#Infra*!mpl@nt@112020';

/*
 A SEGUIR, CRIAREMOS UM USU�RIO PARA CADA BANCO DE DADOS DE DESTINO.
  CERTIFIQUE-SE DE QUE O USU�RIO DEVE TER AS PERMISS�ES APROPRIADAS NO BANCO DE DADOS DE DESTINO. AQUI, 
  ESTOU CONCEDENDO A PERMISS�O DB_OWNER PARA GARANTIR QUE O TRABALHO SQL SEJA EXECUTADO COM �XITO
*/

/*Rodar no Mult Script para cada banco configurado*/
--CREATE USER JobExecuter FROM LOGIN JobExecuter;

--ALTER ROLE db_owner ADD MEMBER [JobExecuter];
--GO

DECLARE @targetGroup VARCHAR(200) = 'Azure-SQL-Automation';
DECLARE @DatabaseName VARCHAR(200) = 'prd-automationjobs-db';
DECLARE @ServerName VARCHAR(200) = 'rgprd-sqlsrv-prd01.database.windows.net';

/* ==================================================================
 --Data: 9/4/2020 
 --Autor :Wesley Neves
 --Observa��o: Passo 2) Criar um  target group
  
 -- ==================================================================
 */
IF(NOT EXISTS (
                  SELECT * FROM jobs.target_groups WHERE target_group_name = 'Azure-SQL-Automation'
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group @targetGroup;
    END;

SELECT * FROM jobs.target_groups AS TG;

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o: Passo 3) adicionar o banco onde será hospedado o script
 
-- ==================================================================
*/
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.target_group_members AS TGM
                   WHERE
                    TGM.target_group_name = 'Azure-SQL-Automation'
                    AND TGM.target_type = 'SqlDatabase'
                    AND TGM.server_name = 'rgprd-sqlsrv-prd01.database.windows.net'
               
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group_member @target_group_name = 'Azure-SQL-Automation',
                                             @target_type = N'SqlDatabase',
                                             @server_name = 'rgprd-sqlsrv-prd01.database.windows.net',
                                             @database_name = N'prd-automationjobs-db';
    END;

SELECT *
  FROM jobs.target_group_members AS TGM
 WHERE
    TGM.target_group_name = 'Azure-SQL-Automation';

SELECT * FROM [jobs].target_groups WHERE target_group_name = N'Azure-SQL-Automation';


/* ==================================================================
--Data: 10/02/2021 
--Autor :Wesley Neves
--Observa��o: Caso queira remover um target_group_member
 
EXEC jobs.sp_delete_target_group_member @target_group_name = N'Azure-SQL-Automation',       -- nvarchar(128)
                                        @target_id = 'E2EF78C0-EEE3-4250-B900-71F8B615A7DC' -- uniqueidentifier


-- ==================================================================
*/

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o: Passo 6) Criar o Job no banco de dados do elasticjob
 
-- ==================================================================
*/
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs_internal.jobs J
                   WHERE
                      J.name = 'Azure-SQL-Automation-DeletarBancosEspelhos'
                      AND J.delete_requested_time IS NULL
              )
  )
    BEGIN

        --Add job for create table
        EXEC jobs.sp_add_job @job_name = 'Azure-SQL-Automation-DeletarBancosEspelhos',
                             @description = 'deleta os bancos de dados espelhos'

    END;


IF(NOT EXISTS (
                  SELECT *
                    FROM jobs_internal.jobs J
                   WHERE
                      J.name = 'Azure-SQL-Automation-CriarBancosEspelhos'
                      AND J.delete_requested_time IS NULL
              )
  )
    BEGIN

        --Add job for create table
        EXEC jobs.sp_add_job @job_name = 'Azure-SQL-Automation-CriarBancosEspelhos',
                             @description = 'cria os bancos de dados espelhos'

    END;


	

SELECT *
  FROM jobs_internal.jobs AS J
 WHERE
    J.delete_requested_time IS NULL;
/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observa��o: Adiciona o Step aonde vai ser executado o script
 
-- ==================================================================
*/




--DECLARE @job_version INT =3;

--EXEC jobs.sp_delete_jobstep @job_name = N'ManutencaoEPerformace',                   -- nvarchar(128)
--                            @step_name = N'Execu��o da procedure uspAutoHealthCheck',                  -- nvarchar(120)
--                            @job_version = @job_version OUTPUT -- int
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.jobsteps AS J
                   WHERE
                      J.job_name = 'Azure-SQL-Automation-DeletarBancosEspelhos'
                      AND J.step_name = 'deletarBancosEspelhos'
              )
  )
    BEGIN
        EXEC jobs.sp_add_jobstep @job_name = 'Azure-SQL-Automation-DeletarBancosEspelhos',
                                 @step_name = 'deletarBancosEspelhos',
                                 @max_parallelism = 1,
								 @command_type ='TSQL',
                                 @command = N'EXEC Automation.uspDeletarEspelhamentoBancoDados',
                                 @credential_name = 'JobExecuter',
                                 @retry_attempts = 3,
                                 @target_group_name = 'Azure-SQL-Automation';
    END;



                        
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.jobsteps AS J
                   WHERE
                      J.job_name = 'Azure-SQL-Automation-CriarBancosEspelhos'
                      AND J.step_name = 'criarBancosEspelhos'
              )
  )
    BEGIN
        EXEC jobs.sp_add_jobstep @job_name = 'Azure-SQL-Automation-CriarBancosEspelhos',
                                 @step_name = 'criarBancosEspelhos',
                                 @max_parallelism = 1,
								 @command_type ='TSQL',
                                 @command = N'EXEC Automation.uspCriarCopiasEspelhos',
                                 @credential_name = 'JobExecuter',
                                 @retry_attempts = 3,
                                 @target_group_name = 'Azure-SQL-Automation';
    END;


	
	 

/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observa��o:  Faz a configura��o para executar  o job
 
-- ==================================================================
*/



EXEC jobs.sp_update_job @job_name = 'Azure-SQL-Automation-DeletarBancosEspelhos',
                        @enabled = 1,
                        @schedule_interval_type = 'Days',
                        @schedule_interval_count = 1,
                        @schedule_start_time = N'20210327 03:03'; --N'20210327 04:00' (gtm -3)  =>> 00:30 da Manha



EXEC jobs.sp_update_job @job_name = 'Azure-SQL-Automation-CriarBancosEspelhos',
                        @enabled = 1,
                        @schedule_interval_type = 'Days',
                        @schedule_interval_count = 1,
                        @schedule_start_time = N'20210327 06:00'; --N'20210327 05:00'   (gtm -3)   =>> 3 da Manha




	
	


/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observa��o:  Inicializa o Job
 
-- ==================================================================
*/
EXEC jobs.sp_start_job 'Azure-SQL-Automation-DeletarBancosEspelhos';


EXEC jobs.sp_start_job 'Azure-SQL-Automation-CriarBancosEspelhos';

/* ==================================================================
--Data: 10/02/2021 
--Autor :Wesley Neves
--Observa��o: Confere a execu��o o job
 
-- ==================================================================
*/



select * from sys.dm_database_copies

select state_desc, * from sys.databases s
ORDER BY s.state_desc  DESC



SELECT last_message  
FROM jobs.job_executions 
WHERE job_name = 'Azure-SQL-Automation-Espelhamento-Job' AND step_name <> 'NULL'

SELECT j.job_id,
       j.job_name,
       j.job_version,
       j.step_name,
       j.target_type,
       j.step_id,
       j.is_active,
       j.lifecycle,
       j.end_time,
       current_attempt_start_time = DATEADD(HOUR, -3, j.current_attempt_start_time),
       time_elapsed = DATEDIFF(SECOND, j.start_time, j.end_time),
       tentativas = j.current_attempts,
       j.last_message,
       j.target_resource_group_name,
       j.target_server_name,
       j.target_database_name,
       j.target_elastic_pool_name
  FROM jobs.job_executions j
 WHERE
     j.lifecycle = 'Failed'
	 AND j.job_name ='Azure-SQL-Automation-CriarBancosEspelhos'


	
SELECT j.job_id,
       j.job_name,
       j.job_version,
       j.step_name,
       j.target_type,
       j.step_id,
       j.is_active,
       j.lifecycle,
       j.end_time,
       current_attempt_start_time = DATEADD(HOUR, -3, j.current_attempt_start_time),
       time_elapsed = DATEDIFF(SECOND, j.start_time, j.end_time),
       tentativas = j.current_attempts,
       j.last_message,
       j.target_resource_group_name,
       j.target_server_name,
       j.target_database_name,
       j.target_elastic_pool_name
  FROM jobs.job_executions j
 WHERE
     j.lifecycle = 'Failed'
	 AND j.job_name ='Azure-SQL-Automation-DeletarBancosEspelhos'


/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o: Expurgar o historico de execu��o antiga
 
-- ==================================================================
*/
DECLARE @oldest_date DATETIME2(2) = GETDATE();

EXEC jobs.sp_purge_jobhistory @job_name = 'Azure-SQL-Automation-DeletarBancosEspelhos',
                              @oldest_date = @oldest_date;


DECLARE @oldest_date DATETIME2(2) = GETDATE();

EXEC jobs.sp_purge_jobhistory @job_name = 'Azure-SQL-Automation-CriarBancosEspelhos',
                              @oldest_date = @oldest_date;
/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observa��o: Tabelas
 
-- ==================================================================
*/
SELECT * FROM jobs_internal.job_cancellations AS JC;

SELECT * FROM jobs_internal.job_executions AS JE;

SELECT * FROM jobs_internal.job_task_executions AS JTE;

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o:  caso vc queria cancelar o job
 
-- ==================================================================
*/
DECLARE @job_execution_id UNIQUEIDENTIFIER;

DECLARE Cursor_Cancelar_Jobs CURSOR FAST_FORWARD READ_ONLY FOR
SELECT DISTINCT job_execution_id
  FROM jobs.job_executions
 WHERE
    is_active = 1
    AND job_name = 'ManutencaoEPerformace';

OPEN Cursor_Cancelar_Jobs;

FETCH NEXT FROM Cursor_Cancelar_Jobs
 INTO @job_execution_id;

WHILE @@FETCH_STATUS = 0
    BEGIN

        -- Cancel job execution with the specified job execution id
        EXEC jobs.sp_stop_job @job_execution_id;

        FETCH NEXT FROM Cursor_Cancelar_Jobs
         INTO @job_execution_id;
    END;

CLOSE Cursor_Cancelar_Jobs;
DEALLOCATE Cursor_Cancelar_Jobs;
GO

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o: Agendamento pra o job
 
 Abaixo tem a seguintes op�oes

 �Once� =Uma vez'
�Minutes� ='Minutos'
�Hours� ='Horas'
�Days�  ='Dias'
�Weeks� ='Semanas'
�Months� ='Meses'
-- ==================================================================
*/
EXEC jobs.sp_update_job @job_name = 'ManutencaoEPerformace',
                        @enabled = 1,
                        @schedule_interval_type = 'Days',
                                                                  --@refresh_credential_name=N'JobRun', --credential required to refresh the databases in a server
                        @schedule_start_time = N'20200905 01:00', -- Esse horario ser�	22:00 pois s�o -3 horas GTM
                        @schedule_interval_count = 1;

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observa��o: Excluir todo o Job
 
-- ==================================================================
*/
EXEC jobs.sp_delete_job @job_name = 'Azure-SQL-Automation-Espelhamento-Job';


