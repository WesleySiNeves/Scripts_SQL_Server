/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação:Tirados do https://docs.microsoft.com/pt-br/azure/azure-sql/database/elastic-jobs-tsql-create-manage#create-a-target-group-servers
						https://www.sqlshack.com/automating-azure-sql-database-index-maintenance-using-elastic-job-agents/
						https://www.sqlshack.com/overview-of-create-database-statement-in-azure-sql-server/#:~:text=Navigate%20to%20SQL%20databases%20and,and%20service%20objective%20as%20S0.
						
-- ==================================================================
--*/

/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Ao criar um novo job , fica mais facil adicionar todos os bancos do servidor 
e posteriormente exluir os desnecessários , para isso  conect em master e rode o script 
para pegar os bancos de dados a serem excluidos

SELECT * FROM  sys.databases AS D
WHERE D.name NOT LIKE '%implantadev%'
 
-- ==================================================================
*/

IF(OBJECT_ID('TEMPDB..#BancosDeDadosExcluidosDoJob') IS NOT NULL)
    DROP TABLE #BancosDeDadosExcluidosDoJob;

CREATE TABLE #BancosDeDadosExcluidosDoJob
(
    DatabaseName NVARCHAR(256),
);

INSERT INTO #BancosDeDadosExcluidosDoJob(
                                            DatabaseName
                                        )
VALUES(N'master'),
(N'Implanta.Manager'),
(N'cra-es.conversor'),
(N'Implanta_CRESSSP'),
(N'aaf-02.implantadev.net.br_Copiar'),
(N'aaf-11.implantadev.net.br'),

(N'rgphml-elasticjob-db'),
(N'aaf-16.implantadev.net.br'),
(N'M-SAF-03.implantadev.net.br'),
(N'ajuda-online.implanta.net.br'),
(N'cress-go.implanta.net.br'),
(N'hml-automationjobs-db'),
(N'Implanta_CRESSSP_Homologacao'),
(N'DNE'),
(N'Implanta.Configuracao'),
(N'Implanta.ManagerTeste');

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 1) Criar a master  key se precisar
 
-- ==================================================================
*/

--CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Very$trongpas'

/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Passo 2) Criar  a CREDENTIAL logado no banco  do job
  
-- ==================================================================
*/
SELECT * FROM sys.database_scoped_credentials AS DSC;



--DROP  DATABASE SCOPED CREDENTIAL SQLJobUser
CREATE DATABASE SCOPED CREDENTIAL [implanta]
WITH IDENTITY = 'implanta',
     SECRET = 'M@st3rP0w3rN@w3r@Hml';




/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Passo 3) Criar os Logins Necessários nos bancos de dados master e os targets

--AGORA, VAMOS CRIAR UM LOGIN SQL NO BANCO DE DADOS MESTRE. O NOME DE LOGIN E A SENHA DEVEM SER OS MESMOS QUE USAMOS COMO IDENTIDADE PARA CRIAR UMA CREDENCIAL 

NÂO PRECISA DA PARTE DO LOGIN
-- ==================================================================
*/
/*This script will be executed on master (System database) database */
CREATE LOGIN SQLJobUser WITH PASSWORD = 'M@st3rP0w3rN@w3r@Hml';

/*
 A SEGUIR, CRIAREMOS UM USUÁRIO PARA CADA BANCO DE DADOS DE DESTINO.
  CERTIFIQUE-SE DE QUE O USUÁRIO DEVE TER AS PERMISSÕES APROPRIADAS NO BANCO DE DADOS DE DESTINO. AQUI, 
  ESTOU CONCEDENDO A PERMISSÃO DB_OWNER PARA GARANTIR QUE O TRABALHO SQL SEJA EXECUTADO COM ÊXITO
*/

/*Rodar no Mult Script para cada banco configurado*/
CREATE USER SQLJobUser FROM LOGIN SQLJobUser;

ALTER ROLE db_owner ADD MEMBER [SQLJobUser];
GO


--NÂO PRECISA DA PARTE DO LOGIN




/* ==================================================================
 --Data: 9/4/2020 
 --Autor :Wesley Neves
 --Observação: Passo 2) Criar um  target group
  
 -- ==================================================================
 */
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.target_groups
                   WHERE
                      target_group_name = 'rghml-sqlsrv-hm01'
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group 'rghml-sqlsrv-hm01';
    END;

SELECT * FROM jobs.target_groups AS TG;

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 3) adicionar o servidor alvo
 
