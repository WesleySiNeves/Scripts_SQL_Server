DECLARE @ROLLBACK BIT = 0;

IF(OBJECT_ID('TEMPDB..#TabelasExcecao') IS NOT NULL)
    DROP TABLE #TabelasExcecao;

CREATE TABLE #TabelasExcecao
(
    [TableName] NVARCHAR(128)
);

INSERT INTO #TabelasExcecao(
                               TableName
                           )
VALUES(N'Sistema.Configuracoes'),
(N'Sistema.Sistemas'),
('Contabilidade.PlanoContas'),
('Contabilidade.PlanoContasAnuais');

/*Region Logical Querys*/
IF(OBJECT_ID('TEMPDB..#Tabelas') IS NOT NULL)
    DROP TABLE #Tabelas;

CREATE TABLE #Tabelas
(
    [object_id]    INT,
    [TableName]    NVARCHAR(128),
    ScriptTruncate AS (CONCAT('DELETE ', TableName, ';'))
);

IF(OBJECT_ID('TEMPDB..#Scripts') IS NOT NULL)
    DROP TABLE #Scripts;

CREATE TABLE #Scripts
(
    [constraint_name]                NVARCHAR(128),
    [FK SCHEMA]                      NVARCHAR(128),
    [Tabela Filha]                   NVARCHAR(128),
    [ColunaFilha]                    NVARCHAR(128),
    [Schema Pai]                     NVARCHAR(128),
    [Tabela Pai]                     NVARCHAR(128),
    [Coluna Pai]                     NVARCHAR(128),
    [delete_referential_action_desc] VARCHAR(11),
    [update_referential_action_desc] VARCHAR(11),
    [Passo1 Sql Disable FK]          NVARCHAR(725),
    [Passo2 Sql Enable FK]           NVARCHAR(734)
);

WITH DadosContrutor
    AS
    (
        SELECT C.CONSTRAINT_NAME [constraint_name],
               C.CONSTRAINT_SCHEMA [FK SCHEMA],
               C.TABLE_NAME [Tabela Filha],
               KCU.COLUMN_NAME [ColunaFilha],
               C2.CONSTRAINT_SCHEMA [Schema Pai],
               C2.TABLE_NAME [Tabela Pai],
               KCU2.COLUMN_NAME [Coluna Pai],
               RC.DELETE_RULE delete_referential_action_desc,
               RC.UPDATE_RULE update_referential_action_desc
          FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
               INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU ON C.CONSTRAINT_SCHEMA = KCU.CONSTRAINT_SCHEMA
                                                                     AND C.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
               INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC ON C.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
                                                                           AND C.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
               INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2 ON RC.UNIQUE_CONSTRAINT_SCHEMA = C2.CONSTRAINT_SCHEMA
                                                                     AND RC.UNIQUE_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
               INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2 ON C2.CONSTRAINT_SCHEMA = KCU2.CONSTRAINT_SCHEMA
                                                                      AND C2.CONSTRAINT_NAME = KCU2.CONSTRAINT_NAME
                                                                      AND KCU.ORDINAL_POSITION = KCU2.ORDINAL_POSITION
         WHERE
            C.CONSTRAINT_TYPE = 'FOREIGN KEY'
    )
INSERT INTO #Scripts(
                        constraint_name,
                        [FK SCHEMA],
                        [Tabela Filha],
                        ColunaFilha,
                        [Schema Pai],
                        [Tabela Pai],
                        [Coluna Pai],
                        delete_referential_action_desc,
                        update_referential_action_desc,
                        [Passo1 Sql Disable FK],
                        [Passo2 Sql Enable FK]
                    )
