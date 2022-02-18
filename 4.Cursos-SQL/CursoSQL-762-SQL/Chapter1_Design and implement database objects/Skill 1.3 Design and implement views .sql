-- ==================================================================
--Observação: Skill 1.3: Design and implement views
-- ==================================================================

-- ==================================================================
/*
Sintaxe
CREATE VIEW SchemaName.ViewName
[WITH OPTIONS]
AS SELECT statement
[WITH CHECK OPTION]
 */
-- ==================================================================


-- ==================================================================
--Observação: Criando um View para buscar todas as ordens de pedidos
--dos ultimos 3 anos que tiveram mais de um pedido
-- ==================================================================


/*
Using views to hide data for a particular purpose
*/


CREATE VIEW Sales.Orders12MonthsMultipleItems
AS
SELECT Orders.OrderID,
       Orders.CustomerID,
       Orders.SalespersonPersonID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate
  FROM Sales.Orders
 WHERE Orders.OrderDate >= DATEADD(MONTH, -36, SYSDATETIME())
   AND (   SELECT COUNT(*)
             FROM Sales.OrderLines
            WHERE OrderLines.OrderID = Orders.OrderID) > 1;



GO
            
-- ==================================================================
--Observação: Using a view to reformatting data in the output
-- ==================================================================

--Query Original
SELECT People.PersonID,
       People.IsPermittedToLogon,
       People.IsEmployee,
       People.IsSalesperson
  FROM Application.People;



GO
-- ==================================================================
--Observação: Criando a view para formatar os dados
-- ==================================================================
CREATE VIEW Application.PeopleEmployeeStatus
AS
SELECT People.PersonID,
       People.FullName,
       People.IsPermittedToLogon,
       People.IsEmployee,
       People.IsSalesperson,
       CASE
            WHEN People.IsPermittedToLogon = 1 THEN 'Can Logon'
            ELSE 'Can''t Logon' END AS LogonRights,
       CASE
            WHEN People.IsEmployee = 1
             AND People.IsSalesperson = 1 THEN 'Sales Person'
            WHEN People.IsEmployee = 1 THEN 'Regular'
            ELSE 'Not Employee' END AS EmployeeType
  FROM Application.People;

  GO
  

  /*Select Na View*/

SELECT * FROM Application.PeopleEmployeeStatus AS PES
  

  -- ==================================================================
  --Observação: Using a view to provide a reporting interface
  -- ==================================================================

GO
CREATE VIEW Reports.InvoiceSummaryBasis
AS
SELECT Invoices.InvoiceID,
       CustomerCategories.CustomerCategoryName,
       Cities.CityName,
       StateProvinces.StateProvinceName,
       StateProvinces.SalesTerritory,
       Invoices.InvoiceDate,
       --the grain of the report is at the invoice, so total
       --the amounts for invoice
       SUM(InvoiceLines.LineProfit) AS InvoiceProfit,
       SUM(InvoiceLines.ExtendedPrice) AS InvoiceExtendedPrice
  FROM Sales.Invoices
  JOIN Sales.InvoiceLines
    ON Invoices.InvoiceID             = InvoiceLines.InvoiceID
  JOIN Sales.Customers
    ON Customers.CustomerID           = Invoices.CustomerID
  JOIN Sales.CustomerCategories
    ON Customers.CustomerCategoryID   = CustomerCategories.CustomerCategoryID
  JOIN Application.Cities
    ON Customers.DeliveryCityID       = Cities.CityID
  JOIN Application.StateProvinces
    ON StateProvinces.StateProvinceID = Cities.StateProvinceID
 GROUP BY Invoices.InvoiceID,
          CustomerCategories.CustomerCategoryName,
          Cities.CityName,
          StateProvinces.StateProvinceName,
          StateProvinces.SalesTerritory,
          Invoices.InvoiceDate;

GO

--Query 1
SELECT * FROM Reports.InvoiceSummaryBasis AS ISB


--Query 2
SELECT TOP 5 InvoiceSummaryBasis.SalesTerritory,
       SUM(InvoiceSummaryBasis.InvoiceProfit) AS InvoiceProfitTotal
  FROM Reports.InvoiceSummaryBasis
 WHERE InvoiceSummaryBasis.InvoiceDate > '2016-05-01'
 GROUP BY InvoiceSummaryBasis.SalesTerritory
 ORDER BY InvoiceProfitTotal DESC;