-- ==================================================================
*/
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.target_group_members AS TGM
                   WHERE
                      TGM.server_name = 'rghml-sqlsrv-hm01.database.windows.net'
                      AND TGM.target_type = 'SqlServer'
                      AND TGM.refresh_credential_name = 'implanta'
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group_member 'rghml-sqlsrv-hm01',
                                             @target_type = N'SqlServer',
                                             @refresh_credential_name = N'implanta',
                                             @server_name = 'rghml-sqlsrv-hm01.database.windows.net';
    END;






SELECT *
  FROM jobs.target_group_members AS TGM
 ORDER BY
    TGM.membership_type DESC;



/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Excluir os bancos de dados no job
 
-- ==================================================================
*/

/* declare variables */
DECLARE @Db_Name_On_Exclude NVARCHAR(256);

DECLARE cursor_DB_Name_on_Exclude CURSOR FAST_FORWARD READ_ONLY FOR
SELECT *
  FROM #BancosDeDadosExcluidosDoJob AS BDDEDJ
 WHERE
    BDDEDJ.DatabaseName NOT IN(
                                  SELECT TGM.database_name
                                    FROM jobs.target_group_members AS TGM
                                   WHERE
                                      TGM.membership_type = 'Exclude'
                              );


OPEN cursor_DB_Name_on_Exclude;

FETCH NEXT FROM cursor_DB_Name_on_Exclude
 INTO @Db_Name_On_Exclude;

WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC jobs.sp_add_target_group_member 'rghml-sqlsrv-hm01',
                                             @membership_type = N'Exclude',
                                             @target_type = N'SqlDatabase',
                                             @server_name = 'rghml-sqlsrv-hm01.database.windows.net',
                                             @database_name = @Db_Name_On_Exclude;

        FETCH NEXT FROM cursor_DB_Name_on_Exclude
         INTO @Db_Name_On_Exclude;
    END;

CLOSE cursor_DB_Name_on_Exclude;
DEALLOCATE cursor_DB_Name_on_Exclude;



/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Verificar os bancos de dados excluidos do job
 
-- ==================================================================
*/

SELECT TGM.target_group_name,
       TGM.target_type,
       TGM.membership_type,
       TGM.refresh_credential_name,
       TGM.server_name,
       TGM.database_name,
       TGM.elastic_pool_name
  FROM jobs.target_group_members AS TGM
 ORDER BY
    TGM.membership_type DESC;

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 6) Criar o Job no banco de dados do elasticjob
 
-- ==================================================================
*/
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs_internal.jobs J
                   WHERE
                      J.name = 'ManutencaoEPerformace'
                      AND J.delete_requested_time IS NULL
              )
  )
    BEGIN

        --Add job for create table
        EXEC jobs.sp_add_job @job_name = 'ManutencaoEPerformace',
                             @description = 'executa as rotinas de manutenção no banco de dados, criação e manutenção de indices e statisticas , alem de expurgos de logs e Elmah';
    END;

SELECT *
  FROM jobs_internal.jobs AS J
 WHERE
    J.delete_requested_time IS NULL;




/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Adiciona o Step aonde vai ser executado o script
 
-- ==================================================================
*/
IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.jobsteps AS J
                   WHERE
                      J.job_name = 'ManutencaoEPerformace'
                      AND J.step_name = 'Execução da procedure uspAutoHealthCheck'
              )
  )
    BEGIN
        EXEC jobs.sp_add_jobstep @job_name = 'ManutencaoEPerformace',
                                 @step_name = 'Execução da procedure uspAutoHealthCheck',
                                 @max_parallelism = 5,
                                 @command = N' EXEC HealthCheck.GetSizeDB;',
                                 @credential_name = 'implanta',
								 @retry_attempts  =2,
                                 @target_group_name = 'rghml-sqlsrv-hm01';
    END;


--EXEC HealthCheck.uspAutoHealthCheck @Efetivar = 1 ,@Visualizar = 0;

/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação:  Caso vc queria fazer alguma alteração no step
						  
-- ==================================================================
*/
DECLARE @job_version INT;




EXEC jobs.sp_update_jobstep @job_name = N'ManutencaoEPerformace',
                            @step_name = 'Execução da procedure uspAutoHealthCheck',
							@retry_attempts  =3,
							@command ='EXEC HealthCheck.uspAutoHealthCheck @Efetivar = 1 ,@Visualizar = 0;',
							@credential_name = 'implanta',
                            @max_parallelism = 5;


