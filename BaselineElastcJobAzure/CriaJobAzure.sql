/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação:Tirados do https://docs.microsoft.com/pt-br/azure/azure-sql/database/elastic-jobs-tsql-create-manage#create-a-target-group-servers
						https://www.sqlshack.com/automating-azure-sql-database-index-maintenance-using-elastic-job-agents/
-- ==================================================================
--*/





/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 1) Criar as  CREDENTIAL com as mesmas senhas
 
-- ==================================================================
*/

CREATE DATABASE SCOPED CREDENTIAL JobRun WITH IDENTITY = 'elasticjob',
    SECRET = 'M@st3rP0w3r@zur3Prd';  
GO
 
CREATE DATABASE SCOPED CREDENTIAL MasterCred WITH IDENTITY = 'implanta',
    SECRET ='M@st3rP0w3r@zur3Prd';
  


 

 /* ==================================================================
 --Data: 9/4/2020 
 --Autor :Wesley Neves
 --Observação: Passo 2) Criar um grupo-alvo
  
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
        EXEC jobs.sp_add_target_group 'rgprd-sqlsrv-prd01'
    END
 
 
 SELECT * FROM jobs.target_groups AS TG
/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 3) adicionar os bancos de dados que seram executados
 
-- ==================================================================
*/




IF(NOT EXISTS (
                  SELECT *
                    FROM jobs.target_group_members AS TGM
                   WHERE
                      TGM.database_name = 'treinamento-siscaf.implanta.net.br'
              )
  )
    BEGIN
        EXEC jobs.sp_add_target_group_member 'rgprd-sqlsrv-prd01',
                                             @target_type = N'SqlDatabase',
                                             @server_name = 'rgprd-sqlsrv-prd01.database.windows.net',
                                             @database_name = N'treinamento-siscaf.implanta.net.br'
    END

SELECT * FROM jobs.target_group_members AS TGM



 
/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 4) tem que ser executado em master
 
-- ==================================================================
*/

CREATE LOGIN MasterUser WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

CREATE LOGIN JobUser WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
 
CREATE USER MasterUser FROM LOGIN MasterUser


/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 5) Criar em cada banco de dados que o job vai executar


--implanta
IF NOT EXISTS (
                  SELECT [name]
                    FROM [sys].[database_principals]
                   WHERE
                      [type] = N'S'
                      AND [name] = N'JobUser'
              )
    BEGIN
        CREATE USER JobUser FROM LOGIN JobUser;

        ALTER ROLE db_owner ADD MEMBER [JobUser];
    END;

 
-- ==================================================================
*/
CREATE USER JobUser FROM LOGIN JobUser;

ALTER ROLE db_owner ADD MEMBER [JobUser];
GO




/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 6) Criar o Job no banco de dados do elasticjob
 
-- ==================================================================
*/



IF(NOT EXISTS (
                  SELECT * FROM jobs_internal.jobs J WHERE J.name = 'ManutencaoEPerformace'
              )
  )
    BEGIN

        --Add job for create table
        EXEC jobs.sp_add_job @job_name = 'ManutencaoEPerformace',
                             @description = 'executa as rotinas de manutenção no banco de dados, criação de indices e outros';
    END;
	
SELECT * FROM  jobs_internal.jobs AS J

EXEC jobs.sp_add_jobstep @job_name = 'ManutencaoEPerformace',
                         @step_name = 'Execução da procedure de uspAutoHealthCheck',
						 @max_parallelism  =30,
                         @command = N'EXEC HealthCheck.uspAutoHealthCheck @Efetivar = 1 ,@Visualizar = 0;',
                         @credential_name = 'JobRun',
                         @target_group_name = 'rgprd-sqlsrv-prd01';



EXEC jobs.sp_update_job
    @job_name='ManutencaoEPerformace',
    @enabled=1,
    @schedule_interval_type='Minutes',
    @schedule_interval_count=1,
    @schedule_start_time= N'20200904 22:00';



EXEC jobs.sp_start_job 'ManutencaoEPerformace'

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação:  caso vc queria cancelar o job
 
-- ==================================================================
*/


SELECT * FROM jobs.job_executions
WHERE is_active = 1 AND job_name = 'ManutencaoEPerformace'
ORDER BY start_time DESC
GO

-- Cancel job execution with the specified job execution id
EXEC jobs.sp_stop_job 'EB9EF3B8-57CE-4BD2-B080-774D9519078E'


/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Excluir todo o Job
 
-- ==================================================================
*/
EXEC jobs.sp_delete_job @job_name='ManutencaoEPerformace'


/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Expurgar o historico de execução antiga
 
-- ==================================================================
*/


DECLARE @oldest_date  DATETIME2(2) = GETDATE();

EXEC jobs.sp_purge_jobhistory @job_name='ManutencaoEPerformace', @oldest_date=@oldest_date

select j.job_id,
       j.job_name,
       j.job_version,
       j.step_name,
	   j.target_type,
       j.step_id,
       j.is_active,
       j.lifecycle,
       j.create_time,
       j.start_time,
       j.end_time,
	   time_elapsed = DATEDIFF(SECOND,j.start_time,j.end_time),
       j.current_attempts,
       j.last_message,
       j.target_resource_group_name,
       j.target_server_name,
       j.target_database_name,
       j.target_elastic_pool_name from jobs.job_executions j
WHERE target_type IS NOT NULL


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
						@schedule_start_time= N'20200905 01:00',-- Esse horario será	22:00 pois são -3 horas GTM
                        @schedule_interval_count = 1;





/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Para adicionar a nova etapa ao trabalho existente, execute o seguinte script 
no banco de dados do Agente. Se você estiver adicionando mais de uma etapa, será necessário especificar o nome da etapa.

@max_parallelism = executa ao mesmo tempo em no maximo  N bancos
 
-- ==================================================================
*/