--Query 3
SELECT TOP 5 InvoiceSummaryBasis.StateProvinceName,
       InvoiceSummaryBasis.CustomerCategoryName,
       SUM(InvoiceSummaryBasis.InvoiceExtendedPrice) AS InvoiceExtendedPriceTotal
  FROM Reports.InvoiceSummaryBasis
 WHERE InvoiceSummaryBasis.InvoiceDate > '2016-05-01'
 GROUP BY InvoiceSummaryBasis.StateProvinceName,
          InvoiceSummaryBasis.CustomerCategoryName
 ORDER BY InvoiceExtendedPriceTotal DESC;


 -- ==================================================================
 --Observação: Identify the steps necessary to design an updateable view
 /*
 o objetivo é
para criar objetos que se comportem exatamente como tabelas em relação a 
SELECT, INSERT, UPDATE,
e instruções DELETE sem modificações especiais.
 */
 -- ==================================================================
 
 /*
 Modificando visualizações que fazem referência a uma tabela
De um modo geral, qualquer visualização que faça referência a uma única tabela 
seja editável. 
 */


CREATE TABLE Examples.Gadget (
    GadgetId INT NOT NULL
        CONSTRAINT PKGadget PRIMARY KEY,
    GadgetNumber CHAR(8) NOT NULL
        CONSTRAINT AKGadget
        UNIQUE,
    GadgetType VARCHAR(10) NOT NULL);
INSERT INTO Examples.Gadget (GadgetId,
                             GadgetNumber,
                             GadgetType)
VALUES (1, '00000001', 'Electronic'),
(2, '00000002', 'Manual'),
(3, '00000003', 'Manual');

GO


CREATE VIEW Examples.ElectronicGadget
AS
SELECT Gadget.GadgetId,
       Gadget.GadgetNumber,
       Gadget.GadgetType,
       UPPER(Gadget.GadgetType) AS UpperGadgedType
  FROM Examples.Gadget
 WHERE Gadget.GadgetType = 'Electronic';
 GO
 

 --query
SELECT * FROM Examples.ElectronicGadget AS EG

SELECT V.GadgetNumber AS FromView,
       Gadget.GadgetNumber AS FromTable,
       Gadget.GadgetType,
       V.UpperGadgedType
  FROM Examples.ElectronicGadget V
  FULL OUTER JOIN Examples.Gadget ON V.GadgetId = Gadget.GadgetId;



INSERT INTO Examples.ElectronicGadget (GadgetId,
                                       GadgetNumber,
                                       GadgetType,
                                       UpperGadgetType)
VALUES (4, '00000004', 'Electronic', 'XXXXXXXXXX'), --row we can see in view
(5, '00000005', 'Manual', 'YYYYYYYYYY'); --row we cannot see in view  (Aqui da erro)

/*
Nome de coluna inválido 'UpperGadgetType'.
Msg 4406, Level 16, State 1, Line 204
Falha na atualização ou inserção da vista ou função 'Examples.ElectronicGadget' 
devido a conter um campo derivado ou constante.
*/

-- ==================================================================
--Observação: Veja que fizemos um insert em uma view , onde o dado não e retornado por ela
-- ================================================================== 

INSERT INTO Examples.ElectronicGadget (GadgetId,
                                       GadgetNumber,
                                       GadgetType)
VALUES (4, '00000004', 'Electronic'),
(5, '00000005', 'Manual');

SELECT * FROM Examples.ElectronicGadget AS EG
WHERE EG.GadgetId =5


--query
SELECT ElectronicGadget.GadgetNumber AS FromView,
       Gadget.GadgetNumber AS FromTable,
       Gadget.GadgetType,
       ElectronicGadget.UpperGadgedType
  FROM Examples.ElectronicGadget
  FULL OUTER JOIN Examples.Gadget
    ON ElectronicGadget.GadgetId = Gadget.GadgetId
 WHERE Gadget.GadgetId IN ( 4, 5 );


--Update the row we could see to values that could not be seen
UPDATE Examples.ElectronicGadget
   SET ElectronicGadget.GadgetType = 'Manual'
 WHERE ElectronicGadget.GadgetNumber = '00000004';


UPDATE Examples.ElectronicGadget
   SET ElectronicGadget.GadgetType = 'Electronic'
 WHERE ElectronicGadget.GadgetNumber = '00000005';


 -- ==================================================================
 --Observação: Limitando quais dados podem ser adicionados a uma tabela através de uma visão através de DDL

 /*
 WITH CHECK OPTION that checks to make sure that the result of the INSERT or
UPDATE statement is still visible to the user of the view
 */
 -- ==================================================================

 GO
 