SELECT PC.constraint_name,
       PC.[FK SCHEMA],
       PC.[Tabela Filha],
       PC.ColunaFilha,
       PC.[Schema Pai],
       PC.[Tabela Pai],
       PC.[Coluna Pai],
       PC.delete_referential_action_desc,
       PC.update_referential_action_desc,
       [Passo1 Sql Disable FK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[', PC.[FK SCHEMA], '].', '[', PC.[Tabela Filha], '])) BEGIN ') + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.', '[', PC.[Tabela Filha], ']', SPACE(2), 'NOCHECK CONSTRAINT', SPACE(2), '[', PC.constraint_name, ']; END'),
       [Passo2 Sql Enable FK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[', PC.[FK SCHEMA], '].', '[', PC.[Tabela Filha], '])) BEGIN ') + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.', '[', PC.[Tabela Filha], ']', SPACE(2), 'WITH CHECK CHECK CONSTRAINT', SPACE(2), '[', PC.constraint_name, ']; END')
  FROM DadosContrutor PC;

INSERT INTO #Tabelas(
                        object_id,
                        TableName
                    )
SELECT T.object_id,
       CONCAT(QUOTENAME(S.name), '.', QUOTENAME(T.name))
  FROM sys.tables AS T
       JOIN sys.schemas AS S ON T.schema_id = S.schema_id
 WHERE
    T.object_id NOT IN(
                          SELECT OBJECT_ID(TE.TableName)FROM #TabelasExcecao AS TE
                      );

IF(EXISTS (
              SELECT *
                FROM sys.syscursors AS S
               WHERE
                  S.cursor_name = 'cursor_TruncateTable'
          )
  )
    BEGIN
        DEALLOCATE cursor_TruncateTable;
    END;

IF(EXISTS (
              SELECT *
                FROM sys.syscursors AS S
               WHERE
                  S.cursor_name = 'cursor_DesabilitaFK'
          )
  )
    BEGIN
        DEALLOCATE cursor_DesabilitaFK;
    END;

IF(EXISTS (
              SELECT *
                FROM sys.syscursors AS S
               WHERE
                  S.cursor_name = 'cursor_HabilitaFK'
          )
  )
    BEGIN
        DEALLOCATE cursor_HabilitaFK;
    END;

SET XACT_ABORT ON;

BEGIN TRANSACTION SCHEDULE;

BEGIN TRY

    /* declare variables */
    DECLARE @ScriptDesabilitaFK VARCHAR(MAX);

    DECLARE cursor_DesabilitaFK CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT S.[Passo1 Sql Disable FK] FROM #Scripts AS S;

    OPEN cursor_DesabilitaFK;

    FETCH NEXT FROM cursor_DesabilitaFK
     INTO @ScriptDesabilitaFK;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT @ScriptDesabilitaFK;

            EXEC(@ScriptDesabilitaFK);

            FETCH NEXT FROM cursor_DesabilitaFK
             INTO @ScriptDesabilitaFK;
        END;

    CLOSE cursor_DesabilitaFK;
    DEALLOCATE cursor_DesabilitaFK;

    /* declare variables */
    DECLARE @ScriptTruncate VARCHAR(MAX);

    DECLARE cursor_TruncateTable CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT T.ScriptTruncate FROM #Tabelas AS T;

    OPEN cursor_TruncateTable;

    FETCH NEXT FROM cursor_TruncateTable
     INTO @ScriptTruncate;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC(@ScriptTruncate);

            FETCH NEXT FROM cursor_TruncateTable
             INTO @ScriptTruncate;
        END;

    CLOSE cursor_TruncateTable;
    DEALLOCATE cursor_TruncateTable;

    /* declare variables */
    DECLARE @ScriptHabilitaFK VARCHAR(MAX);

    DECLARE cursor_HabilitaFK CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT S.[Passo2 Sql Enable FK] FROM #Scripts AS S;

    OPEN cursor_HabilitaFK;

    FETCH NEXT FROM cursor_HabilitaFK
     INTO @ScriptHabilitaFK;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT @ScriptHabilitaFK;

            EXEC(@ScriptHabilitaFK);

            FETCH NEXT FROM cursor_HabilitaFK
             INTO @ScriptHabilitaFK;
        END;

    CLOSE cursor_HabilitaFK;
    DEALLOCATE cursor_HabilitaFK;

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
