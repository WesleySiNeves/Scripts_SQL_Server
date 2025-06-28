USE Implanta
-- View partition metadata
SELECT ps.name AS PartitionScheme,
       pf.name AS PartitionFunction,
       p.partition_number AS PartitionNumber,
       fg.name AS Filegroup,
       prv_left.value AS StartKey,
       prv_right.value AS EndKey,
       p.row_count Rows
  FROM sys.dm_db_partition_stats p
 INNER JOIN sys.indexes i
    ON i.object_id             = p.object_id
   AND i.index_id              = p.index_id
 INNER JOIN sys.data_spaces ds
    ON ds.data_space_id        = i.data_space_id
  LEFT OUTER JOIN sys.partition_schemes ps
    ON ps.data_space_id        = i.data_space_id
  LEFT OUTER JOIN sys.partition_functions pf
    ON ps.function_id          = pf.function_id
  LEFT OUTER JOIN sys.destination_data_spaces dds
    ON dds.partition_scheme_id = ps.data_space_id
   AND dds.destination_id      = p.partition_number
  LEFT OUTER JOIN sys.filegroups fg
    ON fg.data_space_id        = dds.data_space_id
  LEFT OUTER JOIN sys.partition_range_values prv_right
    ON prv_right.function_id   = ps.function_id
   AND prv_right.boundary_id   = p.partition_number
  LEFT OUTER JOIN sys.partition_range_values prv_left
    ON prv_left.function_id    = ps.function_id
   AND prv_left.boundary_id    = p.partition_number - 1
 WHERE 
 --OBJECT_NAME(p.object_id) = 'order_table'
    i.index_id               = 0
 ORDER BY PartitionNumber;
GO


