
/* ==================================================================
--Data: 04/06/2018 
--Observação:  
	Artigos 1) https://www.mssqltips.com/sqlservertip/5109/benefits-of-using-sql-server-temporal-tables--part-1/
	Artigos 2) https://www.mssqltips.com/sqlservertip/3682/sql-server-2016-tsql-syntax-to-query-temporal-tables/
	Artigos 3) https://www.mssqltips.com/sqlservertip/5436/options-to-retrieve-sql-server-temporal-table-and-history-data/

	documentação https://docs.microsoft.com/pt-br/sql/relational-databases/tables/temporal-tables?view=sql-server-2017
	
 
-- ==================================================================
*/

USE master
GO

DROP DATABASE IF EXISTS TestTemporal;

CREATE DATABASE TestTemporal;
GO
 
USE TestTemporal
GO

CREATE TABLE Customer (
    CustomerId INT IDENTITY(1, 1) PRIMARY KEY,
    FirstName VARCHAR(30) NOT NULL,
    LastName VARCHAR(30) NOT NULL,
    Amount_purchased DECIMAL NOT NULL,
    StartDate DATETIME2 GENERATED ALWAYS AS ROW START  HIDDEN NOT NULL,
    EndDate DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME(StartDate, EndDate))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.CustomerHistory));



GO

INSERT INTO dbo.Customer (FirstName, LastName, Amount_Purchased)
VALUES('Frank', 'Sinatra', 20000.00),('Shawn', 'McGuire', 30000.00),('Amy', 'Carlson', 40000.00);
GO




-- Now make some changes in the table
WAITFOR DELAY '00:00:30';

-- insert a row
INSERT INTO Customer (FirstName, LastName, Amount_purchased)
VALUES ('Peter', 'Pan', 50000);
GO

WAITFOR DELAY '00:00:30';

-- delete a row
DELETE FROM dbo.Customer WHERE CustomerId = 2;
GO

WAITFOR DELAY '00:00:30';

-- update a row
UPDATE Customer SET Lastname = 'Clarkson' WHERE CustomerId = 3;


-- Let us query both temporal and history tables
SELECT * FROM dbo.Customer;
SELECT * FROM dbo.CustomerHistory;


-- ==================================================================
--Observação: Para recuperar dados deletados da tabela pai
-- ==================================================================

SELECT * FROM dbo.CustomerHistory AS CH;

-- ==================================================================
--Observação: Registro deletado
-- ==================================================================
SELECT * FROM dbo.CustomerHistory AS CH
 WHERE NOT  EXISTS(SELECT 1
 FROM dbo.Customer AS C WHERE C.CustomerId = CH.CustomerId)
  

  -- ==================================================================
  --Observação: Recupera o registro deletado
  /*
  ocê obtém as linhas em que @dt> = validfrom AND @dt <validto (@dt está on ou
após validfrom e antes de validto). Em outras palavras, o período de validade começa em ou antes de @dt
e termina depois de @dt
   */
  -- ==================================================================

  
SELECT CustomerId, FirstName,LastName, Amount_purchased ,Customer.StartDate,Customer.EndDate
FROM dbo.Customer  
   FOR SYSTEM_TIME AS OF '2018-06-04 16:43:00.5576605' 
WHERE CustomerId =2 

 
SELECT CustomerId, FirstName,LastName, Amount_purchased ,Customer.StartDate,Customer.EndDate
FROM dbo.Customer  
   FOR SYSTEM_TIME AS OF '2018-06-04 16:43:00.5576605' 
WHERE CustomerId =2 

DECLARE @filtro DATETIME2 ='2018-06-04 16:43:00.5576605';


SELECT * FROM  dbo.CustomerHistory AS CH
WHERE CH.CustomerId =2
AND  @filtro >=CH.StartDate AND CH.EndDate < @filtro



--- recover one row that we deleted			
-- this table has an identity column so we need to allow inserts using this command
SET IDENTITY_INSERT dbo.Customer ON 
  
INSERT INTO dbo.Customer(CustomerId, FirstName, LastName, Amount_purchased) 
SELECT CustomerId, FirstName,LastName, Amount_purchased 
FROM dbo.Customer  
   FOR SYSTEM_TIME AS OF '2018-06-04 16:21:42.5909501' 
WHERE CustomerId =2 

