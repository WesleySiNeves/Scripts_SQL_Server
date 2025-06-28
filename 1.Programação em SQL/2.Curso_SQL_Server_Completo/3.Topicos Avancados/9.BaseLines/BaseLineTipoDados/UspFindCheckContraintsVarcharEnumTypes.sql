DECLARE @ObjectName VARCHAR(256) = NULL;-- 'Financeiro.Parcelamentos';


IF (OBJECT_ID('TEMPDB..#TabelasCheks') IS NOT NULL)
    DROP TABLE #TabelasCheks;

CREATE TABLE #TabelasCheks
    (
        [parent_object_id] INT,
        [SchemaName]       NVARCHAR(128),
        [TableName]        NVARCHAR(128),
        [name]             NVARCHAR(128),
        [RowsInTable]      BIGINT,
        [type_desc]        NVARCHAR(60),
        [parent_column_id] INT,
        [Coluna]           NVARCHAR(128),
        [Tipo]             NVARCHAR(128),
		[is_nullable] BIT ,
        [max_length]       SMALLINT,
        [definition]       NVARCHAR(MAX),
        [is_system_named]  BIT
    );


INSERT INTO #TabelasCheks
            SELECT
                CC.parent_object_id,
                S.name    AS SchemaName,
                T.name    AS TableName,
                CC.name,
                S2.rowcnt AS RowsInTable,
                CC.type_desc,
                CC.parent_column_id,
                C.name    AS Coluna,
                T2.name   AS Tipo,
				C.is_nullable,
                C.max_length,
                CC.definition,
                CC.is_system_named
            FROM
                sys.check_constraints AS CC
                JOIN
                    sys.tables        AS T
                        ON CC.parent_object_id = T.object_id
                JOIN
                    sys.schemas       AS S
                        ON CC.schema_id = S.schema_id
                JOIN
                    sys.columns       AS C
                        ON T.object_id = C.object_id
                           AND CC.parent_column_id = C.column_id
                JOIN
                    sys.types         AS T2
                        ON T2.user_type_id = C.user_type_id
                JOIN
                    sys.sysindexes    AS S2
                        ON S2.id = CC.parent_object_id
                           AND S2.indid = 1
            WHERE
                T2.name = 'varchar'
            ORDER BY
                RowsInTable DESC;


SELECT * FROM #TabelasCheks AS TC



IF (OBJECT_ID('TEMPDB..#DadosRefetentesEnum') IS NOT NULL)
    DROP TABLE #DadosRefetentesEnum;

CREATE TABLE #DadosRefetentesEnum
    (
        SchemaName VARCHAR(128),
        TableName  VARCHAR(128),
        Coluna     VARCHAR(128),
        Definicao  VARCHAR(100),
        Valor      VARCHAR(50)
    );


INSERT INTO #DadosRefetentesEnum
    (
        SchemaName,
        TableName,
        Coluna,
        Definicao,
        Valor
    )
VALUES
    (
        'Financeiro',    -- SchemaName - varchar(128)
        'Parcelamentos', -- TableName - varchar(128)
        'TermoEmitido',  -- Coluna - varchar(128)
        'Nenhum',        -- Definicao - varchar(100)
        '0'              -- Valor - varchar(50)
    ),
    (
        'Financeiro',      -- SchemaName - varchar(128)
        'Parcelamentos',   -- TableName - varchar(128)
        'TermoEmitido',    -- Coluna - varchar(128)
        'ConfissaoDivida', -- Definicao - varchar(100)
        '1'                -- Valor - varchar(50)
    ),
    (
        'Financeiro',    -- SchemaName - varchar(128)
        'Parcelamentos', -- TableName - varchar(128)
        'TermoEmitido',  -- Coluna - varchar(128)
        'Parcelamento',  -- Definicao - varchar(100)
        '2'              -- Valor - varchar(50)
    );



DECLARE
    @parent_object_id INT,
    @SchemaName       VARCHAR(128),
    @TableName        VARCHAR(128),
    @CheksName        VARCHAR(128),
    @RowsInTable      BIGINT,
    @type_desc        VARCHAR(60),
    @parent_column_id INT,
    @Coluna           VARCHAR(128),
	@is_nullable BIT ,
    @Tipo             VARCHAR(128),
    @max_length       SMALLINT,
    @definition       NVARCHAR(MAX);



DECLARE cursor_AlteraColuna CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT
        TC.parent_object_id,
        TC.SchemaName,
        TC.TableName,
        TC.name AS CheksName,
        TC.RowsInTable,
        TC.type_desc,
        TC.parent_column_id,
        TC.Coluna,
		TC.is_nullable,
        TC.Tipo,
        TC.max_length,
        TC.definition
    FROM
        #TabelasCheks AS TC
    WHERE
        CONCAT(TC.SchemaName, '.', TC.TableName) = @ObjectName
    ORDER BY
        TC.RowsInTable DESC;


OPEN cursor_AlteraColuna;

FETCH NEXT FROM cursor_AlteraColuna
INTO
    @parent_object_id,
    @SchemaName,
    @TableName,
    @CheksName,
    @RowsInTable,
    @type_desc,
    @parent_column_id,
    @Coluna,
	@is_nullable,
    @Tipo,
    @max_length,
    @definition;

