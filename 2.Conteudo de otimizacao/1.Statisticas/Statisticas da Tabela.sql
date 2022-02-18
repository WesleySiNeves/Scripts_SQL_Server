USE Implanta;

SELECT name AS ObjectName,
       S.stats_id,
       S.auto_created,
       S.user_created,
       S.has_filter,
       STATS_DATE(object_id, stats_id) AS UpdateDate
FROM sys.stats S
WHERE S.auto_created = 0
      AND S.object_id IN (
                             SELECT T.object_id FROM sys.tables AS T
                         );
--WHERE object_id = OBJECT_ID('Sales.Customers');