--Skill 2.1 Ensure data integrity with constraints

----Define table and foreign-key constraints to enforce business rules

------Using DEFAULT constraints to guide the user’s input

DROP DATABASE IF EXISTS ExamBook762Ch2;

CREATE DATABASE ExamBook762Ch2

USE ExamBook762Ch2;


CREATE SCHEMA Examples;
GO

CREATE TABLE Examples.Widget
(
    WidgetId    int CONSTRAINT PKWidget PRIMARY KEY,
    RowLastModifiedTime datetime2(0) NOT NULL
);
GO

ALTER TABLE Examples.Widget
  ADD CONSTRAINT DFLTWidget_RowLastModifiedTime 
         DEFAULT (SYSDATETIME()) FOR RowLastModifiedTime;
GO

INSERT INTO Examples.Widget(WidgetId)
VALUES (1),(2);
GO

INSERT INTO Examples.Widget(WidgetId, RowLastModifiedTime)
VALUES (3,DEFAULT), (4,DEFAULT);
GO

SELECT *
FROM   Examples.Widget;
GO

UPDATE Examples.Widget
SET RowLastModifiedTime = DEFAULT;
GO

ALTER TABLE Examples.Widget
  ADD EnabledFlag BIT NOT NULL
      CONSTRAINT DFLTWidget_EnabledFlag DEFAULT (1);
GO

CREATE TABLE Examples.AllDefaulted
(
    AllDefaultedId int IDENTITY(1,1) NOT NULL,
    RowCreatedTime datetime2(0) NOT NULL
        CONSTRAINT DFLTAllDefaulted_RowCreatedTime DEFAULT (SYSDATETIME()),
    RowModifiedTime datetime2(0) NOT NULL
        CONSTRAINT DFLTAllDefaulted_RowModifiedTime DEFAULT (SYSDATETIME())
);
GO

INSERT INTO Examples.AllDefaulted
DEFAULT VALUES;
GO

INSERT INTO Examples.AllDefaulted(RowModifiedTime, RowCreatedTime)
DEFAULT VALUES;
GO

INSERT INTO Examples.AllDefaulted(RowCreatedTime)
DEFAULT VALUES;
GO

SELECT *
FROM   Examples.AllDefaulted;
GO

INSERT INTO Examples.AllDefaulted(AllDefaultedId)
DEFAULT VALUES;
GO
/*
Msg 339, Level 16, State 1, Line 76
DEFAULT or NULL are not allowed as explicit identity values.

*/

CREATE TABLE Examples.Gadget
(
    GadgetId    int IDENTITY(1,1) NOT NULL CONSTRAINT PKGadget PRIMARY KEY,
    GadgetCode  varchar(10) NOT NULL
);
GO
------Using UNIQUE constraints to enforce secondary uniqueness criteria

INSERT INTO Examples.Gadget(GadgetCode)
VALUES ('Gadget'), ('Gadget'), ('Gadget');
GO

DELETE FROM Examples.Gadget WHERE GadgetId in (2,3);
GO

ALTER TABLE Examples.Gadget 
   ADD CONSTRAINT AKGadget UNIQUE (GadgetCode);
GO


-----Using CHECK constraints to limit data input

-------Limiting data more than a datatype 
CREATE TABLE Examples.GroceryItem
(
   ItemCost smallmoney NULL,
   CONSTRAINT CHKGroceryItem_ItemCostRange 
       CHECK (ItemCost > 0 AND ItemCost < 1000)
);
GO

INSERT INTO Examples.GroceryItem
VALUES (3000.95);
GO

INSERT INTO Examples.GroceryItem
VALUES (100.95);
GO

INSERT INTO Examples.GroceryItem
VALUES (NULL);
GO

--------Enforcing a format for data in a column 

CREATE TABLE Examples.Message
(
    MessageTag  char(5) NOT NULL,
    Comment nvarchar(max) NULL
);
GO

ALTER TABLE Examples.Message
   ADD CONSTRAINT CHKMessage_MessageTagFormat
      CHECK (MessageTag LIKE '[A-Z]-[0-9][0-9][0-9]');
GO

ALTER TABLE Examples.Message
   ADD CONSTRAINT CHKMessage_CommentNotEmpty
       CHECK (LEN(Comment) > 0);
GO

INSERT INTO Examples.Message(MessageTag, Comment)
VALUES ('Bad',''); 
GO

--------Coordinate multiple values together 
CREATE TABLE Examples.Customer
(
    ForcedDisabledFlag bit NOT NULL,
    ForcedEnabledFlag bit NOT NULL,
    CONSTRAINT CHKCustomer_ForcedStatusFlagCheck
      CHECK (NOT (ForcedDisabledFlag = 1 AND ForcedEnabledFlag = 1))
);
GO

INSERT INTO Examples.Customer (ForcedDisabledFlag,
                               ForcedEnabledFlag)
VALUES (0, -- ForcedDisabledFlag - bit
        0 -- ForcedEnabledFlag - bit
    )

INSERT INTO Examples.Customer (ForcedDisabledFlag,
                               ForcedEnabledFlag)
VALUES (1, -- ForcedDisabledFlag - bit
        0 -- ForcedEnabledFlag - bit
    )

INSERT INTO Examples.Customer (ForcedDisabledFlag,
                               ForcedEnabledFlag)
VALUES (1, -- ForcedDisabledFlag - bit
        1 -- ForcedEnabledFlag - bit
    )
/*
The INSERT statement conflicted with the CHECK constraint "CHKCustomer_ForcedStatusFlagCheck". The conflict occurred in database "ExamBook762Ch2", table "Examples.Customer".
*/

------Using FOREIGN KEY constraints to enforce relationships

--------Creating a simple FOREIGN KEY constraint on a table with data in it

DROP TABLE IF EXISTS Examples.Child;
DROP TABLE IF EXISTS Examples.Parent;

CREATE TABLE Examples.Parent
(
    ParentId   int NOT NULL CONSTRAINT PKParent PRIMARY KEY
);
CREATE TABLE Examples.Child
(
    ChildId int NOT NULL CONSTRAINT PKChild PRIMARY KEY,
    ParentId int NULL
);
GO

ALTER TABLE Examples.Child
     ADD CONSTRAINT FKChild_Ref_ExamplesParent
       FOREIGN KEY (ParentId) REFERENCES Examples.Parent(ParentId);
GO

INSERT INTO Examples.Parent(ParentId)
VALUES (1),(2),(3);
GO

INSERT INTO Examples.Child (ChildId, ParentId)
VALUES (1,1);
GO

INSERT INTO Examples.Child (ChildId, ParentId)
VALUES (2,100);
GO

INSERT INTO Examples.Child (ChildId, ParentId)
VALUES (3,NULL);
GO

CREATE TABLE Examples.TwoPartKey
(
    KeyColumn1  int NOT NULL,
    KeyColumn2  int NOT NULL,
    CONSTRAINT PKTwoPartKey PRIMARY KEY (KeyColumn1, KeyColumn2)
);
GO

INSERT INTO Examples.TwoPartKey (KeyColumn1, KeyColumn2)
VALUES (1, 1);
GO

SELECT * FROM Examples.TwoPartKey AS TPK

CREATE TABLE Examples.TwoPartKeyReference
(
    KeyColumn1 int NULL,
    KeyColumn2 int NULL,
    CONSTRAINT FKTwoPartKeyReference_Ref_ExamplesTwoPartKey
        FOREIGN KEY (KeyColumn1, KeyColumn2)
            REFERENCES Examples.TwoPartKey (KeyColumn1, KeyColumn2)
);
GO

INSERT INTO Examples.TwoPartKeyReference (KeyColumn1, KeyColumn2)
VALUES (1, 1), (NULL, NULL);
GO

INSERT INTO Examples.TwoPartKeyReference (KeyColumn1, KeyColumn2)
VALUES (2, 2);
GO

INSERT INTO Examples.TwoPartKeyReference (KeyColumn1, KeyColumn2)
VALUES (6000000, NULL);
GO

SELECT * FROM Examples.TwoPartKeyReference AS TPKR

ALTER TABLE Alt.TwoPartKeyReference
      ADD CONSTRAINT CHKTwoPartKeyReference_FKNULLs
           CHECK ((KeyColumn1 IS NULL and KeyColumn2 IS NULL)
                   OR
                   (KeyColumn1 IS NOT NULL and KeyColumn2 IS NOT NULL));
GO

--------Cascading Operations

CREATE TABLE Examples.Invoice
(
    InvoiceId   int NOT NULL CONSTRAINT PKInvoice PRIMARY KEY
);
GO

CREATE TABLE Examples.InvoiceLineItem
(
    InvoiceLineItemId int NOT NULL CONSTRAINT PKInvoiceLineItem PRIMARY KEY,  
    InvoiceLineNumber smallint NOT NULL,
    InvoiceId     int NOT NULL
       CONSTRAINT FKInvoiceLineItem_Ref_ExamplesInvoice
          REFERENCES Examples.Invoice(InvoiceId)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT AKInvoiceLineItem UNIQUE (InvoiceId, InvoiceLineNumber)
);
GO

INSERT INTO Examples.Invoice(InvoiceId)
VALUES (1),(2),(3);
GO

INSERT INTO Examples.InvoiceLineItem(InvoiceLineItemId, InvoiceId,InvoiceLineNumber)
VALUES (1,1,1),(2,1,2), (3,2,1);
GO