WHILE @@FETCH_STATUS = 0
    BEGIN


        SELECT
            @parent_object_id,
            @SchemaName,
            @TableName,
            @CheksName,
            @RowsInTable,
            @type_desc,
            @parent_column_id,
            @Coluna,
			@is_nullable,
            @Tipo,
            @max_length,
            @definition;


	 DECLARE @AddColuna NVARCHAR(400) = CONCAT('ALTER TABLE',SPACE(1),@SchemaName,'.',@TableName, SPACE(1),'ADD ',CONCAT(@Coluna,'NEW'),' TINYINT NULL;');
			





			IF(@is_nullable = 0)
			BEGIN

			 DECLARE @SchemaNameUpdate VARCHAR(128);

			SELECT DRE.SchemaName,
                   DRE.TableName,
                   DRE.Coluna,
                   DRE.Definicao,
                   DRE.Valor FROM #DadosRefetentesEnum AS DRE
			WHERE DRE.SchemaName =@SchemaName 
			AND DRE.TableName = @TableName
			AND @Coluna = @Coluna	
				
			END
			

--    ALTER TABLE Financeiro.Parcelamentos ADD TipoTermoEmitido TINYINT NULL;


--    UPDATE P
--       SET P.TipoTermoEmitido = (   SELECT ETEFFP.IdEnumTermoEmitidoForFinanceiroParcelamentos
--                                      FROM EnumType.EnumTermoEmitidoForFinanceiroParcelamentos AS ETEFFP
--                                     WHERE ETEFFP.Descricao = 'Nenhum')
--      FROM Financeiro.Parcelamentos P
--     WHERE P.TermoEmitido = 'Nenhum';

--    UPDATE P
--       SET P.TipoTermoEmitido = (   SELECT ETEFFP.IdEnumTermoEmitidoForFinanceiroParcelamentos
--                                      FROM EnumType.EnumTermoEmitidoForFinanceiroParcelamentos AS ETEFFP
--                                     WHERE ETEFFP.Descricao = 'ConfissaoDivida')
--      FROM Financeiro.Parcelamentos P
--     WHERE P.TermoEmitido = 'ConfissaoDivida';

--    UPDATE P
--       SET P.TipoTermoEmitido = (   SELECT ETEFFP.IdEnumTermoEmitidoForFinanceiroParcelamentos
--                                      FROM EnumType.EnumTermoEmitidoForFinanceiroParcelamentos AS ETEFFP
--                                     WHERE ETEFFP.Descricao = 'Parcelamento')
--      FROM Financeiro.Parcelamentos P
--     WHERE P.TermoEmitido = 'Parcelamento';

----    ALTER TABLE Financeiro.Parcelamentos
----    ALTER COLUMN TipoTermoEmitido TINYINT NOT NULL;

----    ALTER TABLE Financeiro.Parcelamentos
----    ADD CONSTRAINT DEF_FinanceiroParcelamentosTipoTermoEmitido
----        DEFAULT (0) FOR TipoTermoEmitido;


----    ALTER TABLE Financeiro.Parcelamentos
----    ADD CONSTRAINT FK_TipoTermoEmitidoEnumTermoEmitidoForFinanceiroParcelamentos
----        FOREIGN KEY (TipoTermoEmitido)
----        REFERENCES EnumType.EnumTermoEmitidoForFinanceiroParcelamentos (IdEnumTermoEmitidoForFinanceiroParcelamentos);



----    ALTER TABLE Financeiro.Parcelamentos
----    DROP CONSTRAINT DEF_FinanceiroParcelamentosTermoEmitido;
----    ALTER TABLE Financeiro.Parcelamentos
----    DROP CONSTRAINT CHECK_FinanceiroParcelamentosTermoEmitido;
----    DROP INDEX [IX_Parcelamentos_IdParcelamentoTipoIdPessoa]
----    ON Financeiro.Parcelamentos;


----    ALTER TABLE Financeiro.Parcelamentos DROP COLUMN TermoEmitido;


------CREATE NONCLUSTERED INDEX [IX_FinanceiroParcelamentosIdParcelamentoTipoIdPessoa]
------ON Financeiro.Parcelamentos ([IdParcelamentoTipo], [IdPessoa])
------INCLUDE
------(   [ValorTotal],
------    [Ativo],
------    [DataAtualizacao],
------    [NomeUsuarioCriacao],
------    [DataCriacao],
------    [NomeUnidadeCriacao],
------    [NomeUsuarioAtualizacao],
------    [NomeUnidadeAtualizacao],
------    [Observacoes],
------    [PrioridadeBaixa],
------	TipoTermoEmitido,
------    [ValorTotalPrincipal],
------    [ValorTotalDescontoPrincipal],
------    [ValorTotalJuros],
------    [ValorTotalDescontoJuros],
------    [ValorTotalMulta],
------    [ValorTotalDescontoMulta],
------    [ValorTotalAcrescimo],
------    [ValorTotalJurosSobreParcela],
------    [DataParcelamento],
------    [Numero],
------    [DataNotificacaoInadimplencia],
------    [ValorTotalAtualizacaoMonetaria],
------    [ValorTotalDescontoAtualizacaoMonetaria])
------WITH (FILLFACTOR = 100);
------GO

------ALTER INDEX PK_FinanceiroParcelamentos ON Financeiro.Parcelamentos REBUILD
----EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Financeiro.Parcelamentos';-- nvarchar(776)
----END;

-- END




        FETCH NEXT FROM cursor_AlteraColuna
        INTO
            @parent_object_id,
            @SchemaName,
            @TableName,
            @CheksName,
            @RowsInTable,
            @type_desc,
            @parent_column_id,
            @Coluna,
			@is_nullable,
            @Tipo,
            @max_length,
            @definition;
    END;

CLOSE cursor_AlteraColuna;
DEALLOCATE cursor_AlteraColuna;




