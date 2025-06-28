USE Implanta;

SELECT BM.IdBemMovel,
       BM.Codigo
FROM Patrimonio.BensMoveis AS BM
WHERE BM.Codigo LIKE '[0-9]%';

SELECT BM.IdBemMovel,
       BM.Codigo
FROM Patrimonio.BensMoveis AS BM
WHERE BM.Codigo NOT LIKE '[0-9]%';