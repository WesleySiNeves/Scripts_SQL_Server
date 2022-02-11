DECLARE @MascararDados BIT = 1;
DECLARE @DetalharCamposSensiveis BIT = 0;

DECLARE @MascararCPFCNPJ BIT = CAST('$_MASCARAR_CPFCNPJ' AS BIT);

IF(EXISTS (
              SELECT * FROM sys.syscursors AS S WHERE S.cursor_name = 'cursor_Execute'
          )
  )
    BEGIN
        DEALLOCATE cursor_Execute;
    END;

IF(OBJECT_ID('TEMPDB..#TermosSensiveis') IS NOT NULL)
    DROP TABLE #TermosSensiveis;

CREATE TABLE #TermosSensiveis
(
    id            SMALLINT PRIMARY KEY IDENTITY(1, 1),
    Termo         VARCHAR(50),
    Classificacao VARCHAR(50),
    Tipo          VARCHAR(50)
);

INSERT INTO #TermosSensiveis
SELECT X.Coluna,
       X.Classificacao,
       X.Tipo
  FROM(
          VALUES('Email', 'Email', 'Contact Info'),
                ('Endereco', 'Endereco', 'Contact Info'),
                ('Eletronico', 'Email', 'Contact Info'),
                ('Link', 'Email', 'Contact Info'),
                ('Site', 'Email', 'Contact Info'),
                ('Logradouro', 'Endereco', 'Contact Info'),
                ('telefone', 'Telefone', 'Contact Info'),
                ('CEP', 'Endereco', 'Contact Info'),
                ('CaixaPostal', 'Endereco', 'Contact Info'),
                ('Passaporte', 'Documento', 'Person Info'),
                ('CPF', 'Documento', 'Person Info'),
                ('CNPJ', 'Documento', 'Person Info'),
                ('CNH', 'Documento', 'Person Info'),
                ('RGIE', 'Documento', 'Person Info'),
                ('Nascimento', 'Person', 'Person Info'),
                ('PISPASEP', 'Person', 'Person Info'),
                ('Nacionalidade', 'Person', 'Person Info'),
                ('Naturalidade', 'Person', 'Person Info'),
                ('EstadoCivil', 'Person', 'Person Info'),
                ('Etnia', 'Person', 'Person Info'),
                ('TipoSanguineo', 'Person', 'Person Info'),
                ('Religiao', 'Person', 'Person Info'),
                ('Deficiencia', 'Person', 'Person Info')
      ) AS X(Coluna, Classificacao, Tipo);

IF(@DetalharCamposSensiveis = 1)
    BEGIN
        SELECT * FROM #TermosSensiveis AS TS;
    END;

DROP TABLE IF EXISTS #ConfidencialData;

CREATE TABLE #ConfidencialData
(
    [SchemaName]     VARCHAR(128),
    [TableName]      VARCHAR(128),
    [PK]             VARCHAR(128),
    [CollunsName]    VARCHAR(128),
    Tamanho          INT,
    [is_nullable]    BIT,
    [TypeData]       VARCHAR(128),
    [Tipo]           VARCHAR(12),
    Level            VARCHAR(30),
    [Classificacao]  VARCHAR(20),
    ScriptSql        NVARCHAR(MAX)
);

IF ( OBJECT_ID('TEMPDB..#AllData') IS NOT NULL )
    DROP TABLE #AllData;	

CREATE TABLE #AllData
(
    [SchemaName]  VARCHAR(128),
    [TableName]   VARCHAR(128),
    [PK]          VARCHAR(128),
    [CollunsName] VARCHAR(128),
    [max_length]  SMALLINT,
    [is_nullable] BIT,
    [TypeData]    VARCHAR(128),
    [Level]       VARCHAR(12)
);


