SELECT C.CONSTRAINT_NAME [constraint_name],
       C.TABLE_NAME [referencing_table_name],
       KCU.COLUMN_NAME [referencing_column_name],
       C2.TABLE_NAME [referenced_table_name],
       KCU2.COLUMN_NAME [referenced_column_name],
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
    AND KCU2.COLUMN_NAME = 'IdPlanoConta'
 ORDER BY
    C.CONSTRAINT_NAME;