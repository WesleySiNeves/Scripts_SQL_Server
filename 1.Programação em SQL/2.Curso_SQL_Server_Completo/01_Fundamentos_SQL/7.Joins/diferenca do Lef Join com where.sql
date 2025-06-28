

-- suppliers from Japan and products they supply
-- suppliers without products included
SELECT S.companyname AS supplier,
       S.country,
       P.productid,
       P.productname,
       P.unitprice
  FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
 WHERE S.country = N'Japan';

--return all suppliers
--show products for only suppliers from Japan
SELECT S.companyname AS supplier,
       S.country,
       P.productid,
       P.productname,
       P.unitprice
  FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
   AND S.country    = N'Japan';