
-- ==================================================================
--Observa��o: Uniqueness Constraints ( Primary Key and Unique 
-- ==================================================================
/*Uniqueness Constraints*/

CREATE TABLE Examples.UniquenessConstraint (
    PrimaryUniqueValue INT NOT NULL,
    AlternateUniqueValue1 INT NULL,
    AlternateUniqueValue2 INT NULL);


-- ==================================================================
--Observa��o: Criando uma PK (que gera uma restri��o unica )
-- ==================================================================
ALTER TABLE Examples.UniquenessConstraint ADD CONSTRAINT PKUniquenessContraint PRIMARY KEY (PrimaryUniqueValue);

SELECT * FROM Examples.UniquenessConstraint AS UC
-- ==================================================================
--Observa��o: Criando uma restri��o  UNIQUE(Restri��o ) que o Sql server internamente gera um indice UNIQUE
-- ==================================================================
ALTER TABLE Examples.UniquenessConstraint
ADD CONSTRAINT AKUniquenessContraint
    UNIQUE (AlternateUniqueValue1, AlternateUniqueValue2);

SELECT indexes.type_desc,
       indexes.is_primary_key,
       indexes.is_unique,
       indexes.is_unique_constraint
  FROM sys.indexes
 WHERE OBJECT_ID('Examples.UniquenessConstraint') = indexes.object_id;


 -- ==================================================================
 --Observa��o: Fazendo a Valida��o
 -- ==================================================================


INSERT INTO Examples.UniquenessConstraint (PrimaryUniqueValue,
                                           AlternateUniqueValue1,
                                           AlternateUniqueValue2)
VALUES (1, NULL, NULL),
(2, NULL, NULL);
/*
Msg 2627, Level 14, State 1, Line 36
Viola��o da restri��o UNIQUE KEY 'AKUniquenessContraint'. N�o � poss�vel inserir uma chave duplicada no objeto 'Examples.UniquenessConstraint'. O valor de chave duplicada � (<NULL>, <NULL>).
A instru��o foi terminada.

*/


-- ==================================================================
--Observa��o: FOREIGN KEY
-- ==================================================================

--Represents an order a person makes, there are 10,000,000 + rows in this table
CREATE TABLE Examples.Invoice (InvoiceId INT NOT NULL CONSTRAINT PKInvoice PRIMARY KEY,
--Other Columns Omitted
);
--Represents a type of discount the office gives a customer,
--there are 200 rows in this table
CREATE TABLE Examples.DiscountType (DiscountTypeId INT NOT NULL CONSTRAINT PKDiscountType PRIMARY KEY,
--Other Columns Omitted
); 
--Represents the individual items that a customer has ordered, There is an average of
--3 items ordered per invoice, so there are over 30,000,000 rows in this table
CREATE TABLE Examples.InvoiceLineItem (
    InvoiceLineItemId INT NOT NULL CONSTRAINT PKInvoiceLineItem PRIMARY KEY,
    InvoiceId INT NOT NULL CONSTRAINT FKInvoiceLineItem$Ref$Invoice REFERENCES Examples.Invoice (InvoiceId),
    DiscountTypeId INT NOT NULL CONSTRAINT FKInvoiceLineItem$Ref$DiscountType REFERENCES Examples.DiscountType (DiscountTypeId) --Other Columns Omitted
);

-- ==================================================================
--Observa��o: Cria um indice FK
-- ==================================================================
CREATE INDEX InvoiceId ON Examples.InvoiceLineItem (InvoiceId);

-- ==================================================================
--Observa��o:  �ndice filtrado

-- ==================================================================

CREATE INDEX DiscountTypeId ON Examples.InvoiceLineItem (DiscountTypeId) WHERE DiscountTypeId IS NOT NULL;

-- ==================================================================
--Observa��o: Indice Unique
-- ==================================================================

CREATE UNIQUE INDEX InvoiceColumns ON Examples.InvoiceLineItem(InvoiceId,DiscountTypeId)



use WideWorldImporters 
GO

-- ==================================================================
 --Observa��o: veja a quantidade de valores nulos na tabela
 --aqui cabe um indice filtrado
-- ==================================================================
SELECT PaymentMethodId, COUNT(*) AS NumRows
FROM Sales.CustomerTransactions
GROUP BY PaymentMethodID;


-- ==================================================================
--Observa��o: rode a query com o plano de execu��o
-- ==================================================================
SELECT *
FROM Sales.CustomerTransactions
WHERE PaymentMethodID = 4;



/*
O processo de adi��o de �ndices come�a durante a fase de desenvolvimento do projeto. At�
com quantidades menores de dados em uma tabela, existem caminhos de acesso dados que n�o correspondem
exatamente aos �ndices as restri��es de singularidade que voc� iniciou com adicionadas. Por exemplo,
*/

--Contagem de verifica��es 1, leituras l�gicas 692,
SET STATISTICS IO ON 
SET STATISTICS TIME ON 
SELECT Orders.CustomerID,
       Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate
  FROM Sales.Orders
 WHERE Orders.CustomerPurchaseOrderNumber = '16374';

 SET STATISTICS IO OFF
SET STATISTICS TIME OFF 



CREATE INDEX CustomerPurchaseOrderNumber
ON Sales.Orders (CustomerPurchaseOrderNumber);


--Conntagem de verifica��es 1, leituras l�gicas 20,
SET STATISTICS IO ON 
SET STATISTICS TIME ON 
SELECT Orders.CustomerID,
       Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate
  FROM Sales.Orders
 WHERE Orders.CustomerPurchaseOrderNumber = '16374';

 SET STATISTICS IO OFF
SET STATISTICS TIME OFF 

--Ficou bom mais ainda temos o operador de  Key Lookup

/*
Quando o custo de busca em ambos os conjuntos
� muito dispendioso, um operador Hash Match � usado. Este operador faz um pseudo �ndice de hash por
segmentando valores em baldes de valores que podem ser mais f�ceis de digitalizar usando uma fun��o hash. isto
n�o precisa de nenhuma ordem para a opera��o, por isso pode funcionar para juntar dois conjuntos realmente grandes
*/


--Vamos criar um  indice cobrindo a FK
--CREATE NONCLUSTERED INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders(ContactPersonID)



--Tabela 'Orders'. Contagem de verifica��es 2, leituras l�gicas 1047, leituras f�sicas 3, leituras antecipadas 628,
--Tabela 'People'. Contagem de verifica��es 1, leituras l�gicas 80, leituras f�sicas 1, leituras antecipadas 71, le

SET STATISTICS IO ON
SET STATISTICS TIME ON 
SELECT Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate,
       People.FullName
  FROM Sales.Orders
  JOIN Application.People
    ON People.PersonID = Orders.ContactPersonID
 WHERE People.PreferredName = 'Aakriti';

 SET STATISTICS IO OFF
SET STATISTICS TIME OFF

DROP INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders;


--abela 'Workfile'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, leit
--abela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, lei
--abela 'Orders'. Contagem de verifica��es 1, leituras l�gicas 692, leituras f�sicas 0, leituras antecipadas 292, le
--abela 'People'. Contagem de verifica��es 1, leituras l�gicas 80, leituras f�sicas 0, leituras antecipadas 75, leit
SET STATISTICS IO ON
SET STATISTICS TIME ON 
SELECT Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate,
       People.FullName
  FROM Sales.Orders
  JOIN Application.People
    ON People.PersonID = Orders.ContactPersonID
 WHERE People.PreferredName = 'Aakriti';

 SET STATISTICS IO OFF
SET STATISTICS TIME OFF



-- ==================================================================
--Observa��o: um indice melhor seria
-- ================================================================== 
--DROP INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders
CREATE NONCLUSTERED INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders(ContactPersonID) INCLUDE(OrderDate,ExpectedDeliveryDate);




-- ==================================================================
--Observa��o: Indices e o Sort
-- ==================================================================

--Veja  o plano de execu��o dessa query


SET STATISTICS IO ON 
SET STATISTICS TIME ON 

/*
Tabela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, 
Tabela 'Orders'. Contagem de verifica��es 5, leituras l�gicas 725, leituras f�sicas 0, leituras antecipadas 295,

Tempos de Execu��o do SQL Server: 
Tempo de CPU = 45 ms, tempo decorrido = 364 ms.

Tempos de Execu��o do SQL Server: 
Tempo de CPU = 0 ms, tempo decorrido = 0 ms.

*/
SELECT SalespersonPersonId, OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonId ASC, OrderDate ASC;
SET STATISTICS IO OFF
SET STATISTICS TIME OFF



--Agora veja criando um indice ordenado
CREATE INDEX SalespersonPersonID_OrderDate
ON Sales.Orders (SalespersonPersonID ASC, OrderDate ASC);

--DROP INDEX SalespersonPersonID_OrderDate ON Sales.Orders


SET STATISTICS IO ON 
SET STATISTICS TIME ON 
--Rode a query

SELECT SalespersonPersonId, OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonId ASC, OrderDate ASC;

/*
Tabela 'Orders'. Contagem de verifica��es 1, leituras l�gicas 159, leituras f�sicas 0, leituras antecipadas 29, 
(1 row affected)
 Tempos de Execu��o do SQL Server: 
 Tempo de CPU = 15 ms, tempo decorrido = 284 ms.
 Tempos de Execu��o do SQL Server: 
 Tempo de CPU = 0 ms, tempo decorrido = 0 ms.
*/

SET STATISTICS IO OFF
SET STATISTICS TIME OFF

/*Distinguish between indexed columns and included columns*/
--Rode as querys com o plano de execu��o ligado e veja o custo do operador  Key Lookup
DROP INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders
CREATE NONCLUSTERED INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders(ContactPersonID)


SELECT Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate,
       People.FullName
  FROM Sales.Orders
  JOIN Application.People
    ON People.PersonID = Orders.ContactPersonID
 WHERE People.PreferredName = 'Aakriti';


 --agora vamos criar um indice de cobertura
CREATE NONCLUSTERED INDEX ContactPersonID_Include_OrderDate_ExpectedDeliveryDate
ON Sales.Orders (ContactPersonID)
INCLUDE (OrderDate, ExpectedDeliveryDate) ON USERDATA;

SET STATISTICS IO ON 

SELECT Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate,
       People.FullName
  FROM Sales.Orders
  JOIN Application.People
    ON People.PersonID = Orders.ContactPersonID
 WHERE People.PreferredName = 'Aakriti';
SET STATISTICS IO OFF




--Veja que ainda n�o foi a melhor op��o
--Vamos criar um indice cobrindo o where
CREATE NONCLUSTERED INDEX PreferredName_Include_FullName
ON Application.People (PreferredName)
INCLUDE (FullName) ON USERDATA;


--Query
SET STATISTICS IO ON 

SELECT Orders.OrderID,
       Orders.OrderDate,
       Orders.ExpectedDeliveryDate,
       People.FullName
  FROM Sales.Orders
  JOIN Application.People
    ON People.PersonID = Orders.ContactPersonID
 WHERE People.PreferredName = 'Aakriti';
SET STATISTICS IO OFF



-- ==================================================================
--Observa��o: Vamos analisar um segundo ponto
-- ==================================================================

/*

(32850 rows affected)
Tabela 'Orders'. Contagem de verifica��es 1, leituras l�gicas 187, leituras f�sicas 0, leituras antecipadas 185,
(1 row affected)
 Tempos de Execu��o do SQL Server: 
 Tempo de CPU = 0 ms, tempo decorrido = 167 ms.

 Tempos de Execu��o do SQL Server: 
 Tempo de CPU = 0 ms, tempo decorrido = 0 ms.

*/
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Orders.OrderDate,
       Orders.ExpectedDeliveryDate
  FROM Sales.Orders
 WHERE Orders.OrderDate > '2015-01-01';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

--Criando o indice

CREATE NONCLUSTERED INDEX [IdxOrderDateCoberto]
ON [Sales].[Orders] ([OrderDate])
INCLUDE ([ExpectedDeliveryDate]);



SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Orders.OrderDate,
       Orders.ExpectedDeliveryDate
  FROM Sales.Orders
 WHERE Orders.OrderDate > '2015-01-01';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;