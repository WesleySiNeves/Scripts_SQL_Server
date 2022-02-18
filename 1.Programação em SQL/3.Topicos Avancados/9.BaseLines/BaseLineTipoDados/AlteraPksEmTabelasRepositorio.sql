/*
https://social.technet.microsoft.com/Forums/pt-BR/302135e7-8468-4fd1-ab02-81ae405536ff/relacionamento-muitos-para-muitos-necessrio-criar-primary-que?forum=520
*/

IF (OBJECT_ID('TEMPDB..#DesabilitaForenKeys') IS NOT NULL)
    DROP TABLE #DesabilitaForenKeys;

CREATE TABLE #DesabilitaForenKeys (
    [ForenKey] NVARCHAR(128),
    [object_id] INT,
    [schema_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [Script] NVARCHAR(418));


IF (OBJECT_ID('TEMPDB..#HabilitaForenKeys') IS NOT NULL)
    DROP TABLE #HabilitaForenKeys;

CREATE TABLE #HabilitaForenKeys (
    [ForenKey] NVARCHAR(128),
    [object_id] INT,
    [schema_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [Script] NVARCHAR(418));


IF (OBJECT_ID('TEMPDB..#ScriptCriacaoPk') IS NOT NULL)
    DROP TABLE #ScriptCriacaoPk;


CREATE TABLE #ScriptCriacaoPk (
    [object_id] INT,
    [SchemaName] VARCHAR(128),
    [TableName] VARCHAR(128),
    [ColunasChaves] VARCHAR(899),
    [Script] NVARCHAR(1705));


IF (OBJECT_ID('TEMPDB..#DropIndex') IS NOT NULL)
    DROP TABLE #DropIndex;

CREATE TABLE #DropIndex (
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [object_id] INT,
    [name] NVARCHAR(128),
    [Script] NVARCHAR(800));


IF (OBJECT_ID('TEMPDB..#DeleteKeysCONSTRAINT') IS NOT NULL)
    DROP TABLE #DeleteKeysCONSTRAINT;


CREATE TABLE #DeleteKeysCONSTRAINT (
    [object_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [CONSTRAINTName] NVARCHAR(128),
    [Script] NVARCHAR(415));



IF (OBJECT_ID('TEMPDB..#DefaultsCONSTRAINT') IS NOT NULL)
    DROP TABLE #DefaultsCONSTRAINT;


CREATE TABLE #DefaultsCONSTRAINT (
    [object_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [CONSTRAINTName] NVARCHAR(128),
    [Script] NVARCHAR(415));

IF (OBJECT_ID('TEMPDB..#DropCollum') IS NOT NULL)
    DROP TABLE #DropCollum;

CREATE TABLE #DropCollum (
    [object_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [ColumPrimaryKey] NVARCHAR(128),
    [ScriptDrop] NVARCHAR(410));


IF (OBJECT_ID('TEMPDB..#TabelasPonte') IS NOT NULL)
    DROP TABLE #TabelasPonte;

	

CREATE TABLE #TabelasPonte (
    [object_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    Rows INT,
    [column_id] INT,
    [Coluna] NVARCHAR(128),
    [ColumPrimaryKey] NVARCHAR(128));


IF (OBJECT_ID('TEMPDB..#AllTable') IS NOT NULL)
    DROP TABLE #AllTable;

CREATE TABLE #AllTable (
    [object_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [column_id] INT,
    [Coluna] NVARCHAR(128),
    [TotalColunas] INT,
    [TotalColunasUniqueidentifier] INT,
    [ColumPrimaryKey] NVARCHAR(128));

WITH AllPrimaryKeysInTable
  AS (SELECT DISTINCT T1.object_id,
             T1.SchemaName,
             T1.TableName,
             T1.Coluna,
             T1.column_id,
             T1.Datatype,
             T1.TotalColunas,
             TaUnique.TotalColunasUniqueidentifier
        FROM (   SELECT T.object_id,
                        S.name AS SchemaName,
                        T.name AS TableName,
                        C.name AS Coluna,
                        C.column_id,
                        T2.name AS Datatype,
                        COUNT(*) OVER (PARTITION BY C.object_id) AS TotalColunas
                   FROM sys.tables AS T
                   JOIN sys.schemas AS S
                     ON T.schema_id    = S.schema_id
                   JOIN sys.columns AS C
                     ON T.object_id    = C.object_id
                   JOIN sys.types AS T2
                     ON C.user_type_id = T2.user_type_id) AS T1
        JOIN (   SELECT T.object_id,
                        S.name AS SchemaName,
                        T.name AS TableName,
                        C.name AS Coluna,
                        T2.name AS Datatype,
                        COUNT(*) OVER (PARTITION BY C.object_id) AS TotalColunasUniqueidentifier
                   FROM sys.tables AS T
                   JOIN sys.schemas AS S
                     ON T.schema_id    = S.schema_id
                   JOIN sys.columns AS C
                     ON T.object_id    = C.object_id
                   JOIN sys.types AS T2
                     ON C.user_type_id = T2.user_type_id
                  WHERE T2.name = 'uniqueidentifier') AS TaUnique
          ON T1.object_id = TaUnique.object_id)