INSERT INTO #AllData
SELECT S.name SchemaName,
       T.name AS TableName,
       Pk.PK,
       C.name AS CollunsName,
       C.max_length,
       C.is_nullable is_nullable,
       T2.name AS TypeData,
       -- @Tipo AS Tipo,
       'Confidential' AS Level
  -- @Classificacao AS Classificacao
  FROM sys.schemas AS S
       JOIN sys.tables AS T ON T.schema_id = S.schema_id
       JOIN sys.dm_db_partition_stats partition ON partition.object_id = T.object_id
       JOIN sys.columns AS C ON C.object_id = T.object_id
       JOIN sys.types AS T2 ON T2.user_type_id = C.user_type_id
       JOIN(
               SELECT T3.object_id,
                      C2.name AS PK,
                      T4.name AS Tipo
                 FROM sys.tables AS T3
                      JOIN sys.columns AS C2 ON C2.object_id = T3.object_id
                      JOIN sys.types AS T4 ON T4.system_type_id = C2.system_type_id
                WHERE
                   C2.column_id = 1
           )Pk ON Pk.object_id = T.object_id
 WHERE
    partition.index_id = 1
    AND partition.row_count > 0
    AND C.is_computed = 0
    AND NOT EXISTS (
                       SELECT I.name,
                              IC.column_id,
                              Co.name,
                              I.is_unique
                         FROM sys.indexes AS I
                              JOIN sys.index_columns IC ON IC.object_id = I.object_id
                                                           AND I.index_id = IC.index_id
                              JOIN sys.columns Co ON Co.object_id = I.object_id
                                                     AND IC.column_id = Co.column_id
                        WHERE
                           I.object_id = T.object_id
                           AND Co.column_id = C.column_id
                           AND I.is_unique = 1
                   );


DECLARE @id            SMALLINT,
        @Termo         VARCHAR(50),
        @Classificacao VARCHAR(100),
        @Tipo          VARCHAR(100);

DECLARE cursor_TermosSensiveis CURSOR FAST_FORWARD READ_ONLY FOR
SELECT * FROM #TermosSensiveis AS TS;

OPEN cursor_TermosSensiveis;

FETCH NEXT FROM cursor_TermosSensiveis
 INTO @id,
      @Termo,
      @Classificacao,
      @Tipo;

WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #ConfidencialData(
                                         SchemaName,
                                         TableName,
                                         PK,
                                         CollunsName,
                                         Tamanho,
                                         is_nullable,
                                         TypeData,
                                         Tipo,
                                         Level,
                                         Classificacao
                                     )
        SELECT S.SchemaName SchemaName,
               S.TableName AS TableName,
               S.PK,
               S.CollunsName,
               S.max_length,
               S.is_nullable is_nullable,
               S.TypeData,
               @Tipo AS Tipo,
               'Confidential' AS Level,
               @Classificacao AS Classificacao
          FROM #AllData AS S
         WHERE
            S.CollunsName LIKE CONCAT('%', @Termo, '%')

        FETCH NEXT FROM cursor_TermosSensiveis
         INTO @id,
              @Termo,
              @Classificacao,
              @Tipo;
    END;

	

CLOSE cursor_TermosSensiveis;
DEALLOCATE cursor_TermosSensiveis;



DELETE CD FROM #ConfidencialData AS CD WHERE CD.CollunsName LIKE '%Label%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName LIKE '%Status%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName LIKE '%Tipo%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName LIKE '%IdConfiguracao%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName LIKE '%Validar%';

DELETE CD FROM #ConfidencialData AS CD WHERE TypeData IN ('bit', 'int');

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName LIKE '%Script%';

DELETE CD FROM #ConfidencialData AS CD WHERE CD.CollunsName LIKE '%sql%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName LIKE '%SiglaUF%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.CollunsName IN ('EnderecoPortal');

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.TableName IN ('Aeroportos', 'LocaisEntregas', 'Bancos', 'Menus');

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.TableName LIKE '%arquivos%';

DELETE CD FROM #ConfidencialData AS CD WHERE CD.TableName LIKE '%Cnab%';

DELETE CD FROM #ConfidencialData AS CD WHERE CD.TableName LIKE '%dirf%';

DELETE CD
  FROM #ConfidencialData AS CD
 WHERE
    CD.TableName LIKE '%integracao%';

DELETE CD FROM #ConfidencialData AS CD WHERE CD.SchemaName = 'DNE';

DELETE CD FROM #ConfidencialData AS CD WHERE CD.CollunsName LIKE '%DNE%';

;WITH Duplicates
    AS
    (
        SELECT TM.SchemaName,
               TM.TableName,
               TM.CollunsName,
               TM.Tamanho,
               TM.TypeData,
               TM.Classificacao,
               RN = ROW_NUMBER() OVER (PARTITION BY TM.SchemaName,
                                                    TM.TableName,
                                                    TM.CollunsName,
                                                    TM.Tamanho,
                                                    TM.TypeData,
                                                    TM.Classificacao
                                           ORDER BY(
                                                       SELECT NULL
                                                   )
                                      )
          FROM #ConfidencialData AS TM
    )
