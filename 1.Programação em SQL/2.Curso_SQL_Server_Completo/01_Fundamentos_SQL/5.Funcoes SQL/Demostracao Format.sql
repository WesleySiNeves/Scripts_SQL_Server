USE TSQL2012;
-- using FORMAT
SELECT productid,
       FORMAT(productid, 'd10') AS str_productid
  FROM Production.Products;
