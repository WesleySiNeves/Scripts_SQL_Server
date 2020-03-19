

--SET XACT_ABORT ON 
--BEGIN TRANSACTION SCHEDULE;
--BEGIN TRY
		/*Region Logical Querys*/
		
		/* ==================================================================
--Data: 01/10/2019 
--Autor :Wesley Neves
--Observação: Script de Validação De Alterações na arquiterura de tabelas
 --Rodar o Script passo a passo com o Script dos tamanhos das tabelas
-- ==================================================================
*/

/* ==================================================================
--Data: 01/10/2019 
--Autor :Wesley Neves
--Observação: 1) tabela de Logradouros
 
-- ==================================================================
*/

IF(OBJECT_ID('TEMPDB..#Tabelas') IS NOT NULL)
    DROP TABLE #Tabelas;

CREATE TABLE #Tabelas
(
    Nome     VARCHAR(200),
    objectId INT,
);

INSERT INTO #Tabelas(
                        Nome
                    )
VALUES('Ocorrencia.Ocorrencias' -- Nome - varchar(200)
      );

UPDATE #Tabelas SET objectId = OBJECT_ID(Nome);

IF(EXISTS (
              SELECT *
                FROM sys.syscursors AS S
               WHERE
                  S.cursor_name = 'cursor_AlteraEstrutura'
          )
  )
    BEGIN
        DEALLOCATE cursor_AlteraEstrutura;
    END;

IF(OBJECT_ID('TEMPDB..#Indices') IS NOT NULL)
    DROP TABLE #Indices;

CREATE TABLE #Indices
(
    [object_id]    INT,
    [name]         NVARCHAR(128),
    [index_id]     INT,
    indexType      INT,
    [type_desc]    NVARCHAR(60),
    ColunaIndexada VARCHAR(128)
);

INSERT INTO #Indices(
                        object_id,
                        name,
                        index_id,
                        indexType,
                        type_desc,
                        ColunaIndexada
                    )
SELECT I.object_id,
       I.name,
       I.index_id,
       I.type,
       I.type_desc,
       C.name AS ColunaIndexada
  FROM sys.indexes AS I
       JOIN #Tabelas AS T ON I.object_id = T.objectId
       JOIN sys.index_columns AS IC ON IC.object_id = I.object_id
                                       AND IC.index_id = I.index_id
       JOIN sys.columns AS C ON C.object_id = I.object_id
                                AND C.column_id = IC.column_id
 WHERE
    IC.index_column_id = 1
    AND IC.key_ordinal = 1;

IF(OBJECT_ID('TEMPDB..#ForenKeys') IS NOT NULL)
    DROP TABLE #ForenKeys;

CREATE TABLE #ForenKeys
(
    [ObjectIdPai]          INT,
    [SchemaNamePai]        NVARCHAR(128),
    [TableNamePai]         NVARCHAR(128),
    [TableName]            NVARCHAR(128),
	[ColunaPK]            NVARCHAR(128),
    [SchemaWithForeignKey] NVARCHAR(128),
    [TableWithForeignKey]  NVARCHAR(128),
    [rows]                 INT,
    [ForeignkeysName]      NVARCHAR(128),
    [FK_PartNo]            INT,
    [ForeignKeyColumn]     NVARCHAR(128),
    [ForeignKeyColumn_Id]  INT,
    [ComandoDisable]       NVARCHAR(418),
    [ComandoEnable]        NVARCHAR(427)
);

/* declare variables */
DECLARE @Nome     VARCHAR(200),
        @objectId INT;

/*Cursor Pai*/
DECLARE cursor_AlteraEstrutura CURSOR FAST_FORWARD READ_ONLY FOR
SELECT * FROM #Tabelas AS T;

OPEN cursor_AlteraEstrutura;

FETCH NEXT FROM cursor_AlteraEstrutura
 INTO @Nome,
      @objectId;

WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #ForenKeys
        SELECT UFDOPK.ObjectIdPai,
               UFDOPK.SchemaNamePai,
               UFDOPK.TableNamePai,
			   UFDOPK.ColunaPK,
               UFDOPK.TableName,
               UFDOPK.SchemaWithForeignKey,
               UFDOPK.TableWithForeignKey,
               UFDOPK.rows,
               UFDOPK.ForeignkeysName,
               UFDOPK.FK_PartNo,
               UFDOPK.ForeignKeyColumn,
               UFDOPK.ForeignKeyColumn_Id,
               ComandoDisable = CONCAT('ALTER TABLE ', UFDOPK.SchemaWithForeignKey, '.', UFDOPK.TableWithForeignKey, '  DROP CONSTRAINT ', UFDOPK.ForeignkeysName),
               ComandoEnable = CONCAT('ALTER TABLE ', UFDOPK.SchemaWithForeignKey, '.', UFDOPK.TableWithForeignKey, ' ADD   CONSTRAINT ', UFDOPK.ForeignkeysName,' FOREIGN KEY(',UFDOPK.ColunaPK,') REFERENCES ',CONCAT(UFDOPK.SchemaNamePai,'.',UFDOPK.TableNamePai))
          FROM HealthCheck.ufnFindDepenciasOnPrimaryKey('1563868638') AS UFDOPK;

   
        /* ==================================================================
        --Data: 21/11/2019 
        --Autor :Wesley Neves
        --Observação: Desabilitar as Foren Keys da Tabela
         
        -- ==================================================================
        */
        DECLARE @ScriptDesabilita VARCHAR(MAX);

        DECLARE cursor_DesabilitaFK CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT FK.ComandoDisable FROM #ForenKeys AS FK;

        OPEN cursor_DesabilitaFK;

        FETCH NEXT FROM cursor_DesabilitaFK
         INTO @ScriptDesabilita;

        WHILE @@FETCH_STATUS = 0
            BEGIN
			   PRINT(@ScriptDesabilita);
                EXEC(@ScriptDesabilita);

                FETCH NEXT FROM cursor_DesabilitaFK
                 INTO @ScriptDesabilita;
            END;

        CLOSE cursor_DesabilitaFK;
        DEALLOCATE cursor_DesabilitaFK;

        DECLARE @PK_Name VARCHAR(300) = (
                                            SELECT I.name FROM #Indices AS I WHERE I.indexType = 1
                                        );

        IF(EXISTS (SELECT * FROM sys.indexes AS I WHERE I.name = @PK_Name))
            BEGIN
                DECLARE @Script_DropPK VARCHAR(200) = CONCAT('ALTER TABLE ', 'Ocorrencia.Ocorrencias', ' DROP CONSTRAINT ', @PK_Name, ';');

            EXEC(@Script_DropPK);
            END;

        DECLARE @ScriptCreate_COLUMNSTORE VARCHAR(200) = CONCAT('CREATE CLUSTERED COLUMNSTORE INDEX ', QUOTENAME('CC_IX_' + REPLACE(@Nome, '.', '')), ' ON ', @Nome);
		
		
        EXEC(@ScriptCreate_COLUMNSTORE);

        DECLARE @ColunaIndexada VARCHAR(128) = (
                                                   SELECT I.ColunaIndexada
                                                     FROM #Indices AS I
                                                    WHERE
                                                       I.object_id = @objectId
                                                       AND I.indexType = 1
                                               );
        DECLARE @ScriptCreate_NONCLUSTERED VARCHAR(200) = CONCAT('ALTER TABLE ', @Nome, '  ADD CONSTRAINT ', QUOTENAME('PK_' + REPLACE(@Nome, '.', '')), ' PRIMARY KEY NONCLUSTERED(', @ColunaIndexada, ')');

        EXEC(@ScriptCreate_NONCLUSTERED);

        /* declare variables */
        DECLARE @ComandoEnable VARCHAR(1000);

        DECLARE cursor_HabilitaForenKey CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT FK.ComandoEnable FROM #ForenKeys AS FK;

        OPEN cursor_HabilitaForenKey;

        FETCH NEXT FROM cursor_HabilitaForenKey
         INTO @ComandoEnable;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC(@ComandoEnable);

                FETCH NEXT FROM cursor_HabilitaForenKey
                 INTO @ComandoEnable;
            END;

        CLOSE cursor_HabilitaForenKey;
        DEALLOCATE cursor_HabilitaForenKey;

        FETCH NEXT FROM cursor_AlteraEstrutura
         INTO @Nome,
              @objectId;
    END;

TRUNCATE TABLE #ForenKeys;
CLOSE cursor_AlteraEstrutura;
DEALLOCATE cursor_AlteraEstrutura;