-- this table has an identity column so now we need to turn off inserts using this command  
SET IDENTITY_INSERT dbo.Customer OFF 


-- Let's look at the old value of CustomerID =3 
SELECT * 
FROM dbo.Customer  
WHERE CustomerId = 3 

SELECT * 
FROM dbo.Customer  
 FOR SYSTEM_TIME AS OF '2018-06-04 16:21:42.5909501'  
WHERE CustomerId = 3 
  


-- ==================================================================
--Observação: Revertendo a Atualização
-- ==================================================================

-- Recover old value of the updated row
UPDATE dbo.Customer
   SET Customer.LastName = history.LastName
  FROM dbo.Customer
    FOR SYSTEM_TIME AS OF '2018-06-04 16:21:42.5909501' AS history
 WHERE history.CustomerId = 3
   AND history.CustomerId = 3;
 
-- Let us query both temporal and history tables
SELECT * FROM dbo.Customer;
SELECT * FROM dbo.CustomerHistory

SELECT * FROM dbo.CustomerHistory AS CH
WHERE CH.CustomerId =2
ORDER BY CH.StartDate


DECLARE @filtro2 DATETIME2 ='2018-06-04 16:21:43';


SELECT C.* FROM dbo.Customer 
FOR SYSTEM_TIME AS OF @filtro2 AS C
WHERE C.CustomerId =2




/*Mostra todas al alterações na tabela*/

--Show list of all changes made to a SQL Server Temporal Table

SELECT * 
FROM dbo.Customer 
   FOR SYSTEM_TIME ALL 
ORDER BY Customer.CustomerId,
 StartDate; 

 --- All records for Amy 
SELECT * 
FROM dbo.Customer 
   FOR SYSTEM_TIME ALL 
WHERE CustomerId = 3 
ORDER BY StartDate; 


-- ==================================================================
--Observação: Parte 2) 
/*
 */
-- ==================================================================

DROP TABLE IF EXISTS dbo.PriceHistory

-- create history table
CREATE TABLE dbo.PriceHistory
	(ID			INT				NOT NULL
	,Product	VARCHAR(50)		NOT NULL
	,Price		NUMERIC(10,2)	NOT NULL
	,StartDate	DATETIME2		NOT NULL
	,EndDate	DATETIME2		NOT NULL
	);
GO


-- insert values for history
INSERT INTO dbo.PriceHistory(ID,Product,Price,StartDate,EndDate)
VALUES	 (1,'myProduct',1.15,'2015-07-01 00:00:00','2015-07-01 11:58:00')
		,(1,'myProduct',1.16,'2015-07-01 11:58:00','2015-07-03 12:00:00')
		,(1,'myProduct',1.18,'2015-07-03 12:00:00','2015-07-05 18:05:00')
		,(1,'myProduct',1.21,'2015-07-05 18:05:00','2015-07-07 08:33:00');

-- create current table to store prices
CREATE TABLE dbo.Price
	(ID			INT				NOT NULL
	,Product	VARCHAR(50)		NOT NULL
	,Price		NUMERIC(10,2)	NOT NULL
	,StartDate	DATETIME2		NOT NULL
	,EndDate	DATETIME2		NOT NULL
	,CONSTRAINT PK_Price PRIMARY KEY CLUSTERED  (ID ASC)
	);
GO



-- insert the current price (make sure start date is not in the future!)
INSERT INTO dbo.Price(ID,Product,Price,StartDate,EndDate)
VALUES	 (1,'myProduct',1.20,'2015-07-07 08:33:00','9999-12-31 23:59:59.9999999');

SELECT * FROM dbo.Price AS P
SELECT * FROM dbo.PriceHistory AS PH

/*
O script cria apenas linhas para um produto, a fim de manter o exemplo simples e fácil de entender. Este produto terá 4 versões históricas e 1 versão atual.
*/

SELECT * FROM dbo.Price    FOR SYSTEM_TIME AS OF '2015-07-01 00:00:00.0000000' 

/*Modificando uma tabela comum para ser temporal*/

ALTER TABLE dbo.Price 
ADD PERIOD FOR SYSTEM_TIME(StartDate, EndDate); 



ALTER TABLE dbo.Price SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PriceHistory,DATA_CONSISTENCY_CHECK=ON));


