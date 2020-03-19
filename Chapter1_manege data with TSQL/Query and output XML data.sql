

/* ==================================================================
--Data: 05/06/2018 
--Observação: 
XML é um padrão amplamente usado para troca de dados, que chama métodos de serviços da Web, configuração
arquivos e muito mais. Esta seção começa com uma breve introdução ao XML. Depois disso, você aprende
como criar XML como resultado de uma consulta usando diferentes sabores da cláusula FOR XML
 
-- ==================================================================
*/

DECLARE @campo XML
    = '<CustomersOrders>
<Customer custid="1" companyname="Customer NRZBB">
<Order orderid="10692" orderdate="2007-10-03T00:00:00" />
<Order orderid="10702" orderdate="2007-10-13T00:00:00" />
<Order orderid="10952" orderdate="2008-03-16T00:00:00" />
</Customer>
<Customer custid="2" companyname="Customer MLTDN">
<Order orderid="10308" orderdate="2006-09-18T00:00:00" />
<Order orderid="10926" orderdate="2008-03-04T00:00:00" />
</Customer>
</CustomersOrders>';


SELECT @campo;


/* ==================================================================
--Data: 05/06/2018 
--Observação:  A Primeira clausula e RAW
 
-- ==================================================================
*/


USE TSQLV4;
SELECT Customer.custid, Customer.companyname,
[Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
INNER JOIN Sales.Orders AS [Order]
ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW;


SELECT Customer.custid, Customer.companyname,
[Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
INNER JOIN Sales.Orders AS [Order]
ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW('Customers');




/* ==================================================================
--Data: 05/06/2018 
--Observação: Usando o comando ROOT
 
-- ==================================================================
*/

SELECT Customer.custid, Customer.companyname,
[Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
INNER JOIN Sales.Orders AS [Order]
ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW('Customers'),ROOT;



SELECT Customer.custid, Customer.companyname,
[Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
INNER JOIN Sales.Orders AS [Order]
ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW('Customer'),ROOT('Customers');



/* ==================================================================
--Data: 05/06/2018 
--Observação: Veja a diferença usando a clausula ELEMENTS
 
-- ==================================================================
*/

SELECT Customer.custid, Customer.companyname,
[Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
INNER JOIN Sales.Orders AS [Order]
ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW('Customer'),ROOT('Customers'),ELEMENTS;


/*

The FOR XML AUTO option gives you nice XML documents with nested elements, and it
is not complicated to use. In AUTO and RAW modes, you can use the keyword ELEMENTS to
produce element-centric XML. The WITH NAMESPACES clause, preceding the SELECT part of
the query, defines namespaces and aliases in the returned XML. Here is an example of a query
with the FOR XML AUTO option used, element-centric, with a namespace defined:


A opção FOR XML AUTO oferece a você documentos XML com elementos aninhados e
não é complicado de usar. Nos modos AUTO e RAW, você pode usar a palavra-chave ELEMENTS para
produzir XML centrado em elementos. A cláusula WITH NAMESPACES, precedendo a parte SELECT do
a consulta, define namespaces e aliases no XML retornado.
*/
WITH XMLNAMESPACES ('ER70761-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid],
       [co:Customer].companyname AS [co:companyname],
       [co:Order].orderid AS [co:orderid],
       [co:Order].orderdate AS [co:orderdate]
  FROM Sales.Customers AS [co:Customer]
 INNER JOIN Sales.Orders AS [co:Order]
    ON [co:Customer].custid = [co:Order].custid
 WHERE [co:Customer].custid   <= 2
   AND [co:Order].orderid % 2 = 0
 ORDER BY [co:Customer].custid,
          [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');



/* ==================================================================
--Data: 05/06/2018 
--Observação: Usando  OPENXML
 
-- ==================================================================
*/

DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(1000);
SET @XmlDocument
    = N'
<CustomersOrders>
<Customer custid="1">
<companyname>Customer NRZBB</companyname>
<Order orderid="10692">
<orderdate>2015-10-03T00:00:00</orderdate>
</Order>
<Order orderid="10702">
<orderdate>2015-10-13T00:00:00</orderdate>
</Order>
<Order orderid="10952">
<orderdate>2016-03-16T00:00:00</orderdate>
</Order>
</Customer>
<Customer custid="2">
<companyname>Customer MLTDN</companyname>
<Order orderid="10308">
<orderdate>2014-09-18T00:00:00</orderdate>
</Order>
<Order orderid="10926">
<orderdate>2016-03-04T00:00:00</orderdate>
</Order>
</Customer>
</CustomersOrders>';


-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;
-- Attribute- and element-centric mapping
-- Combining flag 8 with flags 1 and 2
SELECT *
  FROM
       OPENXML(@DocHandle, '/CustomersOrders/Customer', 11)
       WITH (custid INT,
             companyname NVARCHAR(40)
			);
-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;




/* ==================================================================
--Data: 05/06/2018 
--Observação: Usando SELECT statement with a complex XQuery expression that uses all
of the five FLWOR expressions:
 
-- ==================================================================
*/

DECLARE @x AS XML
    = N'
<CustomersOrders>
<Customer custid="1">
<!-- Comment 111 -->
<companyname>Customer NRZBB</companyname>
<Order orderid="10692">
<orderdate>2015-10-03T00:00:00</orderdate>
</Order>
<Order orderid="10702">
<orderdate>2015-10-13T00:00:00</orderdate>
</Order>
<Order orderid="10952">
<orderdate>2016-03-16T00:00:00</orderdate>
</Order>
</Customer>
<Customer custid="2">
<!-- Comment 222 -->
<companyname>Customer MLTDN</companyname>
<Order orderid="10308">
<orderdate>2014-09-18T00:00:00</orderdate>
</Order>
<Order orderid="10952">
<orderdate>2016-03-04T00:00:00</orderdate>
</Order>

</Customer>
</CustomersOrders>';
SELECT @x.query(
              'for $i in CustomersOrders/Customer/Order
let $j := $i/orderdate
where $i/@orderid < 10900
order by ($j)[1]
return
<Order-orderid-element>
<orderid>{data($i/@orderid)}</orderid>
{$j}
</Order-orderid-element>') AS [Filtered, sorted and reformatted orders with let clause];