SELECT Invoice.InvoiceId, InvoiceLineItem.InvoiceLineItemId
FROM   Examples.Invoice     
          FULL OUTER JOIN Examples.InvoiceLineItem 
            ON Invoice.InvoiceId = InvoiceLineItem.InvoiceId;
GO


DELETE Examples.Invoice
WHERE  InvoiceId = 1;
GO


CREATE TABLE Examples.Code 
(
    Code    varchar(10) NOT NULL CONSTRAINT PKCode PRIMARY KEY
);
GO

CREATE TABLE Examples.CodedItem
(
    Code    varchar(10) NOT NULL
         CONSTRAINT FKCodedItem_Ref_ExampleCode 
            REFERENCES Examples.Code (Code)
                ON UPDATE CASCADE
);
INSERT INTO Examples.Code (Code)
VALUES ('Blacke'); 
GO

INSERT INTO Examples.CodedItem (Code)
VALUES ('Blacke'); 
GO

SELECT Code.Code, CodedItem.Code AS CodedItemCode
FROM   Examples.Code
          FULL OUTER JOIN Examples.CodedItem
               ON Code.Code = CodedItem.Code;
GO

UPDATE Examples.Code
SET   Code = 'Black';
GO

--------Relating a table to itself to form a hierarchy

CREATE TABLE Examples.Employee (
    EmployeeId INT NOT NULL
        CONSTRAINT PKEmployee PRIMARY KEY,
    EmployeeNumber CHAR(8) NOT NULL,
    ManagerId INT NULL
        CONSTRAINT FKEmployee_Ref_ExamplesEmployee
        REFERENCES Examples.Employee (EmployeeId));
GO

INSERT INTO Examples.Employee(EmployeeId, EmployeeNumber, ManagerId)
VALUES (1,'00000001',NULL), (2,'10000001',1),(3,'10000002',1), (4,'20000001',3);
GO

SELECT *
FROM   Examples.Employee;
GO

SELECT * FROM Examples.Employee AS E