DECLARE @SqlScript NVARCHAR(1000) = CONCAT('IF(EXISTS (
              SELECT TOP 1 1
                FROM sys.databases AS D
               WHERE
                  NOT(
                         D.name LIKE ''%master%''
                         OR D.name LIKE ''%Manager%''
                         OR D.name LIKE ''%Copy%''
                         OR D.name LIKE ''%DNE%''
                         OR D.name LIKE ''%automationjobs%''
                         OR D.name LIKE ''%Configuracao%''
                         OR D.name LIKE ''%rglab%''
                     )
          )
  )
    BEGIN
        EXEC HealthCheck.uspAutoHealthCheck @Efetivar = 1, @Visualizar = 0;
    END;','');


EXEC jobs.sp_update_jobstep @job_name = N'ManutencaoEPerformace',
                            @step_name = 'Execução da procedure uspAutoHealthCheck',
							@retry_attempts  =3,
							@command =@SqlScript,
							@credential_name = 'implanta',
                            @max_parallelism = 5;



/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação:  Faz a configuração para executar  o job
 
-- ==================================================================
*/
EXEC jobs.sp_update_job @job_name = 'ManutencaoEPerformace',
                        @enabled = 1,
                        @schedule_interval_type = 'Days',
                        @schedule_interval_count = 1,
                        @schedule_start_time = N'20200904 21:00'; --N'20200904 21:00'  =>> 6:00 da tarde

/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação:  Inicializa o Job
 
-- ==================================================================
*/
EXEC jobs.sp_start_job 'ManutencaoEPerformace';


SELECT j.job_id,
       j.job_name,
       j.job_version,
       j.step_name,
       j.target_type,
       j.step_id,
       j.is_active,
       j.lifecycle,
       j.end_time,
	  current_attempt_start_time = DATEADD(HOUR,-3, j.current_attempt_start_time),
       time_elapsed = DATEDIFF(SECOND, j.start_time, j.end_time),
       tentativas = j.current_attempts,
       j.last_message,
       j.target_resource_group_name,
       j.target_server_name,
       j.target_database_name,
       j.target_elastic_pool_name
  FROM jobs.job_executions j
  WHERE j.lifecycle  = 'Failed'
  AND CAST(DATEADD(HOUR,-3, j.current_attempt_start_time) AS DATETIME2(2)) >= CAST(GETDATE() AS DATE)

  
SELECT J.job_id,
       J.job_version_number,
       J.step_name,
       JD.command_type,
       JD.credential_name,
	   
       JD.target_id,
       JD.initial_retry_interval_ms,
       JD.maximum_retry_interval_ms,
       JD.retry_interval_backoff_multiplier,
       JD.retry_attempts,
       JD.step_timeout_ms,
       JD.max_parallelism,
       CD.text,
	   T.target_group_name
  FROM jobs_internal.jobstep_data AS JD
       JOIN jobs_internal.jobsteps AS J ON J.jobstep_data_id = JD.jobstep_data_id
	   JOIN jobs_internal.targets AS T ON T.target_id = JD.target_id
       JOIN jobs_internal.command_data AS CD ON CD.command_data_id = JD.command_data_id
	   ORDER BY J.job_version_number DESC

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Expurgar o historico de execução antiga
 
-- ==================================================================
*/
DECLARE @oldest_date DATETIME2(2) = GETDATE();

EXEC jobs.sp_purge_jobhistory @job_name = 'ManutencaoEPerformace',
                              @oldest_date = @oldest_date;





/* ==================================================================
--Data: 10/6/2020 
--Autor :Wesley Neves
--Observação: Tabelas
 
-- ==================================================================
*/

SELECT * FROM jobs_internal.job_cancellations AS JC
SELECT * FROM jobs_internal.job_executions AS JE
SELECT * FROM jobs_internal.job_task_executions AS JTE


/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação:  caso vc queria cancelar o job
 
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
--Observação: Agendamento pra o job
 
 Abaixo tem a seguintes opçoes

 ‘Once’ =Uma vez'
‘Minutes’ ='Minutos'
‘Hours’ ='Horas'
‘Days’  ='Dias'
‘Weeks’ ='Semanas'
‘Months’ ='Meses'
-- ==================================================================
*/
EXEC jobs.sp_update_job @job_name = 'ManutencaoEPerformace',
                        @enabled = 1,
                        @schedule_interval_type = 'Days',
                                                                  --@refresh_credential_name=N'JobRun', --credential required to refresh the databases in a server
                        @schedule_start_time = N'20200905 01:00', -- Esse horario será	22:00 pois são -3 horas GTM
                        @schedule_interval_count = 1;



							  
/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Excluir todo o Job
 
-- ==================================================================
*/
EXEC jobs.sp_delete_job @job_name = 'ManutencaoEPerformace';
