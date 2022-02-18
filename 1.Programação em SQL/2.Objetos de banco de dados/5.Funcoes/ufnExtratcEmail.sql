

--DECLARE @Text NVARCHAR(300) ='wesley.si.neves@gmail.com'

--GO




CREATE OR ALTER FUNCTION dbo.ufnExtractEmail(@Text NVARCHAR(300))
RETURNS TABLE RETURN 
WITH CteEmail(email) AS(
    SELECT @Text UNION ALL
    SELECT '' UNION ALL
    SELECT 'no email'
)
,CteStrings AS(
    SELECT
        [Left] = LEFT(email, CHARINDEX('@', email, 0) - 1),
        Reverse_Left = REVERSE(LEFT(email, CHARINDEX('@', email, 0) - 1)),
        [Right] = RIGHT(email, CHARINDEX('@', email, 0) + 1)
    FROM CteEmail
    WHERE email LIKE '%@%'
),
DumpStrings AS (
SELECT *,
    REVERSE(
        SUBSTRING(Reverse_Left, 0, 
            CASE
                WHEN CHARINDEX(' ', Reverse_Left, 0) = 0 THEN LEN(Reverse_Left) + 1
                ELSE CHARINDEX(' ', Reverse_Left, 0)
            END
        )
    )
    +
    SUBSTRING([Right], 0,
        CASE
            WHEN CHARINDEX(' ', [Right], 0) = 0 THEN LEN([Right]) + 1
            ELSE CHARINDEX(' ', [Right], 0)
        END
    ) AS Email
FROM CteStrings
)
SELECT D.Email FROM DumpStrings D