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
('DNE'),
('cra-pr.conversor'),
('cra-rn.conversor'),
('cress-sp.Conversor'),
('cra-mt.conversor'),
('cra-al.conversor'),
('cra-pb.conversor'),
('cress-rj.conversor'),
('cra-to.conversor'),
('cra-am.conversor'),
('cra-pe.conversor'),
('cra-es.conversor'),
('cress-rr-Conversor'),
('cra-df.conversor'),
('cro-sp.conversor'),
('cra-sp.conversor'),
('cra-ma.conversor'),
('cra-sp.conversor-incremental'),
('cra-pa.conversor'),
('cra-sc.Conversor'),
('cra-go.conversor'),
('cra-pi.conversor'),
('cra-se.conversor'),
('cress-sc.conversor'),
('cress-mg.conversor'),
('cress-rs.Conversor'),
('cra-ro.conversor'),
('cro-pr.conversor2'),
('cress-ms.conversor'),
('cress-pa.conversor'),
('cro-pr.conversor'),
('cro-am.conversor'),
('cress-ce.conversor'),
('cress-pe.conversor'),
('cro-go.conversor'),
('prd-automationjobs-db'),
('DNE_1711'),
('cra-ba.conversor'),
('cress-pr.conversor'),
('cress-df.conversor'),
('cra-es.conversor-2'),
('cra-es.conversor-3'),
('cra-ms.conversor'),
('cra-ap.conversor'),
('cra-sp.implanta.net.br-ESPELHO'),
('cro-sp.implanta.net.br-ESPELHO'),
('crtr-08.implanta.net.br'),
('crtr-01.implanta.net.br'),
('crb-03.implanta.net.br'),
('crb-13.implanta.net.br'),
('crb-08.implanta.net.br'),
('conter-br.implanta.net.br'),
('cra-rj.implanta.net.br'),
('crb-07.implanta.net.br'),
('crb-04.implanta.net.br'),
('crb-11.implanta.net.br'),
('crb-01.implanta.net.br'),
('cra-mg.implanta.net.br'),
('cfb-br.implanta.net.br'),
('crb-02.implanta.net.br'),
('crtr-14.implanta.net.br'),
('crtr-09.implanta.net.br'),
('crb-09.implanta.net.br'),
('crb-14.implanta.net.br'),
('crb-10.implanta.net.br'),
('creci-rj.implanta.net.br'),
('crb-06.implanta.net.br'),
('crb-05.implanta.net.br'),
('core-ap.implanta.net.br'),
('conrerp-pe.implanta.net.br'),
('creci-es.implanta.net.br'),
('cra-df.implanta.net.br_COPY'),
('cress-df.implanta.net.br_Copy'),
('cro-go.implanta.net.br_COPY'),
('cra-to.implanta.net.br_COPY'),
('cress-pe.implanta.net.br_COPY'),
('crefito-ba.implanta.net.br_Copy'),
('crefito-sp.implanta.net.br_COPY'),
('cra-pb.implanta.net.br_COPY'),
('cra-es.implanta.net.br_COPY'),
('cra-rn.implanta.net.br_COPY'),
('crn-06.implanta.net.br_Copy'),
('crtr-07.implanta.net.br'),
('cra-sp-hml.implanta.net.br'),
('crtr-13.implanta.net.br'),
('crtr-15.implanta.net.br'),
('crtr-11.implanta.net.br'),
('cro-pa.conversor'),
('cro-to.conversor'),
('cro-ac.conversor'),
('cress-al.conversor'),
('oab-ba.conversor'),
('cress-al.conversor'),
('cro-ac.conversor'),
('cro-to.conversor'),
('cress-am.conversor'),
('cro-pi.conversor'),
('cress-rj.implanta.net.br_COPY'),
('cra-df.implanta.net.br_COPY'),
('cress-sp.implanta.net.br_COPY'),
('cress-al.implanta.net.br_COPY'),
('cress-go.implanta.net.br_COPY')


/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 1) Criar a master  key se precisar
 
-- ==================================================================
*/

--CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'M@st3rP0w3rN@w3r@'

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
     SECRET = 'M@st3rP0w3rN@w3r@';

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



DECLARE  @targetGroup VARCHAR(200) ='rgprd-sqlsrv-prd01';

DECLARE  @ServerName VARCHAR(200) ='rgprd-sqlsrv-prd01.database.windows.net';


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
                      target_group_name = 'rgprd-sqlsrv-prd01'
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group 'rgprd-sqlsrv-prd01';
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
                      TGM.server_name = 'rgprd-sqlsrv-prd01.database.windows.net'
                      AND TGM.target_type = 'SqlServer'
                      AND TGM.refresh_credential_name = 'implanta'
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group_member 'rgprd-sqlsrv-prd01',
                                             @target_type = N'SqlServer',
                                             @refresh_credential_name = N'implanta',
                                             @server_name = 'rgprd-sqlsrv-prd01.database.windows.net';
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
        EXEC jobs.sp_add_target_group_member 'rgprd-sqlsrv-prd01',
                                             @membership_type = N'Exclude',
                                             @target_type = N'SqlDatabase',
                                             @server_name = 'rgprd-sqlsrv-prd01.database.windows.net',
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
                                 @target_group_name = 'rgprd-sqlsrv-prd01';
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
  AND j.target_database_name NOT LIKE '%conversor%'
  AND CAST(DATEADD(HOUR,-3, j.current_attempt_start_time) AS DATETIME2(2)) >= CAST(GETDATE() AS DATE)

  
  /* ==================================================================
  --Data: 10/7/2020 
  --Autor :Wesley Neves
  --Observação: Historico de alterações dos jobs
   
  -- ==================================================================
  */
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