/* ==================================================================
--Data: 04/06/2018 
--Observação: Parte 2
A cláusula SELECT ... FROM possui uma nova cláusula no SQL Server 2016: FOR SYSTEM_TIME. Esta nova cláusula também tem 4 novas subcláusulas temporais específicas.  

1)AS OF <datetime>
2)ALL
3)FROM <start_datetime> TO <end_datetime>
4)BETWEEN <start_datetime> AND <end_datetime> ( validfrom < @end AND validto > @start)
5)CONTAINED IN (start_datetime, end_datetime)
-- ==================================================================
*/



-- ==================================================================
/* Clausula 1)

Usando "AS OF sub-clause"
você recupera a versão de cada linha que era válida naquele ponto específico no tempo. Basicamente, permite viajar no tempo até um certo ponto no passado para ver em que estado a mesa se encontrava naquele momento.
 */

-- ==================================================================

SELECT * FROM dbo.Price AS P

SELECT * FROM dbo.PriceHistory AS PH
WHERE PH.StartDate <= '2015-07-01 00:00:00.0000000'

SELECT * FROM dbo.Price 
FOR SYSTEM_TIME AS OF '2015-07-01 00:00:00.0000000'
AS PH 



SELECT * FROM dbo.Price 
FOR SYSTEM_TIME AS OF '2015-07-01 11:58:00.0000000'
AS PH 

SELECT * FROM dbo.Price 
FOR SYSTEM_TIME AS OF '2015-07-03 12:00:00.0000000'
AS PH 

/*
Query FROM A TO B for SQL Server Temporal Table Data

exemplo:
 SELECT * FROM dbo.Price FOR SYSTEM_TIME FROM '2015-07-02' TO '2015-07-06';

 isso vai ficar assim 
 StartDate < B AND EndDate > A
*/




SELECT * FROM dbo.Price
--StartDate < B AND EndDate > A
FOR SYSTEM_TIME FROM  '2015-07-01' TO '2015-07-03'


-- ==================================================================
--Observação: BETWEEN A AND B Logic for SQL Server Temporal Tables
/*
 StartDate ? B AND EndDate > A
*/
-- ==================================================================

SELECT * FROM dbo.Price
 --validfrom <= @end AND validto > @start
FOR SYSTEM_TIME BETWEEN  '2015-07-01'  AND '2015-07-03'


/* ==================================================================
--Data: 04/06/2018 
--Observação: CONTAINED IN (A,B) Logic for SQL Server Temporal Tables
 Essa logica emgloba (validfrom >= @start AND validto <= @end)
-- ==================================================================
*/

SELECT * FROM dbo.Price
--A ? StartDate AND EndDate ? B
FOR SYSTEM_TIME CONTAINED IN ('2015-07-02','2015-07-06');


/* ==================================================================
--Data: 04/06/2018 
--Observação: Parte 3 da demo contexto de uma situação problema
 
Vamos mergulhar em um exemplo para entender como essas subcláusulas funcionam e que tipo de dados elas retornam e por quê.
Assumiremos um cenário da vida real em que já existem soluções manuais para acompanhar a história de alguma forma.
Temos uma tabela de Voluntários que acompanha a atribuição de deveres atuais de cada voluntário.
Também temos uma tabela VolunteersHistory, que registra as mudanças na história da tabela Volunteers. 
Vamos juntar as duas tabelas em uma solução temporal que automaticamente monitora a história
-- ==================================================================
*/


/* ==================================================================
--Data: 04/06/2018 
--Observação: 1)Criar exemplo de tabela temporal
 
-- ==================================================================
*/




  
-- Volunteers table
CREATE TABLE dbo.Volunteers
(
  id INT NOT NULL CONSTRAINT PK_Volunteers PRIMARY KEY NONCLUSTERED,
  Serving_Area VARCHAR(20) NULL,
  Volunteer_name VARCHAR(25) NOT NULL,
  sysstart DATETIME2(0) NOT NULL,
  sysend DATETIME2(0) NOT NULL
);
CREATE UNIQUE CLUSTERED INDEX  ix_Volunteers ON dbo.Volunteers  (id, sysstart, sysend);
 
