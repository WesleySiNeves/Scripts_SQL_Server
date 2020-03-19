/*########################
# OBS: Trabalhando com Constraints
*/

/*########################
# OBS: Using DEFAULT constraints

*/


CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.Widget
(
    WidgetId INT
        CONSTRAINT PKWidget PRIMARY KEY,
    RowLastModifiedTime DATETIME2(0) NOT NULL
);

ALTER TABLE Examples.Widget
ADD CONSTRAINT DFLTWidget_RowLastModifiedTime
    DEFAULT (SYSDATETIME()) FOR RowLastModifiedTime;


/*########################
# OBS: Comando de insert
*/

INSERT INTO Examples.Widget
(
    WidgetId
)
VALUES (1),
(2);
INSERT INTO Examples.Widget
(
    WidgetId,
    RowLastModifiedTime
)
VALUES
(3, DEFAULT),
(4, DEFAULT);



SELECT *
FROM Examples.Widget;

/*########################
# OBS:Alteração 
*/

UPDATE Examples.Widget
SET RowLastModifiedTime = DEFAULT;



/*########################
# OBS:Adicionando Campo ja com default
*/


ALTER TABLE Examples.Widget
ADD EnabledFlag BIT NOT NULL CONSTRAINT DFLTWidget_EnabledFlag
                             DEFAULT (1);



/*########################
# OBS: Nova tabela
*/
CREATE TABLE Examples.AllDefaulted
(
    AllDefaultedId INT IDENTITY(1, 1) NOT NULL,
    RowCreatedTime DATETIME2(0) NOT NULL
        CONSTRAINT DFLTAllDefaulted_RowCreatedTime
            DEFAULT (SYSDATETIME()),
    RowModifiedTime DATETIME2(0) NOT NULL
        CONSTRAINT DFLTAllDefaulted_RowModifiedTime
            DEFAULT (SYSDATETIME())
);


--Usando DEFAULT VALUES

INSERT INTO Examples.AllDefaulted
DEFAULT VALUES;

INSERT INTO Examples.AllDefaulted
(
    RowModifiedTime,
    RowCreatedTime
)
DEFAULT VALUES;

SELECT *
FROM Examples.AllDefaulted AS AD;

INSERT INTO Examples.AllDefaulted
(
    RowCreatedTime
)
DEFAULT VALUES;



--Resultado
SELECT *
FROM Examples.AllDefaulted;


INSERT INTO Examples.AllDefaulted
(
    AllDefaultedId
)
DEFAULT VALUES;

/*Erro*/

--Msg 339, Level 16, State 1, Line 69
--DEFAULT or NULL are not allowed as explicit identity values.


/*########################
# OBS:Using UNIQUE constraints to enforce secondary uniqueness criteria
*/


CREATE TABLE Examples.Gadget
(
    GadgetId INT IDENTITY(1, 1) NOT NULL
        CONSTRAINT PKGadget PRIMARY KEY,
    GadgetCode VARCHAR(10) NOT NULL
);

INSERT INTO Examples.Gadget
(
    GadgetCode
)
VALUES ('Gadget'),
('Gadget'),
('Gadget');



/*########################
# OBS: Na coluna GadgetCode da tabela Examples.Gadget, crie uma restrição UNIQUE,
depois de excluir os dados duplicados logicamente:
*/

DELETE FROM Examples.Gadget
WHERE GadgetId IN ( 2, 3 );

ALTER TABLE Examples.Gadget ADD CONSTRAINT AKGadget UNIQUE (GadgetCode);


SELECT *
FROM Examples.Gadget AS G;

INSERT INTO Examples.Gadget
(
    GadgetCode
)
VALUES ('Gadget');

/*
Msg 2627, Level 14, State 1, Line 150
Violação da restrição UNIQUE KEY 'AKGadget'. Não é possível inserir a chave duplicada no objeto 'Examples.Gadget'. O valor de chave duplicada é (Gadget).
A instrução foi finalizada.

*/



/*########################
# OBS: Using CHECK constraints to limit data input
*/


CREATE TABLE Examples.GroceryItem
(
    ItemCost SMALLMONEY NULL,
    CONSTRAINT CHKGroceryItem_ItemCostRange CHECK (ItemCost > 0
                                                   AND ItemCost < 1000
                                                  )
);

