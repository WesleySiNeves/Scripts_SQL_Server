SELECT SCHEMA_NAME(T.schema_id),
       T.object_id,
       T.name,
       T.type_desc,
       QuantidadeColunas = T.max_column_id_used,
       TotalLinhas = S.rowcnt,
       TOT.QuantidadeIndicesNonClusterTabela
FROM sys.tables AS T
     JOIN
     sys.sysindexes AS S ON T.object_id = S.id
                            AND S.indid = 1
     LEFT JOIN
     (
     SELECT I.object_id,
            QuantidadeIndicesNonClusterTabela = COUNT(*)
     FROM sys.indexes AS I
     WHERE I.type > 1
     GROUP BY
         I.object_id
     ) AS TOT ON T.object_id = TOT.object_id
ORDER BY
    TOT.QuantidadeIndicesNonClusterTabela DESC;