WITH EmployeeHierarchy
  AS (SELECT Employee.EmployeeId,
             CAST(CONCAT('\', Employee.EmployeeId, '\') AS VARCHAR(1500)) AS Hierarchy
        FROM Examples.Employee
       WHERE Employee.ManagerId IS NULL
      UNION ALL
      SELECT Employee.EmployeeId,
             CAST(CONCAT(EmployeeHierarchy.Hierarchy, Employee.EmployeeId, '\') AS VARCHAR(1500)) AS Hierarchy
        FROM Examples.Employee
       INNER JOIN EmployeeHierarchy
          ON Employee.ManagerId = EmployeeHierarchy.EmployeeId)
SELECT *
  FROM EmployeeHierarchy;
GO

--------FOREIGN KEY constraints relating to a UNIQUE constraint instead of a PRIMARY KEY constraint
CREATE TABLE Examples.Color
(
      ColorId   int NOT NULL CONSTRAINT PKColor PRIMARY KEY,
      ColorName varchar(30) NOT NULL CONSTRAINT AKColor UNIQUE
);
INSERT INTO Examples.Color(ColorId, ColorName)
VALUES (1,'Orange'),(2,'White');
GO

CREATE TABLE Examples.Product
(
    ProductId int NOT NULL CONSTRAINT PKProduct PRIMARY KEY,
    ColorName varchar(30) NOT NULL 
         CONSTRAINT FKProduct_Ref_ExamplesColor
                REFERENCES Examples.Color (ColorName)
);
GO

INSERT INTO Examples.Product(ProductId,ColorName)
VALUES (1,'Orange');
GO

INSERT INTO Examples.Product(ProductId,ColorName)
VALUES (2,'Crimson');
GO

------Limiting a column to a set of values

CREATE TABLE Examples.Attendee
(
      ShirtSize  varchar(8) NULL
);
GO

ALTER TABLE Examples. Attendee 
    ADD  CONSTRAINT CHKAttendee_ShirtSizeDomain 
        CHECK  (ShirtSize in ('S', 'M','L','XL','XXL'));
GO

INSERT INTO Examples.Attendee(ShirtSize)
VALUES ('LX');
GO

CREATE TABLE Examples.ShirtSize
(
     ShirtSize varchar(10) NOT NULL CONSTRAINT PKShirtSize PRIMARY KEY
);
INSERT INTO Examples.ShirtSize(ShirtSize)
VALUES ('S'),('M'),('L'),('XL'),('XXL');
GO

ALTER TABLE Examples.Attendee
    DROP CONSTRAINT CHKAttendee_ShirtSizeDomain;
GO

ALTER TABLE Examples.Attendee
    ADD CONSTRAINT FKAttendee_Ref_ExamplesShirtSize
        FOREIGN KEY (ShirtSize) REFERENCES Examples.ShirtSize(ShirtSize);
GO

INSERT INTO Examples.Attendee(ShirtSize)
VALUES ('LX');
GO

----Write Transact-SQL statements to add constraints to tables
CREATE TABLE Examples.CreateTableExample
(
    --Uniqueness constraint referencing single column
    SingleColumnKey int NOT NULL CONSTRAINT PKCreateTableExample PRIMARY KEY,

    --Uniqueness constraint in separate line
    TwoColumnKey1 int NOT NULL,
    TwoColumnKey2 int NOT NULL,
    CONSTRAINT AKCreateTableExample UNIQUE (TwoColumnKey1, TwoColumnKey2),

    --CHECK constraint declare as column constraint
    PositiveInteger int NOT NULL 
         CONSTRAINT CHKCreateTableExample_PostiveInteger CHECK (PositiveInteger > 0),
    --CHECK constraint that could reference multiple columns
    NegativeInteger int NOT NULL,
    CONSTRAINT CHKCreateTableExample_NegativeInteger CHECK (NegativeInteger > 0),
    --FOREIGN KEY constraint inline with column
    FKColumn1 int NULL CONSTRAINT FKColumn1_ref_Table REFERENCES Tbl (TblId),
    --FOREIGN KEY constraint… Could reference more than one columns
    FKColumn2 int NULL,
    CONSTRAINT FKColumn2_ref_Table FOREIGN KEY (FKColumn2) REFERENCES Tbl (TblId)
);
GO

ALTER TABLE Examples.CreateTableExample
    DROP PKCreateTableExample;
GO

ALTER TABLE Examples.CreateTableExample
    ADD CONSTRAINT PKCreateTableExample PRIMARY KEY (SingleColumnKey);
GO

CREATE TABLE Examples.BadData
(
        PositiveValue int NOT NULL
);
GO

INSERT INTO Examples.BadData(PositiveValue)
VALUES (-1),(-2),(-3),(-4);
GO

ALTER TABLE Examples.BadData
   ADD CONSTRAINT CHKBadData_PostiveValue CHECK(PositiveValue > 0);
GO

ALTER TABLE Examples.BadData WITH NOCHECK
   ADD CONSTRAINT CHKBadData_PostiveValue CHECK(PositiveValue > 0);
GO

UPDATE Examples.BadData
SET    PositiveValue = PositiveValue;
GO

DELETE FROM Examples.BadData
WHERE  PositiveValue <= 0;
GO

SELECT is_not_trusted, is_disabled
FROM   sys.check_constraints --for a FOREIGN KEY, use sys.foreign_keys
WHERE  OBJECT_SCHEMA_NAME(object_id) = 'Examples'
  and  OBJECT_NAME(object_id) = 'CHKBadData_PostiveValue';
GO

ALTER TABLE Examples.BadData
	NOCHECK CONSTRAINT CHKBadData_PostiveValue;
GO

ALTER TABLE Sales.Invoices 
    ADD CONSTRAINT CHKInvoices_OrderIdBetween0and1000000  
        CHECK (OrderId BETWEEN 0 AND 1000000);
GO

SELECT *
FROM   Sales.Invoices
WHERE  OrderID = -100;
GO

SELECT *
FROM   Sales.Invoices
WHERE  OrderID = 100;
GO

USE ExamBook762Ch2;
GO

----Identify results of Data Manipulation Language (DML) statements given existing tables and constraints
CREATE TABLE Examples.ScenarioTestType
(
    ScenarioTestType varchar(10) NOT NULL CONSTRAINT PKScenarioTestType PRIMARY KEY
);
GO


CREATE TABLE Examples.ScenarioTest
(
    ScenarioTestId int NOT NULL PRIMARY KEY,
    ScenarioTestType varchar(10) NULL CONSTRAINT CHKScenarioTest_ScenarioTestType CHECK (ScenarioTestType IN ('Type1','Type2'))
);
GO

ALTER TABLE Examples.ScenarioTest
   ADD CONSTRAINT FKScenarioTest_Ref_ExamplesScenarioTestType
       FOREIGN KEY (ScenarioTestType) REFERENCES Examples.ScenarioTestType;
GO

--TRUNCATE TABLE Examples.ScenarioTest


INSERT INTO Examples.ScenarioTest(ScenarioTestId, ScenarioTestType)
VALUES (1,'Type1');


INSERT INTO Examples.ScenarioTestType(ScenarioTestType)
VALUES ('Type1');

INSERT INTO Examples.ScenarioTest(ScenarioTestId, ScenarioTestType)
VALUES (1,'Type1');


INSERT INTO Examples.ScenarioTest(ScenarioTestId, ScenarioTestType)
VALUES (1,'Type2');

INSERT INTO Examples.ScenarioTest (ScenarioTestId,
                                   ScenarioTestType)
VALUES (2, 'Type1');

INSERT INTO Examples.ScenarioTests (ScenarioTestId,
                                    ScenarioTestType)
VALUES (3, 'Type1');

----Identify proper usage of PRIMARY KEY constraints

CREATE SCHEMA Examples;
GO

CREATE TABLE Examples.Company
(
    CompanyName   nvarchar(50) NOT NULL CONSTRAINT PKCompany PRIMARY KEY,
    CompanyURL nvarchar(max) NOT NULL
);
INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Blue Yonder Airlines','http://www.blueyonderairlines.com/'),
       ('Tailspin Toys','http://www.tailspintoys.com/');
GO

SELECT *
FROM   Examples.Company;
GO

DROP TABLE IF EXISTS Examples.Company;
CREATE TABLE Examples.Company
(
    CompanyId     int NOT NULL IDENTITY(1,1) CONSTRAINT PKCompany PRIMARY KEY,
    CompanyName   nvarchar(50) NOT NULL CONSTRAINT AKCompany UNIQUE,
    CompanyURL nvarchar(max) NOT NULL
);
GO

INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Blue Yonder Airlines','http://www.blueyonderairlines.com/'),
       ('Tailspin Toys','http://www.tailspintoys.com/');
GO

INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Blue Yonder Airlines','http://www.blueyonderairlines.com/');
GO

INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Northwind Traders','http://www.northwindtraders.com/');
GO

SELECT *
FROM   Examples.Company;
GO

DROP TABLE IF EXISTS Examples.Company;
DROP SEQUENCE IF EXISTS Examples.Company_SEQUENCE;

CREATE SEQUENCE Examples.Company_SEQUENCE AS INT START WITH 1;
CREATE TABLE Examples.Company
(
    CompanyId     int NOT NULL CONSTRAINT PKCompany PRIMARY KEY
                               CONSTRAINT DFLTCompany_CompanyId DEFAULT
                                          (NEXT VALUE FOR Examples.Company_SEQUENCE),
    CompanyName   nvarchar(50) NOT NULL CONSTRAINT AKCompany UNIQUE,
    CompanyURL nvarchar(max) NOT NULL
);
INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Blue Yonder Airlines','http://www.blueyonderairlines.com/'),
       ('Tailspin Toys','http://www.tailspintoys.com/');
GO


DECLARE @CompanyId INT = NEXT VALUE FOR Examples.Company_SEQUENCE;

INSERT INTO Examples.Company(CompanyId, CompanyName, CompanyURL)
VALUES (@CompanyId, 'Northwind Traders','http://www.northwindtraders.com/');
GO

DROP TABLE IF EXISTS Examples.Company;
CREATE TABLE Examples.Company
(
    CompanyId     uniqueidentifier NOT NULL CONSTRAINT PKCompany PRIMARY KEY
                               CONSTRAINT DFLTCompany_CompanyId DEFAULT (NEWID()),
    CompanyName   nvarchar(50) NOT NULL CONSTRAINT AKCompany UNIQUE,
    CompanyURL nvarchar(max) NOT NULL
);
GO


CREATE TABLE Examples.DriversLicense
(
        Locality char(10) NOT NULL,
        LicenseNumber varchar(40) NOT NULL,
        CONSTRAINT PKDriversLicense PRIMARY KEY (Locality, LicenseNumber)
);
CREATE TABLE Examples.EmployeeDriverLicense
(
        EmployeeNumber char(10) NOT NULL, --Ref to Employee table
        Locality char(10) NOT NULL, --Ref to DriversLicense table
        LicenseNumber varchar(40) NOT NULL, --Ref to DriversLicense table
        CONSTRAINT PKEmployeeDriversLicense PRIMARY KEY 
                  (EmployeeNumber, Locality, LicenseNumber)
);
GO

CREATE TABLE Examples.DriversLicense
(
        DriversLicenseId int CONSTRAINT PKDriversLicense PRIMARY KEY, 
        Locality char(10) NOT NULL,
        LicenseNumber varchar(40) NOT NULL,
        CONSTRAINT AKDriversLicense UNIQUE (Locality, LicenseNumber)
);
CREATE TABLE Examples.EmployeeDriverLicense
(
        EmployeeDriverLicenseId int NOT NULL 
                 CONSTRAINT PKEmployeeDriverLicense PRIMARY KEY,
        EmployeeId int NOT NULL, --Ref to Employee table
        DriversLicenseId int NOT NULL, --Ref to DriversLicense table
        CONSTRAINT AKEmployeeDriverLicense UNIQUE (EmployeeId, DriversLicenseId)
);
GO

--Skill 2.2 Create stored procedures

----Design stored procedure components and structure based on business requirements

CREATE TABLE Examples.SimpleTable
(
    SimpleTableId int NOT NULL IDENTITY(1,1)
              CONSTRAINT PKSimpleTable PRIMARY KEY,
    Value1   varchar(20) NOT NULL,
    Value2   varchar(20) NOT NULL
);
GO

CREATE PROCEDURE Examples.SimpleTable_Insert
    @SimpleTableId int,
    @Value1  varchar(20),
    @Value2  varchar(20)
AS
    INSERT INTO Examples.SimpleTable(Value1, Value2)
    VALUES (@Value1, @Value2);
GO

CREATE PROCEDURE Examples.SimpleTable_Update
    @SimpleTableId int,
    @Value1  varchar(20),
    @Value2  varchar(20)
AS
    UPDATE Examples.SimpleTable
    SET Value1 = @Value1,
        Value2 = @Value2
    WHERE SimpleTableId = @SimpleTableId;
GO
CREATE PROCEDURE Examples.SimpleTable_Delete
    @SimpleTableId int,
    @Value  varchar(20)
AS
    DELETE Examples.SimpleTable
    WHERE SimpleTableId = @SimpleTableId
GO


CREATE PROCEDURE Examples.SimpleTable_Select
AS
   SELECT SimpleTableId, Value1, Value2
   FROM Examples.SimpleTable
   ORDER BY Value1;
GO


CREATE PROCEDURE Examples.SimpleTable_SelectValue1StartWithQorZ
AS
   SELECT SimpleTableId, Value1, Value2
   FROM Examples.SimpleTable
   WHERE Value1 LIKE 'Q%'
   ORDER BY Value1;

   SELECT SimpleTableId, Value1, Value2
   FROM Examples.SimpleTable
   WHERE Value1 LIKE 'Z%'
   ORDER BY Value1 DESC;
GO


DROP PROCEDURE Examples.SimpleTable_SelectValue1StartWithQorZ


CREATE PROCEDURE Examples.SimpleTable_SelectValue1StartWithQorZ
AS
  IF DATENAME(weekday,getdate()) NOT IN ('Saturday','Sunday')
     SELECT SimpleTableId, Value1, Value2
     FROM Examples.SimpleTable
     WHERE  Value1 LIKE '[QZ]%';
GO

CREATE PROCEDURE Examples.ProcedureName
AS
SELECT ColumnName From Bogus.TableName;
GO


DROP PROCEDURE Examples.SimpleTable_Select;

CREATE PROCEDURE Examples.SimpleTable_Select
AS
   SET NOCOUNT ON;
   SELECT SimpleTableId, Value1, Value2
   FROM Examples.SimpleTable
   ORDER BY Value1;
GO

----Implement input and output parameters

CREATE TABLE Examples.Parameter
(
    ParameterId int NOT NULL IDENTITY(1,1) CONSTRAINT PKParameter PRIMARY KEY,
    Value1   varchar(20) NOT NULL,
    Value2  varchar(20) NOT NULL,
)
GO

CREATE PROCEDURE Examples.Parameter_Insert
    @Value1 varchar(20) = 'No entry given',
    @Value2 varchar(20) = 'No entry given'
AS
    SET NOCOUNT ON;
    INSERT INTO Examples.Parameter(Value1,Value2)
    VALUES (@Value1, @Value2);
GO

--using all defaults
EXECUTE Examples.Parameter_Insert;

--by position, @Value1 parameter only
EXECUTE Examples.Parameter_Insert 'Some Entry';
--both columns by position
EXECUTE Examples.Parameter_Insert 'More Entry','More Entry';

-- using the name of the parameter (could also include @Value2);
EXECUTE Examples.Parameter_Insert @Value1 = 'Other Entry';

--starting positionally, but finishing by name
EXECUTE Examples.Parameter_Insert 'Mixed Entry', @Value2 = 'Mixed Entry';
GO

EXECUTE Examples.Parameter_Insert @Value1 = 'Remixed Entry', 'Remixed Entry';
GO

/*
Msg 119, Level 15, State 1, Line 808
Must pass parameter number 2 and subsequent parameters as '@name = value'. After the form '@name = value' has been used, all subsequent parameters must be passed in the form '@name = value'.

*/


-- ==================================================================
--Observação: fazendo insert na procedure e retonrando o Id Inserido
-- ==================================================================
ALTER PROCEDURE Examples.Parameter_Insert
    @Value1 varchar(20) = 'No entry given',
    @Value2 varchar(20) = 'No entry given' OUTPUT,
    @NewParameterId int = NULL OUTPUT
AS
    SET NOCOUNT ON;
    SET @Value1 = UPPER(@Value1);
    SET @Value2 = LOWER(@Value2);

    INSERT INTO Examples.Parameter(Value1,Value2)
    VALUES (@Value1, @Value2);

    SET @NewParameterId = SCOPE_IDENTITY();
GO


DECLARE @Value1 varchar(20) = 'Test',
        @Value2 varchar(20) = 'Test',
        @NewParameterId int = -200;

EXECUTE Examples.Parameter_Insert @Value1 = @Value1,
                                  @Value2 = @Value2 OUTPUT,
                                  @NewParameterId = @NewParameterId OUTPUT;

SELECT @Value1 as Value1, @Value2 as Value2, @NewParameterId as NewParameterId;

SELECT *
FROM Examples.Parameter
WHERE ParameterId = @NewParameterId;
GO

----Implement table-valued parameters
CREATE TABLE Examples.Machine
(
    MachineId   int NOT NULL CONSTRAINT PKMachine PRIMARY KEY,
    MachineNumber char(3) NOT NULL CONSTRAINT AKMachine UNIQUE,
    Description varchar(50) NOT NULL
);
INSERT INTO Examples.Machine(MachineId, MachineNumber, Description)
VALUES (1,'001','Thing1'),(2,'002','Thing2'),(3,'003','Thing3');
GO

CREATE PROCEDURE Examples.Machine_MultiSelect
    @MachineList varchar(200)
AS
    SET NOCOUNT ON;
    SELECT Machine.MachineId, Machine.MachineNumber
    FROM   Examples.Machine
            JOIN STRING_SPLIT(@MachineList,',') AS StringList
                ON StringList.value = Machine.MachineId;
GO

CREATE TYPE Examples.SurrogateKeyList AS table
(
    SurrogateKeyId int PRIMARY KEY --note you cannot name constraints for table types
);
GO

ALTER PROCEDURE Examples.Machine_MultiSelect
    @MachineList Examples.SurrogateKeyList READONLY
AS
    SET NOCOUNT ON;
    SELECT Machine.MachineId, Machine.MachineNumber
    FROM   Examples.Machine
            JOIN @MachineList AS MachineList
                ON MachineList.SurrogateKeyId = Machine.MachineId;
GO

DECLARE @MachineList Examples.SurrogateKeyList;
INSERT INTO @MachineList (SurrogateKeyId)
VALUES (1),(3);
EXECUTE Examples.Machine_MultiSelect @MachineList = @MachineList;
GO

CREATE TYPE Examples.Machine AS TABLE
(
    MachineId int NOT NULL PRIMARY KEY,
    MachineNumber char(3) NOT NULL UNIQUE,
    Description varchar(50) NOT NULL
);
GO
CREATE PROCEDURE Examples.Machine_MultiInsert
    @MachineList Examples.Machine READONLY
AS
    SET NOCOUNT ON;
    INSERT INTO Examples.Machine(MachineId, MachineNumber, Description)
    SELECT MachineId, MachineNumber, Description
    FROM   @MachineList;
GO

DECLARE @NewMachineRows Examples.Machine;
INSERT INTO @NewMachineRows (MachineId, MachineNumber, Description)
VALUES (4,'004','NewThing4'), (5, '005','NewThing5');

EXECUTE Examples.Machine_MultiInsert @MachineList = @NewMachineRows;
GO

----Implement return codes

CREATE PROCEDURE SimpleReturnValue
AS
    DECLARE @NoOp int;
GO

DECLARE @ReturnCode int;
EXECUTE @ReturnCode = SimpleReturnValue;
SELECT @ReturnCode as ReturnCode;
GO

CREATE PROCEDURE DoOperation
(
    @Value  int
) 
--Procedure returns via return code:
-- 1 - successful execution, with 0 entered
-- 0 - successful execution
-- -1 - invalid, NULL input
AS
    IF @Value = 0
        RETURN 1;
    ELSE IF @Value IS NULL 
        RETURN -1;
    ElSE RETURN 0;
GO

DECLARE @ReturnCode int;
EXECUTE @ReturnCode = DoOperation @Value = NULL;
SELECT  @ReturnCode, 
        CASE @ReturnCode WHEN 1 THEN 'Success, 0 Entered' 
                         WHEN -1 THEN 'Invalid Input'
                         WHEN 0 THEN 'Success' 
        END as ReturnMeaning;
GO

----Streamline existing stored procedure logic
CREATE TABLE Examples.Player
(
    PlayerId    int NOT NULL CONSTRAINT PKPlayer PRIMARY KEY,
    TeamId      int NOT NULL, --not implemented reference to Team Table
    PlayerNumber char(2) NOT NULL,
    CONSTRAINT AKPlayer UNIQUE (TeamId, PlayerNumber)
)
INSERT INTO Examples.Player(PlayerId, TeamId, PlayerNumber)
VALUES (1,1,'18'),(2,1,'45'),(3,1,'40');
GO

CREATE PROCEDURE Examples.Player_GetByPlayerNumber (@PlayerNumber CHAR(2))
AS
SET NOCOUNT ON;
DECLARE @PlayerList TABLE (PlayerId INT NOT NULL);

DECLARE @Cursor            CURSOR,
        @Loop_PlayerId     INT,
        @Loop_PlayerNumber CHAR(2)

SET @Cursor = CURSOR FAST_FORWARD FOR(
SELECT Player.PlayerId,
       Player.PlayerNumber
  FROM Examples.Player);

OPEN @Cursor;
WHILE (1 = 1)
BEGIN
    FETCH NEXT FROM @Cursor
     INTO @Loop_PlayerId,
          @Loop_PlayerNumber
    IF @@FETCH_STATUS <> 0
        BREAK;

    IF @PlayerNumber = @Loop_PlayerNumber
        INSERT INTO @PlayerList (PlayerId)
        VALUES (@Loop_PlayerId);
END


EXECUTE  Examples.Player_GetByPlayerNumber @PlayerNumber = '18';  
GO
      

ALTER PROCEDURE Examples.Player_GetByPlayerNumber
(
    @PlayerNumber char(2)
) AS
    SET NOCOUNT ON
    SELECT Player.PlayerId, Player.TeamId
    FROM   Examples.Player
    WHERE  PlayerNumber = @PlayerNumber;
GO

EXECUTE  Examples.Player_GetByPlayerNumber @PlayerNumber = '18';      
GO
  
----Implement error handling and transaction control logic within stored procedures

-------Throwing an error
THROW 50000, 'This is an error message',1;
GO

RAISERROR ('This is an error message',16,1);
GO

THROW 50000, 'This is an error message',1;
SELECT 'Batch continued'
GO

RAISERROR ('This is an error message',16,1);
GO

SELECT 'Batch continued'
GO
ALTER PROCEDURE DoOperation (@Value INT)
AS
SET NOCOUNT ON;
IF @Value = 0
    RETURN 1;
ELSE IF @Value IS NULL
BEGIN
    THROW 50000, 'The @value parameter should not be NULL', 1;
    SELECT 'Continued to here';
    RETURN -1;
END
ELSE
    RETURN 0;
GO

DECLARE @ReturnCode int
EXECUTE @ReturnCode = DoOperation @Value = NULL;
SELECT  @ReturnCode AS ReturnCode;
GO

------Handling an error
CREATE TABLE Examples.ErrorTesting
(
    ErrorTestingId int NOT NULL CONSTRAINT PKErrorTesting PRIMARY KEY,
    PositiveInteger int NOT NULL 
         CONSTRAINT CHKErrorTesting_PositiveInteger CHECK (PositiveInteger > 0)
);
GO

INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
VALUES (1,1); --Succeed
INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
VALUES (1,1); --Fail PRIMARY KEY violation
INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
VALUES (2,-1); --Fail CHECK constraint violation
INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
VALUES (2,2); --Succeed
SELECT *
FROM   Examples.ErrorTesting;

-- ==================================================================
--Observação: Usando  @@ERROR para controlar as alterações nas tabelas
-- ==================================================================


------Using @@ERROR to deal with errors
CREATE PROCEDURE Examples.ErrorTesting_InsertTwo
AS
    SET NOCOUNT ON;
    INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
    VALUES (3,3); --Succeeds

    IF @@ERROR <> 0
       BEGIN
            THROW 50000, 'First statement failed', 1;
            RETURN -1;
       END;

    INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
    VALUES (4,-1); --Fail Constraint

    IF @@ERROR <> 0
       BEGIN
            THROW 50000, 'Second statement failed', 1;
            RETURN -1;
       END;
    INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
    VALUES (5,1); --Will succeed if statement executes
    IF @@ERROR <> 0
       BEGIN
            THROW 50000, 'Third statement failed', 1;
            RETURN -1;
       END;

GO

EXECUTE Examples.ErrorTesting_InsertTwo;
GO

------Using TRY…CATCH
ALTER PROCEDURE Examples.ErrorTesting_InsertTwo
AS
SET NOCOUNT ON;
DECLARE @Location NVARCHAR(30);

BEGIN TRY
    SET @Location = 'First statement';
    INSERT INTO Examples.ErrorTesting (ErrorTestingId,
                                       PositiveInteger)
    VALUES (6, 3); --Succeeds

    SET @Location = 'Second statement';
    INSERT INTO Examples.ErrorTesting (ErrorTestingId,
                                       PositiveInteger)
    VALUES (7, -1); --Fail Constraint

    SET @Location = 'First statement';
    INSERT INTO Examples.ErrorTesting (ErrorTestingId,
                                       PositiveInteger)
    VALUES (8, 1); --Will succeed if statement executes
END TRY
BEGIN CATCH
    SELECT ERROR_PROCEDURE() AS ErrorProcedure,
           @Location AS ErrorLocation
    SELECT ERROR_MESSAGE() AS ErrorMessage;
    SELECT ERROR_NUMBER() AS ErrorNumber,
           ERROR_SEVERITY() AS ErrorSeverity,
           ERROR_LINE() AS ErrorLine;
END CATCH
			  


EXECUTE Examples.ErrorTesting_InsertTwo;
GO

------Transaction Control Logic in Your Error Handling

-- ==================================================================
--Observação: Exemplo 1)
-- ==================================================================
BEGIN TRANSACTION;
BEGIN TRANSACTION;
GO
SELECT @@TRANCOUNT
GO
ROLLBACK
GO

-- ==================================================================
--Observação: Exemplo 2)
-- ==================================================================
BEGIN TRANSACTION T1;
BEGIN TRANSACTION t2;
GO
SELECT @@TRANCOUNT
GO
ROLLBACK TRAN t2
/*
Msg 6401, Level 16, State 1, Line 1162
Cannot roll back t2. No transaction or savepoint of that name was found.
*/
SELECT @@TRANCOUNT
GO


-- ==================================================================
--Observação: Exemplo 3)
-- ==================================================================
BEGIN TRANSACTION T1;
BEGIN TRANSACTION t2;
GO
SELECT @@TRANCOUNT
GO
SAVE TRAN t1;
ROLLBACK TRAN t2
/*
Msg 6401, Level 16, State 1, Line 1185
Cannot roll back t2. No transaction or savepoint of that name was found.
*/
SELECT @@TRANCOUNT
GO


-- ==================================================================
--Observação: Exemplo 4) aqui sim funciona vc precisa fazer o save na transação especifica 
-- e se precisar fazer o rollback desta transação
-- ==================================================================
BEGIN TRANSACTION T1;
BEGIN TRANSACTION t2;
GO
SELECT @@TRANCOUNT
GO
SAVE TRAN t2;
ROLLBACK TRAN t2

