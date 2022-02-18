/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Adicionar banco de dados para os jobs

-- ==================================================================
*/

DECLARE @visualizarBancosAtivados BIT = 1;
DECLARE @adicionarTodosBancos BIT = 1;

/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Passo 1) rode essa query no banco de dados master

SELECT D.database_id,
       D.name,
       D.compatibility_level,
       D.state_desc,
       D.snapshot_isolation_state_desc,
       D.is_read_committed_snapshot_on
  FROM sys.databases AS D
  WHERE D.name NOT IN 
  (
  'master','DNE','rgprd-elasticjob-db'
  )
  AND CHARINDEX('_',D.name) =0
  AND CHARINDEX('conversor',D.name) =0
  ORDER BY D.name

 
-- ==================================================================
*/
DROP TABLE IF EXISTS #BancoDadosProducao;

CREATE TABLE #BancoDadosProducao
(
   
    [name]                          NVARCHAR(128)
);

INSERT INTO #BancoDadosProducao(
                                   name
                               )
VALUES(N'apresentacao-siscaf.implanta.net.br'),
('caa-ma.implanta.net.br'),
('cau-ac.implanta.net.br'),
('cau-al.implanta.net.br'),
('cau-am.implanta.net.br'),
('cau-ap.implanta.net.br'),
('cau-ba.implanta.net.br'),
('cau-br.implanta.net.br'),
('cau-ce.implanta.net.br'),
('cau-df.implanta.net.br'),
('cau-es.implanta.net.br'),
('cau-go.implanta.net.br'),
('cau-ma.implanta.net.br'),
('cau-mg.implanta.net.br'),
('cau-ms.implanta.net.br'),
('cau-mt.implanta.net.br'),
('cau-pa.implanta.net.br'),
('cau-pb.implanta.net.br'),
('cau-pe.implanta.net.br'),
('cau-pi.implanta.net.br'),
('cau-pr.implanta.net.br'),
('cau-rj.implanta.net.br'),
('cau-rn.implanta.net.br'),
('cau-ro.implanta.net.br'),
('cau-rr.implanta.net.br'),
('cau-rs.implanta.net.br'),
('cau-sc.implanta.net.br'),
('cau-se.implanta.net.br'),
('cau-sp.implanta.net.br'),
('cau-to.implanta.net.br'),
('cfa-br.implanta.net.br'),
('cfess-br.implanta.net.br'),
('cff-br.implanta.net.br'),
('cffa-br.implanta.net.br'),
('cfm-br.implanta.net.br'),
('cfmv-br.implanta.net.br'),
('cfn-br.implanta.net.br'),
('cfo-br.implanta.net.br'),
('cfp-br.implanta.net.br'),
('cfq-br.implanta.net.br'),
('cft-br.implanta.net.br'),
('cfta-br.implanta.net.br'),
('codhab-df.implanta.net.br'),
('cofen-br.implanta.net.br'),
('coffito-br.implanta.net.br'),
('confea-br.implanta.net.br'),
('confere-br.implanta.net.br'),
('conferp-br.implanta.net.br'),
('conre-ba.implanta.net.br'),
('conre-df.implanta.net.br'),
('conrerp-ba.implanta.net.br'),
('conrerp-df.implanta.net.br'),
('conrerp-mg.implanta.net.br'),
('conrerp-rj.implanta.net.br'),
('conrerp-rs.implanta.net.br'),
('conrerp-sp.implanta.net.br'),
('consed-df.implanta.net.br'),
('core-al.implanta.net.br'),
('core-am.implanta.net.br'),
('core-ba.implanta.net.br'),
('core-ce.implanta.net.br'),
('core-df.implanta.net.br'),
('core-es.implanta.net.br'),
('core-go.implanta.net.br'),
('core-ma.implanta.net.br'),
('core-mg.implanta.net.br'),
('core-ms.implanta.net.br'),
('core-mt.implanta.net.br'),
('core-pa.implanta.net.br'),
('core-pb.implanta.net.br'),
('core-pe.implanta.net.br'),
('core-pi.implanta.net.br'),
('core-pr.implanta.net.br'),
('core-rj.implanta.net.br'),
('core-rn.implanta.net.br'),
('core-ro.implanta.net.br'),
('core-rs.implanta.net.br'),
('core-sc.implanta.net.br'),
('core-se.implanta.net.br'),
('core-sp.implanta.net.br'),
('core-to.implanta.net.br'),
('corecon-rs.implanta.net.br'),
('corecon-sp.implanta.net.br'),
('coren-ac.implanta.net.br'),
('coren-al.implanta.net.br'),
('coren-ap.implanta.net.br'),
('coren-ba.implanta.net.br'),
('coren-ce.implanta.net.br'),
('coren-df.implanta.net.br'),
('coren-es.implanta.net.br'),
('coren-go.implanta.net.br'),
('coren-ma.implanta.net.br'),
('coren-mg.implanta.net.br'),
('coren-ms.implanta.net.br'),
('coren-pa.implanta.net.br'),
('coren-pe.implanta.net.br'),
('coren-pi.implanta.net.br'),
('coren-pr.implanta.net.br'),
('coren-rj.implanta.net.br'),
('coren-rn.implanta.net.br'),
('coren-ro.implanta.net.br'),
('coren-rr.implanta.net.br'),
('coren-rs.implanta.net.br'),
('coren-sc.implanta.net.br'),
('coren-sp.implanta.net.br'),
('coren-to.implanta.net.br'),
('cra-ac.implanta.net.br'),
('cra-al.implanta.net.br'),
('cra-am.implanta.net.br'),
('cra-ap.implanta.net.br'),
('cra-ba.implanta.net.br'),
('cra-df.implanta.net.br'),
('cra-es.implanta.net.br'),
('cra-go.implanta.net.br'),
('cra-ma.implanta.net.br'),
('cra-ms.implanta.net.br'),
('cra-mt.implanta.net.br'),
('cra-pa.implanta.net.br'),
('cra-pb.implanta.net.br'),
('cra-pe.implanta.net.br'),
('cra-pi.implanta.net.br'),
('cra-pr.implanta.net.br'),
('cra-rn.implanta.net.br'),
('cra-ro.implanta.net.br'),
('cra-rr.implanta.net.br'),
('cra-rs.implanta.net.br'),
('cra-sc.implanta.net.br'),
('cra-se.implanta.net.br'),
('cra-sp-hml.implanta.net.br'),
('cra-sp.implanta.net.br'),
('cra-sp.implanta.net.br-ESPELHO'),
('cra-to.implanta.net.br'),
('cra-to.implanta.net.br_COPY'),
('crb-15.implanta.net.br'),
('crbm-01.implanta.net.br'),
('crea-ac.implanta.net.br'),
('crea-al.implanta.net.br'),
('crea-am.implanta.net.br'),
('crea-ap.implanta.net.br'),
('crea-ba.implanta.net.br'),
('crea-ce.implanta.net.br'),
('crea-df.implanta.net.br'),
('crea-es.implanta.net.br'),
('crea-go.implanta.net.br'),
('crea-ma.implanta.net.br'),
('crea-mg.implanta.net.br'),
('crea-ms.implanta.net.br'),
('crea-mt.implanta.net.br'),
('crea-pa.implanta.net.br'),
('crea-pb.implanta.net.br'),
('crea-pe.implanta.net.br'),
('crea-pi.implanta.net.br'),
('crea-pr.implanta.net.br'),
('crea-rj.implanta.net.br'),
('crea-rn.implanta.net.br'),
('crea-ro.implanta.net.br'),
('crea-rr.implanta.net.br'),
('crea-rs.implanta.net.br'),
('crea-sc.implanta.net.br'),
('crea-se.implanta.net.br'),
('crea-sp.implanta.net.br'),
('crea-to.implanta.net.br'),
('cref-sp.implanta.net.br'),
('crefito-ba.implanta.net.br'),
('crefito-ba.implanta.net.br_Copy'),
('crefito-ce.implanta.net.br'),
('crefito-df.implanta.net.br'),
('crefito-es.implanta.net.br'),
('crefito-ma.implanta.net.br'),
('crefito-mg.implanta.net.br'),
('crefito-ms.implanta.net.br'),
('crefito-mt.implanta.net.br'),
('crefito-pa.implanta.net.br'),
('crefito-pe.implanta.net.br'),
('crefito-pi.implanta.net.br'),
('crefito-pr.implanta.net.br'),
('crefito-rj.implanta.net.br'),
('crefito-rs.implanta.net.br'),
('crefito-sc.implanta.net.br'),
('crefito-sp.implanta.net.br'),
('cress-ac.implanta.net.br'),
('cress-al.implanta.net.br'),
('cress-am.implanta.net.br'),
('cress-ap.implanta.net.br'),
('cress-ba.implanta.net.br'),
('cress-ce.implanta.net.br'),
('cress-df.implanta.net.br'),
('cress-df.implanta.net.br_Copy'),
('cress-es.implanta.net.br'),
('cress-go.implanta.net.br'),
('cress-ma.implanta.net.br'),
('cress-mg.implanta.net.br'),
('cress-ms.implanta.net.br'),
('cress-mt.implanta.net.br'),
('cress-pa.implanta.net.br'),
('cress-pb.implanta.net.br'),
('cress-pe.implanta.net.br'),
('cress-pe.implanta.net.br_COPY'),
('cress-pi.implanta.net.br'),
('cress-pr.implanta.net.br'),
('cress-rj.implanta.net.br'),
('cress-rn.implanta.net.br'),
('cress-ro.implanta.net.br'),
('cress-rr.implanta.net.br'),
('cress-rs.implanta.net.br'),
('cress-sc.implanta.net.br'),
('cress-se.implanta.net.br'),
('cress-sp.implanta.net.br'),
('cress-to.implanta.net.br'),
('crf-ac.implanta.net.br'),
('crf-al.implanta.net.br'),
('crf-am.implanta.net.br'),
('crf-ap.implanta.net.br'),
('crf-ba.implanta.net.br'),
('crf-ce.implanta.net.br'),
('crf-df.implanta.net.br'),
('crf-es.implanta.net.br'),
('crf-go.implanta.net.br'),
('crf-ma.implanta.net.br'),
('crf-mg.implanta.net.br'),
('crf-ms.implanta.net.br'),
('crf-mt.implanta.net.br'),
('crf-pa.implanta.net.br'),
('crf-pb.implanta.net.br'),
('crf-pe.implanta.net.br'),
('crf-pi.implanta.net.br'),
('crf-pr.implanta.net.br'),
('crf-rj.implanta.net.br'),
('crf-rn.implanta.net.br'),
('crf-ro.implanta.net.br'),
('crf-rr.implanta.net.br'),
('crf-rs.implanta.net.br'),
('crf-sc.implanta.net.br'),
('crf-se.implanta.net.br'),
('crf-sp.implanta.net.br'),
('crf-to.implanta.net.br'),
('crfa-am.implanta.net.br'),
('crfa-ce.implanta.net.br'),
('crfa-go.implanta.net.br'),
('crfa-mg.implanta.net.br'),
('crfa-pe.implanta.net.br'),
('crfa-pr.implanta.net.br'),
('crfa-rj.implanta.net.br'),
('crfa-rs.implanta.net.br'),
('crfa-sp.implanta.net.br'),
('crm-ac.implanta.net.br'),
('crm-al.implanta.net.br'),
('crm-am.implanta.net.br'),
('crm-ap.implanta.net.br'),
('crm-ba.implanta.net.br'),
('crm-ce.implanta.net.br'),
('crm-df.implanta.net.br'),
('crm-es.implanta.net.br'),
('crm-go.implanta.net.br'),
('crm-ma.implanta.net.br'),
('crm-mg.implanta.net.br'),
('crm-ms.implanta.net.br'),
('crm-mt.implanta.net.br'),
('crm-pa.implanta.net.br'),
('crm-pb.implanta.net.br'),
('crm-pe.implanta.net.br'),
('crm-pi.implanta.net.br'),
('crm-pr.implanta.net.br'),
('crm-rj.implanta.net.br'),
('crm-rn.implanta.net.br'),
('crm-ro.implanta.net.br'),
('crm-rr.implanta.net.br'),
('crm-rs.implanta.net.br'),
('crm-sc.implanta.net.br'),
('crm-se.implanta.net.br'),
('crm-to.implanta.net.br'),
('crmv-ac.implanta.net.br'),
('crmv-al.implanta.net.br'),
('crmv-am.implanta.net.br'),
('crmv-ap.implanta.net.br'),
('crmv-ba.implanta.net.br'),
('crmv-ce.implanta.net.br'),
('crmv-df.implanta.net.br'),
('crmv-es.implanta.net.br'),
('crmv-go.implanta.net.br'),
('crmv-ma.implanta.net.br'),
('crmv-mg.implanta.net.br'),
('crmv-ms.implanta.net.br'),
('crmv-mt.implanta.net.br'),
('crmv-pa.implanta.net.br'),
('crmv-pb.implanta.net.br'),
('crmv-pe.implanta.net.br'),
('crmv-pi.implanta.net.br'),
('crmv-pr.implanta.net.br'),
('crmv-rj.implanta.net.br'),
('crmv-rn.implanta.net.br'),
('crmv-ro.implanta.net.br'),
('crmv-rr.implanta.net.br'),
('crmv-rs.implanta.net.br'),
('crmv-sc.implanta.net.br'),
('crmv-se.implanta.net.br'),
('crmv-sp.implanta.net.br'),
('crmv-to.implanta.net.br'),
('crn-04.implanta.net.br'),
('crn-06.implanta.net.br'),
('crn-ba.implanta.net.br'),
('crn-df.implanta.net.br'),
('crn-mg.implanta.net.br'),
('crn-pa.implanta.net.br'),
('crn-pr.implanta.net.br'),
('crn-rs.implanta.net.br'),
('crn-sc.implanta.net.br'),
('crn-sp.implanta.net.br'),
('cro-ac.implanta.net.br'),
('cro-al.implanta.net.br'),
('cro-am.implanta.net.br'),
('cro-ap.implanta.net.br'),
('cro-ba.implanta.net.br'),
('cro-ce.implanta.net.br'),
('cro-df.implanta.net.br'),
('cro-es.implanta.net.br'),
('cro-go.implanta.net.br'),
('cro-ma.implanta.net.br'),
('cro-mg.implanta.net.br'),
('cro-ms.implanta.net.br'),
('cro-mt.implanta.net.br'),
('cro-pa.implanta.net.br'),
('cro-pb.implanta.net.br'),
('cro-pe.implanta.net.br'),
('cro-pi.implanta.net.br'),
('cro-pr.implanta.net.br'),
('cro-rj.implanta.net.br'),
('cro-rn.implanta.net.br'),
('cro-ro.implanta.net.br'),
('cro-rr.implanta.net.br'),
('cro-rs.implanta.net.br'),
('cro-sc.implanta.net.br'),
('cro-se.implanta.net.br'),
('cro-sp.implanta.net.br'),
('cro-sp.implanta.net.br-ESPELHO'),
('cro-to.implanta.net.br'),
('crp-al.implanta.net.br'),
('crp-am.implanta.net.br'),
('crp-ba.implanta.net.br'),
('crp-ce.implanta.net.br'),
('crp-df.implanta.net.br'),
('crp-es.implanta.net.br'),
('crp-go.implanta.net.br'),
('crp-ma.implanta.net.br'),
('crp-mg.implanta.net.br'),
('crp-ms.implanta.net.br'),
('crp-mt.implanta.net.br'),
('crp-pa.implanta.net.br'),
('crp-pb.implanta.net.br'),
('crp-pe.implanta.net.br'),
('crp-pi.implanta.net.br'),
('crp-pr.implanta.net.br'),
('crp-rj.implanta.net.br'),
('crp-rn.implanta.net.br'),
('crp-rs.implanta.net.br'),
('crp-sc.implanta.net.br'),
('crp-se.implanta.net.br'),
('crp-sp.implanta.net.br'),
('crp-to.implanta.net.br'),
('crq-al.implanta.net.br'),
('crq-am.implanta.net.br'),
('crq-ba.implanta.net.br'),
('crq-ce.implanta.net.br'),
('crq-es.implanta.net.br'),
('crq-go.implanta.net.br'),
('crq-ma.implanta.net.br'),
('crq-mg.implanta.net.br'),
('crq-ms.implanta.net.br'),
('crq-mt.implanta.net.br'),
('crq-pa.implanta.net.br'),
('crq-pb.implanta.net.br'),
('crq-pe.implanta.net.br'),
('crq-pi.implanta.net.br'),
('crq-pr.implanta.net.br'),
('crq-rj.implanta.net.br'),
('crq-rn.implanta.net.br'),
('crq-rs.implanta.net.br'),
('crq-sc.implanta.net.br'),
('crq-se.implanta.net.br'),
('crq-sp.implanta.net.br'),
('crt-01.implanta.net.br'),
('crt-02.implanta.net.br'),
('crt-03.implanta.net.br'),
('crt-04.implanta.net.br'),
('crt-ba.implanta.net.br'),
('crt-es.implanta.net.br'),
('crt-mg.implanta.net.br'),
('crt-rj.implanta.net.br'),
('crt-rn.implanta.net.br'),
('crt-rs.implanta.net.br'),
('crt-sp.implanta.net.br'),
('crtr-02.implanta.net.br'),
('crtr-03.implanta.net.br'),
('crtr-06.implanta.net.br'),
('crtr-07.implanta.net.br'),
('crtr-10.implanta.net.br'),
('crtr-11.implanta.net.br'),
('crtr-12.implanta.net.br'),
('crtr-13.implanta.net.br'),
('crtr-15.implanta.net.br'),
('crtr-16.implanta.net.br'),
('crtr-17.implanta.net.br'),
('crtr-18.implanta.net.br'),
('crtr-19.implanta.net.br'),
('crtr-rj.implanta.net.br'),
('crtr-sp.implanta.net.br'),
('oab-ac.implanta.net.br'),
('oab-al.implanta.net.br'),
('oab-am.implanta.net.br'),
('oab-ap.implanta.net.br'),
('oab-ba.implanta.net.br'),
('oab-ce.implanta.net.br'),
('oab-df.implanta.net.br'),
('oab-ms.implanta.net.br'),
('oab-pa.implanta.net.br'),
('oab-pi.implanta.net.br'),
('oab-rn.implanta.net.br'),
('oab-ro.implanta.net.br'),
('oab-rr.implanta.net.br'),
('oab-rs.implanta.net.br'),
('oab-se.implanta.net.br'),
('patrimonio-df.implanta.net.br'),
('treinamento-siscaf.implanta.net.br')

