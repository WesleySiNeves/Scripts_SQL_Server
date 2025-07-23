DROP TABLE IF EXISTS #tempConselhosCategoria;
-- Criação da tabela temporária no SQL Server
CREATE TABLE #tempConselhosCategoria
    (
        Id              INT          IDENTITY(1, 1) PRIMARY KEY,
        Categoria       VARCHAR(50)  NOT NULL,
        NomeRazaoSocial VARCHAR(100) NOT NULL,
        Sigla           VARCHAR(20)  NOT NULL
    );


DROP TABLE IF EXISTS #DadosFinais;

CREATE TABLE #DadosFinais
    (
        [IdConselhoFederal] UNIQUEIDENTIFIER,
        [NomeRazaoSocial]   VARCHAR(250),
        [Sigla]             VARCHAR(50),
        [SkCategoria]       INT,
        [Ativo]             INT,
        [DataCarga]         DATETIME,
        [DataAtualizacao]   DATETIME
    );

-- Inserção dos dados com associação categoria-conselho
INSERT INTO #tempConselhosCategoria
    (
        Categoria,
        NomeRazaoSocial,
        Sigla
    )
VALUES
    (
        'VETERINÁRIA', 'Conselho Federal de Medicina Veterinária', 'CFMV'
    ),
    (
        'QUÍMICA', 'Conselho Federal de Química', 'CFQ'
    ),
    (
        'ODONTOLOGIA', 'Conselho Federal de Odontologia', 'CFO'
    ),
    (
        'TECNICOS AGRICOLAS', 'Conselho Federal dos Técnicos Agrícolas', 'CFTA'
    ),
    (
        'REL. PÚBLICAS', 'Conselho Federal de Profissionais de Relações Públicas', 'CONFERP'
    ),
    (
        'FONOAUDIOLOGIA', 'Conselho Federal de Fonoaudiologia', 'COFFITO'
    ),
    (
        'FISIOTERAPIA', 'Conselho Federal de Fisioterapia e Terapia Ocupacional', 'CFFA'
    ),
    (
        'BIOMEDICINA', 'Conselho Federal de Biomedicina', 'CFBM'
    ),
    (
        'PSICOLOGIA', 'Conselho Federal de Psicologia', 'CFP'
    ),
    (
        'TECNICOS INDUSTRIAIS', 'Conselho Federal de Técnicos', 'CFT'
    ),
    (
        'MEDICINA', 'Conselho Federal de Medicina', 'CFM'
    ),
    (
        'MEDICINA', 'Conselho Regional de Medicina', 'CRM'
    ),
    (
        'ADMINISTRAÇÃO', 'Conselho Federal de Administração', 'CFA'
    ),
    (
        'NUTRICIONISTAS', 'Conselho Federal de Nutrição', 'CFN'
    ),
    (
        'ENFERMAGEM', 'Conselho Federal de Enfermagem', 'COFEN'
    ),
    (
        'SERVIÇO SOCIAL', 'Conselho Federal de Serviço Social', 'CFESS'
    ),
    (
        'REPRESENTANTES', 'Conselho Federal de Representantes Comerciais', 'CONFERE'
    ),
    (
        'ESTATÍSTICA', 'Conselho Federal de Estatística', 'CONFE'
    ),
    (
        'EDUCAÇÃO FÍSICA', 'Conselho Federal de Educação Física', 'CONFEF'
    ),
    (
        'ARQUITETURA', 'Conselho de Arquitetura e Urbanismo do Brasil', 'CAU/BR'
    ),
    (
        'FARMÁCIA', 'Conselho Federal de Farmácia', 'CFF'
    ),
    (
        'RADIOLOGIA', 'Conselho Nacional dos Técnicos em Radiologia', 'CONTER'
    ),
    (
        'ENGENHARIA', 'Conselho Federal de Engenharia', 'CONFEA'
    );



-- Inserção dos conselhos adicionais que não estavam mapeados nas categorias originais
INSERT INTO #tempConselhosCategoria
    (
        Categoria,
        NomeRazaoSocial,
        Sigla
    )
VALUES
    (
        'BIOLOGIA', 'Conselho Federal de Biologia', 'CFBio'
    ),
    (
        'CONTABILIDADE', 'Conselho Federal de Contabilidade', 'CFC'
    ),
    (
        'DESIGNERS', 'Conselho Federal de Designers de Interiores', 'CFDD'
    ),
    (
        'EDUCAÇÃO', 'Conselho Federal de Educação', 'CFED'
    ),
    (
        'CORRETORES', 'Conselho Federal de Corretores de Imóveis', 'COFECI'
    ),
    (
        'ECONOMIA', 'Conselho Federal de Economia', 'COFECON'
    ),
    (
        'OFTALMOLOGIA', 'Conselho Brasileiro de Oftalmologia', 'CBO'
    ),
    (
        'MUSEOLOGIA', 'Conselho de Museologia', 'COFEM'
    ),
    (
        'BIBLIOTECÁRIO', 'Conselho Federal de Biblioteconomia', 'CFB'
    );


INSERT INTO #DadosFinais
            SELECT
                    conf.IdConselhoFederal,
                    conf.NomeRazaoSocial,
                    conf.Sigla,
                    R.SkCategoria,
                    1         AS Ativo,
                    GETDATE() AS DataCarga,
                    GETDATE() AS DataAtualizacao
            FROM
                    Implanta.ConselhosFederais conf
                LEFT JOIN
                    (
                        SELECT
                                con.*,
                                ISNULL(tem.Id, 0) AS SkCategoria,
                                tem.Categoria
                        FROM
                                Implanta.ConselhosFederais con
                            LEFT JOIN
                                #tempConselhosCategoria    tem
                                    ON con.Sigla = tem.Sigla
                    )                          R
                        ON R.Sigla = conf.Sigla;



MERGE Shared.DimConselhosFederais AS target
USING #DadosFinais AS source
ON target.Sigla = source.Sigla
WHEN MATCHED AND (
                     source.NomeRazaoSocial <> target.NomeRazaoSocial
                     OR target.IdConselhoFederal <> source.IdConselhoFederal
                     OR source.Ativo <> target.Ativo
                 )
    THEN UPDATE SET
             target.NomeRazaoSocial = source.NomeRazaoSocial,
             target.IdConselhoFederal = source.IdConselhoFederal,
             target.Ativo = source.Ativo
WHEN NOT MATCHED
    THEN INSERT
             (
                 IdConselhoFederal,
                 NomeRazaoSocial,
                 Sigla,
                 SkCategoria,
                 Ativo,
                 DataCarga,
                 DataAtualizacao
             )
         VALUES
             (
                 source.IdConselhoFederal, source.NomeRazaoSocial, source.Sigla, source.SkCategoria, source.Ativo,
                 source.DataCarga, source.DataAtualizacao
             );
  