DELETE R FROM Duplicates R WHERE R.RN > 1;

IF(@DetalharCamposSensiveis = 1)
    BEGIN
      SELECT * FROM #ConfidencialData AS CD
    END;
	

IF(@DetalharCamposSensiveis = 1)
    BEGIN
        DROP TABLE IF EXISTS #TabelasModificaveis;

        CREATE TABLE #TabelasModificaveis
        (
            [SchemaName]     VARCHAR(150),
            [TableName]      VARCHAR(150),
            [PK]             VARCHAR(50),
            [ValorPK]        UNIQUEIDENTIFIER,
            [ColunaSensivel] VARCHAR(200),
            [ValorSensivel]  VARCHAR(MAX),
            Tipo             VARCHAR(200),
            Level            VARCHAR(100),
            Classificacao    VARCHAR(100),
        );

        DECLARE @Script_Select_Insert NVARCHAR(4000);
        DECLARE @Script_Select NVARCHAR(2000);
        DECLARE @SchemaName      VARCHAR(128),
                @TableName       VARCHAR(128),
                @PK              VARCHAR(128),
                @CollunsName     VARCHAR(128),
                @TypeData        VARCHAR(128),
                @Tipo_C          VARCHAR(12),
                @Level           VARCHAR(30),
                @Classificacao_C VARCHAR(20);

        DECLARE cursor_LGDP CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT CD.SchemaName,
               CD.TableName,
               CD.PK,
               CD.CollunsName,
               CD.TypeData,
               CD.Tipo,
               CD.Level,
               CD.Classificacao
          FROM #ConfidencialData AS CD;

        --WHERE
        --   CD.Classificacao = 'Endereco';
        OPEN cursor_LGDP;

        FETCH NEXT FROM cursor_LGDP
         INTO @SchemaName,
              @TableName,
              @PK,
              @CollunsName,
              @TypeData,
              @Tipo_C,
              @Level,
              @Classificacao_C;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @Script_Select_Insert = CONCAT('IF (EXISTS (SELECT TOP 1 1 FROM ', SPACE(1), QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), ' AS X');
                SET @Script_Select_Insert += CONCAT(' WHERE LEN(X.', @CollunsName, ') > 0 ))');
                SET @Script_Select_Insert += CONCAT(SPACE(1), 'BEGIN', SPACE(1));
                SET @Script_Select_Insert += CONCAT(SPACE(2), 'INSERT INTO #TabelasModificaveis ');
                SET @Script_Select_Insert += CONCAT('SELECT ', CHAR(39), @SchemaName, CHAR(39), ' AS SchemaName, ', CHAR(39), @TableName, CHAR(39), ' as TableName, ', CHAR(39), @PK, CHAR(39), ' AS PK,', ' X.', @PK, ' AS ValorPK,', CHAR(39), @CollunsName, CHAR(39), ' as ColunaSensivel, ', 'X.', @CollunsName, ' AS ValorSensivel ,', CHAR(39), @Tipo_C, CHAR(39), ' as Tipo, ', CHAR(39), @Level, CHAR(39), ' as Level, ', CHAR(39), @Classificacao_C, CHAR(39), ' as Classificacao ', ' FROM ', SPACE(1), QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), ' as X');
                SET @Script_Select_Insert += CONCAT(' WHERE LEN(X.', @CollunsName, ') > 0');
                SET @Script_Select_Insert += CONCAT(SPACE(1), 'END', SPACE(1));
                SET @Script_Select = CONCAT('SELECT ', CHAR(39), @SchemaName, CHAR(39), ' AS SchemaName, ', CHAR(39), @TableName, CHAR(39), ' as TableName, ', CHAR(39), @PK, CHAR(39), ' AS PK,', ' X.', @PK, ' AS ValorPK,', CHAR(39), @CollunsName, CHAR(39), ' as ColunaSensivel, ', 'X.', @CollunsName, ' AS ValorSensivel, ', CHAR(39), @Tipo_C, CHAR(39), ' as Tipo, ', CHAR(39), @Level, CHAR(39), ' as Level, ', CHAR(39), @Classificacao_C, CHAR(39), ' as Classificacao ', ' FROM ', SPACE(1), QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), ' as X');
                SET @Script_Select += CONCAT(' WHERE LEN(X.', @CollunsName, ') > 0');

                --  EXEC sys.sp_executesql @Script_Select;
                EXEC sys.sp_executesql @Script_Select_Insert;

                FETCH NEXT FROM cursor_LGDP
                 INTO @SchemaName,
                      @TableName,
                      @PK,
                      @CollunsName,
                      @TypeData,
                      @Tipo_C,
                      @Level,
                      @Classificacao_C;
            END;

        CLOSE cursor_LGDP;
        DEALLOCATE cursor_LGDP;
    END;