INSERT INTO Examples.GroceryItem
VALUES (3000.95);


/*
Msg 547, Level 16, State 0, Line 176
A instrução INSERT conflitou com a restrição do CHECK "CHKGroceryItem_ItemCostRange". O conflito ocorreu no banco de dados "ExamBook762Ch3", tabela "Examples.GroceryItem", column 'ItemCost'.
A instrução foi finalizada.

*/


SELECT *
FROM Examples.GroceryItem AS GI;

INSERT INTO Examples.GroceryItem
(
    ItemCost
)
VALUES (NULL -- ItemCost - smallmoney
       );

SELECT *
FROM Examples.GroceryItem AS GI;

SELECT COUNT(*)
FROM Examples.GroceryItem AS GI;


/*########################
# OBS: Enforcing a format for data in a column
*/



CREATE TABLE Examples.Message
(
    MessageTag CHAR(5) NOT NULL,
    Comment NVARCHAR(MAX) NULL
);


ALTER TABLE Examples.Message
ADD CONSTRAINT CHKMessage_MessageTagFormat CHECK (MessageTag LIKE '[A-Z]-[0-9][0-9][0-9]');

ALTER TABLE Examples.Message
ADD CONSTRAINT CHKMessage_CommentNotEmpty CHECK (LEN(Comment) > 0);



INSERT INTO Examples.Message(MessageTag, Comment)
VALUES ('Bad','');


INSERT INTO Examples.Message(MessageTag, Comment)
VALUES ('A-123','A');



/*########################
# OBS: Como um último exemplo, considere um caso em que dois valores de coluna podem influenciar o legal
valor para outro. Por exemplo, diga que você possui uma tabela do Cliente e possui um conjunto de status
*/


CREATE TABLE Examples.Customer
(
    ForcedDisabledFlag BIT NOT NULL,
    ForcedEnabledFlag BIT NOT NULL,
    CONSTRAINT CHKCustomer_ForcedStatusFlagCheck CHECK (NOT (
                                                                ForcedDisabledFlag = 1
                                                                AND ForcedEnabledFlag = 1
                                                            )
                                                       )
);


INSERT INTO Examples.Customer
(
    ForcedDisabledFlag,
    ForcedEnabledFlag
)
VALUES
(   0, -- ForcedDisabledFlag - bit
    0  -- ForcedEnabledFlag - bit
)

INSERT INTO Examples.Customer
(
    ForcedDisabledFlag,
    ForcedEnabledFlag
)
VALUES
(   0, -- ForcedDisabledFlag - bit
    1  -- ForcedEnabledFlag - bit
)


INSERT INTO Examples.Customer
(
    ForcedDisabledFlag,
    ForcedEnabledFlag
)
VALUES
(   1, -- ForcedDisabledFlag - bit
    1  -- ForcedEnabledFlag - bit
)


/*########################
# Using FOREIGN KEY constraints to enforce relationships
*/


CREATE TABLE Examples.Parent
(
ParentId int NOT NULL CONSTRAINT PKParent PRIMARY KEY
);
CREATE TABLE Examples.Child
(
ChildId int NOT NULL CONSTRAINT PKChild PRIMARY KEY,
ParentId int NULL
);

ALTER TABLE Examples.Child
ADD CONSTRAINT FKChild_Ref_ExamplesParent
    FOREIGN KEY (ParentId)
    REFERENCES Examples.Parent (ParentId);


INSERT INTO Examples.Parent(ParentId)
VALUES (1),(2),(3);


INSERT INTO Examples.Child (ChildId, ParentId)
VALUES (1,1);


INSERT INTO Examples.Child (ChildId, ParentId)
VALUES (2,100);


/*########################
# Msg 547, Level 16, State 0, Line 326
A instrução INSERT conflitou com a restrição do FOREIGN KEY "FKChild_Ref_ExamplesParent". O conflito ocorreu no banco de dados "ExamBook762Ch3", tabela "Examples.Parent", column 'ParentId'.
A instrução foi finalizada.
*/

SELECT * FROM sys.messages AS M
WHERE M.message_id ='547'

INSERT INTO Examples.Child (ChildId, ParentId)
VALUES (3,NULL);

