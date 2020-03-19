USE TSQLV4;


/* ==================================================================
--Data: 07/06/2018 
--Observação: Criando um Schema 
 
-- ==================================================================
*/


DROP  TABLE IF EXISTS dbo.Beverages
DROP TABLE IF EXISTS dbo.Condiments

DROP XML SCHEMA COLLECTION ProductsAdditionalAttributes


ALTER TABLE Production.Products DROP CONSTRAINT ck_Namespace;
ALTER TABLE Production.Products DROP COLUMN additionalattributes;


---- Auxiliary tables
CREATE TABLE dbo.Beverages (percentvitaminsRDA INT);
CREATE TABLE dbo.Condiments (shortdescription NVARCHAR(50));


GO

-- Store the schemas in a variable and create the collection
DECLARE @mySchema AS NVARCHAR(MAX) = N'';
SET @mySchema += (SELECT * FROM Beverages FOR XML AUTO, ELEMENTS, XMLSCHEMA('Beverages'));
SET @mySchema += (SELECT * FROM Condiments FOR XML AUTO, ELEMENTS, XMLSCHEMA('Condiments'));
SELECT CAST(@mySchema AS XML);
CREATE XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes AS
@mySchema;
GO
-- Drop auxiliary tables
DROP TABLE dbo.Beverages,
           dbo.Condiments;
GO





/* ==================================================================
--Data: 07/06/2018 
--Observação: Agora precisamos Alterar a coluna 
O próximo passo é alterar a coluna XML de um estado bem formado para um esquema validado pelo esquema.
 
-- ==================================================================
*/


ALTER TABLE Production.Products
 ALTER COLUMN additionalattributes
XML(dbo.ProductsAdditionalAttributes);




/* ==================================================================
--Data: 07/06/2018 
--Observação: Antes de usar o novo tipo de dados, você precisa cuidar de mais um problema. Como você
evitar vincular o esquema errado a um produto de uma categoria específica? Por exemplo, como
você evita ligar um esquema de condimentos a uma bebida? Você poderia resolver esse problema com um
desencadear; no entanto, ter uma restrição declarativa
 
-- ==================================================================
*/
GO

-- Function to retrieve the namespace
CREATE OR ALTER FUNCTION dbo.GetNamespace (@chkcol AS XML)
RETURNS NVARCHAR(15)
AS
BEGIN
    RETURN @chkcol.value('namespace-uri((/*)[1])', 'NVARCHAR(15)');
END;
GO
-- Function to retrieve the category name
CREATE OR ALTER FUNCTION dbo.GetCategoryName (@catid AS INT)
RETURNS NVARCHAR(15)
AS
BEGIN
    RETURN (SELECT categoryname FROM Production.Categories WHERE categoryid = @catid);
END;
GO
--

-- Add the constraint
ALTER TABLE Production.Products ADD CONSTRAINT ck_Namespace CHECK (dbo.GetNamespace(additionalattributes) =
dbo.GetCategoryName(categoryid));


/* ==================================================================
--Data: 07/06/2018 
--Observação: A infra-estrutura está preparada.
  Execute o código a seguir para tentar inserir alguns XML válidos
  dados em sua nova coluna
 
-- ==================================================================
*/

/* ==================================================================
--Data: 07/06/2018 
--Observação: Agora vamos fazer algumas alteracoes
 
-- ==================================================================
*/

-- Beverage
UPDATE Production.Products
SET additionalattributes = N'
<Beverages xmlns="Beverages">
<percentvitaminsRDA>27</percentvitaminsRDA>
</Beverages>'
WHERE productid = 1;

-- Condiment
UPDATE Production.Products
SET additionalattributes = N'
<Condiments xmlns="Condiments">
<shortdescription>very sweet</shortdescription>
</Condiments>'
WHERE productid = 3;



-- String instead of int
UPDATE Production.Products
SET additionalattributes = N'
<Beverages xmlns="Beverages">
<percentvitaminsRDA>twenty seven</percentvitaminsRDA>
</Beverages>'
WHERE productid = 1;
-- Wrong namespace
UPDATE Production.Products
SET additionalattributes = N'
<Condiments xmlns="Condiments">
<shortdescription>very sweet</shortdescription>
</Condiments>'
WHERE productid = 2;
-- Wrong element
UPDATE Production.Products
SET additionalattributes = N'
<Condiments xmlns="Condiments">
<unknownelement>very sweet</unknownelement>
</Condiments>'
WHERE productid = 3;