ALTER VIEW Examples.ElectronicGadget
AS
 SELECT Gadget.GadgetId, 
		Gadget.GadgetNumber,
	    Gadget.GadgetType,
	    UPPER(Gadget.GadgetType) AS UpperGadgetType
 FROM Examples.Gadget
 WHERE Gadget.GadgetType = 'Electronic'
WITH CHECK OPTION;


go
-- ==================================================================
--Observação: Em alguns objetos vc pode usar o novo comando  DROP TABLE IF EXISTS
/*
https://blogs.msdn.microsoft.com/sqlserverstorageengine/2015/11/03/drop-if-exists-new-thing-in-sql-server-2016/
 */
-- ==================================================================


-- ==================================================================
--Observação: Agora vamos fazer um insert que satizfaz a tabela mas não satisfaz a view
-- ==================================================================
INSERT INTO Examples.ElectronicGadget (GadgetId,
                                       GadgetNumber,
                                       GadgetType)
VALUES (6, '00000006', 'Manual');
/*
Falha da tentativa de inserção ou de atualização porque a vista de destino especifica WITH CHECK OPTION ou abrange uma vista que especifica WITH CHECK OPTION, 
e a uma ou mais linhas resultantes da operação não se qualificaram sob a restrição CHECK OPTION.
*/


-- ==================================================================
--Observação: 
/*
Modificando dados em vistas com mais de uma tabela
Até agora, a visão com a qual trabalhamos apenas continha uma tabela. Nesta seção, observamos
como as coisas são afetadas quando você tem maior que uma tabela na vista
 */
-- ==================================================================

CREATE TABLE Examples.GadgetType (
    GadgetType VARCHAR(10) NOT NULL
        CONSTRAINT PKGadgetType PRIMARY KEY,
    Description VARCHAR(200) NOT NULL);
INSERT INTO Examples.GadgetType (GadgetType,
                                 Description)
VALUES ('Manual', 'No batteries'),
('Electronic', 'Lots of bats');
ALTER TABLE Examples.Gadget
ADD CONSTRAINT FKGadget$ref$Examples_GadgetType
    FOREIGN KEY (GadgetType)
    REFERENCES Examples.GadgetType (GadgetType);


--query
SELECT * FROM Examples.GadgetType AS GT


-- ==================================================================
--Observação: Agora vamos criar uma view com mais de uma tabela
/*
 */
-- ==================================================================

GO

CREATE VIEW Examples.GadgetExtension
AS
SELECT Gadget.GadgetId,
       Gadget.GadgetNumber,
       Gadget.GadgetType,
       GadgetType.GadgetType AS DomainGadgetType,
       GadgetType.Description AS GadgetTypeDescription
  FROM Examples.Gadget
  JOIN Examples.GadgetType
    ON Gadget.GadgetType = GadgetType.GadgetType;

	GO
    

-- ==================================================================
/* Agora vamos  disparar um insert contra a view
 */
-- ==================================================================

INSERT INTO Examples.GadgetExtension (GadgetId,
                                      GadgetNumber,
                                      GadgetType,
                                      DomainGadgetType,
                                      GadgetTypeDescription)
VALUES (7, '00000007', 'Acoustic', 'Acoustic', 'Sound');

/*
Msg 4405, Level 16, State 1, Line 352
A vista ou a função 'Examples.GadgetExtension' não é atualizável
 devido à modificação afetar várias tabelas base.
*/


SELECT * FROM Examples.GadgetExtension AS GE
SELECT * FROM Examples.Gadget AS G
SELECT * FROM Examples.GadgetType AS GT


INSERT INTO Examples.GadgetExtension(DomainGadgetType,
GadgetTypeDescription)
VALUES('Acoustic','Sound');


INSERT INTO Examples.GadgetExtension(GadgetId, GadgetNumber,
GadgetType)
VALUES(7,'00000007','Acoustic');



UPDATE Examples.GadgetExtension
SET GadgetTypeDescription = 'Uses Batteries'
WHERE GadgetId = 1;

SELECT *
FROM Examples.Gadget
JOIN Examples.GadgetType
ON Gadget.GadgetType = GadgetType.GadgetType
WHERE Gadget.GadgetType = 'Electronic';

-- ==================================================================
--Observação: Implement partitioned views
-- ==================================================================
--Criando duas tabelas
CREATE TABLE Examples.Invoices_Region1 (
    InvoiceId INT NOT NULL
        CONSTRAINT PKInvoices_Region1 PRIMARY KEY,
    CONSTRAINT CHKInvoices_Region1_PartKey CHECK (InvoiceId BETWEEN 1 AND 10000),
    CustomerId INT NOT NULL,
    InvoiceDate DATE NOT NULL);