CREATE TABLE Examples.TwoPartKey
(
    KeyColumn1 INT NOT NULL,
    KeyColumn2 INT NOT NULL,
    CONSTRAINT PKTwoPartKey
        PRIMARY KEY
        (
            KeyColumn1,
            KeyColumn2
        )
);


INSERT INTO Examples.TwoPartKey (KeyColumn1, KeyColumn2)
VALUES (1, 1);



CREATE TABLE Examples.TwoPartKeyReference
(
KeyColumn1 int NULL,
KeyColumn2 int NULL,
CONSTRAINT FKTwoPartKeyReference_Ref_ExamplesTwoPartKey
FOREIGN KEY (KeyColumn1, KeyColumn2)
REFERENCES Examples.TwoPartKey (KeyColumn1,
KeyColumn2)
);


INSERT INTO Examples.TwoPartKeyReference (KeyColumn1,
KeyColumn2)
VALUES (1, 1), (NULL, NULL)

INSERT INTO Examples.TwoPartKeyReference (KeyColumn1,
KeyColumn2)
VALUES (2, 2);



--Cascading Operations

/*
NO ACTION Prevent any updates or deletions where the end result would leave the
data invalid. This behaves as seen in the previous section, as this is the default
action.
CASCADE Repeat on the referencing table what occurs in the referenced. If the key
column is changed, change it in the referencing table. If the row is deleted, remove it
from the referencing table as well.
SET (NULL or DEFAULT) In these cases, if the referenced row is deleted or the
key value is changed, the referencing data is set to either NULL or to the value from a
DEFAULT constraint, respectively.

*/
CREATE TABLE Examples.Invoice (   InvoiceId INT NOT NULL
                                      CONSTRAINT PKInvoice PRIMARY KEY
                              );
CREATE TABLE Examples.InvoiceLineItem
(
    InvoiceLineItemId INT NOT NULL
        CONSTRAINT PKInvoiceLineItem PRIMARY KEY,
    InvoiceLineNumber SMALLINT NOT NULL,
    InvoiceId INT NOT NULL
        CONSTRAINT FKInvoiceLineItem_Ref_ExamplesInvoice
        REFERENCES Examples.Invoice (InvoiceId) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT AKInvoiceLineItem
        UNIQUE
        (
            InvoiceId,
            InvoiceLineNumber
        )
);



INSERT INTO Examples.Invoice(InvoiceId)
VALUES (1),(2),(3);
INSERT INTO Examples.InvoiceLineItem(InvoiceLineItemId,
InvoiceId,InvoiceLineNumber)
VALUES (1,1,1),(2,1,2), (3,2,1);


SELECT Invoice.InvoiceId, InvoiceLineItem.InvoiceLineItemId
FROM Examples.Invoice
FULL OUTER JOIN Examples.InvoiceLineItem
ON Invoice.InvoiceId = InvoiceLineItem.InvoiceId;


DELETE Examples.Invoice
WHERE InvoiceId = 1;



/*########################
# OBS: Operacoes em Cascate
*/

CREATE TABLE Examples.Code (   Code VARCHAR(10) NOT NULL
                                   CONSTRAINT PKCode PRIMARY KEY
                           );
CREATE TABLE Examples.CodedItem (   Code VARCHAR(10) NOT NULL
                                        CONSTRAINT FKCodedItem_Ref_ExampleCode
                                        REFERENCES Examples.Code (Code) ON UPDATE CASCADE
                                );






INSERT INTO Examples.Code (Code)
VALUES ('Blacke');

SELECT * FROM Examples.Code AS C

INSERT INTO Examples.CodedItem (Code)
VALUES ('Blacke');


SELECT Code.Code, CodedItem.Code AS CodedItemCode
FROM Examples.Code
FULL OUTER JOIN Examples.CodedItem
ON Code.Code = CodedItem.Code;


UPDATE Examples.Code
SET Code = 'Black';


/*########################
# OBS: Auto relaciomamento
Relating a table to itself to form a hierarchy
*/


CREATE TABLE Examples.Employee
(
    EmployeeId INT NOT NULL
        CONSTRAINT PKEmployee PRIMARY KEY,
    EmployeeNumber CHAR(8) NOT NULL,
    ManagerId INT NULL
        CONSTRAINT FKEmployee_Ref_ExamplesEmployee
        REFERENCES Examples.Employee (EmployeeId)
);