SELECT @@TRANCOUNT
GO





BEGIN TRANSACTION;
GO
INSERT INTO Examples.ErrorTesting(ErrorTestingId, PositiveInteger)
VALUES (9,1); 
GO
BEGIN TRANSACTION;
SELECT * FROM Examples.ErrorTesting WHERE ErrorTestingId = 9;
ROLLBACK TRANSACTION;

SELECT * FROM Examples.ErrorTesting WHERE ErrorTestingId = 9;
GO

CREATE TABLE Examples.Worker
(
    WorkerId int NOT NULL IDENTITY(1,1) CONSTRAINT PKWorker PRIMARY KEY,
    WorkerName nvarchar(50) NOT NULL CONSTRAINT AKWorker UNIQUE
);
CREATE TABLE Examples.WorkerAssignment
(
    WorkerAssignmentId int IDENTITY(1,1) CONSTRAINT PKWorkerAssignment PRIMARY KEY,
    WorkerId int NOT NULL,
    CompanyName nvarchar(50) NOT NULL 
       CONSTRAINT CHKWorkerAssignment_CompanyName 
           CHECK (CompanyName <> 'Contoso, Ltd.'),
    CONSTRAINT AKWorkerAssignment UNIQUE (WorkerId, CompanyName)
);
GO

CREATE PROCEDURE Examples.Worker_AddWithAssignment
    @WorkerName nvarchar(50),
    @CompanyName nvarchar(50)
