

--DNE	BairrosFaixas	DataCadastro	datetime2	102516	0

--EXEC HealthCheck.uspCalculaAlteracaoCampoDatetime2ToDate @IdRegistro = 102516,    -- int
--                                                         @SchemaName = 'Cadastro',   -- varchar(256)
--                                                         @TableName = 'Emails',    -- varchar(256)
--                                                         @Column = 'DataCriacao',       -- varchar(128)
--                                                         @DataTypeAtual = 'datetime2' -- varchar(100)

CREATE OR  ALTER PROCEDURE HealthCheck.uspCalculaAlteracaoCampoDatetime2ToDate
(
    @IdRegistro    INT,
    @SchemaName    VARCHAR(256),
    @TableName     VARCHAR(256),
    @Column        VARCHAR(128),
    @DataTypeAtual VARCHAR(100)
)
AS
    BEGIN
        SET NOCOUNT ON;

        --DECLARE @IdRegistro    INT          = 839,
        --        @SchemaName    VARCHAR(256) = 'Planejamento',
        --        @TableName     VARCHAR(256) = 'Programas',
        --        @Column        VARCHAR(256) = 'DataInicioVigencia',
        --        @DataTypeAtual VARCHAR(100) = 'datetime2';

        --SELECT @IdRegistro = 1,                    -- int
        --       @SchemaName = 'Processo',           -- varchar(256)
        --       @TableName = 'ProcessosAndamentos', -- varchar(256)
        --       @Column = 'DataPrazo',              -- varchar(128)
        --       @DataTypeAtual = 'datetime2';       -- varchar(100) 

        IF(OBJECT_ID('TEMPDB..#Retorno') IS NOT NULL)
            DROP TABLE #Retorno;

        CREATE TABLE #Retorno
        (
            Id                             INT PRIMARY KEY,
            [SchemaName]                   NVARCHAR(128),
            [TableName]                    NVARCHAR(128),
            [Coluna]                       NVARCHAR(128),
            [Type]                         NVARCHAR(128),
            [Indexable]                    BIT,
            QuantidadeLinhas               INT,
            PossoAlterar                   BIT,
            DatabasesQuePossueValorHora    VARCHAR(MAX),
            DatabasesQueNaoPossueValorHora VARCHAR(MAX),
            DatabasesTableVazio            VARCHAR(MAX),
        );

        IF(OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
            DROP TABLE #Dados;

        CREATE TABLE #Dados
        (
            [SchemaName] NVARCHAR(128),
            [TableName]  NVARCHAR(128),
            [Rows]       INT,
            [object_id]  INT,
            [Coluna]     NVARCHAR(128),
            [Type]       NVARCHAR(128),
            [Indexable]  BIT
        );

        INSERT INTO #Dados
        SELECT SchemaName = S.name,
               TableName = T.name,
               S2.rows,
               [object_id] = T.object_id,
               [Coluna] = C.name COLLATE DATABASE_DEFAULT,
               [Type] = T2.name,
               CAST(COLUMNPROPERTYEX(C.object_id, C.name, 'IsIndexable') AS bit) AS Indexable
          FROM sys.tables AS T
               JOIN sys.sysindexes S2 ON T.object_id = S2.id
                                         AND S2.indid = 1
               JOIN sys.schemas AS S ON S.schema_id = T.schema_id
               JOIN sys.columns AS C ON C.object_id = T.object_id
               JOIN sys.types AS T2 ON T2.system_type_id = C.system_type_id
         WHERE
            C.is_computed = 0
            AND S.name = @SchemaName
            AND T.name = @TableName
            AND C.name = @Column
            AND T2.name = @DataTypeAtual
            AND NOT EXISTS (
                               SELECT *
                                 FROM sys.computed_columns AS CC
                                WHERE
                                   CC.object_id = T.object_id
                                   AND PATINDEX(CONCAT('%', C.name COLLATE DATABASE_DEFAULT, '%'), CC.definition COLLATE DATABASE_DEFAULT) > 1
                           );

        DECLARE @Sql VARCHAR(3000);
        DECLARE @aspas_simples CHAR(1) = CHAR(39);
        DECLARE @aspas_duplas CHAR(2) = CONCAT(CHAR(39), CHAR(39));

        SET @Sql = CONCAT(' IF(EXISTS (SELECT TOP 1 1 FROM #Dados AS D))', SPACE(1));
        SET @Sql += CONCAT('BEGIN', SPACE(1));
        SET @Sql += CONCAT(' IF(EXISTS (SELECT TOP 1 1 FROM #Dados AS D WHERE D.Rows = 0))', SPACE(1));
        SET @Sql += CONCAT('BEGIN', SPACE(1));
        SET @Sql += CONCAT('INSERT INTO #Retorno(
                                Id,
                                SchemaName,
                                TableName,
                                Coluna,
                                Type,
                                Indexable,
                                QuantidadeLinhas,
                                PossoAlterar,
                                DatabasesQuePossueValorHora,
                                DatabasesQueNaoPossueValorHora,
                                DatabasesTableVazio
                            )
			  SELECT ', @IdRegistro, SPACE(1), ',
               D.SchemaName,
               D.TableName,
               D.Coluna,
               D.Type,
               D.Indexable,
               D.Rows,
               CAST(1 AS BIT) as PossoAlterar,', '', @aspas_simples, '', @aspas_simples, ' As DatabasesQuePossueValorHora ', ',', @aspas_simples, @aspas_simples, ' AS DatabasesQueNaoPossueValorHora,', @aspas_simples, DB_NAME(), @aspas_simples, ' AS DatabasesTableVazio', ' FROM #Dados AS D
         WHERE
            D.Rows = 0 ');
        SET @Sql += CONCAT('END;', SPACE(1));
        SET @Sql += CONCAT('ELSE', SPACE(1));
        SET @Sql += CONCAT('BEGIN', SPACE(1));
        SET @Sql += CONCAT(' IF(EXISTS ( SELECT 1 FROM ', @SchemaName, '.', @TableName, ' AS X');
        SET @Sql += CONCAT(' WHERE  TRY_CAST(CAST(X.', @Column, ' AS VARCHAR(20)) AS TIME) <> ''00:00:00.0000000'' ))');
        SET @Sql += CONCAT(' BEGIN INSERT INTO #Retorno
										(Id,
									    SchemaName,
										TableName,
										Coluna,
										Type,
										Indexable,
										QuantidadeLinhas,
										PossoAlterar,
										DatabasesQuePossueValorHora,
										DatabasesQueNaoPossueValorHora,
										DatabasesTableVazio)', SPACE(2));
        SET @Sql += CONCAT('SELECT', SPACE(1), @IdRegistro, ',', SPACE(1), 'D.SchemaName,
					  D.TableName,
                      D.Coluna,
                      D.Type,
                      D.Indexable,
                      D.Rows,
                      CAST(0 AS BIT) PossoAlterar,', @aspas_simples, DB_NAME(), @aspas_simples, ' AS DatabasesQuePossueValorHora', ',', @aspas_simples, @aspas_simples, ' As DatabasesQueNaoPossueValorHora ,', @aspas_simples, @aspas_simples, ' AS DatabasesTableVazio', ' FROM #Dados AS D ');
        SET @Sql += CONCAT(' END;', SPACE(1));
        SET @Sql += CONCAT('ELSE', SPACE(1));
        SET @Sql += CONCAT('BEGIN', SPACE(1));
        SET @Sql += CONCAT('INSERT INTO #Retorno(Id,
										SchemaName,
										TableName,
										Coluna,
										Type,
										Indexable,
										QuantidadeLinhas,
										PossoAlterar,
										DatabasesQuePossueValorHora,
										DatabasesQueNaoPossueValorHora,
										DatabasesTableVazio)', SPACE(1));
        SET @Sql += CONCAT('
                SELECT ', @IdRegistro, SPACE(1), ',
                       D.SchemaName,
                       D.TableName,
                       D.Coluna,
                       D.Type,
                       D.Indexable,
                       D.Rows,
                       CAST(1 AS BIT) PossoAlterar,', '', @aspas_simples, '', @aspas_simples, ' As DatabasesQuePossueValorHora ', ',', @aspas_simples, DB_NAME(), @aspas_simples, ' AS DatabasesQueNaoPossueValorHora,', @aspas_simples, @aspas_simples, ' AS DatabasesTableVazio ', ' FROM #Dados AS D  END;', SPACE(1));
        SET @Sql += CONCAT(' END;', SPACE(1));
        SET @Sql += CONCAT(' END;', SPACE(1));

        EXEC(@Sql);

        SELECT * FROM #Retorno AS R;
    END;
GO