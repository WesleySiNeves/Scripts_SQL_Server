

/* ==================================================================
--Data: 08/03/2019 
--Autor :Wesley Neves
--Observação: 

Criação das Configuraçoes (Acesso)

UtilizaExpurgoLogsAzureTableStorage :	Indica se os dados a serem inseridos na tabela expurgo ficará o Sql server ou no TableStorage
ContainerNameAzureTableStorageExpurgo:  Indica o nome do Conteiner disponibilizado para o cliente no azure table storage para guardar os dados de expurgo
ConnectionStringAzureStorageTable :     string de conexão



Criação das Configuraçoes (Controle Dias)

QtdMesExpurgoLogsAuditoria :(Ja existe) Valor tem um Valor padrão de 3 meses ,passará para 12  meses

QtdMesDeletarRegistrosLogsExpurgo (Nova) quantidade meses para deletar registros da tabela expurgo

ExecutouMigracaoLogsJson :Sinaliza que houve a migração dos dados antigos para nova tabela (LogsJson)

ExecutouMigracaoExpurgoLogsJson ::Sinaliza que houve a migração dos dados antigos para nova tabela (ExpurgoJson)

 DataMigracaoLogsJson : Data de Migração dos Logs
-- ==================================================================
*/

DECLARE @NovoValorPadraoQtdMesExpurgoLogsAuditoria TINYINT = 12;
DECLARE @CriarConfiguracao BIT = 1;
DECLARE @AlterarConfiguracao BIT = 0;

IF(@CriarConfiguracao = 1)
    BEGIN
        BEGIN
            IF(EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'ExpurgoEmExecucao'
                      )
              )
                DELETE FROM Sistema.Configuracoes
                 WHERE
                    Configuracoes.Configuracao = 'ExpurgoEmExecucao';
        END;

        IF(EXISTS (
                      SELECT 1
                        FROM Sistema.Configuracoes AS C
                       WHERE
                          C.Configuracao = 'QtdMesExpurgoLogsAuditoria'
                  )
          )
            BEGIN
                UPDATE C
                   SET C.Valor = @NovoValorPadraoQtdMesExpurgoLogsAuditoria
                  FROM Sistema.Configuracoes C
                 WHERE
                    C.Configuracao = 'QtdMesExpurgoLogsAuditoria'
                    AND C.Modulo = 'Logon';
            END;
        ELSE
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                    -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000002',     -- CodSistema - uniqueidentifier
                          'Logon',                                    -- Modulo - varchar(100)
                          'QtdMesExpurgoLogsAuditoria',               -- Configuracao - varchar(100)
                          @NovoValorPadraoQtdMesExpurgoLogsAuditoria, -- Valor - varchar(max)
                          0                                           -- Ano - int
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'HorarioInicioProcessamentoExpurgo'
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'HorarioInicioProcessamentoExpurgo',    -- Configuracao - varchar(100)
                          '22:00:00',                             -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'DataExecucaoExpurgo'
                      )
          )
            --2019-05-08
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'DataExecucaoExpurgo',                  -- Configuracao - varchar(100)
                          '',                                     -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'ConnectionStringAzureStorageTable'
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                                                                                                                                                                      -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000',                                                                                                                                                       -- CodSistema - uniqueidentifier
                          'Global',                                                                                                                                                                                     -- Modulo - varchar(100)
                          'ConnectionStringAzureStorageTable',                                                                                                                                                          -- Configuracao - varchar(100)
                          'DefaultEndpointsProtocol=https;AccountName=imdevblob02;AccountKey=6XDERJnF6V34xAKomrppUbbOXhQRwkkb6Yz9KBrQvjvzVf+Ob+Pgi+kV9s0zE9FY8E4Wvwg7QEfDiT3JQmD1aw==;EndpointSuffix=core.windows.net', -- Valor - varchar(max)
                          0                                                                                                                                                                                             -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'ContainerNameAzureTableStorageExpurgo'
                      )
          )
            BEGIN
                DECLARE @NomeCliente VARCHAR(200) = DB_NAME();

                SELECT @NomeCliente = REPLACE(@NomeCliente, '.implanta.net.br', '');

                SELECT @NomeCliente = REPLACE(@NomeCliente, '.implantadev', '');

                SELECT @NomeCliente = REPLACE(@NomeCliente, '.net.br', '');

                DECLARE @Numero VARCHAR(10) = '';

                SELECT @Numero = SUBSTRING(@NomeCliente, PATINDEX('%[0-9]%', @NomeCliente), 2);

                SELECT @NomeCliente = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@NomeCliente, '1', ''), '2', ''), '3', ''), '4', ''), '5', ''), '6', ''), '7', '0'), '8', ''), '9', ''), '0', '');

                SELECT @NomeCliente = REPLACE(REPLACE(@NomeCliente, '.', ''), '-', '');

                SELECT @NomeCliente = CONCAT('ExpurgoLogs', CONCAT(UPPER(LEFT(@NomeCliente, 1)), SUBSTRING(@NomeCliente, 2, LEN(@NomeCliente))), @Numero);

                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                 -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000',  -- CodSistema - uniqueidentifier
                          'Global',                                -- Modulo - varchar(100)
                          'ContainerNameAzureTableStorageExpurgo', -- Configuracao - varchar(100)
                          @NomeCliente,                            -- Valor - varchar(max)
                          0                                        -- Ano - smallint
                      );
            END;
        ELSE
            BEGIN
                DECLARE @NomeClienteUpdate VARCHAR(200) = DB_NAME();
                DECLARE @NumeroUpdade VARCHAR(10) = '';

                SELECT @NumeroUpdade = SUBSTRING(@NomeClienteUpdate, PATINDEX('%[0-9]%', @NomeCliente), 2);

                SELECT @NomeClienteUpdate = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@NomeClienteUpdate, '1', ''), '2', ''), '3', ''), '4', ''), '5', ''), '6', ''), '7', '0'), '8', ''), '9', ''), '0', '');

                SELECT @NomeClienteUpdate = REPLACE(REPLACE(@NomeClienteUpdate, '.', ''), '-', '');

                SELECT @NomeClienteUpdate = CONCAT('ExpurgoLogs', CONCAT(UPPER(LEFT(@NomeCliente, 1)), SUBSTRING(@NomeClienteUpdate, 2, LEN(@NomeClienteUpdate))), @NumeroUpdade);

                UPDATE Sistema.Configuracoes
                   SET Configuracoes.Valor = @NomeClienteUpdate
                 WHERE
                    Configuracoes.Configuracao = 'ContainerNameAzureTableStorageExpurgo';
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'UtilizaExpurgoLogsAzureTableStorage'
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'UtilizaExpurgoLogsAzureTableStorage',  -- Configuracao - varchar(100)
                          'False',                                -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'UtilizaArmazenamentoLogsJson'
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'UtilizaArmazenamentoLogsJson',         -- Configuracao - varchar(100)
                          'False',                                -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'DataMigracaoLogsJson'
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'DataMigracaoLogsJson',                 -- Configuracao - varchar(100)
                          '',                                     -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'ExecutouMigracaoLogsJson'
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'ExecutouMigracaoLogsJson',             -- Configuracao - varchar(100)
                          'False',                                -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;

        IF(NOT EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'QtdMesDeletarRegistrosLogsExpurgo' --  180 -- seis meses  360 1 ano , 540 (1 ano e meio)
                      )
          )
            BEGIN
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                          'Global',                               -- Modulo - varchar(100)
                          'QtdMesDeletarRegistrosLogsExpurgo',    -- Configuracao - varchar(100)
                          '12',                                   -- Valor - varchar(max)
                          0                                       -- Ano - smallint
                      );
            END;
    END;

