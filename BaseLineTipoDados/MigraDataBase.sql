IF (OBJECT_ID('TEMPDB..#AlteraModelagemDb') IS NOT NULL)
    DROP TABLE #AlteraModelagemDb;


CREATE TABLE #AlteraModelagemDb
(
    [object_idPai] INT,
    [SchemaName] VARCHAR(128),
    [TableName] VARCHAR(128),
    [PrimaryKey] VARCHAR(128),
    [CollumPrimaryKey] VARCHAR(128),
	ForeignkeysName VARCHAR(128),
    [RowsInTable] BIGINT,
    [ObjectIdForeignKey] INT,
    SchemaWithForeignKey VARCHAR(128),
    [TableWithForeignKey] VARCHAR(128),
    [rows] INT,
    [FK_PartNo] INT,
    [ForeignKeyColumn] NVARCHAR(128),
    ForeignKeyColumn_Id INT
);
INSERT INTO #AlteraModelagemDb
SELECT T.object_id AS object_idPai,
       S.name AS SchemaName,
       T.name AS TableName,
       Pk.PrimaryKey,
       Pk.CollumPrimaryKey,
	   Dep.ForeignkeysName,
       S2.rowcnt AS RowsInTable,
       Dep.ObjectIdForeignKey AS ObjectIdForeignKey,
       Dep.SchemaWithForeignKey,
       Dep.TableWithForeignKey,
	   
       Dep.rows,
       Dep.FK_PartNo,
       Dep.ForeignKeyColumn,
       Dep.ForeignKeyColumn_Id
FROM sys.tables AS T
    JOIN sys.schemas AS S
        ON T.schema_id = S.schema_id
    JOIN sys.sysindexes AS S2
        ON S2.id = T.object_id
           AND S2.indid = 1
    JOIN
    (
        SELECT I.object_id,
               I.name AS PrimaryKey,
               C.name AS CollumPrimaryKey
        FROM sys.index_columns AS IC
            JOIN sys.indexes AS I
                ON IC.object_id = I.object_id
                   AND IC.index_id = I.index_id
            JOIN sys.columns AS C
                ON I.object_id = C.object_id
                   AND IC.column_id = C.column_id
        WHERE I.type = 1
    ) AS Pk
        ON T.object_id = Pk.object_id
    OUTER APPLY
(
    SELECT *
    FROM HealthCheck.ufnFindDepenciasOnPrimaryKey(T.object_id)
) AS Dep
WHERE
    --  T.name LIKE '%Tipo%'
    T.name = 'ParcelamentosTipos'
    AND S2.rowcnt < 20;





/* declare variables */
DECLARE @object_idPai INT,
        @SchemaName VARCHAR(128),
        @TableName VARCHAR(128),
        @Ordem INT,
        @MaxOrdem INT,
        @PrimaryKey VARCHAR(128),
        @CollumPrimaryKey VARCHAR(128),
        @RowsInTable BIGINT,
        @ObjectIdoreignKey INT,
        @SchemaWithForeignKey VARCHAR(128),
        @TableWithForeignKey VARCHAR(128),
        @rows INT,
        @FK_PartNo INT,
        @ForeignKeyColumn VARCHAR(128),
        @ForeignKeyColumn_Id INT;

DECLARE cursor_AlteraModelagem CURSOR FAST_FORWARD READ_ONLY FOR WITH DadosOrdenados
                                                                 AS (
                                                                    SELECT AMD.object_idPai,
                                                                           AMD.SchemaName,
                                                                           Ordem = ROW_NUMBER() OVER (PARTITION BY AMD.object_idPai ORDER BY AMD.object_idPai),
                                                                           AMD.TableName,
                                                                           AMD.PrimaryKey,
                                                                           AMD.CollumPrimaryKey,
                                                                           AMD.RowsInTable,
                                                                           AMD.ObjectIdForeignKey,
                                                                           AMD.SchemaWithForeignKey,
                                                                           AMD.TableWithForeignKey,
                                                                           AMD.rows,
                                                                           AMD.FK_PartNo,
                                                                           AMD.ForeignKeyColumn,
                                                                           AMD.ForeignKeyColumn_Id
                                                                    FROM #AlteraModelagemDb AS AMD
                                                                    )
