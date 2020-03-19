;WITH CTE_INDEX_DATA
AS (SELECT SCHEMA_DATA.name AS schema_name,
           TABLE_DATA.name AS table_name,
           INDEX_DATA.name AS index_name,
           STUFF(
           (
               SELECT ', ' + COLUMN_DATA_KEY_COLS.name + ' '
                      + CASE
                            WHEN INDEX_COLUMN_DATA_KEY_COLS.is_descending_key = 1 THEN
                                'DESC'
                            ELSE
                                'ASC'
                        END -- Include column order (ASC / DESC)
               FROM sys.tables AS T
                   INNER JOIN sys.indexes INDEX_DATA_KEY_COLS
                       ON T.object_id = INDEX_DATA_KEY_COLS.object_id
                   INNER JOIN sys.index_columns INDEX_COLUMN_DATA_KEY_COLS
                       ON INDEX_DATA_KEY_COLS.object_id = INDEX_COLUMN_DATA_KEY_COLS.object_id
                          AND INDEX_DATA_KEY_COLS.index_id = INDEX_COLUMN_DATA_KEY_COLS.index_id
                   INNER JOIN sys.columns COLUMN_DATA_KEY_COLS
                       ON T.object_id = COLUMN_DATA_KEY_COLS.object_id
                          AND INDEX_COLUMN_DATA_KEY_COLS.column_id = COLUMN_DATA_KEY_COLS.column_id
               WHERE INDEX_DATA.object_id = INDEX_DATA_KEY_COLS.object_id
                     AND INDEX_DATA.index_id = INDEX_DATA_KEY_COLS.index_id
                     AND INDEX_COLUMN_DATA_KEY_COLS.is_included_column = 0
               ORDER BY INDEX_COLUMN_DATA_KEY_COLS.key_ordinal
               FOR XML PATH('')
           ),
           1,
           2,
           ''
                ) AS key_column_list,
           STUFF(
           (
               SELECT ', ' + COLUMN_DATA_INC_COLS.name
               FROM sys.tables AS T
                   INNER JOIN sys.indexes INDEX_DATA_INC_COLS
                       ON T.object_id = INDEX_DATA_INC_COLS.object_id
                   INNER JOIN sys.index_columns INDEX_COLUMN_DATA_INC_COLS
                       ON INDEX_DATA_INC_COLS.object_id = INDEX_COLUMN_DATA_INC_COLS.object_id
                          AND INDEX_DATA_INC_COLS.index_id = INDEX_COLUMN_DATA_INC_COLS.index_id
                   INNER JOIN sys.columns COLUMN_DATA_INC_COLS
                       ON T.object_id = COLUMN_DATA_INC_COLS.object_id
                          AND INDEX_COLUMN_DATA_INC_COLS.column_id = COLUMN_DATA_INC_COLS.column_id
               WHERE INDEX_DATA.object_id = INDEX_DATA_INC_COLS.object_id
                     AND INDEX_DATA.index_id = INDEX_DATA_INC_COLS.index_id
                     AND INDEX_COLUMN_DATA_INC_COLS.is_included_column = 1
               ORDER BY INDEX_COLUMN_DATA_INC_COLS.key_ordinal
               FOR XML PATH('')
           ),
           1,
           2,
           ''
                ) AS include_column_list,
           INDEX_DATA.is_disabled -- Check if index is disabled before determining which dupe to drop (if applicable)
    FROM sys.indexes INDEX_DATA
        INNER JOIN sys.tables TABLE_DATA
            ON TABLE_DATA.object_id = INDEX_DATA.object_id
        INNER JOIN sys.schemas SCHEMA_DATA
            ON SCHEMA_DATA.schema_id = TABLE_DATA.schema_id
    WHERE TABLE_DATA.is_ms_shipped = 0
          AND INDEX_DATA.type_desc IN ( 'NONCLUSTERED', 'CLUSTERED' )
   )
SELECT *
FROM CTE_INDEX_DATA DUPE1
WHERE EXISTS
(
    SELECT *
    FROM CTE_INDEX_DATA DUPE2
    WHERE DUPE1.schema_name = DUPE2.schema_name
          AND DUPE1.table_name = DUPE2.table_name
          AND DUPE1.key_column_list = DUPE2.key_column_list
          AND ISNULL(DUPE1.include_column_list, '') = ISNULL(DUPE2.include_column_list, '')
          AND DUPE1.index_name <> DUPE2.index_name
);