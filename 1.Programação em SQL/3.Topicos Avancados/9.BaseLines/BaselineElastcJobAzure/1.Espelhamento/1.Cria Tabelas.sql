IF (NOT EXISTS
(
    SELECT *
    FROM sys.schemas AS S
    WHERE S.name = 'Espelhamento'
)
   )
BEGIN


    EXEC ('CREATE SCHEMA Espelhamento;');
END;


IF (NOT EXISTS
(
    SELECT *
    FROM sys.tables AS T
    WHERE T.name = 'DatabasesEspelhados'
)
   )
BEGIN

    CREATE TABLE [Espelhamento].[DatabasesEspelhados]
    (
        [DatabaseId] [INT] NOT NULL IDENTITY(1, 1),
        [DatabaseName] [VARCHAR](250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
        [Periodicidade] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
        [DatabasePoolName] [VARCHAR](200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
    ) ON [PRIMARY];

    ALTER TABLE [Espelhamento].[DatabasesEspelhados]
    ADD CONSTRAINT [PK_EspelhamentoDatabasesEspelhadosDatabaseId]
        PRIMARY KEY CLUSTERED ([DatabaseId]);

    ALTER TABLE [Espelhamento].[DatabasesEspelhados]
    ADD CONSTRAINT [UQ_EspelhamentoDatabasesEspelhadosDatabaseName]
        UNIQUE NONCLUSTERED ([DatabaseName]);


    SET IDENTITY_INSERT Espelhamento.DatabasesEspelhados OFF;

    INSERT INTO Espelhamento.DatabasesEspelhados
    VALUES
    (1, 'cfo-br.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (2, 'codhab-df.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (3, 'confea-br.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (4, 'coren-pr.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (5, 'cra-go.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (6, 'cra-pr.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (7, 'cra-sp.implanta.net.br', 'Diariamente', 'rgprd-elspool-mix01'),
    (8, 'crea-mg.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (9, 'crea-sp.implanta.net.br', 'Diariamente', 'rgprd-elspool-mix01'),
    (10, 'crea-to.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (11, 'crefito-mg.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (12, 'crf-sp.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (13, 'crm-rs.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (14, 'cro-ac.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (15, 'cro-al.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (16, 'cro-am.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (17, 'cro-ap.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (18, 'cro-ba.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (19, 'cro-ce.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (20, 'cro-df.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (21, 'cro-es.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (22, 'cro-go.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (23, 'cro-ma.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (24, 'cro-mg.implanta.net.br', 'Diariamente', 'rgprd-elspool-cro01'),
    (25, 'cro-ms.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (26, 'cro-mt.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (27, 'cro-pa.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (28, 'cro-pb.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (29, 'cro-pe.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (30, 'cro-pi.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (31, 'cro-pr.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (32, 'cro-rj.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (33, 'cro-rn.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (34, 'cro-ro.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (35, 'cro-rr.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (36, 'cro-rs.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (37, 'cro-sc.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (38, 'cro-se.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (39, 'cro-sp.implanta.net.br', 'Diariamente', 'rgprd-elspool-cro01'),
    (40, 'cro-to.implanta.net.br', 'Sabado', 'rgprd-elspool-cro01'),
    (41, 'oab-df.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (42, 'oab-rs.implanta.net.br', 'Sabado', 'rgprd-elspool-mix01'),
    (43, 'oab-ba.implanta.net.br', 'Diariamente', 'rgprd-elspool-mix01'),
    (44, 'crmv-sp.implanta.net.br', 'Diariamente', 'rgprd-elspool-mix01');


    SET IDENTITY_INSERT Espelhamento.DatabasesEspelhados ON;

END;