SELECT R.object_idPai,
       R.SchemaName,
       R.Ordem,
       MaxOrdem = MAX(R.Ordem) OVER (PARTITION BY R.object_idPai ORDER BY R.object_idPai),
       R.TableName,
       R.PrimaryKey,
       R.CollumPrimaryKey,
       R.RowsInTable,
       R.ObjectIdForeignKey,
       R.SchemaWithForeignKey,
       R.TableWithForeignKey,
       R.rows,
       R.FK_PartNo,
       R.ForeignKeyColumn,
       R.ForeignKeyColumn_Id
FROM DadosOrdenados R;


OPEN cursor_AlteraModelagem;

FETCH NEXT FROM cursor_AlteraModelagem
INTO @object_idPai,
     @SchemaName,
     @Ordem,
     @MaxOrdem,
     @TableName,
     @PrimaryKey,
     @CollumPrimaryKey,
     @RowsInTable,
     @ObjectIdoreignKey,
     @SchemaWithForeignKey,
     @TableWithForeignKey,
     @rows,
     @FK_PartNo,
     @ForeignKeyColumn,
     @ForeignKeyColumn_Id;

WHILE @@FETCH_STATUS = 0
BEGIN


    DECLARE @CScriptCriaNovaColuna NVARCHAR(500);
    --- Cria uma nova coluna Temporária
    DECLARE @NewCollum VARCHAR(200) = CONCAT(@CollumPrimaryKey, 'New');



    --Cria nova Coluna PK e insere seus dados
    IF (NOT EXISTS
    (
        SELECT C.name
        FROM sys.tables AS T
            JOIN sys.columns AS C
                ON T.object_id = C.object_id
        WHERE T.object_id = @object_idPai
              AND C.name = @NewCollum
    )
       )
    BEGIN

        SET @CScriptCriaNovaColuna
            = CONCAT('ALTER TABLE ', @SchemaName, '.', @TableName, 'ADD ', @NewCollum, ' TINYINT');

        --Exec nova coluna
        SELECT @CScriptCriaNovaColuna;

        ;WITH Dados
        AS (SELECT PT.IdParcelamentoTipo,
                   Target = ROW_NUMBER() OVER (ORDER BY PT.IdParcelamentoTipo)
            FROM Financeiro.ParcelamentosTipos AS PT
           )
        UPDATE T
        SET T.IdParcelamentoTipoNew = R.Target
        FROM Financeiro.ParcelamentosTipos T
            JOIN Dados R
                ON T.IdParcelamentoTipo = R.IdParcelamentoTipo;



        ALTER TABLE Financeiro.ParcelamentosTipos
        ALTER COLUMN IdParcelamentoTipoNew TINYINT NOT NULL;


    END;
	


    SELECT @ObjectIdoreignKey,
		@SchemaWithForeignKey,
           @TableWithForeignKey,
           @rows,
           @FK_PartNo,
           @ForeignKeyColumn,
           @ForeignKeyColumn_Id;

	 
 
    IF (@Ordem = @MaxOrdem)
    BEGIN

        SELECT 1;

    ----Parte da Sequence
    --DECLARE @MaxValue TINYINT =
    --(
    --    SELECT MAX(PT.IdParcelamentoTipoNew)
    --    FROM Financeiro.ParcelamentosTipos AS PT
    --) + 1;

    --SELECT @MaxValue;

    --CREATE SEQUENCE Seq_FinanceiroParcelamentosTipos
    --AS TINYINT
    --MINVALUE 1
    --INCREMENT BY 1
    --START WITH 4
    --NO CACHE
    --NO CYCLE;


    --ALTER TABLE Financeiro.ParcelamentosTipos  ADD CONSTRAINT DEF_FinanceiroParcelamentosTipos DEFAULT( NEXT VALUE FOR Seq_FinanceiroParcelamentosTipos) FOR  IdParcelamentoTipoNew
    END;



    FETCH NEXT FROM cursor_AlteraModelagem
    INTO @object_idPai,
         @SchemaName,
         @Ordem,
         @MaxOrdem,
         @TableName,
         @PrimaryKey,
         @CollumPrimaryKey,
         @RowsInTable,
         @ObjectIdoreignKey,
         @SchemaWithForeignKey,
         @TableWithForeignKey,
         @rows,
         @FK_PartNo,
         @ForeignKeyColumn,
         @ForeignKeyColumn_Id;

END;

