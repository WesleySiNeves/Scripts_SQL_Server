
DECLARE @NomeCampoPesquisado VARCHAR(30) ='IdplanoConta';




WITH    DadosContrutor
          AS ( SELECT   C.CONSTRAINT_NAME [constraint_name] ,
                        C.CONSTRAINT_SCHEMA [FK SCHEMA] ,
                        C.TABLE_NAME [Tabela Filha] ,
                        KCU.COLUMN_NAME [ColunaFilha] ,
                        C2.CONSTRAINT_SCHEMA [Schema Pai] ,
                        C2.TABLE_NAME [Tabela Pai] ,
                        KCU2.COLUMN_NAME [Coluna Pai] ,
                        RC.DELETE_RULE delete_referential_action_desc ,
                        RC.UPDATE_RULE update_referential_action_desc
               FROM     INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU ON C.CONSTRAINT_SCHEMA = KCU.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC ON C.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2 ON RC.UNIQUE_CONSTRAINT_SCHEMA = C2.CONSTRAINT_SCHEMA
                                                              AND RC.UNIQUE_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2 ON C2.CONSTRAINT_SCHEMA = KCU2.CONSTRAINT_SCHEMA
                                                              AND C2.CONSTRAINT_NAME = KCU2.CONSTRAINT_NAME
                                                              AND KCU.ORDINAL_POSITION = KCU2.ORDINAL_POSITION
               WHERE    C.CONSTRAINT_TYPE = 'FOREIGN KEY'
                        AND KCU2.COLUMN_NAME = @NomeCampoPesquisado
             )
    SELECT  PC.constraint_name ,
            PC.[FK SCHEMA] ,
            PC.[Tabela Filha] ,
            PC.[ColunaFilha] ,
            PC.[Schema Pai] ,
            PC.[Tabela Pai] ,
            PC.[Coluna Pai] ,
            PC.delete_referential_action_desc ,
            PC.update_referential_action_desc ,
            [Passo1 Sql Disable FK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[',
                                        PC.[FK SCHEMA], '].', '[',
                                        PC.[Tabela Filha], '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2), 'NOCHECK CONSTRAINT',
                     SPACE(2), '[', PC.constraint_name, ']; END') ,
            [Passo2 Sql Enable FK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[',
                                        PC.[FK SCHEMA], '].', '[',
                                        PC.[Tabela Filha], '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2), 'WITH CHECK CHECK CONSTRAINT',
                     SPACE(2), '[', PC.constraint_name, ']; END')
    FROM    DadosContrutor PC;