UPDATE #ConfidencialData SET Tamanho = IIF(Tamanho = -1, 1000, Tamanho);

DECLARE @SchemaName_update     VARCHAR(150),
        @TableName_update      VARCHAR(150),
        @ColunaSensivel_update VARCHAR(200),
        @Tamanho_update        INT,
        @Type_data_update      VARCHAR(200),
        @Classificacao_update  VARCHAR(200);
DECLARE @ScriptUpdate VARCHAR(MAX) = '';

DECLARE cursor_Update CURSOR FAST_FORWARD READ_ONLY FOR
SELECT CD.SchemaName,
       CD.TableName,
       CD.CollunsName,
       CD.Tamanho,
       CD.TypeData,
       CD.Classificacao
  FROM #ConfidencialData AS CD;

--  WHERE CD.TableName ='Inspetorias'

--WHERE
--   CD.Classificacao IN ('Person');
OPEN cursor_Update;

FETCH NEXT FROM cursor_Update
 INTO @SchemaName_update,
      @TableName_update,
      @ColunaSensivel_update,
      @Tamanho_update,
      @Type_data_update,
      @Classificacao_update;

WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ScriptUpdate = '';

        IF(@Classificacao_update = 'Email')
            BEGIN
                IF(@Type_data_update = 'varchar')
                    BEGIN
                        IF(
                              @ColunaSensivel_update LIKE '%assunto%'
                              OR @ColunaSensivel_update LIKE '%Texto%'
                          )
                            BEGIN
                                SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', CHAR(39), 'não informado', CHAR(39), ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                            END;
                        ELSE
                            BEGIN
                                SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', CHAR(39), 'implanta30@implantainfo.com.br', CHAR(39), ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                            END;
                    END;
            END;

        IF(@Classificacao_update = 'Telefone')
            BEGIN
                IF(@Type_data_update = 'varchar')
                    BEGIN
                        SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), '9999999999', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                    END;
            END;

        IF(@Classificacao_update = 'Endereco')
            BEGIN
                IF(@Type_data_update = 'varchar')
                    BEGIN
                        IF(
                              @ColunaSensivel_update IN ('CEP', 'CaixaPostal')
                              AND LEN(@ColunaSensivel_update) = 0
                          )
                            BEGIN
                                SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), '00.000-000', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                            END;
                        ELSE IF(
                                   @ColunaSensivel_update LIKE '%Numero%'
                                   AND LEN(@ColunaSensivel_update) = 0
                               )
                                 BEGIN
                                     SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', CHAR(39), '0', CHAR(39), ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                                 END;
                        ELSE
                                 BEGIN
                                     SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), '00.000-000', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                                 END;
                    END;
            END;

        IF(@Classificacao_update = 'Documento')
            BEGIN
                IF(@Type_data_update = 'varchar')
                    BEGIN
                        IF(@ColunaSensivel_update LIKE '%Passaporte%' AND LEN(@ScriptUpdate) = 0)
                            BEGIN
                                SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), 'GA499999', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                            END;

                        IF(@ColunaSensivel_update LIKE '%RGIE%' AND LEN(@ScriptUpdate) = 0)
                            BEGIN
                                SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), '11111111-9', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                            END;

                        IF(@ColunaSensivel_update = 'CPF' AND LEN(@ScriptUpdate) = 0)
                            BEGIN
                                IF(@MascararCPFCNPJ = 1)
                                    BEGIN
                                        SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', CHAR(39), '111.111.111-11', CHAR(39), ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                                    END;
                            END;

                        IF(@ColunaSensivel_update LIKE '%CNPJ%' AND LEN(@ScriptUpdate) = 0)
                            BEGIN
                                IF(@MascararCPFCNPJ = 1)
                                    BEGIN
                                        SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'IIF(LEN(RTRIM(LTRIM(target.', QUOTENAME(@ColunaSensivel_update), '))) <= 15,', SPACE(2), CHAR(39), '111.111.111-11', CHAR(39), ',', SPACE(2), CHAR(39), '00.000.000/0000-00', CHAR(39), ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                                    END;
                            END;
                    END;
            END;

        IF(@Classificacao_update = 'Person')
            BEGIN
                IF(@Type_data_update IN ('date', 'datetime2'))
                    BEGIN
                        SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', CHAR(39), '2000-01-01', CHAR(39), ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                    END;

                IF(@Type_data_update IN ('varchar'))
                    BEGIN
                        SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), 'Não informado', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
                    END;
            END;

        IF(
              LEN(@ScriptUpdate) = 0
              AND @Type_data_update IN ('varchar')
              AND NOT(
                         @ColunaSensivel_update = 'CPF'
                         OR @ColunaSensivel_update LIKE '%CNPJ%'
                     )
          )
            BEGIN
                SET @ScriptUpdate = CONCAT('UPDATE target SET target.', QUOTENAME(@ColunaSensivel_update), '=', 'SUBSTRING(', CHAR(39), 'Não informado', CHAR(39), ',', '0', ',', @Tamanho_update, ')', ' FROM  ', QUOTENAME(@SchemaName_update), '.', QUOTENAME(@TableName_update), ' as target');
            END;

        IF(LEN(@ScriptUpdate) > 0)
            BEGIN
                SET @ScriptUpdate = CONCAT(@ScriptUpdate, SPACE(2), ' WHERE target.', QUOTENAME(@ColunaSensivel_update), ' IS NOT NULL ');
            END;

        UPDATE target
           SET target.ScriptSql = @ScriptUpdate
          FROM #ConfidencialData AS target
         WHERE
            target.SchemaName = @SchemaName_update
            AND target.TableName = @TableName_update
            AND target.CollunsName = @ColunaSensivel_update;

        FETCH NEXT FROM cursor_Update
         INTO @SchemaName_update,
              @TableName_update,
              @ColunaSensivel_update,
              @Tamanho_update,
              @Type_data_update,
              @Classificacao_update;
    END;