INSERT INTO #AllTable (object_id,
                       SchemaName,
                       TableName,
                       column_id,
                       Coluna,
                       TotalColunas,
                       TotalColunasUniqueidentifier,
                       ColumPrimaryKey)
SELECT R.object_id,
       R.SchemaName,
       R.TableName,
       R.column_id,
       R.Coluna,
       R.TotalColunas,
       R.TotalColunasUniqueidentifier,
       ColumPrimaryKey = (   SELECT TOP 1 C.name
                               FROM sys.indexes AS I
                               JOIN sys.index_columns AS IC
                                 ON I.object_id  = IC.object_id
                                AND I.index_id   = IC.index_id
                               JOIN sys.columns AS C
                                 ON I.object_id  = C.object_id
                                AND IC.column_id = C.column_id
                              WHERE I.object_id = R.object_id
                                AND I.type      = 1)
  FROM AllPrimaryKeysInTable R
 ORDER BY R.object_id,
          R.column_id;


DELETE FROM #AllTable
WHERE #AllTable.ColumPrimaryKey IS NULL

INSERT INTO #TabelasPonte
SELECT AT.object_id,
       AT.SchemaName,
       AT.TableName,
       S.rows,
       AT.column_id,
       AT.Coluna,
       AT.ColumPrimaryKey
  FROM #AllTable AS AT
  LEFT JOIN sys.sysindexes AS S
    ON AT.object_id = S.id
   AND S.indid = 1
 OUTER APPLY HealthCheck.ufnFindDepenciasOnPrimaryKey(AT.object_id) AS Fore
 WHERE Fore.ObjectIdPai IS NULL
   AND AT.TotalColunasUniqueidentifier = 3
   AND AT.TotalColunas                 = 3;



INSERT INTO #DeleteKeysCONSTRAINT
SELECT DISTINCT KC.parent_object_id,
       TP.SchemaName COLLATE DATABASE_DEFAULT AS SchemaName,
       TP.TableName COLLATE DATABASE_DEFAULT AS TableName,
       KC.name COLLATE DATABASE_DEFAULT AS CONSTRAINTName,
       Script = CONCAT(
                    'ALTER TABLE ',
                    TP.SchemaName COLLATE DATABASE_DEFAULT,
                    '.',
                    TP.TableName COLLATE DATABASE_DEFAULT,
                    ' DROP CONSTRAINT ',
                    KC.name COLLATE DATABASE_DEFAULT)
  FROM #TabelasPonte AS TP
  JOIN sys.key_constraints AS KC
    ON TP.object_id = KC.parent_object_id;






INSERT INTO #DefaultsCONSTRAINT
SELECT DISTINCT DC.parent_object_id,
       TP.SchemaName COLLATE DATABASE_DEFAULT AS SchemaName,
       TP.TableName COLLATE DATABASE_DEFAULT AS TableName,
       DC.name COLLATE DATABASE_DEFAULT AS CONSTRAINTName,
       Script = CONCAT(
                    'ALTER TABLE ',
                    TP.SchemaName COLLATE DATABASE_DEFAULT,
                    '.',
                    TP.TableName COLLATE DATABASE_DEFAULT,
                    ' DROP CONSTRAINT ',
                    DC.name COLLATE DATABASE_DEFAULT)
  FROM #TabelasPonte AS TP
  JOIN sys.default_constraints AS DC
    ON TP.object_id = DC.parent_object_id;





INSERT INTO #DropCollum
SELECT DISTINCT TP.object_id,
       TP.SchemaName,
       TP.TableName,
       TP.ColumPrimaryKey,
       ScriptDrop = CONCAT('ALTER TABLE ', TP.SchemaName, '.', TP.TableName, ' DROP COLUMN ', TP.ColumPrimaryKey)
  FROM #TabelasPonte AS TP;






