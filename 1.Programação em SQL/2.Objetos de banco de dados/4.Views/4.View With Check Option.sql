--SELECT * FROM  Production.Categories AS C



ALTER VIEW getCategorias AS 

SELECT * FROM Production.Categories AS C

WHERE C.categoryname ='Condiments'
WITH CHECK OPTION;




--DROP VIEW dbo.getCategorias
SELECT * FROM dbo.getCategorias AS GC;

INSERT INTO dbo.getCategorias
        ( categoryname, description )
VALUES  ( N'Automovel', -- categoryname - nvarchar(15)
          N'Categorias de carros'  -- description - nvarchar(200)
          );