CLOSE cursor_Update;
DEALLOCATE cursor_Update;

UPDATE target
   SET target.ScriptSql = CONCAT('UPDATE target SET target.', QUOTENAME(target.CollunsName), '=', CHAR(39), '00000000-0000-0000-0000-000000000700', CHAR(39), ' FROM  ', QUOTENAME(target.SchemaName), '.', QUOTENAME(target.TableName), ' as target')
  FROM #ConfidencialData target
 WHERE
    target.TableName = 'PessoasFisicas'
    AND target.CollunsName = 'IdTipoSanguineo';

UPDATE target
   SET target.ScriptSql = CONCAT('UPDATE target SET target.', QUOTENAME(target.CollunsName), '=', CHAR(39), '00000000-0000-0000-0000-000000000600', CHAR(39), ' FROM  ', QUOTENAME(target.SchemaName), '.', QUOTENAME(target.TableName), ' as target')
  FROM #ConfidencialData target
 WHERE
    target.TableName = 'PessoasFisicas'
    AND target.CollunsName = 'IdEtnia';

UPDATE target
   SET target.ScriptSql = CONCAT('UPDATE target SET target.', QUOTENAME(target.CollunsName), '=', CHAR(39), '00000000-0000-0000-0000-000000000000', CHAR(39), ' FROM  ', QUOTENAME(target.SchemaName), '.', QUOTENAME(target.TableName), ' as target')
  FROM #ConfidencialData target
 WHERE
    target.TableName = 'PessoasFisicas'
    AND target.CollunsName = 'IdNaturalidade';

UPDATE target
   SET target.ScriptSql = CONCAT('UPDATE target SET target.', QUOTENAME(target.CollunsName), '=', CHAR(39), 'E4FCA1B6-A10B-E111-A3B4-B8AC6FC43B89', CHAR(39), ' FROM  ', QUOTENAME(target.SchemaName), '.', QUOTENAME(target.TableName), ' as target')
  FROM #ConfidencialData target
 WHERE
    target.TableName = 'PessoasFisicas'
    AND target.CollunsName = 'IdEstadoCivil';

UPDATE target
   SET target.ScriptSql = CONCAT('UPDATE target SET target.', QUOTENAME(target.CollunsName), '=', CHAR(39), '00000000-0000-0000-0000-000000000000', CHAR(39), ' FROM  ', QUOTENAME(target.SchemaName), '.', QUOTENAME(target.TableName), ' as target')
  FROM #ConfidencialData target
 WHERE
    target.TableName = 'PessoasFisicas'
    AND target.CollunsName = 'IdReligiao';

