--EXEC HealthCheck.uspDeletaArquivosAnexosOrfaoes


CREATE OR ALTER PROCEDURE HealthCheck.uspDeletarArquivosAnexosOrfaos
(
    @Visualizar BIT = 1,
    @Deletar    BIT = 0
)
AS
    BEGIN
        IF(OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
            DROP TABLE #Dados;

        CREATE TABLE #Dados
        (
            IdArquivoAnexo UNIQUEIDENTIFIER,
            [Entidade]     VARCHAR(50),
            [IdEntidade]   UNIQUEIDENTIFIER
        );

        IF(OBJECT_ID('TEMPDB..#DadosCompilados') IS NOT NULL)
            DROP TABLE #DadosCompilados;

        CREATE TABLE #DadosCompilados
        (
            [object_id]  INT,
            [PkColum]    NVARCHAR(128),
            [column_id]  INT,
            [Entidade]   VARCHAR(50),
            [IdEntidade] UNIQUEIDENTIFIER
        );

        INSERT INTO #Dados
        SELECT DISTINCT AA.IdArquivoAnexo,
               AA.Entidade,
               AA.IdEntidade
          FROM Sistema.ArquivosAnexos AS AA
         WHERE
            AA.ConteudoEmStorageExterno = 0;

        IF(OBJECT_ID('TEMPDB..#ArquivosIncosistentes') IS NOT NULL)
            DROP TABLE #ArquivosIncosistentes;

        CREATE TABLE #ArquivosIncosistentes
        (
            [IdArquivoAnexo]           UNIQUEIDENTIFIER,
            [IdEntidade]               UNIQUEIDENTIFIER,
            [Entidade]                 VARCHAR(50),
            [Nome]                     VARCHAR(200),
            [ContentType]              VARCHAR(100),
            [Tamanho]                  BIGINT,
            DataCadastro               DATETIME2(2),
            [ConteudoEmStorageExterno] BIT
        );

        /* declare variables */
        DECLARE @TableName  VARCHAR(128),
                @ShemaName  VARCHAR(128),
                @PkColum    VARCHAR(128),
                @column_id  INT,
                @Entidade   VARCHAR(50),
                @IdEntidade UNIQUEIDENTIFIER;

        DECLARE cursor_ValidaArquivosAnexos CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT T.name AS TableName,
               S.name AS ShemaName,
               C.name AS PkColum,
               C.column_id,
               D.Entidade,
               D.IdEntidade
          FROM sys.tables AS T
               JOIN sys.schemas AS S ON S.schema_id = T.schema_id
               JOIN sys.columns AS C ON C.object_id = T.object_id
               JOIN(
                       SELECT IC.object_id,
                              IC.index_id,
                              IC2.index_column_id,
                              IC2.column_id
                         FROM sys.indexes AS IC
                              JOIN sys.index_columns AS IC2 ON IC2.object_id = IC.object_id
                                                               AND IC2.index_id = IC.index_id
                        WHERE
                           IC.is_primary_key = 1
                   )X ON X.object_id = T.object_id
                         AND X.column_id = C.column_id
               JOIN #Dados AS D ON T.object_id = OBJECT_ID(D.Entidade)
         WHERE
            C.column_id = 1
         ORDER BY
            D.Entidade;

        OPEN cursor_ValidaArquivosAnexos;

        FETCH NEXT FROM cursor_ValidaArquivosAnexos
         INTO @TableName,
              @ShemaName,
              @PkColum,
              @column_id,
              @Entidade,
              @IdEntidade;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @HasErrorOnInsertSelect INT = 0;
                DECLARE @Sql NVARCHAR(3000) = '';

                SET @Sql = CONCAT(' IF(NOT EXISTS ( SELECT X.', @PkColum, ' FROM ', '[', @ShemaName, '].[', @TableName, ']', ' AS X WHERE X.', @PkColum, ' =', CHAR(39), @IdEntidade, CHAR(39), ' ))');
                SET @Sql += CONCAT(' BEGIN INSERT INTO #ArquivosIncosistentes
											SELECT IdArquivoAnexo,
												   IdEntidade,
												   Entidade,
												   Nome,
												   ContentType,
												   Tamanho,
												   DataCadastro,
												   ConteudoEmStorageExterno
										 FROM Sistema.ArquivosAnexos WHERE Entidade = ', CHAR(39), @Entidade, CHAR(39), ' AND IdEntidade = ', CHAR(39), @IdEntidade, CHAR(39), ' END;');

                EXEC @HasErrorOnInsertSelect = sys.sp_executesql @Sql;

                IF(@HasErrorOnInsertSelect <> 0)
                    BEGIN
                        SELECT 'Esse Script deu Erro!';

                        PRINT @Sql;

                        BREAK;
                    END;

                FETCH NEXT FROM cursor_ValidaArquivosAnexos
                 INTO @TableName,
                      @ShemaName,
                      @PkColum,
                      @column_id,
                      @Entidade,
                      @IdEntidade;
            END;

        CLOSE cursor_ValidaArquivosAnexos;
        DEALLOCATE cursor_ValidaArquivosAnexos;

        IF(@Visualizar = 1)
            BEGIN
                SELECT * FROM #ArquivosIncosistentes AS AI;
            END;

        IF(@Deletar = 1)
            BEGIN
                DELETE TARGET
                  FROM Sistema.ArquivosAnexos TARGET
                       JOIN #ArquivosIncosistentes source ON source.IdArquivoAnexo = TARGET.IdArquivoAnexo;
            END;
    END;