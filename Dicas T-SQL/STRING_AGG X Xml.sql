IF (OBJECT_ID('TEMPDB..#tempObjects') IS NOT NULL)
    DROP TABLE #tempObjects;


CREATE TABLE #tempObjects
(
    [object_id] INT,
    [object_name] NVARCHAR(261),
    CONSTRAINT PK_Objects
        PRIMARY KEY ([object_id])
);


IF (OBJECT_ID('TEMPDB..#tempColluns') IS NOT NULL)
    DROP TABLE #tempColluns;


CREATE TABLE #tempColluns
(
    [object_id] INT NOT NULL,
    --FOREIGN KEY REFERENCES #tempObjects([object_id]), 
    column_name sysname,
    CONSTRAINT PK_Columns
        PRIMARY KEY
        (
            [object_id],
            column_name
        )
);



INSERT #tempObjects
(
    [object_id],
    [object_name]
)
VALUES
(1, N'Employees'),
(2, N'Orders');

INSERT #tempColluns
(
    [object_id],
    column_name
)
VALUES
(1, N'EmployeeID'),
(1, N'CurrentStatus'),
(2, N'OrderID'),
(2, N'OrderDate'),
(2, N'CustomerID');



SELECT [object]  = o.[object_name],
       [columns] = STUFF(
                    (SELECT N',' + c.column_name
                       FROM #tempColluns AS c
                       WHERE c.[object_id] = o.[object_id]
                       FOR XML PATH, TYPE
                    ).value(N'.[1]',N'nvarchar(max)'),1,1,N'')
FROM #tempObjects AS o;


SELECT [object]  = o.[object_name],
       [columns] = STRING_AGG(c.column_name, N',')
FROM #tempObjects AS o
INNER JOIN #tempColluns AS c
ON o.[object_id] = c.[object_id]
GROUP BY o.[object_name];





SELECT [object]  = o.object_name,
       [columns] = STUFF(
                    (SELECT N',' +c.column_name
                       FROM #tempColluns AS c
                       WHERE c.object_id = o.[object_id]
                       ORDER BY c.column_name -- only change
                       FOR XML PATH, TYPE
                    ).value(N'.[1]',N'nvarchar(max)'),1,1,N'')
FROM #tempObjects AS o;

