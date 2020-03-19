WITH Eu
  AS (SELECT T.*
        FROM (   VALUES ('Wesley Neves'),
                        ('Analista.NET'),
                        ('Pós Graduando em Banco de Dados com ênfase em BI -SENAC-DF'),
                        ('MTA -SQL Server'),
                        ('MTA -Web Developed')) AS T (X) )
SELECT Eu.X
  FROM Eu;


  WITH Eu
AS (SELECT * FROM ( VALUES
            ( CONCAT('Wesley Neves ','#','.NET Developer') ),
            (CONCAT('M®CSA SQL 2016 Database Development',' # ',' MTA-SQL Server',' MTA-Web Developed')),
            ('Pós Graduando em Banco de Dados com ênfase em BI')
    ) AS X (X)
   )
SELECT *
FROM Eu;