CLOSE cursor_AlteraModelagem;
DEALLOCATE cursor_AlteraModelagem;





	ALTER TABLE Financeiro.Parcelamentos ADD IdParcelamentoTipoNew TINYINT 


	


	UPDATE P SET P.IdParcelamentoTipoNew =PT.IdParcelamentoTipoNew
	 FROM Financeiro.Parcelamentos AS P
	 JOIN Financeiro.ParcelamentosTipos AS PT ON P.IdParcelamentoTipo = PT.IdParcelamentoTipo
	

	SELECT DISTINCT P.IdParcelamentoTipo,P.IdParcelamentoTipoNew FROM Financeiro.Parcelamentos AS P


	DROP INDEX IX_FinanceiroParcelamentosIdParcelamentoTipoIdPessoa ON Financeiro.Parcelamentos

	DROP INDEX IX_Parcelamentos_IdParcelamentoTipoIdPessoaAtivo ON Financeiro.Parcelamentos

	ALTER TABLE Financeiro.Parcelamentos DROP CONSTRAINT FK_ParcelamentosIdParcelamentoTipo_ParcelamentosTiposIdParcelamentoTipo

	ALTER TABLE Financeiro.Parcelamentos DROP COLUMN IdParcelamentoTipo

	EXEC sys.sp_rename  @objname = N'Financeiro.Parcelamentos.IdParcelamentoTipoNew',  -- nvarchar(1035)
	                   @newname = 'IdParcelamentoTipo'; -- sysname
	                 
	
	ALTER TABLE Financeiro.Parcelamentos ALTER COLUMN IdParcelamentoTipo TINYINT NOT NULL

	
	ALTER TABLE  Financeiro.ConfiguracoesParcelamentos ADD IdParcelamentoTipoNew TINYINT


	SELECT * FROM Financeiro.ConfiguracoesParcelamentos AS CP

	UPDATE  CP  SET CP.IdParcelamentoTipoNew = PT.IdParcelamentoTipoNew  FROM Financeiro.ConfiguracoesParcelamentos AS CP
	JOIN Financeiro.ParcelamentosTipos AS PT ON CP.IdParcelamentoTipo = PT.IdParcelamentoTipo

	
	
	ALTER TABLE Financeiro.ConfiguracoesParcelamentos DROP CONSTRAINT FK_ConfiguracoesParcelamentosIdParcelamentoTipo_ParcelamentosTiposIdParcelamentoTipo


	ALTER TABLE Financeiro.ConfiguracoesParcelamentos DROP COLUMN IdParcelamentoTipo


	
	EXEC sys.sp_rename  @objname = N'Financeiro.ConfiguracoesParcelamentos.IdParcelamentoTipoNew',  -- nvarchar(1035)
	                   @newname = 'IdParcelamentoTipo'; -- sysname
	

	SELECT * FROM Financeiro.ConfiguracoesParcelamentos AS CP

CREATE NONCLUSTERED INDEX [IX_FinanceiroParcelamentosIdParcelamentoTipoIdPessoa] ON [Financeiro].[Parcelamentos] ([IdParcelamentoTipo], [IdPessoa]) INCLUDE ([ValorTotal], [Ativo], [DataAtualizacao], [NomeUsuarioCriacao], [DataCriacao], [NomeUnidadeCriacao], [NomeUsuarioAtualizacao], [NomeUnidadeAtualizacao], [Observacoes], [PrioridadeBaixa], [TipoTermoEmitido], [ValorTotalPrincipal], [ValorTotalDescontoPrincipal], [ValorTotalJuros], [ValorTotalDescontoJuros], [ValorTotalMulta], [ValorTotalDescontoMulta], [ValorTotalAcrescimo], [ValorTotalJurosSobreParcela], [DataParcelamento], [Numero], [DataNotificacaoInadimplencia], [ValorTotalAtualizacaoMonetaria], [ValorTotalDescontoAtualizacaoMonetaria]) WITH (FILLFACTOR=100)
GO
CREATE NONCLUSTERED INDEX [IX_Parcelamentos_IdParcelamentoTipoIdPessoaAtivo] ON [Financeiro].[Parcelamentos] ([IdParcelamentoTipo], [IdPessoa], [Ativo])
GO

	--ALTER TABLE Financeiro.Parcelamentos ADD CONSTRAINT FK_ParcelamentosIdParcelamentoTipo_ParcelamentosTiposIdParcelamentoTipo 
	--FOREIGN KEY(IdParcelamentoTipo)REFERENCES Financeiro.ParcelamentosTipos(IdParcelamentoTipoNew)




	IdParcelamentoTipo
00000000-0000-0000-0000-000000000001