IF(@MascararDados = 1)
    BEGIN

        /* declare variables */
        DECLARE @Schema_execute        VARCHAR(200),
                @Table_execute         VARCHAR(200),
                @Classificacao_execute VARCHAR(200),
                @Coluna_execute        VARCHAR(200),
                @Script_execute        NVARCHAR(MAX);

        DECLARE cursor_Execute CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT CD.SchemaName,
               CD.TableName,
               CD.Classificacao,
               CD.CollunsName,
               CD.ScriptSql
          FROM #ConfidencialData AS CD
         WHERE
            LEN(CD.ScriptSql) > 0;

        OPEN cursor_Execute;

        FETCH NEXT FROM cursor_Execute
         INTO @Schema_execute,
              @Table_execute,
              @Classificacao_execute,
              @Coluna_execute,
              @Script_execute;

        WHILE @@FETCH_STATUS = 0
            BEGIN

                /*Region Logical Querys*/
                EXEC sys.sp_executesql @Script_execute;

                FETCH NEXT FROM cursor_Execute
                 INTO @Schema_execute,
                      @Table_execute,
                      @Classificacao_execute,
                      @Coluna_execute,
                      @Script_execute;
            END;

        CLOSE cursor_Execute;
        DEALLOCATE cursor_Execute;
    END;



IF(@MascararCPFCNPJ = 1)
    BEGIN
                WITH Strip_Name
            AS
            (
                SELECT P.IdPessoa,
                       UPPER(CONCAT(String_AGG(strip.strip_Name, ' '), ' Da Silva')) stripName
                  FROM Cadastro.Pessoas AS P
                       CROSS APPLY(
                                      SELECT value AS strip_Name,
                                             RN = ROW_NUMBER() OVER (ORDER BY(SELECT NULL))
                                        FROM STRING_SPLIT(REPLACE(REPLACE(REPLACE(P.NomeRazaoSocial, 'DAS', ' '), 'DOS', ' '), 'DE', ' '), ' ')
                                  )strip
                 WHERE
                    P.TipoPessoaFisica = 1
                   
                    AND P.IdPessoa <> '00000000-1111-2222-3333-000000000002'
                    AND strip.RN <= 2
                 GROUP BY
                    P.IdPessoa
            )
        UPDATE P
           SET P.NomeRazaoSocial = strip.stripName
          FROM Cadastro.Pessoas AS P
               JOIN Strip_Name strip ON P.IdPessoa = strip.IdPessoa;

			   
			  

			 ;WITH Strip_PreCadastroLogico
            AS
            (
                SELECT P.IdPreCadastroLogico,
                       UPPER(CONCAT(String_AGG(strip.strip_Name, ' '), ' Da Silva')) stripName
                  FROM ONLINE.PreCadastroLogico P
                       CROSS APPLY(
                                      SELECT value AS strip_Name,
                                             RN = ROW_NUMBER() OVER (ORDER BY(SELECT NULL))
                                        FROM STRING_SPLIT(REPLACE(REPLACE(REPLACE(P.NomeRazaoSocial, 'DAS', ' '), 'DOS', ' '), 'DE', ' '), ' ')
                                  )strip
                 WHERE
                     strip.RN <= 2
					 AND LEN(P.CPFCNPJ) = 14
					 GROUP BY P.IdPreCadastroLogico
                
            )
        UPDATE P
           SET P.NomeRazaoSocial = strip.stripName
          FROM ONLINE.PreCadastroLogico AS P
               JOIN Strip_PreCadastroLogico strip ON P.IdPreCadastroLogico = strip.IdPreCadastroLogico;

    END;

/*Parte especifica para limpar configurações com vinculo ao cliente*/
UPDATE C
   SET C.Valor = 'D:\temp_blob_azure\demonstracao\'
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'CaminhoCacheLocalAzureStorageArquivosAnexos';

UPDATE C
   SET C.Valor = ''
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao LIKE '%Link%'
    AND LEN(C.Valor) > 0
    AND C.Configuracao NOT LIKE '%Treinamento%';

UPDATE C
   SET C.Valor = 'Demonstração/DF'
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'SiglaCliente';

UPDATE C
   SET C.Valor = 'Conselho de demonstração'
  FROM Sistema.Configuracoes AS C
 WHERE
    C.Configuracao = 'NomeClienteExtenso';