CREATE TABLE Examples.Invoices_Region2 (
    InvoiceId INT NOT NULL
        CONSTRAINT PKInvoices_Region2 PRIMARY KEY,
    CONSTRAINT CHKInvoices_Region2_PartKey CHECK (InvoiceId BETWEEN 10001 AND 20000),
    CustomerId INT NOT NULL,
    InvoiceDate DATE NOT NULL);

	--Fazendo o Insert de Dados

INSERT INTO Examples.Invoices_Region1 (InvoiceId,
                                       CustomerId,
                                       InvoiceDate)
SELECT InvoiceId,
       CustomerId,
       InvoiceDate
  FROM WideWorldImporters.Sales.Invoices
 WHERE InvoiceId BETWEEN 1 AND 10000;


 --Fazendo o Insert de Dados
INSERT INTO Examples.Invoices_Region2 (InvoiceId,
                                       CustomerId,
                                       InvoiceDate)
SELECT InvoiceId,
       CustomerId,
       InvoiceDate
  FROM WideWorldImporters.Sales.Invoices
 WHERE InvoiceId BETWEEN 10001 AND 20000;

 --Link de leitura https://msdn.microsoft.com/en-us/library/ms187956.aspx

 GO
CREATE VIEW Examples.InvoicesPartitioned
AS
SELECT Invoices_Region1.InvoiceId,
       Invoices_Region1.CustomerId,
       Invoices_Region1.InvoiceDate
  FROM Examples.Invoices_Region1
UNION ALL
SELECT Invoices_Region2.InvoiceId,
       Invoices_Region2.CustomerId,
       Invoices_Region2.InvoiceDate
  FROM Examples.Invoices_Region2;

GO

--Rode a query  com o plano de execução habilitado
  SELECT *
FROM Examples.InvoicesPartitioned
WHERE InvoiceId = 1;



-- ==================================================================
--Observação: Implement indexed views
/*
Uma visualização indexada (às vezes referida como uma visão materializada), é uma visão que foi
fez mais do que apenas uma simples consulta armazenada criando um índice agrupado nela. Fazendo
Isto, basicamente, torna uma cópia de dados em uma estrutura física muito parecida com uma tabela.
O primeiro benefício de usar uma visualização indexada é que quando você a usa Enterprise Edition de
SQL Server, ele usa os dados armazenados na estrutura do índice. Para Standard Edition, ele usa o
código da consulta, a menos que você use uma dica da tabela NOEXPAND, caso em que usa a
representação de índice em cluster.

The limitations are pretty stiff. For example, a
few common bits of coding syntax that are not allowed:

1)SELECT * syntax—columns must be explicitly named
2)UNION, EXCEPT, or INTERSECT
3)Subqueries
4)TOP in the SELECT clause
5)DISTINCT
6)SUM() function referencing more than one column

7)any aggregate function against an expression that can return NULL
8)Reference any other views, or use CTEs or derived tables
9)Reference any nondeterministic functions
 */
-- ==================================================================


-- ==================================================================
--Observação: Exemplo
/*
 */
-- ==================================================================
GO

CREATE VIEW Sales.InvoiceCustomerInvoiceAggregates
WITH SCHEMABINDING
AS
SELECT Invoices.CustomerID,
       SUM(InvoiceLines.ExtendedPrice * InvoiceLines.Quantity) AS SumCost,
       SUM(InvoiceLines.LineProfit) AS SumProfit,
       COUNT_BIG(*) AS TotalItemCount
  FROM Sales.Invoices
  JOIN Sales.InvoiceLines
    ON Invoices.InvoiceID = InvoiceLines.InvoiceID
 GROUP BY Invoices.CustomerID;


 GO
 

 /*
 Tabela 'Invoices'. Contagem de verificações 1, leituras lógicas 166, lei
 Tabela 'InvoiceLines'. Contagem de verificações 1, leituras lógicas 5003
 */
 SET STATISTICS IO ON 
 SELECT * FROM Sales.InvoiceCustomerInvoiceAggregates AS ICIA
 SET STATISTICS IO OFF


 --Aqui cria um indice unique para a view (tem que ser unique)
 CREATE UNIQUE CLUSTERED INDEX XPKInvoiceCustomerInvoiceAggregates ON Sales.InvoiceCustomerInvoiceAggregates(CustomerID)


 --Rode com plano de execução acionado

  SET STATISTICS IO ON 
 SELECT * FROM Sales.InvoiceCustomerInvoiceAggregates AS ICIA
 SET STATISTICS IO OFF