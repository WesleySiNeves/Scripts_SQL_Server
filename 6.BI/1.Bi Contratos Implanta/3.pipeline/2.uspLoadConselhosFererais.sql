
/*
SELECT * FROM  Shared.DimConselhosFederais
*/


CREATE OR ALTER PROCEDURE Shared.uspLoadDimConselhosFederais
AS
BEGIN

    BEGIN TRY

        DROP TABLE IF EXISTS #tempConselhosCategoria;
        -- Criação da tabela temporária no SQL Server
        CREATE TABLE #tempConselhosCategoria
        (
            Id INT IDENTITY(1, 1) PRIMARY KEY,
            Categoria VARCHAR(50) NOT NULL,
            NomeRazaoSocial VARCHAR(100) NOT NULL,
            Sigla VARCHAR(20) NOT NULL
        );

        -- Inserção dos dados com associação categoria-conselho
        INSERT INTO #tempConselhosCategoria
        (
            Categoria,
            NomeRazaoSocial,
            Sigla
        )
        VALUES
        ('VETERINÁRIA', 'Conselho Federal de Medicina Veterinária', 'CFMV'),
        ('QUÍMICA', 'Conselho Federal de Química', 'CFQ'),
        ('ODONTOLOGIA', 'Conselho Federal de Odontologia', 'CFO'),
        ('TECNICOS AGRICOLAS', 'Conselho Federal dos Técnicos Agrícolas', 'CFTA'),
        ('REL. PÚBLICAS', 'Conselho Federal de Profissionais de Relações Públicas', 'CONFERP'),
        ('FONOAUDIOLOGIA', 'Conselho Federal de Fonoaudiologia', 'COFFITO'),
        ('FISIOTERAPIA', 'Conselho Federal de Fisioterapia e Terapia Ocupacional', 'CFFA'),
        ('BIOMEDICINA', 'Conselho Federal de Biomedicina', 'CFBM'),
        ('PSICOLOGIA', 'Conselho Federal de Psicologia', 'CFP'),
        ('TECNICOS INDUSTRIAIS', 'Conselho Federal de Técnicos', 'CFT'),
        ('MEDICINA', 'Conselho Federal de Medicina', 'CFM'),
        ('MEDICINA', 'Conselho Regional de Medicina', 'CRM'),
        ('ADMINISTRAÇÃO', 'Conselho Federal de Administração', 'CFA'),
        ('NUTRICIONISTAS', 'Conselho Federal de Nutrição', 'CFN'),
        ('ENFERMAGEM', 'Conselho Federal de Enfermagem', 'COFEN'),
        ('SERVIÇO SOCIAL', 'Conselho Federal de Serviço Social', 'CFESS'),
        ('REPRESENTANTES', 'Conselho Federal de Representantes Comerciais', 'CONFERE'),
        ('ESTATÍSTICA', 'Conselho Federal de Estatística', 'CONFE'),
        ('EDUCAÇÃO FÍSICA', 'Conselho Federal de Educação Física', 'CONFEF'),
        ('ARQUITETURA', 'Conselho de Arquitetura e Urbanismo do Brasil', 'CAU/BR'),
        ('FARMÁCIA', 'Conselho Federal de Farmácia', 'CFF'),
        ('RADIOLOGIA', 'Conselho Nacional dos Técnicos em Radiologia', 'CONTER'),
        ('ENGENHARIA', 'Conselho Federal de Engenharia', 'CONFEA');



        -- Inserção dos conselhos adicionais que não estavam mapeados nas categorias originais
        INSERT INTO #tempConselhosCategoria
        (
            Categoria,
            NomeRazaoSocial,
            Sigla
        )
        VALUES
        ('BIOLOGIA', 'Conselho Federal de Biologia', 'CFBio'),
        ('CONTABILIDADE', 'Conselho Federal de Contabilidade', 'CFC'),
        ('DESIGNERS', 'Conselho Federal de Designers de Interiores', 'CFDD'),
        ('EDUCAÇÃO', 'Conselho Federal de Educação', 'CFED'),
        ('CORRETORES', 'Conselho Federal de Corretores de Imóveis', 'COFECI'),
        ('ECONOMIA', 'Conselho Federal de Economia', 'COFECON'),
        ('OFTALMOLOGIA', 'Conselho Brasileiro de Oftalmologia', 'CBO'),
        ('MUSEOLOGIA', 'Conselho de Museologia', 'COFEM'),
        ('BIBLIOTECÁRIO', 'Conselho Federal de Biblioteconomia', 'CFB');


        DROP TABLE IF EXISTS #Dados;
        CREATE TABLE #Dados
        (
            [IdConselhoFederal] UNIQUEIDENTIFIER,
            [NomeRazaoSocial] VARCHAR(250),
            [Sigla] VARCHAR(50),
            [SkCategoria] INT,
            [Ativo] INT,
            [DataCarga] DATETIME,
            [DataAtualizacao] DATETIME
        );

        INSERT INTO #Dados
        SELECT conf.IdConselhoFederal,
               conf.NomeRazaoSocial,
               conf.Sigla,
               R.SkCategoria,
               1 AS Ativo,
               GETDATE() AS DataCarga,
               GETDATE() AS DataAtualizacao
        FROM Implanta.ConselhosFederais conf
            LEFT JOIN
            (
                SELECT con.*,
                       ISNULL(tem.Id, 0) AS SkCategoria,
                       tem.Categoria
                FROM Implanta.ConselhosFederais con
                    LEFT JOIN #tempConselhosCategoria tem
                        ON con.Sigla = tem.Sigla
            ) R
                ON R.Sigla = conf.Sigla;


        MERGE INTO Shared.DimConselhosFederais AS target
        USING #Dados AS SOURCE
        ON target.Sigla = SOURCE.Sigla COLLATE Latin1_General_CI_AI
        WHEN MATCHED THEN
            UPDATE SET target.NomeRazaoSocial = SOURCE.NomeRazaoSocial,
                       target.SkCategoria = SOURCE.SkCategoria,
                       target.Ativo = SOURCE.Ativo,
                       target.DataAtualizacao = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT
            (
                IdConselhoFederal,
                NomeRazaoSocial,
                Sigla,
                SkCategoria,
                Ativo,
                DataAtualizacao,
                DataCarga
            )
            VALUES
            (SOURCE.IdConselhoFederal, SOURCE.NomeRazaoSocial, SOURCE.Sigla, SOURCE.SkCategoria, SOURCE.Ativo,
             SOURCE.DataAtualizacao, SOURCE.DataCarga);




    END TRY
    BEGIN CATCH
        -- Tratamento de erros melhorado
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();

        -- Log detalhado do erro
        PRINT '========== ERRO NA EXECUÇÃO DA PROCEDURE ==========';
        PRINT 'Procedure: ' + ISNULL(@ErrorProcedure, 'uspInsertUpdateDw');
        PRINT 'Número do Erro: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Linha do Erro: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT 'Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(MAX));
        PRINT 'Estado: ' + CAST(@ErrorState AS VARCHAR(MAX));

        PRINT '==================================================';

        -- Re-lança o erro para o cliente
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    END CATCH;
END;