DROP TABLE IF EXISTS #BancoDadosComJobsAtivados;

CREATE TABLE #BancoDadosComJobsAtivados
(
    [name]                          NVARCHAR(128),
  
);

DECLARE @MembershipType NVARCHAR(50) = N'Include';
DECLARE @TargetType NVARCHAR(50) = N'SqlDatabase';
DECLARE @RefreshCredName NVARCHAR(128) = N'JobRun';
DECLARE @ServerName NVARCHAR(128) = N'rgprd-sqlsrv-prd01.database.windows.net';
DECLARE @Target_group_name NVARCHAR(128) = 'rgprd-sqlsrv-prd01';

IF(@adicionarTodosBancos = 1)
    BEGIN

        /* declare variables */
        DECLARE 
                @DatabaseName VARCHAR(200);

        DECLARE cursor_AdicionaBanco CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT 
               BDP.name
          FROM #BancoDadosProducao AS BDP
         WHERE
            BDP.name NOT IN(
                               SELECT TGM.database_name FROM jobs.target_group_members AS TGM
                           )
         ORDER BY
            BDP.name;

        OPEN cursor_AdicionaBanco;

        FETCH NEXT FROM cursor_AdicionaBanco
         INTO 
              @DatabaseName;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC jobs.sp_add_target_group_member @target_group_name = @Target_group_name,
                                                     @membership_type = @MembershipType,
                                                     @target_type = @TargetType,
                                                     --@refresh_credential_name = @RefreshCredName,
                                                     @server_name = @ServerName,
                                                     @database_name = @DatabaseName;

                SELECT @DatabaseName;

                FETCH NEXT FROM cursor_AdicionaBanco
                 INTO 
                      @DatabaseName;
            END;

        CLOSE cursor_AdicionaBanco;
        DEALLOCATE cursor_AdicionaBanco;
    END;




INSERT INTO #BancoDadosComJobsAtivados
SELECT *
  FROM #BancoDadosProducao AS BDP
 WHERE
    BDP.name IN(
                   SELECT TGM.database_name FROM jobs.target_group_members AS TGM
               );



IF(@visualizarBancosAtivados = 1)
    BEGIN
	
        SELECT	 BDCJA.name AS ClientesInstalados FROM #BancoDadosComJobsAtivados AS BDCJA;
    END;