AS
    SET NOCOUNT ON;
    --do any non-data testing before starting the transaction
    IF @WorkerName IS NULL or @CompanyName IS NULL
        THROW 50000,'Both parameters must be not null',1;

    DECLARE @Location nvarchar(30), @NewWorkerId int;
    BEGIN TRY
        BEGIN TRANSACTION;

        SET @Location = 'Creating Worker Row';
        INSERT INTO Examples.Worker(WorkerName)
        VALUES (@WorkerName);

        SELECT @NewWorkerId = SCOPE_IDENTITY(),
               @Location = 'Creating WorkAssignment Row';

        INSERT INTO Examples.WorkerAssignment(WorkerId, CompanyName)
        VALUES (@NewWorkerId, @CompanyName);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        --at the end of the call, we want the transaction rolled back
        --rollback the transaction first, so it definitely occurs as the THROW
        --statement would keep it from happening. 
        IF XACT_STATE() <> 0 --if there is a transaction in effect
                             --commitable or not   
            ROLLBACK TRANSACTION;

        --format a message that tells the error and then THROW it.
        DECLARE @ErrorMessage nvarchar(4000);
        SET @ErrorMessage = CONCAT('Error occurred during: ''',@Location,'''',
                                   ' System Error: ',
                                   ERROR_NUMBER(),':',ERROR_MESSAGE());
        THROW 50000, @ErrorMessage, 1;
    END CATCH;
GO

EXEC Examples.Worker_AddWithAssignment @WorkerName = NULL, @CompanyName = NULL;
GO


EXEC Examples.Worker_AddWithAssignment 
                         @WorkerName='David So', @CompanyName='Margie''s Travel';
GO

EXEC Examples.Worker_AddWithAssignment 
                         @WorkerName='David So', @CompanyName='Margie''s Travel';
GO

EXEC Examples.Worker_AddWithAssignment 
                         @WorkerName='Ian Palangio', @CompanyName='Contoso, Ltd.';
EXEC Examples.Worker_AddWithAssignment 
                     @WorkerName='Ian Palangio', @CompanyName='Humongous Insurance';
GO


ALTER PROCEDURE Examples.Worker_AddWithAssignment
    @WorkerName nvarchar(50),
    @CompanyName nvarchar(50)
AS
    SET NOCOUNT ON;
    DECLARE @NewWorkerId int;
    --still check the parameter values first
    IF @WorkerName IS NULL or @CompanyName IS NULL
        THROW 50000,'Both parameters must be not null',1;
    --Start a transaction
    BEGIN TRANSACTION
    INSERT INTO Examples.Worker(WorkerName)
    VALUES (@WorkerName);
    --check the value of the @@error system function
    IF @@ERROR <> 0 
      BEGIN 
        --rollback the transaction before the THROW (or RETURN if using), because
        --otherwise the THROW will end the batch and transaction stay open
        ROLLBACK TRANSACTION;
        THROW 50000,'Error occurred inserting data into Examples.Worker table',1;
      END;
    SELECT @NewWorkerId = SCOPE_IDENTITY()

    INSERT INTO Examples.WorkerAssignment(WorkerId, CompanyName)
    VALUES (@NewWorkerId, @CompanyName);
     IF @@ERROR <> 0 
      BEGIN 
        ROLLBACK TRANSACTION;
        THROW 50000,
          'Error occurred inserting data into Examples.WorkerAssignment table',1;
      END;
    --if you get this far in the batch, you can commit the transaction
    COMMIT TRANSACTION;
GO


EXEC Examples.Worker_AddWithAssignment @WorkerName='Seth Grossman', @CompanyName='Margie''s Travel';
GO
--Cause an error due to duplicating all of the data from previous call
EXEC Examples.Worker_AddWithAssignment @WorkerName='Seth Grossman', @CompanyName='Margie''s Travel';
GO

ALTER PROCEDURE Examples.Worker_AddWithAssignment
    @WorkerName nvarchar(50),
    @CompanyName nvarchar(50)
AS
    SET NOCOUNT ON;
    --will cause batch to end on any error
    SET XACT_ABORT ON;

    DECLARE @NewWorkerId int;

    --Same parameter check as other cases
    IF @WorkerName IS NULL or @CompanyName IS NULL
        THROW 50000,'Both parameters must be not null',1;

    --start the transaction
    BEGIN TRANSACTION;
    --  Execute the code as normal
    INSERT INTO Examples.Worker(WorkerName)
    VALUES (@WorkerName);

    SELECT @NewWorkerId = SCOPE_IDENTITY()

    INSERT INTO Examples.WorkerAssignment(WorkerId, CompanyName)
    VALUES (@NewWorkerId, @CompanyName);

    COMMIT TRANSACTION;
GO


EXEC Examples.Worker_AddWithAssignment 
            @WorkerName='Stig Panduro', @CompanyName='Margie''s Travel';
GO
--Cause an error due to duplicating all of the data from previous call
EXEC Examples.Worker_AddWithAssignment 
            @WorkerName='Stig Panduro', @CompanyName='Margie''s Travel';
GO


CREATE PROCEDURE ChangeTransactionLevel
AS
    BEGIN TRANSACTION;
    ROLLBACK TRANSACTION;
GO

BEGIN TRANSACTION;
EXEC ChangeTransactionLevel;
ROLLBACK TRANSACTION;
GO

ALTER PROCEDURE ChangeTransactionLevel
AS
    BEGIN TRANSACTION;
    ROLLBACK TRANSACTION;
    THROW 50000,'Error After Rollback',1;
GO

BEGIN TRANSACTION;
EXEC ChangeTransactionLevel;
ROLLBACK TRANSACTION;
GO

ALTER PROCEDURE dbo.CallChangeTransactionLevel
AS
    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @Location nvarchar(30) = 'Execute Procedure';
        EXECUTE ChangeTransactionLevel; --This will cause an error by design
        
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK; 
        DECLARE @ErrorMessage nvarchar(4000)
        SET @ErrorMessage = CONCAT('Error occurred during: ''',@Location,'''',
                                   ' System Error: ',ERROR_NUMBER(),':',
                                   ERROR_MESSAGE());
        THROW 50000, @ErrorMessage, 1;
    END CATCH;
GO

EXECUTE dbo.CallChangeTransactionLevel;
GO


--Skill 2.3 Create triggers and user-defined functions

----Design trigger logic based on business requirements

------Complex data integrity 

CREATE TABLE Examples.AccountContact 
(
     AccountContactId int NOT NULL CONSTRAINT PKAccountContact PRIMARY KEY, 
     AccountId        char(4) NOT NULL,
     PrimaryContactFlag bit NOT NULL
);
GO

SELECT AccountId, SUM(CASE WHEN PrimaryContactFlag = 1 THEN 1 ELSE 0 END)
FROM   Examples.AccountContact
GROUP BY AccountId
HAVING SUM(CASE WHEN PrimaryContactFlag = 1 THEN 1 ELSE 0 END) <> 1
GO

CREATE TRIGGER Examples.AccountContact_TriggerAfterInsertUpdate
ON Examples.AccountContact
AFTER INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  SET ROWCOUNT 0; --in case the client has modified the rowcount
  BEGIN TRY
  --check to see if data is returned by the query from previously
  IF EXISTS ( SELECT AccountId
              FROM   Examples.AccountContact
                     --correlates the changed rows in inserted to the other rows
                     --for the account, so we can check if the rows have changed
              WHERE  EXISTS (SELECT *
                             FROM   inserted
                             WHERE  inserted.AccountId = 
                                                 AccountContact.AccountId
                             UNION ALL
                             SELECT *
                             FROM   deleted
                             WHERE  deleted.AccountId = 
                                                 AccountContact.AccountId)
              GROUP BY AccountId
              HAVING SUM(CASE WHEN PrimaryContactFlag = 1 then 1 ELSE 0 END) <> 1)
          THROW  50000, 'Account(s) do not have only one primary contact.', 1;
   END TRY
   BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
     END CATCH
END;
GO


SELECT @AccountId = AccountId FROM inserted;
GO

--Success, 1 row
INSERT INTO Examples.AccountContact(AccountContactId, AccountId, PrimaryContactFlag)
VALUES (1,1,1);
--Success, two rows
INSERT INTO Examples.AccountContact(AccountContactId, AccountId, PrimaryContactFlag)
VALUES (2,2,1),(3,3,1);
--Two rows, same account
INSERT INTO Examples.AccountContact(AccountContactId, AccountId, PrimaryContactFlag)
VALUES (4,4,1),(5,4,0);
--Invalid, two accounts with primary
INSERT INTO Examples.AccountContact(AccountContactId, AccountId, PrimaryContactFlag)
VALUES (6,5,1),(7,5,1);
GO

--Invalid, no primary
INSERT INTO Examples.AccountContact(AccountContactId, AccountId, PrimaryContactFlag)
VALUES (8,6,0),(9,6,0);
GO

--Won't work, because AccountId is new, and this row is not primary
UPDATE Examples.AccountContact
SET    AccountId = 6
WHERE  AccountContactId = 5; 
GO

CREATE TRIGGER Examples.AccountContact_TriggerAfterDelete
ON Examples.AccountContact
AFTER DELETE AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   BEGIN TRY
   IF EXISTS ( SELECT AccountId
                FROM   Examples.AccountContact
                WHERE  EXISTS (SELECT *
                               FROM   deleted
                               WHERE  deleted.AccountId = 
                                          AccountContact.AccountId)
             GROUP BY AccountId
             HAVING SUM(CASE WHEN PrimaryContactFlag = 1 then 1 ELSE 0 END) > 1)
       THROW  50000, 'One or more Accounts did not have one primary contact.', 1;
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; 
    END CATCH;
END;
GO

------Running code in response to some action 

CREATE TABLE Examples.Promise
(
    PromiseId int NOT NULL CONSTRAINT PKPromise PRIMARY KEY,
    PromiseAmount money NOT NULL
);
GO

CREATE TABLE Examples.VerifyPromise
(
    VerifyPromiseId int NOT NULL CONSTRAINT PKVerifyPromise PRIMARY KEY,
    PromiseId int NOT NULL CONSTRAINT AKVerifyPromise UNIQUE
                  --FK not included for simplicity
);
GO

CREATE TRIGGER Examples.Promise_TriggerInsertUpdate
ON Examples.Promise
AFTER INSERT, UPDATE AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   BEGIN TRY
       INSERT INTO Examples.VerifyPromise(PromiseId)
       SELECT PromiseId 
       FROM   inserted
       WHERE  PromiseAmount > 10000.00
         AND  NOT EXISTS (SELECT * --keep from inserting duplicates
                          FROM   VerifyPromise
                          WHERE  VerifyPromise.PromiseId = inserted.PromiseId)
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; --will halt the batch or be caught by the caller's catch block
   END CATCH
END;
GO

------Ensuring columnar data is modified

CREATE TABLE Examples.Lamp
(
    LampId       int IDENTITY(1,1) CONSTRAINT PKLamp PRIMARY KEY,
    Value          varchar(10) NOT NULL,
    RowCreatedTime datetime2(0) NOT NULL
        CONSTRAINT DFLTLamp_RowCreatedTime DEFAULT(SYSDATETIME()),
    RowLastModifiedTime datetime2(0) NOT NULL
        CONSTRAINT DFLTLamp_RowLastModifiedTime DEFAULT(SYSDATETIME())
);
GO

CREATE TRIGGER Examples.Lamp_TriggerInsteadOfInsert
ON Examples.Lamp
INSTEAD OF INSERT AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   BEGIN TRY
        --skip columns to automatically set
        INSERT INTO Examples.Lamp( Value)
        SELECT Value
        FROM   inserted
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; --will halt the batch or be caught by the caller's catch block
   END CATCH
END;
GO

INSERT INTO Examples.Lamp(Value, RowCreatedTime, RowLastModifiedTime)
VALUES ('Original','1900-01-01','1900-01-01');
GO

SELECT *
FROM   Examples.Lamp;
GO


CREATE TRIGGER Examples.Lamp_TriggerInsteadOfUpdate
ON Examples.Lamp
INSTEAD OF UPDATE AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   BEGIN TRY
        UPDATE Lamp
        SET    Value = inserted.Value,
               RowLastModifiedTime = DEFAULT --use default constraint
        FROM   Examples.Lamp
                 JOIN inserted
                    ON Lamp.LampId = inserted.LampId;
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; --will halt the batch or be caught by the caller's catch block
   END CATCH;
END;
GO


UPDATE Examples.Lamp
SET    Value = 'Modified',
       RowCreatedTime = '1900-01-01',
       RowLastModifiedTime = '1900-01-01'
WHERE LampId = 1;
GO

SELECT *
FROM   Examples.Lamp;
GO

------Making any view modifiable using INSTEAD OF triggers
CREATE TABLE Examples.KeyTable1
(
    KeyValue int NOT NULL CONSTRAINT PKKeyTable1 PRIMARY KEY,
    Value1   varchar(10) NULL
);
CREATE TABLE Examples.KeyTable2
(
    KeyValue int NOT NULL CONSTRAINT PKKeyTable2 PRIMARY KEY,
    Value2    varchar(10) NULL
);
GO

CREATE VIEW Examples.KeyTable
AS
    SELECT COALESCE(KeyTable1.KeyValue, KeyTable2.KeyValue) as KeyValue,
           KeyTable1.Value1, KeyTable2.Value2
    FROM   Examples.KeyTable1
             FULL OUTER JOIN Examples.KeyTable2
                ON KeyTable1.KeyValue = KeyTable2.KeyValue;
GO

INSERT INTO Examples.KeyTable (KeyValue, Value1, Value2)
VALUES (1,'Value1','Value2');
GO

/*
Msg 4406, Level 16, State 1, Line 1675
Update or insert of view or function 'Examples.KeyTable' failed because it contains a derived or constant field.
*/

CREATE TRIGGER Examples.KeyTable_InsteadOfInsertTrigger
ON Examples.KeyTable
INSTEAD OF INSERT 
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
          --Insert data into one of the tables
        INSERT INTO Examples.KeyTable1(KeyValue, Value1)
        SELECT KeyValue, Value1
        FROM   Inserted;
        --and then the other
        INSERT INTO Examples.KeyTable2(KeyValue, Value2)
        SELECT KeyValue, Value2
        FROM   Inserted;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW; --will halt the batch or be caught by the caller's catch block
    END CATCH;
END;
GO

INSERT INTO Examples.KeyTable (KeyValue, Value1, Value2)
VALUES (1,'Value1','Value2');
GO

SELECT *
FROM   Examples.KeyTable;
GO

----Determine when to use Data Manipulation Language (DML) triggers, Data Definition Language (DDL) triggers, or logon triggers

------DDL Triggers

--------Server

USE ExamBook762Ch2;
GO
CREATE TABLE Examples.DDLDatabaseChangeLog
(
   DDLDatabaseChangeLogId int NOT NULL IDENTITY 
        CONSTRAINT PKDDLDatabaseChangeLog PRIMARY KEY,
    LogTime datetime2(0) NOT NULL,
    DDLStatement nvarchar(max) NOT NULL,
    LoginName sysname NOT NULL
);
GO

--Names used to make it clear where you have used examples from this book outside
--of primary database
CREATE LOGIN Exam762Examples_DDLTriggerLogging WITH PASSWORD = 'PASSWORD$1';
CREATE USER Exam762Examples_DDLTriggerLogging 
                                 FOR LOGIN Exam762Examples_DDLTriggerLogging;
GRANT INSERT ON  Examples.DDLDatabaseChangeLog TO 
                            Exam762Examples_DDLTriggerLogging;
GO

CREATE TRIGGER DatabaseCreations_ServerDDLTrigger
ON ALL SERVER   
WITH EXECUTE AS 'Exam762Examples_DDLTriggerLogging'
FOR CREATE_DATABASE, ALTER_DATABASE, DROP_DATABASE 
AS   
    SET NOCOUNT ON;
    --trigger is stored in master db, so must 
    INSERT INTO ExamBook762Ch2.Examples.DDLDatabaseChangeLog(LogTime, DDLStatement, 
                                                                          LoginName)
    SELECT SYSDATETIME(),EVENTDATA().value(
                     '(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)'),
           ORIGINAL_LOGIN(); --Original login gives you the user that is connected. 
                             --Otherwise we would get the EXECUTE AS user.
GO


CREATE LOGIN Exam762Examples_DatabaseCreator WITH PASSWORD = 'PASSWORD$1';
GRANT CREATE ANY DATABASE TO Exam762Examples_DatabaseCreator;
GRANT ALTER ANY DATABASE TO Exam762Examples_DatabaseCreator;
GO

CREATE DATABASE Example
GO
ALTER DATABASE Example SET RECOVERY SIMPLE;
GO
DROP DATABASE Example;
GO

SELECT LogTime, DDLStatement, LoginName
FROM Examples.DDLDatabaseChangeLog;
GO

CREATE TRIGGER DatabaseCreations_StopThemAll
ON ALL SERVER   
FOR CREATE_DATABASE, ALTER_DATABASE, DROP_DATABASE 
AS   
    SET NOCOUNT ON;
    ROLLBACK TRANSACTION;
    THROW 50000,'No more databases created please',1;
GO

DISABLE TRIGGER DatabaseCreations_StopThemAll ON ALL SERVER;
GO

DROP TRIGGER DatabaseCreations_ServerDDLTrigger ON ALL SERVER;
GO

DROP USER Exam762Examples_DDLTriggerLogging;
DROP LOGIN Exam762Examples_DDLTriggerLogging;
DROP LOGIN Exam762Examples_DatabaseCreator;
GO

--------Database

CREATE TABLE Examples.DDLChangeLog
(
   DDLChangeLogId int NOT NULL IDENTITY 
        CONSTRAINT PKDDLChangeLog PRIMARY KEY,
    LogTime datetime2(0) NOT NULL,
    DDLStatement nvarchar(max) NOT NULL,
    LoginName sysname NOT NULL
);
GO

CREATE USER Exam762Examples_DDLTriggerLogging WITHOUT LOGIN;
GRANT INSERT ON Examples.DDLChangeLog TO Exam762Examples_DDLTriggerLogging;
GO

CREATE TRIGGER DatabaseChanges_DDLTrigger
ON DATABASE
--WITH EXECUTE AS 'Exam762Examples_DDLTriggerLogging'
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS   
    SET NOCOUNT ON;
    DECLARE @eventdata XML = EVENTDATA();
    ROLLBACK; --Make sure the event doesn't occur
    INSERT INTO Examples.DDLChangeLog(LogTime, DDLStatement, LoginName)
    SELECT SYSDATETIME(),                       
           @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]',
                                                                      'nvarchar(max)'),
           ORIGINAL_LOGIN();      
    THROW 50000,'Denied!',1;
GO

CREATE TABLE Examples.Test
(
    TestId int NOT NULL
);
GO

DROP TABLE Examples.DDLChangeLog;
GO

SELECT LogTime, DDLStatement, LoginName
FROM   Examples.DDLChangeLog;
GO

DROP TRIGGER DatabaseChanges_DDLTrigger ON DATABASE;
GO

DROP USER Exam762Examples_DDLTriggerLogging;
GO

------Logon Triggers

CREATE TABLE Examples.LoginLog
(
    LoginLogId  int NOT NULL IDENTITY(1,1) 
          CONSTRAINT PKLoginLog PRIMARY KEY,
    LoginName   sysname NOT NULL,
    LoginTime   datetime2(0) NOT NULL ,
    ApplicationName sysname NOT NULL
);
GO

CREATE LOGIN Exam762Examples_LogonTriggerLogging WITH PASSWORD = 'PASSWORD$1';
CREATE USER Exam762Examples_LogonTriggerLogging 
                                 FOR LOGIN Exam762Examples_LogonTriggerLogging;
GRANT INSERT ON Examples.LoginLog TO Exam762Examples_LogonTriggerLogging;
GO

CREATE TRIGGER Exam762ExampleLogonTrigger
ON ALL SERVER
WITH EXECUTE AS 'Exam762Examples_LogonTriggerLogging'
FOR LOGON  
AS  
    IF ORIGINAL_LOGIN() = 'Login_NotAllowed'
        THROW 50000,'Unauthorized Access',1;
    ELSE
        INSERT INTO ExamBook762Ch2.Examples.LoginLog(LoginName, LoginTime, 
                                                     ApplicationName)
        VALUES (ORIGINAL_LOGIN(),SYSDATETIME(),APP_NAME());
GO

CREATE LOGIN Login_NotAllowed WITH PASSWORD = 'PASSWORD$1';
DROP TRIGGER Exam762ExampleLogonTrigger ON ALL SERVER;
DROP USER Exam762Examples_LogonTriggerLogging;
DROP LOGIN Exam762Examples_LogonTriggerLogging;
GO

----Recognize results based on execution of AFTER or INSTEAD OF triggers

CREATE TABLE Examples.UpdateRows
(
    UpdateRowsId int NOT NULL IDENTITY(1,1)
        CONSTRAINT PKUpdateRows PRIMARY KEY,
    Value varchar(20) NOT NULL
);
INSERT INTO Examples.UpdateRows (Value)
VALUES ('Original'),('Original'),('Original');
GO

CREATE TRIGGER Examples.UpdateRows_TriggerInsert
ON Examples.UpdateRows
AFTER UPDATE AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; 
   BEGIN TRY
        DECLARE @UpdateRowsId int
        SELECT @UpdateRowsId = UpdateRowsId 
        FROM   inserted
        ORDER BY UpdateRowsId;
        
        UPDATE Examples.UpdateRows
        SET    Value = UPPER(Value)
        WHERE  UpdateRowsId = @UpdateRowsId;
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; --will halt the batch or be caught by the caller's catch block
   END CATCH;
GO

UPDATE Examples.UpdateRows
SET    Value = 'Modified';
go


CREATE TABLE Examples.KeyModify
(
    KeyModifyId  int CONSTRAINT PKKeyModify PRIMARY KEY,
    Value       varchar(20)
);
INSERT INTO Examples.KeyModify(KeyModifyId, Value)
VALUES (1,'Original'), (2,'Original'),(3,'Original');
GO

CREATE TRIGGER Examples.KeyModify_TriggerInsteadOfInsert
ON Examples.KeyModify
INSTEAD OF UPDATE AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; 
   BEGIN TRY
        UPDATE Examples.KeyModify 
        SET    Value = UPPER(inserted.Value)
        FROM   Examples.KeyModify
                 JOIN inserted
                    ON KeyModify.KeyModifyId = inserted.KeyModifyId
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; 
   END CATCH
UPDATE Examples.KeyModify
SET     KeyModifyId = KeyModifyId + 10, --Change Primary Key Value       
        Value = 'Modified';

----Design scalar-valued and table-valued user-defined functions based on business requirements
------Scalar-Valued user-defined functions




CREATE FUNCTION Examples.ReturnIntValue
(
    @Value  int
)
RETURNS int
AS
  BEGIN
    RETURN @Value
  END;
GO

SELECT Examples.ReturnIntValue(1) as IntValue;
GO

SELECT OrderId, 1/ (4732-OrderId)
FROM   WideWorldImporters.Sales.Orders;
GO


USE WideWorldImporters;


CREATE FUNCTION Sales.Customers_ReturnOrderCount
(
    @CustomerID int,
    @OrderDate date = NULL
)
RETURNS INT
WITH RETURNS NULL ON NULL INPUT, --if all parameters NULL, return NULL immediately
     SCHEMABINDING --make certain that the tables/columns referenced cannot change
AS
  BEGIN
      DECLARE @OutputValue int

      SELECT  @OutputValue = COUNT(*)
      FROM    Sales.Orders
      WHERE   CustomerID = @CustomerID
        AND   (OrderDate = @OrderDate
               OR @OrderDate IS NULL);

      RETURN @OutputValue 
   END;
GO

SELECT Sales.Customers_ReturnOrderCount(905, '2013-01-01');
GO

SELECT Sales.Customers_ReturnOrderCount(905, DEFAULT);
GO

SELECT CustomerID, Sales.Customers_ReturnOrderCount(905, DEFAULT)
FROM   Sales.Customers;
GO

SELECT CustomerID, COUNT(*)
FROM   Sales.Orders
GROUP  BY CustomerID;
GO

SELECT N'CPO' + RIGHT(N'00000000' + CustomerPurchaseOrderNumber,8)
FROM WideWorldImporters.Sales.Orders;
GO

CREATE FUNCTION Sales.Orders_ReturnFormattedCPO
(
    @CustomerPurchaseOrderNumber nvarchar(20)
)
RETURNS nvarchar(20)
WITH RETURNS NULL ON NULL INPUT,
     SCHEMABINDING
AS
 BEGIN
    RETURN (N'CPO' + RIGHT(N'00000000' + @CustomerPurchaseOrderNumber,8));
 END;
GO

SELECT Sales.Orders_ReturnFormattedCPO('12345') as CustomerPurchaseOrderNumber;
GO

SELECT OrderId
FROM   Sales.Orders
WHERE  Sales.Orders_ReturnFormattedCPO(CustomerPurchaseOrderNumber) = 'CPO00019998';
GO


SELECT Sales.Orders_ReturnFormattedCPO(CustomerPurchaseOrderNumber)
FROM   Sales.Orders;
GO

SELECT N'CPO' + RIGHT(N'00000000' + [CustomerPurchaseOrderNumber],8)
FROM WideWorldImporters.Sales.Orders;
GO


----Table-Valued user-defined functions

CREATE FUNCTION Sales.Customers_ReturnOrderCountSetSimple
(
    @CustomerID int,
    @OrderDate date = NULL
)
RETURNS TABLE
AS 
RETURN (SELECT COUNT(*) AS SalesCount, 
               CASE WHEN MAX(BackorderOrderId) IS NOT NULL 
                          THEN 1 ElSE 0 END AS HasBackorderFlag
        FROM   Sales.Orders
        WHERE  CustomerID = @CustomerID
        AND   (OrderDate = @OrderDate
               OR @OrderDate IS NULL));
GO

SELECT *
FROM   Sales.Customers_ReturnOrderCountSetSimple(905,'2013-01-01');
GO


SELECT *
FROM   Sales.Customers_ReturnOrderCountSetSimple(905,DEFAULT);
GO


SELECT CustomerId, FirstDaySales.SalesCount, FirstDaySales.HasBackorderFlag
FROM   Sales.Customers
        OUTER APPLY Sales.Customers_ReturnOrderCountSetSimple
                            (CustomerId, AcountOpenedDate) as FirstDaySales
WHERE  FirstDaySales.SalesCount > 0;
GO

CREATE FUNCTION Sales.Customers_ReturnOrderCountSetMulti
(
    @CustomerID int,
    @OrderDate date = NULL
)
RETURNS  @OutputValue TABLE (SalesCount int NOT NULL,
                             HasBackorderFlag bit NOT NULL)
AS 
 BEGIN 
    INSERT INTO @OutputValue (SalesCount, HasBackorderFlag)
    SELECT COUNT(*) as SalesCount,
                   CASE WHEN MAX(BackorderOrderId) IS NOT NULL 
                               THEN 1 ElSE 0 END AS HasBackorderFlag
    FROM   Sales.Orders
    WHERE  CustomerID = @CustomerID
    AND   (OrderDate = @OrderDate
            OR @OrderDate IS NULL)

    RETURN;
END;
GO

SELECT CustomerId, FirstDaySales.SalesCount, FirstDaySales.HasBackorderFlag
FROM   Sales.Customers
        OUTER APPLY Sales.Customers_ReturnOrderCountSetSimple
                        (CustomerId, AccountOpenedDate) as FirstDaySales
WHERE  FirstDaySales.SalesCount > 0;
GO


SELECT CustomerId, FirstDaySales.SalesCount, FirstDaySales.HasBackorderFlag
FROM   Sales.Customers
        OUTER APPLY Sales.Customers_ReturnOrderCountSetMulti
                        (CustomerId, AccountOpenedDate) as FirstDaySales
WHERE  FirstDaySales.SalesCount > 0;
GO

----Identify differences between deterministic and non-deterministic functions
CREATE FUNCTION Examples.UpperCaseFirstLetter (@Value VARCHAR(50))
RETURNS NVARCHAR(50)
WITH SCHEMABINDING
AS
BEGIN
    --start at position 2, as 1 will always be uppercase if it exists
    DECLARE @OutputValue      NVARCHAR(50),
            @position         INT         = 2,
            @previousPosition INT
    IF LEN(@Value) = 0
        RETURN @OutputValue;
    --remove leading spaces, uppercase the first character
    SET @OutputValue = (LTRIM(CONCAT(UPPER(SUBSTRING(@Value, 1, 1)), LOWER(SUBSTRING(@Value, 2, 99)))));
    --if no space characters, exit
    IF CHARINDEX(' ', @OutputValue, 1) = 0
        RETURN @OutputValue;
    WHILE 1 = 1
    BEGIN
        SET @position = CHARINDEX(' ', @OutputValue, @position) + 1
        IF @position < @previousPosition
        OR @position = 0
            BREAK;
        SELECT @OutputValue
            = CONCAT(
                  SUBSTRING(@OutputValue, 1, @position - 1),
                  UPPER(SUBSTRING(@OutputValue, @position, 1)),
                  SUBSTRING(@OutputValue, @position + 1, 50)),
               @previousPosition = @position
    END
    RETURN @OutputValue
END;
GO

SELECT Examples.UpperCaseFirstLetter(N'NO MORE YELLING') as Name;
GO

SELECT OBJECTPROPERTY(OBJECT_ID('Examples.UpperCaseFirstLetter'), 'IsDeterministic') 
                                                                      AS IsDeterministic
GO

CREATE FUNCTION Examples.StartOfCurrentMonth
()
RETURNS date
WITH SCHEMABINDING
AS
 BEGIN
    RETURN (DATEADD(day, 0, DATEDIFF(day, 0, SYSDATETIME() ) - 
                                        DATEPART(DAY,SYSDATETIME()) + 1));
 END;
GO

SELECT OBJECTPROPERTY(OBJECT_ID('Examples.StartOfCurrentMonth'), 'IsDeterministic') 
                                                                  AS IsDeterministic
GO

CREATE FUNCTION Examples.ReturnOneToTenSet
()
RETURNS @OutputTable TABLE (I int)
WITH SCHEMABINDING
AS  
  BEGIN
    INSERT INTO @OutputTable(I)
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

    RETURN;
  END;
SELECT OBJECTPROPERTY(OBJECT_ID('Examples.ReturnOneToTenSet'), 'IsDeterministic') 
                                                                   AS IsDeterministic;
GO

--Summary
----Though Experiment Answer

CREATE TABLE Examples.Respondent
(
     RespondentId int NOT NULL CONSTRAINT PKRespondent PRIMARY KEY,
     EmailAddress  nvarchar(500) NOT NULL
);
GO

ALTER TABLE Examples.Respondent
     ADD CONSTRAINT AKRespondent UNIQUE (EmailAddress);
GO

CREATE TABLE Examples.ThreeInsert
(
	ThreeInsertId int CONSTRAINT PKThreeInsert PRIMARY KEY
);
GO

CREATE PROCEDURE Examples.ThreeInsert_Create
            @SecondValue int = 2 --Pass in 1 to and no data is inserted
AS
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO Examples.ThreeInsert (ThreeInsertId)
        VALUES (1);
       INSERT INTO Examples.ThreeInsert (ThreeInsertId)
       VALUES (@SecondValue); 
       COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
	--No THROW will mean no reporting of message
    END CATCH;

    INSERT INTO Examples.ThreeInsert (ThreeInsertId)
    VALUES (3);
GO


CREATE TABLE Examples.Recipient
(
    RecipientType varchar(30) NOT NULL
);
GO

ALTER TABLE Examples.Recipient 
   ADD CONSTRAINT CHKRecipient_RecipientType 
         CHECK (RecipientType IN ('Regular','Special Handling'));
GO

CREATE TABLE Examples.RecipientType
(
       RecipientType varchar(30) NOT NULL CONSTRAINT PKRecipientType PRIMARY KEY
);
INSERT INTO Examples.RecipientType(RecipientType)
VALUES ('Regular'),('Special Handling');
GO

ALTER TABLE Examples.Recipient
      ADD CONSTRAINT FKRecipient_Ref_ExamplesRecipientType
      FOREIGN KEY (RecipientType) REFERENCES Examples.RecipientType(RecipientType);
GO

CREATE TABLE Examples.Offer
(
    OfferCode char(5) NOT NULL
);
GO

CREATE TRIGGER Examples.Offer_TriggerInsteadOfInsert
ON Examples.Offer 
INSTEAD OF INSERT AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   BEGIN TRY
        IF EXISTS (SELECT *
                   FROM   inserted
                   WHERE  OfferCode NOT LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z]')
            THROW 50000,'An OfferCode is not all alpha characters',1;

        --skip columns to automatically set
        INSERT INTO Examples.Offer (OfferCode)
        SELECT UPPER(OfferCode)
        FROM   inserted
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
           ROLLBACK TRANSACTION;
       THROW; --will halt the batch or be caught by the caller's catch block
   END CATCH
END;
GO

SELECT collation_name
FROM sys.databases
WHERE  database_id = DB_ID();
GO

ALTER TABLE Examples.Offer
    ADD CONSTRAINT CHKOffer_OfferCode 
       CHECK (OfferCode LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z]' 
                             COLLATE Latin1_General_100_CS_AS);
GO

CREATE TRIGGER DatabaseChanges_DDLTrigger
ON DATABASE
WITH EXECUTE AS 'Exam762Examples_DDLTriggerLogging'
FOR CREATE_INDEX
AS   
    SET NOCOUNT ON;
    IF CAST(SYSDATETIME() AS time) >= '08:00:00' 
        AND CAST(SYSDATETIME() AS time) < '10:00:00'
    THROW 50000,'No indexes may be added between 8 and 10 AM',1;
GO