INSERT INTO Examples.Employee
(
    EmployeeId,
    EmployeeNumber,
    ManagerId
)
VALUES
(1, '00000001', NULL),
(2, '10000001', 1),
(3, '10000002', 1),
(4, '20000001', 3);


SELECT * FROM Examples.Employee AS E


;WITH EmployeeHierarchy
AS (SELECT EmployeeId,
           CAST(CONCAT('\', EmployeeId, '\') AS VARCHAR(1500)) AS Hierarchy
    FROM Examples.Employee
    WHERE ManagerId IS NULL
    UNION ALL
    SELECT Employee.EmployeeId,
           CAST(CONCAT(Hierarchy, Employee.EmployeeId, '\') AS VARCHAR(1500)) AS Hierarchy
    FROM Examples.Employee
        INNER JOIN EmployeeHierarchy
            ON Employee.EmployeeId = EmployeeHierarchy.EmployeeId
   )
SELECT *
FROM EmployeeHierarchy;


--FOREIGN KEY constraints relating to a UNIQUE constraint instead of a PRIMARY KEY constraint


CREATE TABLE Examples.Color
(
ColorId int NOT NULL CONSTRAINT PKColor PRIMARY KEY,
ColorName varchar(30) NOT NULL CONSTRAINT AKColor UNIQUE
);
INSERT INTO Examples.Color(ColorId, ColorName)
VALUES (1,'Orange'),(2,'White');



CREATE TABLE Examples.Product
(
ProductId int NOT NULL CONSTRAINT PKProduct PRIMARY KEY,
ColorName varchar(30) NOT NULL
CONSTRAINT FKProduct_Ref_ExamplesColor
REFERENCES Examples.Color (ColorName)
)


INSERT INTO Examples.Product(ProductId,ColorName)
VALUES (1,'Orange');

INSERT INTO Examples.Product(ProductId,ColorName)
VALUES (2,'Crimson');



--Limiting a column to a set of values


CREATE TABLE Examples.Attendee
(
ShirtSize varchar(8) NULL
);


--the first is using a simple CHECK constraint:

ALTER TABLE Examples.Attendee ADD CONSTRAINT CHKAttendee_ShirtSizeDomain
CHECK (ShirtSize in ('S', 'M','L','XL','XXL'));


INSERT INTO Examples.Attendee(ShirtSize)
VALUES ('LX');

/*
Msg 547, Level 16, State 0, Line 566
A instrução INSERT conflitou com a restrição do CHECK "CHKAttendee_ShirtSizeDomain". O conflito ocorreu no banco de dados "ExamBook762Ch3", tabela "Examples.Attendee", column 'ShirtSize'.
A instrução foi finalizada.

*/

CREATE TABLE Examples.ShirtSize (   ShirtSize VARCHAR(8) NOT NULL
                                        CONSTRAINT PKShirtSize PRIMARY KEY
                                );
INSERT INTO Examples.ShirtSize
(
    ShirtSize
)
VALUES ('S'),
('M'),
('L'),
('XL'),
('XXL');



ALTER TABLE Examples.Attendee DROP CONSTRAINT CHKAttendee_ShirtSizeDomain;

ALTER TABLE Examples.Attendee ADD CONSTRAINT FKAttendee_Ref_ExamplesShirtSize
FOREIGN KEY (ShirtSize) REFERENCES
Examples.ShirtSize(ShirtSize)
/*
Msg 1753, Level 16, State 0, Line 592
A coluna 'Examples.ShirtSize.ShirtSize' não tem o mesmo comprimento ou a mesma escala da coluna de 
referência 'Attendee.ShirtSize' na chave estrangeira 'FKAttendee_Ref_ExamplesShirtSize'.
 As colunas que participam de uma relação de chave estrangeira devem ser definidas
  com o mesmo comprimento e a mesma escala.
Msg 1750, Level 16, State 1, Line 592
Não foi possível criar a restrição ou o índice. Consulte os erros anteriores.

*/

INSERT INTO Examples.Attendee(ShirtSize)
VALUES ('LX');