IF(@AlterarConfiguracao = 1)
    BEGIN
        UPDATE Sistema.Configuracoes
           SET Configuracoes.Valor = 'False'
         WHERE
            Configuracoes.Configuracao = 'UtilizaArmazenamentoLogsJson';

        UPDATE Sistema.Configuracoes
           SET Configuracoes.Valor = 'False'
         WHERE
            Configuracoes.Configuracao = 'ExecutouMigracaoLogsJson';

        UPDATE Sistema.Configuracoes
           SET Configuracoes.Valor = ''
         WHERE
            Configuracoes.Configuracao = 'DataMigracaoLogsJson';

        UPDATE Sistema.Configuracoes
           SET Configuracoes.Valor = ''
         WHERE
            Configuracoes.Configuracao = 'DataExecucaoExpurgo';

        UPDATE Sistema.Configuracoes
           SET Configuracoes.Valor = 12
         WHERE
            Configuracoes.Configuracao = 'QtdMesExpurgoLogsAuditoria';
    END;


	UPDATE Sistema.Configuracoes SET Configuracoes.Valor ='True'
	WHERE Configuracoes.Configuracao ='UtilizaArmazenamentoLogsJson'

SELECT 1 AS Ordem,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'UtilizaArmazenamentoLogsJson'
UNION ALL
SELECT 2,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'ExecutouMigracaoLogsJson'
UNION ALL
SELECT 3,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'ExpurgoEmExecucao'
UNION ALL
SELECT 4,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'DataMigracaoLogsJson'
UNION ALL
SELECT 5,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'DataExecucaoExpurgo'
UNION ALL
SELECT 6,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'QtdMesExpurgoLogsAuditoria'
UNION ALL
SELECT 6,
       *
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'QtdMesDeletarRegistrosLogsExpurgo';


	

/*


 

 

*/
SELECT *
  FROM Sistema.Configuracoes AS C WITH(NOLOCK)
 WHERE
    (
        C.Configuracao LIKE '%Expurgo%'
        OR C.Configuracao LIKE '%Table%'
        OR C.Configuracao LIKE '%Logs%'
    )
  