-- Insert data into Volunteers table 
INSERT INTO dbo.Volunteers (id, Serving_Area, Volunteer_name, sysstart, sysend)
VALUES
   (1 , NULL,           'David', '2018-01-31 17:44:04', '9999-12-31 23:59:59'), 
   (2 , 'Nursing Home', 'Eliza', '2018-01-31 17:44:04', '9999-12-31 23:59:59'), 
   (3 , 'Nursing Home', 'Inara', '2018-01-31 17:44:04', '9999-12-31 23:59:59'), 
   (4 , 'Shelter',      'Sam',   '2018-01-31 17:44:04', '9999-12-31 23:59:59'), 
   (5 , 'Shelter',      'Leo',   '2018-02-01 19:54:20', '9999-12-31 23:59:59'), 
   (6 , 'Baby Sitting', 'Steve', '2018-03-29 18:44:04', '9999-12-31 23:59:59'), 
   (7 , 'Soup Kitchen', 'Aaron', '2018-03-01 17:44:04', '9999-12-31 23:59:59'), 
   (8 , 'School',       'Laila', '2018-03-01 17:44:04', '9999-12-31 23:59:59'), 
   (9 , 'Soup Kitchen', 'Eva',   '2018-03-01 17:44:04', '9999-12-31 23:59:59'), 
   (10, 'School',       'Sean',  '2018-03-29 17:44:04', '9999-12-31 23:59:59'),  
   (11, 'Library',      'Uriel', '2018-03-29 18:44:04', '9999-12-31 23:59:59'); 
 


-- VolunteersHistory table
CREATE TABLE dbo.VolunteersHistory (
    id INT NOT NULL,
    Serving_Area VARCHAR(20) NULL,
    Volunteer_name VARCHAR(25) NOT NULL,
    sysstart DATETIME2(0) NOT NULL,
    sysend DATETIME2(0) NOT NULL);
CREATE CLUSTERED INDEX ix_VolunteersHistory
ON dbo.VolunteersHistory (id, sysstart, sysend)
WITH (DATA_COMPRESSION = PAGE);
 
-- Insert some historical data into VolunteersHistory table
INSERT INTO dbo.VolunteersHistory  (id, Serving_Area, Volunteer_name, sysstart, sysend) 
VALUES
   (6 , 'Shelter',      'Steve',   '2018-01-31 17:44:04', '2018-03-29 18:44:04'), 
   (7 , 'Baby Sitting', 'Aaron',   '2018-01-31 17:44:04', '2018-03-01 17:44:04'), 
   (9 , 'Lost Found',   'Eva',     '2018-01-31 17:44:04', '2018-01-31 18:44:04'),
   (9 , 'Baby Sitting', 'Eva',     '2018-01-31 18:45:04', '2018-03-01 17:44:04'), 
   (11, 'Lost Found',   'Uriel',   '2018-01-31 17:44:04', '2018-01-31 18:44:04'), 
   (11, 'Baby Sitting', 'Uriel',   '2018-01-31 18:44:04', '2018-03-29 18:44:04'), 
   (12, 'Traffic',      'Emily',   '2018-01-31 17:44:04', '2018-03-29 19:01:41'), 
   (13, 'Traffic',      'Michael', '2018-01-31 17:44:04', '2018-01-31 18:44:04'), 
   (14, 'Traffic',      'Tom',     '2018-01-31 17:44:04', '2018-01-31 18:44:04'); 


   /*Adiciona a clausula de periodo para as versões*/
   ALTER TABLE dbo.Volunteers ADD PERIOD FOR SYSTEM_TIME(sysstart,sysend);

   /*Vincula a tabela de historico */
   ALTER TABLE dbo.Volunteers SET(SYSTEM_VERSIONING =ON (HISTORY_TABLE =dbo.VolunteersHistory));


   SELECT * FROM dbo.Volunteers;
SELECT * FROM dbo.VolunteersHistory;

/* ==================================================================
--Data: 04/06/2018 
--Observação: Querying Temporal Table Data Using SYSTEM_TIME AS OF and ALL
 
 A subseção AS OF retorna linhas da tabela temporal e de histórico válidas até a hora especificada.
-- ==================================================================
*/

/*Tabela Transacional*/
SELECT * FROM dbo.Volunteers AS V
WHERE V.id =11


/*Tabela De Historico*/
SELECT * FROM dbo.VolunteersHistory
FOR SYSTEM_TIME AS OF '2018-03-29 18:44:04'
WHERE VolunteersHistory.id =11


