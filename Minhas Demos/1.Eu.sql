WITH Eu
  AS (SELECT T.*
        FROM (   VALUES ('Wesley Neves'),
                        ('Analista.NET'),
                        ('P�s Graduando em Banco de Dados com �nfase em BI -SENAC-DF'),
                        ('MTA -SQL Server'),
                        ('MTA -Web Developed')) AS T (X) )
SELECT Eu.X
  FROM Eu;


  WITH Eu
AS (SELECT * FROM ( VALUES
            ( CONCAT('Wesley Neves ','#','.NET Developer') ),
            (CONCAT('M�CSA SQL 2016 Database Development',' # ',' MTA-SQL Server',' MTA-Web Developed')),
            ('P�s Graduando em Banco de Dados com �nfase em BI')
    ) AS X (X)
   )
SELECT *
FROM Eu;