DECLARE @ROLLBACK BIT = 1;

SET XACT_ABORT ON;


BEGIN TRANSACTION SCHEDULE;

BEGIN TRY
    /*Region Logical Querys*/
    IF(OBJECT_ID('TEMPDB..#BancosDedados') IS NOT NULL)
        DROP TABLE #BancosDedados;

    DROP TABLE IF EXISTS #BancosDedados;

    CREATE TABLE #BancosDedados
    (
        banco                                       VARCHAR(200) PRIMARY KEY,
        StorageAccount                              VARCHAR(300),
        Container                                   VARCHAR(30)  UNIQUE,
        ConnectionStringAzureStorageArquivosAnexos  VARCHAR(MAX),
        HorarioMigracao                             VARCHAR(20),
        UtilizaAzure                                CHAR(4),
        CaminhoCacheLocalAzureStorageArquivosAnexos VARCHAR(200),
        QuantidadeDeArquivosMigradosPorExecucao     INT
    );

    CREATE UNIQUE NONCLUSTERED INDEX Ix_Regra_um
    ON #BancosDedados(Container, StorageAccount);

    CREATE UNIQUE NONCLUSTERED INDEX Ix_Regra_dois
    ON #BancosDedados(CaminhoCacheLocalAzureStorageArquivosAnexos);
	
	ALTER TABLE #BancosDedados ADD CONSTRAINT CK_regra_3 CHECK(RIGHT(Container,1) <> '.')

	ALTER TABLE #BancosDedados ADD CONSTRAINT CK_regra_4 CHECK(CHARINDEX(Container,CaminhoCacheLocalAzureStorageArquivosAnexos) > 0)

	ALTER TABLE #BancosDedados ADD CONSTRAINT CK_regra_5 CHECK(CHARINDEX(StorageAccount,ConnectionStringAzureStorageArquivosAnexos) > 0)

	
	

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    -- Caus
    VALUES('cau-al.implanta.net.br', 'improblob01', 'cau-al', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-al\', 500),
    ('cau-am.implanta.net.br', 'improblob01', 'cau-am', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-am\', 500),
    ('cau-ap.implanta.net.br', 'improblob01', 'cau-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-ap\', 500),
    ('cau-ba.implanta.net.br', 'improblob01', 'cau-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-ba\', 500),
    ('cau-br.implanta.net.br', 'improblob01', 'cau-br', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-br\', 500),
    ('cau-ce.implanta.net.br', 'improblob01', 'cau-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-ce\', 500),
    ('cau-df.implanta.net.br', 'improblob01', 'cau-df', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-df\', 500),
    ('cau-es.implanta.net.br', 'improblob01', 'cau-es', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-es\', 500),
    ('cau-go.implanta.net.br', 'improblob01', 'cau-go', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-go\', 500),
    ('cau-ma.implanta.net.br', 'improblob01', 'cau-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-ma\', 500),
    ('cau-mg.implanta.net.br', 'improblob01', 'cau-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-mg\', 500),
    ('cau-ms.implanta.net.br', 'improblob01', 'cau-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-ms\', 500),
    ('cau-mt.implanta.net.br', 'improblob01', 'cau-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-mt\', 500),
    ('cau-pa.implanta.net.br', 'improblob01', 'cau-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-pa\', 500),
    ('cau-pb.implanta.net.br', 'improblob01', 'cau-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-pb\', 500),
    ('cau-pe.implanta.net.br', 'improblob01', 'cau-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-pe\', 500),
    ('cau-pi.implanta.net.br', 'improblob01', 'cau-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-pi\', 500),
    ('cau-pr.implanta.net.br', 'improblob01', 'cau-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cau-pr\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- CRAs
    ('cra-ac.implanta.net.br', 'improblob01', 'cra-ac', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '22:00:00', 'true', 'D:\temp_blob_azure\cra-ac\', 500),
    ('cra-rr.implanta.net.br', 'improblob01', 'cra-rr', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '22:00:00', 'true', 'D:\temp_blob_azure\cra-rr\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- cro
    ('cro-rj.implanta.net.br', 'improblob01', 'cro-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\cro-rj\', 500),
    ('cro-rs.implanta.net.br', 'improblob01', 'cro-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\cro-rs\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- crq
    ('crq-al.implanta.net.br', 'improblob01', 'crq-al', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-al\', 500),
    ('crq-ba.implanta.net.br', 'improblob01', 'crq-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-ba\', 500),
    ('crq-ce.implanta.net.br', 'improblob01', 'crq-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-ce\', 500),
    ('crq-es.implanta.net.br', 'improblob01', 'crq-es', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-es\', 500),
    ('crq-go.implanta.net.br', 'improblob01', 'crq-go', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-go\', 500),
    ('crq-ma.implanta.net.br', 'improblob01', 'crq-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-ma\', 500),
    ('crq-ms.implanta.net.br', 'improblob01', 'crq-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-ms\', 500),
    ('crq-pa.implanta.net.br', 'improblob01', 'crq-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-pa\', 500),
    ('crq-pb.implanta.net.br', 'improblob01', 'crq-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-pb\', 500),
    ('crq-pe.implanta.net.br', 'improblob01', 'crq-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-pe\', 500),
    ('crq-pi.implanta.net.br', 'improblob01', 'crq-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-pi\', 500),
    ('crq-pr.implanta.net.br', 'improblob01', 'crq-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-pr\', 500),
    ('crq-rj.implanta.net.br', 'improblob01', 'crq-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-rj\', 500),
    ('crq-rn.implanta.net.br', 'improblob01', 'crq-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-rn\', 500),
    ('crq-rs.implanta.net.br', 'improblob01', 'crq-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-rs\', 500),
    ('crq-sc.implanta.net.br', 'improblob01', 'crq-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-sc\', 500),
    ('crq-se.implanta.net.br', 'improblob01', 'crq-se', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-se\', 500),
    ('crq-sp.implanta.net.br', 'improblob01', 'crq-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob01;AccountKey=PJIhpHc87NOvJgun39MNGH0sk/Rud+RCwigJ77LnQMkAowC3hOe5hKIGa0csKA83AZ3zHh6hkoDn6mqylTH02A==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\crq-sp\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- cress
    ('cress-ba.implanta.net.br', 'improblob02', 'cress-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\cress-ba\', 500),
    ('cress-es.implanta.net.br', 'improblob02', 'cress-es', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\cress-es\', 500),
    ('cress-mt.implanta.net.br', 'improblob02', 'cress-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\cress-mt\', 500),
    ('cress-pb.implanta.net.br', 'improblob02', 'cress-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\cress-pb\', 500),
    ('cress-se.implanta.net.br', 'improblob02', 'cress-se', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\cress-se\', 500),
    ('cress-to.implanta.net.br', 'improblob02', 'cress-to', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\cress-to\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- CRTR
    ('crtr-02.implanta.net.br', 'improblob02', 'crtr-02', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crtr-02\', 500),
    ('crtr-03.implanta.net.br', 'improblob02', 'crtr-03', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crtr-03\', 500),
    ('crtr-12.implanta.net.br', 'improblob02', 'crtr-12', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crtr-12\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- Conre
    ('conre-ba.implanta.net.br', 'improblob02', 'conre-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conre-ba\', 500),
    ('conre-df.implanta.net.br', 'improblob02', 'conre-df', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conre-df\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- conrerp
    ('conrerp-ba.implanta.net.br', 'improblob02', 'conrerp-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conrerp-ba\', 500),
    ('conrerp-df.implanta.net.br', 'improblob02', 'conrerp-df', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conrerp-df\', 500),
    ('conrerp-mg.implanta.net.br', 'improblob02', 'conrerp-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conrerp-mg\', 500),
    ('conrerp-rj.implanta.net.br', 'improblob02', 'conrerp-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conrerp-rj\', 500),
    ('conrerp-rs.implanta.net.br', 'improblob02', 'conrerp-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conrerp-rs\', 500),
    ('conrerp-sp.implanta.net.br', 'improblob02', 'conrerp-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conrerp-sp\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- consed-df
    ('consed-df.implanta.net.br', 'improblob02', 'consed-df', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\consed-df\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- Federais
    ('cfa-br.implanta.net.br', 'improblob02', 'cfa-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfa-br\', 500),
    ('cfmv-br.implanta.net.br', 'improblob02', 'cfmv-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfmv-br\', 500),
    ('cfn-br.implanta.net.br', 'improblob02', 'cfn-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfn-br\', 500),
    ('cfp-br.implanta.net.br', 'improblob02', 'cfp-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfp-br\', 500),
    ('cfta-br.implanta.net.br', 'improblob02', 'cfta-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfta-br\', 500),
    ('codhab-df.implanta.net.br', 'improblob02', 'codhab-df', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\codhab-df\', 500),
    ('cofen-br.implanta.net.br', 'improblob02', 'cofen-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cofen-br\', 500),
    ('coffito-br.implanta.net.br', 'improblob02', 'coffito-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\coffito-br\', 500),
    ('confea-br.implanta.net.br', 'improblob02', 'confea-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\confea-br\', 500),
    ('conferp-br.implanta.net.br', 'improblob02', 'conferp-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\conferp-br\', 500),
	('cfess-br.implanta.net.br', 'improblob02', 'cfess-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfess-br\', 500),
	('cff-br.implanta.net.br', 'improblob02', 'cff-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cff-br\', 500),
	('cffa-br.implanta.net.br', 'improblob02', 'cffa-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cffa-br\', 500),
	('cfm-br.implanta.net.br', 'improblob02', 'cfm-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfm-br\', 500),
	('cfo-br.implanta.net.br', 'improblob02', 'cfo-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfo-br\', 500),
	('cfq-br.implanta.net.br', 'improblob02', 'cfq-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cfq-br\', 500),
	('cft-br.implanta.net.br', 'improblob02', 'cft-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\cft-br\', 500),
	('confere-br.implanta.net.br', 'improblob02', 'confere-br', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\confere-br\', 500);
	
	
 INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES 
('crt-01.implanta.net.br', 'improblob02', 'crt-01', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-01\', 500),
('crt-02.implanta.net.br', 'improblob02', 'crt-02', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-02\', 500),
('crt-03.implanta.net.br', 'improblob02', 'crt-03', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-03\', 500),
('crt-04.implanta.net.br', 'improblob02', 'crt-04', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-04\', 500),
('crt-ba.implanta.net.br', 'improblob02', 'crt-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-ba\', 500),
('crt-es.implanta.net.br', 'improblob02', 'crt-es', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-es\', 500),
('crt-mg.implanta.net.br', 'improblob02', 'crt-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-mg\', 500),
('crt-rj.implanta.net.br', 'improblob02', 'crt-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-rj\', 500),
('crt-rn.implanta.net.br', 'improblob02', 'crt-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-rn\', 500),
('crt-rs.implanta.net.br', 'improblob02', 'crt-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-rs\', 500),
('crt-sp.implanta.net.br', 'improblob02', 'crt-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob02;AccountKey=4mYKld+m23dwKP82K6kERUpU9/zGnBjKy+kGijtFISmgkXOLVAOJtNDsQZjPTfMrcrRQdG/iIjOj5tIotsGyWQ==;EndpointSuffix=core.windows.net', '23:00:00', 'true', 'D:\temp_blob_azure\crt-sp\', 500);





    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- cref
    ('cref-sp.implanta.net.br', 'improblob03', 'cref-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '20:00:00', 'true', 'D:\temp_blob_azure\cref-sp\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              ) --OAbs
    VALUES('oab-ac.implanta.net.br', 'improblob03', 'oab-ac', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-ac\', 500),
    ('oab-al.implanta.net.br', 'improblob03', 'oab-al', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-al\', 500),
    ('oab-am.implanta.net.br', 'improblob03', 'oab-am', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-am\', 500),
    ('oab-ap.implanta.net.br', 'improblob03', 'oab-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-ap\', 500),
    ('oab-ce.implanta.net.br', 'improblob03', 'oab-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-ce\', 500),
    ('oab-df.implanta.net.br', 'improblob03', 'oab-df', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-df\', 500),
    ('oab-ms.implanta.net.br', 'improblob03', 'oab-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-ms\', 500),
    ('oab-pa.implanta.net.br', 'improblob03', 'oab-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-pa\', 500),
    ('oab-pi.implanta.net.br', 'improblob03', 'oab-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-pi\', 500),
    ('oab-rn.implanta.net.br', 'improblob03', 'oab-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-rn\', 500),
    ('oab-rr.implanta.net.br', 'improblob03', 'oab-rr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-rr\', 500),
    ('oab-rs.implanta.net.br', 'improblob03', 'oab-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-rs\', 500),
    ('oab-se.implanta.net.br', 'improblob03', 'oab-se', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\oab-se\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              ) --crfa
    VALUES('crfa-am.implanta.net.br', 'improblob03', 'crfa-am', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-am\', 500),
    ('crfa-ce.implanta.net.br', 'improblob03', 'crfa-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-ce\', 500),
    ('crfa-go.implanta.net.br', 'improblob03', 'crfa-go', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-go\', 500),
    ('crfa-mg.implanta.net.br', 'improblob03', 'crfa-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-mg\', 500),
    ('crfa-pe.implanta.net.br', 'improblob03', 'crfa-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-pe\', 500),
    ('crfa-pr.implanta.net.br', 'improblob03', 'crfa-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-pr\', 500),
    ('crfa-rj.implanta.net.br', 'improblob03', 'crfa-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-rj\', 500),
    ('crfa-rs.implanta.net.br', 'improblob03', 'crfa-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-rs\', 500),
    ('crfa-sp.implanta.net.br', 'improblob03', 'crfa-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crfa-sp\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              ) --crefito
    VALUES('crefito-ba.implanta.net.br', 'improblob03', 'crefito-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-ba\', 500),
    ('crefito-ce.implanta.net.br', 'improblob03', 'crefito-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-ce\', 500),
    ('crefito-df.implanta.net.br', 'improblob03', 'crefito-df', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-df\', 500),
    ('crefito-es.implanta.net.br', 'improblob03', 'crefito-es', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-es\', 500),
    ('crefito-ma.implanta.net.br', 'improblob03', 'crefito-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-ma\', 500),
    ('crefito-mg.implanta.net.br', 'improblob03', 'crefito-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-mg\', 500),
    ('crefito-ms.implanta.net.br', 'improblob03', 'crefito-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-ms\', 500),
    ('crefito-mt.implanta.net.br', 'improblob03', 'crefito-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-mt\', 500),
    ('crefito-pa.implanta.net.br', 'improblob03', 'crefito-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-pa\', 500),
    ('crefito-pe.implanta.net.br', 'improblob03', 'crefito-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-pe\', 500),
    ('crefito-pi.implanta.net.br', 'improblob03', 'crefito-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-pi\', 500),
    ('crefito-pr.implanta.net.br', 'improblob03', 'crefito-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-pr\', 500),
    ('crefito-rj.implanta.net.br', 'improblob03', 'crefito-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-rj\', 500),
    ('crefito-rs.implanta.net.br', 'improblob03', 'crefito-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-rs\', 500),
    ('crefito-sc.implanta.net.br', 'improblob03', 'crefito-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-sc\', 500),
    ('crefito-sp.implanta.net.br', 'improblob03', 'crefito-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crefito-sp\', 500);

	INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
 VALUES
('crm-ac.implanta.net.br', 'improblob03', 'crm-ac', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ac\', 500),
('crm-al.implanta.net.br', 'improblob03', 'crm-al', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-al\', 500),
('crm-am.implanta.net.br', 'improblob03', 'crm-am', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-am\', 500),
('crm-ap.implanta.net.br', 'improblob03', 'crm-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ap\', 500),
('crm-ba.implanta.net.br', 'improblob03', 'crm-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ba\', 500),
('crm-ce.implanta.net.br', 'improblob03', 'crm-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ce\', 500),
('crm-df.implanta.net.br', 'improblob03', 'crm-df', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-df\', 500),
('crm-es.implanta.net.br', 'improblob03', 'crm-es', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-es\', 500),
('crm-go.implanta.net.br', 'improblob03', 'crm-go', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-go\', 500),
('crm-ma.implanta.net.br', 'improblob03', 'crm-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ma\', 500),
('crm-mg.implanta.net.br', 'improblob03', 'crm-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-mg\', 500),
('crm-ms.implanta.net.br', 'improblob03', 'crm-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ms\', 500),
('crm-mt.implanta.net.br', 'improblob03', 'crm-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-mt\', 500),
('crm-pa.implanta.net.br', 'improblob03', 'crm-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-pa\', 500),
('crm-pb.implanta.net.br', 'improblob03', 'crm-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-pb\', 500),
('crm-pe.implanta.net.br', 'improblob03', 'crm-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-pe\', 500),
('crm-pi.implanta.net.br', 'improblob03', 'crm-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-pi\', 500),
('crm-pr.implanta.net.br', 'improblob03', 'crm-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-pr\', 500),
('crm-rj.implanta.net.br', 'improblob03', 'crm-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-rj\', 500),
('crm-rn.implanta.net.br', 'improblob03', 'crm-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-rn\', 500),
('crm-ro.implanta.net.br', 'improblob03', 'crm-ro', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-ro\', 500),
('crm-rr.implanta.net.br', 'improblob03', 'crm-rr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-rr\', 500),
('crm-rs.implanta.net.br', 'improblob03', 'crm-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-rs\', 500),
('crm-sc.implanta.net.br', 'improblob03', 'crm-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-sc\', 500),
('crm-se.implanta.net.br', 'improblob03', 'crm-se', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-se\', 500),
('crm-to.implanta.net.br', 'improblob03', 'crm-to', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crm-to\', 500);

	INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
 VALUES
('crmv-al.implanta.net.br','improblob03', 'crmv-al', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-al\', 500),
('crmv-ba.implanta.net.br','improblob03', 'crmv-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-ba\', 500),
('crmv-ce.implanta.net.br','improblob03', 'crmv-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-ce\', 500),
('crmv-df.implanta.net.br','improblob03', 'crmv-df', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-df\', 500),
('crmv-go.implanta.net.br','improblob03', 'crmv-go', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-go\', 500),
('crmv-mg.implanta.net.br','improblob03', 'crmv-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-mg\', 500),
('crmv-ms.implanta.net.br','improblob03', 'crmv-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-ms\', 500),
('crmv-mt.implanta.net.br','improblob03', 'crmv-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-mt\', 500),
('crmv-pb.implanta.net.br','improblob03', 'crmv-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-pb\', 500),
('crmv-pe.implanta.net.br','improblob03', 'crmv-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-pe\', 500),
('crmv-pi.implanta.net.br','improblob03', 'crmv-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-pi\', 500),
('crmv-pr.implanta.net.br','improblob03', 'crmv-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-pr\', 500),
('crmv-rj.implanta.net.br','improblob03', 'crmv-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-rj\', 500),
('crmv-rn.implanta.net.br','improblob03', 'crmv-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-rn\', 500),
('crmv-ro.implanta.net.br','improblob03', 'crmv-ro', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-ro\', 500),
('crmv-rs.implanta.net.br','improblob03', 'crmv-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-rs\', 500),
('crmv-sc.implanta.net.br','improblob03', 'crmv-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-sc\', 500),
('crmv-se.implanta.net.br','improblob03', 'crmv-se', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-se\', 500),
('crmv-sp.implanta.net.br','improblob03', 'crmv-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-sp\', 500),
('crmv-to.implanta.net.br','improblob03', 'crmv-to', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crmv-to\', 500);


	INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
VALUES
('crn-04.implanta.net.br','improblob03', 'crn-04', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-04\', 500),
('crn-06.implanta.net.br','improblob03', 'crn-06', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-06\', 500),
('crn-ba.implanta.net.br','improblob03', 'crn-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-ba\', 500),
('crn-df.implanta.net.br','improblob03', 'crn-df', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-df\', 500),
('crn-mg.implanta.net.br','improblob03', 'crn-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-mg\', 500),
('crn-pa.implanta.net.br','improblob03', 'crn-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-pa\', 500),
('crn-pr.implanta.net.br','improblob03', 'crn-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-pr\', 500),
('crn-rs.implanta.net.br','improblob03', 'crn-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-rs\', 500),
('crn-sc.implanta.net.br','improblob03', 'crn-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-sc\', 500),
('crn-sp.implanta.net.br','improblob03', 'crn-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crn-sp\', 500);


	INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
VALUES
('crp-ba.implanta.net.br','improblob03', 'crp-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-ba\', 500),
('crp-ce.implanta.net.br','improblob03', 'crp-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-ce\', 500),
('crp-df.implanta.net.br','improblob03', 'crp-df', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-df\', 500),
('crp-es.implanta.net.br','improblob03', 'crp-es', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-es\', 500),
('crp-go.implanta.net.br','improblob03', 'crp-go', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-go\', 500),
('crp-ma.implanta.net.br','improblob03', 'crp-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-ma\', 500),
('crp-mg.implanta.net.br','improblob03', 'crp-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-mg\', 500),
('crp-ms.implanta.net.br','improblob03', 'crp-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-ms\', 500),
('crp-mt.implanta.net.br','improblob03', 'crp-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-mt\', 500),
('crp-pa.implanta.net.br','improblob03', 'crp-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-pa\', 500),
('crp-pb.implanta.net.br','improblob03', 'crp-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-pb\', 500),
('crp-pe.implanta.net.br','improblob03', 'crp-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-pe\', 500),
('crp-pi.implanta.net.br','improblob03', 'crp-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-pi\', 500),
('crp-rj.implanta.net.br','improblob03', 'crp-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-rj\', 500),
('crp-rn.implanta.net.br','improblob03', 'crp-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-rn\', 500),
('crp-rs.implanta.net.br','improblob03', 'crp-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-rs\', 500),
('crp-sc.implanta.net.br','improblob03', 'crp-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-sc\', 500),
('crp-se.implanta.net.br','improblob03', 'crp-se', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-se\', 500),
('crp-sp.implanta.net.br','improblob03', 'crp-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-sp\', 500),
('crp-to.implanta.net.br','improblob03', 'crp-to', 'DefaultEndpointsProtocol=https;AccountName=improblob03;AccountKey=WEA4YzMZHaeDg0TBLXQje+EkZanSNVyPxKvmYKGQeVO/Blo9bsjlI4yjpI7DivAMuK6KPvoRBHq5MRZzqDdJEA==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\crp-to\', 500);






    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- core	
    ('core-al.implanta.net.br', 'improblob04', 'core-al', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-al\', 500),
    ('core-am.implanta.net.br', 'improblob04', 'core-am', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-am\', 500),
    ('core-ap.implanta.net.br', 'improblob04', 'core-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-ap\', 500),
    ('core-ba.implanta.net.br', 'improblob04', 'core-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-ba\', 500),
    ('core-ce.implanta.net.br', 'improblob04', 'core-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-ce\', 500),
    ('core-df.implanta.net.br', 'improblob04', 'core-df', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-df\', 500),
    ('core-es.implanta.net.br', 'improblob04', 'core-es', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-es\', 500),
    ('core-go.implanta.net.br', 'improblob04', 'core-go', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-go\', 500),
    ('core-ma.implanta.net.br', 'improblob04', 'core-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-ma\', 500),
    ('core-mg.implanta.net.br', 'improblob04', 'core-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-mg\', 500),
    ('core-ms.implanta.net.br', 'improblob04', 'core-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-ms\', 500),
    ('core-mt.implanta.net.br', 'improblob04', 'core-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-mt\', 500),
    ('core-pa.implanta.net.br', 'improblob04', 'core-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-pa\', 500),
    ('core-pb.implanta.net.br', 'improblob04', 'core-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-pb\', 500),
    ('core-pe.implanta.net.br', 'improblob04', 'core-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-pe\', 500),
    ('core-pi.implanta.net.br', 'improblob04', 'core-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-pi\', 500),
    ('core-pr.implanta.net.br', 'improblob04', 'core-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-pr\', 500),
    ('core-rj.implanta.net.br', 'improblob04', 'core-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-rj\', 500),
    ('core-rn.implanta.net.br', 'improblob04', 'core-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-rn\', 500),
    ('core-ro.implanta.net.br', 'improblob04', 'core-ro', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-ro\', 500),
    ('core-rs.implanta.net.br', 'improblob04', 'core-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-rs\', 500),
    ('core-sc.implanta.net.br', 'improblob04', 'core-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-sc\', 500),
    ('core-se.implanta.net.br', 'improblob04', 'core-se', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-se\', 500),
    ('core-sp.implanta.net.br', 'improblob04', 'core-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-sp\', 500),
    ('core-to.implanta.net.br', 'improblob04', 'core-to', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\core-to\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- corecon	
    ('corecon-rs.implanta.net.br', 'improblob04', 'corecon-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\corecon-rs\', 500),
    ('corecon-sp.implanta.net.br', 'improblob04', 'corecon-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '02:00:00', 'true', 'D:\temp_blob_azure\corecon-sp\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES -- coren	
    ('coren-ac.implanta.net.br', 'improblob04', 'coren-ac', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ac\', 500),
    ('coren-al.implanta.net.br', 'improblob04', 'coren-al', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-al\', 500),
    ('coren-ap.implanta.net.br', 'improblob04', 'coren-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ap\', 500),
    ('coren-ba.implanta.net.br', 'improblob04', 'coren-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ba\', 500),
    ('coren-ce.implanta.net.br', 'improblob04', 'coren-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ce\', 500),
    ('coren-df.implanta.net.br', 'improblob04', 'coren-df', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-df\', 500),
    ('coren-es.implanta.net.br', 'improblob04', 'coren-es', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-es\', 500),
    ('coren-ma.implanta.net.br', 'improblob04', 'coren-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ma\', 500),
    ('coren-mg.implanta.net.br', 'improblob04', 'coren-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-mg\', 500),
    ('coren-ms.implanta.net.br', 'improblob04', 'coren-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ms\', 500),
    ('coren-pa.implanta.net.br', 'improblob04', 'coren-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-pa\', 500),
    ('coren-pe.implanta.net.br', 'improblob04', 'coren-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-pe\', 500),
    ('coren-pi.implanta.net.br', 'improblob04', 'coren-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-pi\', 500),
    ('coren-pr.implanta.net.br', 'improblob04', 'coren-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-pr\', 500),
    ('coren-rj.implanta.net.br', 'improblob04', 'coren-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-rj\', 500),
    ('coren-rn.implanta.net.br', 'improblob04', 'coren-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-rn\', 500),
    ('coren-ro.implanta.net.br', 'improblob04', 'coren-ro', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-ro\', 500),
    ('coren-rr.implanta.net.br', 'improblob04', 'coren-rr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-rr\', 500),
    ('coren-rs.implanta.net.br', 'improblob04', 'coren-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-rs\', 500),
    ('coren-sc.implanta.net.br', 'improblob04', 'coren-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-sc\', 500),
    ('coren-sp.implanta.net.br', 'improblob04', 'coren-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-sp\', 500),
    ('coren-to.implanta.net.br', 'improblob04', 'coren-to', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\coren-to\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES --crbm
    ('crbm-01.implanta.net.br', 'improblob04', 'crbm-01', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crbm-01\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES('crea-ac.implanta.net.br', 'improblob04', 'crea-ac', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-ac\', 500),
    ('crea-al.implanta.net.br', 'improblob04', 'crea-al', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-al\', 500),
    ('crea-am.implanta.net.br', 'improblob04', 'crea-am', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-am\', 500),
    ('crea-ap.implanta.net.br', 'improblob04', 'crea-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-ap\', 500),
    ('crea-ba.implanta.net.br', 'improblob04', 'crea-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-ba\', 500),
    ('crea-ce.implanta.net.br', 'improblob04', 'crea-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-ce\', 500),
    ('crea-df.implanta.net.br', 'improblob04', 'crea-df', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-df\', 500),
    ('crea-es.implanta.net.br', 'improblob04', 'crea-es', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-es\', 500),
    ('crea-go.implanta.net.br', 'improblob04', 'crea-go', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-go\', 500),
    ('crea-mg.implanta.net.br', 'improblob04', 'crea-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-mg\', 500),
    ('crea-ms.implanta.net.br', 'improblob04', 'crea-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-ms\', 500),
    ('crea-mt.implanta.net.br', 'improblob04', 'crea-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-mt\', 500),
    ('crea-pa.implanta.net.br', 'improblob04', 'crea-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-pa\', 500),
    ('crea-pe.implanta.net.br', 'improblob04', 'crea-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-pe\', 500),
    ('crea-pr.implanta.net.br', 'improblob04', 'crea-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-pr\', 500),
    ('crea-rj.implanta.net.br', 'improblob04', 'crea-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-rj\', 500),
    ('crea-rn.implanta.net.br', 'improblob04', 'crea-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-rn\', 500),
    ('crea-ro.implanta.net.br', 'improblob04', 'crea-ro', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-ro\', 500),
    ('crea-rr.implanta.net.br', 'improblob04', 'crea-rr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-rr\', 500),
    ('crea-rs.implanta.net.br', 'improblob04', 'crea-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-rs\', 500),
    ('crea-sc.implanta.net.br', 'improblob04', 'crea-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-sc\', 500),
    ('crea-se.implanta.net.br', 'improblob04', 'crea-se', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-se\', 500),
    ('crea-sp.implanta.net.br', 'improblob04', 'crea-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-sp\', 500),
    ('crea-to.implanta.net.br', 'improblob04', 'crea-to', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crea-to\', 500);

    INSERT INTO #BancosDedados(
                                  banco,
                                  StorageAccount,
                                  Container,
                                  ConnectionStringAzureStorageArquivosAnexos,
                                  HorarioMigracao,
                                  UtilizaAzure,
                                  CaminhoCacheLocalAzureStorageArquivosAnexos,
                                  QuantidadeDeArquivosMigradosPorExecucao
                              )
    VALUES --crf
    ('crf-ac.implanta.net.br', 'improblob04', 'crf-ac', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ac\', 500),
    ('crf-al.implanta.net.br', 'improblob04', 'crf-al', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-al\', 500),
    ('crf-am.implanta.net.br', 'improblob04', 'crf-am', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-am\', 500),
    ('crf-ap.implanta.net.br', 'improblob04', 'crf-ap', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ap\', 500),
    ('crf-ba.implanta.net.br', 'improblob04', 'crf-ba', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ba\', 500),
    ('crf-ce.implanta.net.br', 'improblob04', 'crf-ce', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ce\', 500),
    ('crf-df.implanta.net.br', 'improblob04', 'crf-df', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-df\', 500),
    ('crf-es.implanta.net.br', 'improblob04', 'crf-es', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-es\', 500),
    ('crf-go.implanta.net.br', 'improblob04', 'crf-go', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-go\', 500),
    ('crf-ma.implanta.net.br', 'improblob04', 'crf-ma', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ma\', 500),
    ('crf-mg.implanta.net.br', 'improblob04', 'crf-mg', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-mg\', 500),
    ('crf-ms.implanta.net.br', 'improblob04', 'crf-ms', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ms\', 500),
    ('crf-mt.implanta.net.br', 'improblob04', 'crf-mt', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-mt\', 500),
    ('crf-pa.implanta.net.br', 'improblob04', 'crf-pa', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-pa\', 500),
    ('crf-pb.implanta.net.br', 'improblob04', 'crf-pb', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-pb\', 500),
    ('crf-pe.implanta.net.br', 'improblob04', 'crf-pe', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-pe\', 500),
    ('crf-pi.implanta.net.br', 'improblob04', 'crf-pi', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-pi\', 500),
    ('crf-pr.implanta.net.br', 'improblob04', 'crf-pr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-pr\', 500),
    ('crf-rj.implanta.net.br', 'improblob04', 'crf-rj', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-rj\', 500),
    ('crf-rn.implanta.net.br', 'improblob04', 'crf-rn', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-rn\', 500),
    ('crf-ro.implanta.net.br', 'improblob04', 'crf-ro', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-ro\', 500),
    ('crf-rr.implanta.net.br', 'improblob04', 'crf-rr', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-rr\', 500),
    ('crf-rs.implanta.net.br', 'improblob04', 'crf-rs', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-rs\', 500),
    ('crf-sc.implanta.net.br', 'improblob04', 'crf-sc', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-sc\', 500),
    ('crf-se.implanta.net.br', 'improblob04', 'crf-se', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-se\', 500),
    ('crf-sp.implanta.net.br', 'improblob04', 'crf-sp', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-sp\', 500),
    ('crf-to.implanta.net.br', 'improblob04', 'crf-to', 'DefaultEndpointsProtocol=https;AccountName=improblob04;AccountKey=S1mX9KTxe0Pqf0Z/pv/TNg/3iqpa+xidHgMGWAfF7lGileqEZtpRu6jF7pp0T1gcW0x7VgFMCKcZGA7IMSo5bg==;EndpointSuffix=core.windows.net', '03:00:00', 'true', 'D:\temp_blob_azure\crf-to\', 500);

    
	SELECT BD.StorageAccount, COUNT(1) FROM #BancosDedados AS BD
	GROUP BY BD.StorageAccount
	WHERE BD.StorageAccount ='improblob02'
	 

    /* declare variables */
    DECLARE @banco_Cursor                                       VARCHAR(200),
            @StorageAccount_Cursor                              VARCHAR(300),
            @Container_Cursor                                   VARCHAR(30),
            @ConnectionStringAzureStorageArquivosAnexos_Cursor  VARCHAR(MAX),
            @HorarioMigracao_Cursor                             VARCHAR(20),
            @UtilizaAzure_Cursor                                CHAR(4),
            @CaminhoCacheLocalAzureStorageArquivosAnexos_Cursor VARCHAR(200),
            @QuantidadeDeArquivosMigradosPorExecucao_Cursor     INT;

    DECLARE cursor_CriaConfiguracoes CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT TOP 1 * FROM #BancosDedados AS BD;

    --WHERE BD.banco = DB_NAME();
    OPEN cursor_CriaConfiguracoes;

    FETCH NEXT FROM cursor_CriaConfiguracoes
     INTO @banco_Cursor,
          @StorageAccount_Cursor,
          @Container_Cursor,
          @ConnectionStringAzureStorageArquivosAnexos_Cursor,
          @HorarioMigracao_Cursor,
          @UtilizaAzure_Cursor,
          @CaminhoCacheLocalAzureStorageArquivosAnexos_Cursor,
          @QuantidadeDeArquivosMigradosPorExecucao_Cursor;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF(NOT EXISTS (
                              SELECT *
                                FROM Sistema.Configuracoes AS C
                               WHERE
                                  C.Configuracao = 'ContainerAzureStorageArquivosAnexos'
                          )
              )
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
                          'ContainerAzureStorageArquivosAnexos',  -- Configuracao - varchar(100)
                          @Container_Cursor,                      -- Valor - varchar(max)
                          0                                       -- Ano - int
                      );

            IF(NOT EXISTS (
                              SELECT *
                                FROM Sistema.Configuracoes AS C
                               WHERE
                                  C.Configuracao = 'ConnectionStringAzureStorageArquivosAnexos'
                          )
              )
                INSERT INTO Sistema.Configuracoes(
                                                     CodConfiguracao,
                                                     CodSistema,
                                                     Modulo,
                                                     Configuracao,
                                                     Valor,
                                                     Ano
                                                 )
                VALUES(   NEWID(),                                            -- CodConfiguracao - uniqueidentifier
                          '00000000-0000-0000-0000-000000000000',             -- CodSistema - uniqueidentifier
                          'Global',                                           -- Modulo - varchar(100)
                          'ConnectionStringAzureStorageArquivosAnexos',       -- Configuracao - varchar(100)
                          @ConnectionStringAzureStorageArquivosAnexos_Cursor, -- Valor - varchar(max)
                          0                                                   -- Ano - int
                      );

            IF(NOT EXISTS (
                              SELECT *
                                FROM Sistema.Configuracoes AS C
                               WHERE
                                  C.Configuracao = 'HorarioMigracaoArquivosAnexosParaAzureStorage'
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
                    VALUES(   NEWID(),                                         -- CodConfiguracao - uniqueidentifier
                              '00000000-0000-0000-0000-000000000000',          -- CodSistema - uniqueidentifier
                              'Global',                                        -- Modulo - varchar(100)
                              'HorarioMigracaoArquivosAnexosParaAzureStorage', -- Configuracao - varchar(100)
                              @HorarioMigracao_Cursor,                         -- Valor - varchar(max)
                              0                                                -- Ano - int
                          );
                END;

            IF(NOT EXISTS (
                              SELECT *
                                FROM Sistema.Configuracoes AS C
                               WHERE
                                  C.Configuracao = 'UsaAzureStorageArquivosAnexos'
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
                              'UsaAzureStorageArquivosAnexos',        -- Configuracao - varchar(100)
                              @UtilizaAzure_Cursor,                   -- Valor - varchar(max)
                              0                                       -- Ano - int
                          );
                END;

            IF(NOT EXISTS (
                              SELECT *
                                FROM Sistema.Configuracoes AS C
                               WHERE
                                  C.Configuracao = 'CaminhoCacheLocalAzureStorageArquivosAnexos'
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
                    VALUES(   NEWID(),                                             -- CodConfiguracao - uniqueidentifier
                              '00000000-0000-0000-0000-000000000000',              -- CodSistema - uniqueidentifier
                              'Global',                                            -- Modulo - varchar(100)
                              'CaminhoCacheLocalAzureStorageArquivosAnexos',       -- Configuracao - varchar(100)
                              @CaminhoCacheLocalAzureStorageArquivosAnexos_Cursor, -- Valor - varchar(max)
                              0                                                    -- Ano - int
                          );
                END;

            IF(NOT EXISTS (
                              SELECT *
                                FROM Sistema.Configuracoes AS C
                               WHERE
                                  C.Configuracao = 'QuantidadeDeArquivosMigradosPorExecucao'
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
                    VALUES(   NEWID(),                                         -- CodConfiguracao - uniqueidentifier
                              '00000000-0000-0000-0000-000000000000',          -- CodSistema - uniqueidentifier
                              'Global',                                        -- Modulo - varchar(100)
                              'QuantidadeDeArquivosMigradosPorExecucao',       -- Configuracao - varchar(100)
                              @QuantidadeDeArquivosMigradosPorExecucao_Cursor, -- Valor - varchar(max)
                              0                                                -- Ano - int
                          );
                END;

            /* ==================================================================
			--Data: 28/03/2021 
			--Autor :Wesley Neves
			--Observação: Update
			 
			-- ==================================================================
			*/
            IF(EXISTS (
                          SELECT *
                            FROM Sistema.Configuracoes AS C
                           WHERE
                              C.Configuracao = 'QuantidadeDeArquivosMigradosPorExecucao'
                      )
              )
                BEGIN
                    UPDATE Sistema.Configuracoes
                       SET Valor = @QuantidadeDeArquivosMigradosPorExecucao_Cursor
                     WHERE
                        Configuracao = 'QuantidadeDeArquivosMigradosPorExecucao';
                END;

            SELECT @banco_Cursor,
                   @StorageAccount_Cursor,
                   @Container_Cursor,
                   @ConnectionStringAzureStorageArquivosAnexos_Cursor,
                   @HorarioMigracao_Cursor,
                   @UtilizaAzure_Cursor,
                   @CaminhoCacheLocalAzureStorageArquivosAnexos_Cursor,
                   @QuantidadeDeArquivosMigradosPorExecucao_Cursor;

            FETCH NEXT FROM cursor_CriaConfiguracoes
             INTO @banco_Cursor,
                  @StorageAccount_Cursor,
                  @Container_Cursor,
                  @ConnectionStringAzureStorageArquivosAnexos_Cursor,
                  @HorarioMigracao_Cursor,
                  @UtilizaAzure_Cursor,
                  @CaminhoCacheLocalAzureStorageArquivosAnexos_Cursor,
                  @QuantidadeDeArquivosMigradosPorExecucao_Cursor;
        END;

    CLOSE cursor_CriaConfiguracoes;
    DEALLOCATE cursor_CriaConfiguracoes;


	SELECT * FROM #BancosDedados AS BD
    /*End region */
    IF @ROLLBACK = 0
        BEGIN
            COMMIT TRANSACTION SCHEDULE;
        END;
    ELSE
        BEGIN
            ROLLBACK TRANSACTION SCHEDULE;
        END;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION SCHEDULE;

    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
    PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    PRINT 'Error detected, all changes reversed.';
END CATCH;