USE WideWorldImporters

SELECT OBJECT_NAME(object_id) AS ObjectName,
       name,
       auto_created
FROM
 sys.stats
WHERE auto_created = 1
      AND object_id IN (
                           SELECT object_id FROM sys.objects WHERE type = 'U'
                       );