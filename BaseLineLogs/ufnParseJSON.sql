/* ==================================================================
--Data: 26/02/2019 
--Autor :Wesley Neves
--Observação: Testado no Sql Server 2014 express
 
-- ==================================================================
*/

DECLARE @Table TABLE
(
    ID INT,
    Active BIT,
    First_Name VARCHAR(50),
    Last_Name VARCHAR(50),
    EMail VARCHAR(50)
);
INSERT INTO @Table
VALUES
(1, 1, 'John', 'Smith', 'john.smith@email.com'),
(2, 0, 'Jane', 'Doe', 'jane.doe@email.com');

SELECT A.ID,
       A.Last_Name,
       A.First_Name,
       B.JSON
FROM @Table A
    CROSS APPLY
(SELECT JSON = [Sistema].[ufnParseJSON](0, 1, (SELECT A.* FOR XML RAW))) B;





GO
CREATE OR ALTER FUNCTION Sistema.[ufnParseJSON]
(
    @IncludeHead INT,
    @ToLowerCase INT,
    @XML XML
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @Head VARCHAR(MAX) = '',
            @JSON VARCHAR(MAX) = '';
    WITH cteEAV
    AS (SELECT RowNr = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
               Entity = R.xRow.value('@*[1]', 'varchar(100)'),
               Attribute = xAtt.value('local-name(.)', 'varchar(100)'),
               Value = xAtt.value('.', 'varchar(max)')
        FROM @XML.nodes('/row') AS R(xRow)
            CROSS APPLY R.xRow.nodes('./@*') AS A(xAtt)
       ),
         cteSum
    AS (SELECT Records = COUNT(DISTINCT cteEAV.Entity),
               Head = IIF(@IncludeHead = 0,
                          IIF(COUNT(DISTINCT cteEAV.Entity) <= 1, '[getResults]', '[[getResults]]'),
                          CONCAT(
                                    '{"status":{"successful":"true","timestamp":"',
                                    FORMAT(GETUTCDATE(), 'yyyy-MM-dd hh:mm:ss '),
                                    'GMT',
                                    '","rows":"',
                                    COUNT(DISTINCT cteEAV.Entity),
                                    '"},"results":[[getResults]]}'
                                ))
        FROM cteEAV
       ),
         cteBld
    AS (SELECT *,
               NewRow = IIF(
                            LAG(cteEAV.Entity, 1) OVER (PARTITION BY cteEAV.Entity ORDER BY (SELECT NULL)) = cteEAV.Entity,
                            '',
                            ',[{'),
               EndRow = IIF(
                            LEAD(cteEAV.Entity, 1) OVER (PARTITION BY cteEAV.Entity ORDER BY (SELECT NULL)) = cteEAV.Entity,
                            ',',
                            '}]'),
               JSON = CONCAT(
                                '"',
                                IIF(@ToLowerCase = 1, LOWER(cteEAV.Attribute), cteEAV.Attribute),
                                '":',
                                '"',
                                cteEAV.Value,
                                '"'
                            )
        FROM cteEAV
       )
    SELECT @JSON = @JSON + cteBld.NewRow + cteBld.JSON + cteBld.EndRow,
           @Head = cteSum.Head
    FROM cteBld,
         cteSum;
    RETURN REPLACE(@Head, '[getResults]', STUFF(@JSON, 1, 1, ''));
END;