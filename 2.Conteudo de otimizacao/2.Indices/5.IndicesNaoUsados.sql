

WITH Dados
  AS (
	
     -- Show writes versus reads to see candidates for unused indexes
     SELECT
	  DB_NAME(DB_ID()) AS DB,
	  CONVERT(VARCHAR(120), OBJECT_NAME(ios.object_id)) AS [Object Name],
            i.name AS [Index Name],
            i.type_desc,
            SUM(ios.range_scan_count + ios.singleton_lookup_count) AS 'Reads',
            SUM(ios.leaf_insert_count + ios.leaf_update_count + ios.leaf_delete_count) AS 'Writes'
       FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ios
      INNER JOIN sys.indexes AS i
         ON i.object_id = ios.object_id
        AND i.index_id  = ios.index_id
      WHERE OBJECTPROPERTY(ios.object_id, 'IsUserTable') = 1
        AND i.type_desc                                  <> 'CLUSTERED'
      GROUP BY OBJECT_NAME(ios.object_id),
               i.name,
               i.type_desc)
SELECT *
  FROM Dados R
  WHERE R.Reads = 0
 ORDER BY R.Reads ASC,
          R.Writes DESC;


--SELECT * FROM sys.dm_db_index_usage_stats AS DDIUS
--WHERE (DDIUS.user_seeks + DDIUS.user_scans + DDIUS.user_lookups) = 0