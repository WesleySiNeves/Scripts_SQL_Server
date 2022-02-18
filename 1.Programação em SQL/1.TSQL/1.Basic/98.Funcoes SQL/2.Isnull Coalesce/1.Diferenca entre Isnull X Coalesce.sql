/*ISNULL faz tipagem implicita de dados*/

DECLARE
@x AS VARCHAR(3) = NULL,
@y AS VARCHAR(10) = '1234567890';
SELECT COALESCE(@x, @y) AS [COALESCE], ISNULL(@x, @y) AS [ISNULL]