UPDATE P
   SET P.NomeRazaoSocial = 'Conselho de demonstração'
  FROM Cadastro.Pessoas AS P
 WHERE
    P.IdPessoa = '00000000-0000-0000-0000-000000000001';

UPDATE PJ
   SET PJ.Sigla = 'Demonstração/DF'
  FROM Cadastro.PessoasJuridicas AS PJ
 WHERE
    PJ.IdPessoaJuridica = '00000000-0000-0000-0000-000000000001';

UPDATE AA
   SET AA.Conteudo = NULL,
       AA.NomeIdentificadorStorageExterno = '',
       AA.UrlStorageExterno = ''
  FROM Sistema.ArquivosAnexos AS AA
 WHERE
    AA.Entidade = 'Cadastro.PessoasImagens'
    AND AA.IdEntidade IN(
                            SELECT PI.IdPessoaImagem
                              FROM Cadastro.PessoasJuridicas AS PJ
                                   JOIN Cadastro.PessoasImagens AS PI ON PI.IdPessoa = PJ.IdPessoa
                             WHERE
                                PJ.IdPessoaJuridica = '00000000-0000-0000-0000-000000000001'
                        );





/*Mascaramento em colunas JSON*/
/* declare variables */
DECLARE @IdPreCadastroLogico UNIQUEIDENTIFIER,
        @NomeRazaoSocial     VARCHAR(200),
        @Informacaoes        VARCHAR(MAX);
DECLARE @json VARCHAR(MAX) = '';

DECLARE cursor_LimpaDadosPessoaisInJson CURSOR FAST_FORWARD READ_ONLY FOR
SELECT IdPreCadastroLogico,
       NomeRazaoSocial,
       Informacoes
  FROM Online.PreCadastroLogico precadastro
   WHERE Informacoes IS NOT NULL

OPEN cursor_LimpaDadosPessoaisInJson;

FETCH NEXT FROM cursor_LimpaDadosPessoaisInJson
 INTO @IdPreCadastroLogico,
      @NomeRazaoSocial,
      @Informacaoes;
	  
WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @json = '';
        SET @json = @Informacaoes;

        SELECT @json = LOWER(@json);

		

		
        SET @json = JSON_MODIFY(@json, '$.nomerazaosocial', CONCAT(SUBSTRING(@NomeRazaoSocial, 0, CHARINDEX(' ', @NomeRazaoSocial)), ' DA SILVA'));
        SET @json = JSON_MODIFY(@json, '$.cpfcnpj', '999.999.999-99');
        SET @json = JSON_MODIFY(@json, '$.rgnumero', REPLICATE('1', LEN('$.rgnumero')));
        SET @json = JSON_MODIFY(@json, '$.tituloeleitornumero', '9999999909');
        SET @json = JSON_MODIFY(@json, '$.tituloeleitorsecao', '1111');
        SET @json = JSON_MODIFY(@json, '$.cdnumero', '9999');
        SET @json = JSON_MODIFY(@json, '$.endereco.logradouro', 'Não identificável');
        SET @json = JSON_MODIFY(@json, '$.endereco.complemento', 'Não identificável');
        SET @json = JSON_MODIFY(@json, '$.endereco.cep', '77777777');
        SET @json = JSON_MODIFY(@json, '$.nomepai', 'Não identificável');
        SET @json = JSON_MODIFY(@json, '$.nomemae', 'Não identificável');
        SET @json = JSON_MODIFY(@json, '$.telefonecomercial.telefone', '55555555500');
        SET @json = JSON_MODIFY(@json, '$.telefonecelular.telefone', '(61) 11111-0101');
        SET @json = JSON_MODIFY(@json, '$.telefoneresidencial.telefone', '(61) 11111-0101');
        SET @json = JSON_MODIFY(@json, '$.email.email', 'emailnaoinformado@emailnaoinformado.com');

		
		 
        UPDATE target
           SET target.Informacoes = @json
          FROM Online.PreCadastroLogico target
         WHERE
            target.IdPreCadastroLogico = @IdPreCadastroLogico;

        FETCH NEXT FROM cursor_LimpaDadosPessoaisInJson
         INTO @IdPreCadastroLogico,
              @NomeRazaoSocial,
              @Informacaoes;
    END;

CLOSE cursor_LimpaDadosPessoaisInJson;
DEALLOCATE cursor_LimpaDadosPessoaisInJson;