/*Resultado*/
SELECT * FROM dbo.Volunteers
FOR SYSTEM_TIME AS OF '2018-03-29' AS V
WHERE V.id =11

/*Resultado*/
SELECT * FROM dbo.Volunteers
FOR SYSTEM_TIME AS OF '2018-03-30' AS V
WHERE V.id =11

/*FOR SYSTEM_TIME filtra as linhas que têm um período de validade com duração zero (SysStartTime = SysEndTime).*/
SELECT * FROM dbo.VolunteersHistory AS VH
WHERE VH.id=11

SELECT * FROM dbo.Volunteers 
FOR SYSTEM_TIME AS OF '2018-01-31 18:44:04' AS VH
WHERE VH.id=11 


/* ==================================================================
--Data: 04/06/2018 
--Observação: SYSTEM_TIME ALL
Por outro lado, ALL fornece tudo da tabela atual e de histórico
 
-- ==================================================================
*/

/*A consulta acima é equivalente à consulta UNION ALL a seguir, mas veja como a consulta temporal é mais simples e mais limpa.*/
SELECT * FROM dbo.Volunteers 
FOR SYSTEM_TIME ALL
AS V
ORDER BY V.id,V.sysstart


DECLARE @datetime AS DATETIME2(0) = '2018-03-01 17:44:04', @id AS INT = 9;

SELECT * FROM dbo.Volunteers FOR SYSTEM_TIME AS OF @datetime WHERE id = @id



/* ==================================================================
--Data: 04/06/2018 
--Observação: Querying Temporal Table Data Using SYSTEM_TIME Using FROM and TO clause
 
-- ==================================================================
*/

DECLARE
  @start AS DATETIME2(0)= '2018-01-31 17:44:04', -- time of Eva's first assignment
  @end   AS DATETIME2(0)= '2018-03-01 17:44:04', -- time of Eva's current assignment
  @id AS INT = 9;
 
SELECT * FROM dbo.Volunteers FOR SYSTEM_TIME FROM @start TO @end WHERE id = @id;
 
-- Equivalent Union Query
SELECT * FROM dbo.Volunteers WHERE id = @id AND sysstart < @end AND sysend > @start
UNION ALL
SELECT * FROM dbo.VolunteersHistory WHERE id = @id AND sysstart < @end   AND sysend > @start;
GO

/* ==================================================================
--Data: 04/06/2018 
--Observação: Querying Temporal Table Data Using SYSTEM_TIME Using BETWEEN AND pair
 
-- ==================================================================
*/

DECLARE
  @start AS DATETIME2(0)= '2018-01-31 17:44:04', -- time of Eva's first assignment
  @end   AS DATETIME2(0)= '2018-03-01 17:44:04',  -- time of Eva's current assignment
  @id AS INT = 9;
 
SELECT * FROM dbo.Volunteers FOR SYSTEM_TIME BETWEEN @start AND @end WHERE id = @id;
 
-- UNION ALL equivalent
SELECT * FROM dbo.Volunteers WHERE id = @id AND sysstart < = @end AND sysend > @start
UNION ALL
SELECT * FROM dbo.VolunteersHistory WHERE id = @id AND sysstart < = @end AND sysend > @start;
GO

/* ==================================================================
--Data: 04/06/2018 
--Observação: Querying Temporal Table Data Using SYSTEM_TIME Using Contained IN
 
-- ==================================================================
*/

DECLARE @start AS DATETIME2(0) = '2018-01-31 17:44:04', -- time of Eva's first assignment
        @end AS   DATETIME2(0) = '2018-03-01 17:44:04', -- time of Eva's current assignment
        @id AS    INT          = 9;

SELECT *
  FROM dbo.Volunteers
    FOR SYSTEM_TIME CONTAINED IN(@start, @end)
 WHERE Volunteers.id = @id;

-- Equivalent UNION ALL query
SELECT *
  FROM dbo.Volunteers
 WHERE Volunteers.id       = @id
   AND Volunteers.sysstart >= @start
   AND Volunteers.sysend   <= @end
UNION ALL
SELECT *
  FROM dbo.VolunteersHistory
 WHERE VolunteersHistory.id       = @id
   AND VolunteersHistory.sysstart >= @start
   AND VolunteersHistory.sysend   <= @end;
GO