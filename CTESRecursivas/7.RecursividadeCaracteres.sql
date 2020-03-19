
WITH numbers AS 
( 
  SELECT 0 AS Number 
  UNION ALL 
  SELECT Number + 1 
  FROM Numbers 
  WHERE Number + 1 <= 255 
) 
SELECT Number, CHAR(Number) AS Character FROM numbers 
OPTION (MAXRECURSION 255);

