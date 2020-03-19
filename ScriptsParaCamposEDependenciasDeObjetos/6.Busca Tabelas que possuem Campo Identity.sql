
/*Localiza Tabelas que possue Campos  Identity */

SELECT  IDENT_SEED(TABLE_NAME) AS Seed ,
        IDENT_INCR(TABLE_NAME) AS Increment ,
        IDENT_CURRENT(TABLE_NAME) AS Current_Identity ,
        TABLE_NAME
FROM    INFORMATION_SCHEMA.TABLES
WHERE   OBJECTPROPERTY(OBJECT_ID(TABLE_NAME), 'TableHasIdentity') = 1
        AND TABLE_TYPE = 'BASE TABLE';