;WITH Dados
   AS (SELECT ACIT.object_id,
              ACIT.SchemaName,
              ACIT.TableName,
              ACIT.Coluna,
              ACIT.column_id,
              ColunasChaves = STUFF(
                                  (   SELECT ', ' + c2.Coluna
                                        FROM #TabelasPonte c2
                                       -- group by
                                       WHERE c2.object_id = ACIT.object_id
                                         AND c2.Coluna    <> c2.ColumPrimaryKey
                                       ORDER BY c2.column_id
                                      FOR XML PATH(''), TYPE).value('.', 'varchar(900)'), -- extract element value and convert
                                  1,
                                  2,
                                  '')
         FROM #TabelasPonte AS ACIT)
INSERT INTO #ScriptCriacaoPk
SELECT DISTINCT R.object_id,
       R.SchemaName,
       R.TableName,
       R.ColunasChaves,
       Script = CONCAT(
                    'ALTER TABLE ',
                    QUOTENAME(R.SchemaName),
                    '.',
                    QUOTENAME(R.TableName),
                    ' ADD CONSTRAINT ',
                    'PK_',
                    R.SchemaName,
                    R.TableName,
                    ' PRIMARY KEY  (',
                    R.ColunasChaves,
                    ')')
  FROM Dados R;





INSERT INTO #DropIndex
SELECT Sc.name AS SchemaName,
       T.name AS TableName,
       IC.object_id,
       I.name,
       Script = CONCAT('DROP INDEX ', QUOTENAME(I.name), ' ON ', Sc.name, '.', T.name)
  FROM sys.indexes AS I
  JOIN sys.tables T
    ON I.object_id  = T.object_id
  JOIN sys.schemas Sc
    ON Sc.schema_id = T.schema_id
  JOIN sys.index_columns AS IC
    ON I.object_id  = IC.object_id
   AND I.index_id   = IC.index_id
  JOIN sys.columns AS C
    ON I.object_id  = C.object_id
   AND IC.column_id = C.column_id
 WHERE I.object_id IN ( SELECT SCP.object_id FROM #ScriptCriacaoPk AS SCP )
   AND I.type = 2
   AND I.is_unique = 0




/* declare variables */
DECLARE @object_id_Alter  INT,
        @SchemaName_Alter VARCHAR(128),
        @TableName_Alter  VARCHAR(128),
        @Script_CreatePK  NVARCHAR(800);

DECLARE cursor_AlteraEstruturaTable CURSOR FAST_FORWARD READ_ONLY FOR
SELECT DISTINCT TP.object_id,
       TP.SchemaName,
       TP.TableName,
       TP.Script
  FROM #ScriptCriacaoPk AS TP
  WHERE TP.TableName NOT IN
  (
  'InstituicoesEnsinoCursos',
  'ProcessamentoArquivosRetornosItensEmissoes',
  'RegistrosOcorrencias'
 
  )
--WHERE TP.object_id ='980914566'



OPEN cursor_AlteraEstruturaTable;


FETCH NEXT FROM cursor_AlteraEstruturaTable
 INTO @object_id_Alter,
      @SchemaName_Alter,
      @TableName_Alter,
      @Script_CreatePK;

WHILE @@FETCH_STATUS = 0
BEGIN

    BEGIN TRY
        BEGIN TRANSACTION Task;

        DECLARE @TempScript NVARCHAR(2000);
        DECLARE @HasError INT = 0;


        IF (@HasError = 0)
            IF (EXISTS (   SELECT *
                             FROM #DeleteKeysCONSTRAINT DKC
                            WHERE DKC.object_id = @object_id_Alter))
            BEGIN

                /* declare variables */
                DECLARE @DeleteCONSTRAINT NVARCHAR(1000);

                DECLARE cursor_KeysCONSTRAINT CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT DE.Script
                  FROM #DeleteKeysCONSTRAINT DE
                 WHERE DE.object_id = @object_id_Alter;

				 
                OPEN cursor_KeysCONSTRAINT;

                FETCH NEXT FROM cursor_KeysCONSTRAINT
                 INTO @DeleteCONSTRAINT;

                WHILE @@FETCH_STATUS = 0
                BEGIN

                    PRINT @DeleteCONSTRAINT;
                    EXEC @HasError = sys.sp_executesql @DeleteCONSTRAINT;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @DeleteCONSTRAINT;
                        BREAK;
                    END;


                    SET @TempScript = '';

                    FETCH NEXT FROM cursor_KeysCONSTRAINT
                     INTO @DeleteCONSTRAINT;
                END;

                CLOSE cursor_KeysCONSTRAINT;
                DEALLOCATE cursor_KeysCONSTRAINT;


                SET @TempScript = '';

            END;

        IF (@HasError = 0)
            IF (EXISTS (   SELECT *
                             FROM #DefaultsCONSTRAINT AS DC
                            WHERE DC.object_id = @object_id_Alter))
            BEGIN

			
                SET @TempScript = (   SELECT DE.Script
                                        FROM #DefaultsCONSTRAINT DE
                                       WHERE DE.object_id = @object_id_Alter);

                PRINT @TempScript;
                EXEC @HasError = sys.sp_executesql @TempScript;

                IF (@HasError <> 0)
                BEGIN


                    SELECT 'Deu Erro';
                    SELECT @TempScript;
                    BREAK;
                END;
            END;

		IF(EXISTS( SELECT * FROM #DropIndex AS DI
			WHERE DI.object_id = @object_id_Alter))
			BEGIN

                /* declare variables */
                DECLARE @DeleteIndex NVARCHAR(1000);

                DECLARE cursor_DeleteIndex CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT DISTINCT DE.Script
                  FROM #DropIndex DE
                 WHERE DE.object_id = @object_id_Alter;


                OPEN cursor_DeleteIndex;

                FETCH NEXT FROM cursor_DeleteIndex
                 INTO @DeleteIndex;

                WHILE @@FETCH_STATUS = 0
                BEGIN

                    PRINT @DeleteIndex;
                    EXEC @HasError = sys.sp_executesql @DeleteIndex;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @DeleteIndex;
                        BREAK;
                    END;


                    SET @TempScript = '';

                    FETCH NEXT FROM cursor_DeleteIndex
                     INTO @DeleteIndex;
                END;

                CLOSE cursor_DeleteIndex;
                DEALLOCATE cursor_DeleteIndex;


                SET @TempScript = '';

            END;

        IF (@HasError = 0)
            IF (EXISTS (   SELECT *
                             FROM #DropCollum DKC
                            WHERE DKC.object_id = @object_id_Alter))
            BEGIN

			
                SET @TempScript = (   SELECT DE.ScriptDrop
                                        FROM #DropCollum DE
                                       WHERE DE.object_id = @object_id_Alter);

                PRINT @TempScript;
                EXEC @HasError = sys.sp_executesql @TempScript;

                IF (@HasError <> 0)
                BEGIN


                    SELECT 'Deu Erro';
                    SELECT @TempScript;
                    BREAK;
                END;
            END;

        PRINT @Script_CreatePK;
        EXEC @HasError = sys.sp_executesql @Script_CreatePK;

        IF (@HasError <> 0)
        BEGIN


            SELECT 'Deu Erro';
            PRINT @HasError;
			PRINT @Script_CreatePK;
            BREAK;
        END;

		IF(@HasError = 0)
		BEGIN
		COMMIT TRANSACTION Task;		
		END
        ELSE
		ROLLBACK TRAN Task



        FETCH NEXT FROM cursor_AlteraEstruturaTable
         INTO @object_id_Alter,
              @SchemaName_Alter,
              @TableName_Alter,
              @Script_CreatePK;



    END TRY
    BEGIN CATCH

        PRINT N'THE TRANSACTION IS IN AN UNCOMMITTABLE STATE. ROLLING BACK TRANSACTION.';

		IF(EXISTS(SELECT * FROM  sys.syscursors AS S
		WHERE S.cursor_name ='cursor_DeleteIndex'))
		BEGIN
				
				DEALLOCATE cursor_DeleteIndex;
		END

		IF(@@TRANCOUNT > 0)
		BEGIN
				
				ROLLBACK TRANSACTION Task;
		END
        

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

    END CATCH;

END;


CLOSE cursor_AlteraEstruturaTable;
DEALLOCATE cursor_AlteraEstruturaTable;




--BEGIN TRAN t1
--ALTER TABLE Financeiro.ProcessamentoArquivosRetornosItensEmissoes DROP CONSTRAINT PK_FinanceiroProcessamentoArquivosRetornosItensEmissoes
--DROP INDEX IX_FinanceiroProcessamentoArquivosRetornosItensEmissoesIdProcessamentoArquivoRetornoItem ON Financeiro.ProcessamentoArquivosRetornosItensEmissoes
--ALTER TABLE Financeiro.ProcessamentoArquivosRetornosItensEmissoes DROP COLUMN IdProcessamentoArquivoRetornoItemEmissao
--ALTER TABLE [Financeiro].[ProcessamentoArquivosRetornosItensEmissoes] ADD CONSTRAINT PK_FinanceiroProcessamentoArquivosRetornosItensEmissoes PRIMARY KEY  (IdProcessamentoArquivoRetornoItem, IdEmissao)



--SELECT PARIE.IdProcessamentoArquivoRetornoItem,PARIE.IdEmissao,COUNT(*) FROM [Financeiro].[ProcessamentoArquivosRetornosItensEmissoes] AS [PARIE]
--GROUP BY PARIE.IdProcessamentoArquivoRetornoItem,
--         PARIE.IdEmissao 
--		 HAVING  COUNT(*) >1
--		 ORDER BY COUNT(*) DESC


--SELECT RO.IdRegistro,RO.IdOcorrencia,COUNT(*) FROM Registro.RegistrosOcorrencias AS RO
--GROUP BY RO.IdRegistro,
--         RO.IdOcorrencia
--		 HAVING COUNT(*) >1

