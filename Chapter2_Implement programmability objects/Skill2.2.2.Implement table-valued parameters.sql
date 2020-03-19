/*########################
# OBS: Antes vamos 
Implementando mult -parametros
*/

CREATE TABLE Examples.Machine
(
    MachineId INT NOT NULL
        CONSTRAINT PKMachine PRIMARY KEY,
    MachineNumber CHAR(3) NOT NULL
        CONSTRAINT AKMachine
        UNIQUE,
    Description VARCHAR(50) NOT NULL
);
INSERT INTO Examples.Machine
(
    MachineId,
    MachineNumber,
    Description
)
VALUES
(1, '001', 'Thing1'),
(2, '002', 'Thing2'),
(3, '003', 'Thing3');




 --SQL Server 2016 adicionou uma nova função do sistema STRING_SPLIT ().


GO

CREATE PROCEDURE Examples.Machine_MultiSelect @MachineList VARCHAR(200)
AS
SET NOCOUNT ON;
SELECT Machine.MachineId,
       Machine.MachineNumber
FROM Examples.Machine
    JOIN STRING_SPLIT(@MachineList, ',') AS StringList
        ON StringList.value = Machine.MachineId;



/*########################
# OBS:Usando TVP
*/		

CREATE TYPE Examples.SurrogateKeyList AS TABLE
(SurrogateKeyId INT PRIMARY KEY --note you cannot name constraints for table types
);


GO


ALTER PROCEDURE Examples.Machine_MultiSelect
 @MachineList Examples.SurrogateKeyList READONLY

AS
SET NOCOUNT ON;
SELECT Machine.MachineId,
       Machine.MachineNumber
FROM Examples.Machine
    JOIN @MachineList AS MachineList
        ON MachineList.SurrogateKeyId = Machine.MachineId;





/*########################
# OBS: Agora declaramos uma variavel do tipo SurrogateKeyList
*/


DECLARE @MachineList Examples.SurrogateKeyList;
INSERT INTO @MachineList (SurrogateKeyId)
VALUES (1),(3);
EXECUTE Examples.Machine_MultiSelect @MachineList =
@MachineList;


/*
Beyond the ability to return a specific set of rows, passing a table of values can be used
to create multiple rows in a single call. It is technically possible to do without a table, as
you could either use multiple sets of parameters (@MachineId1, @MachineNumber1,
@MachineId2, etc), or a complex parameter such as an XML type, but neither is as
straightforward as using a table-valued parameter. As with our previous example, we start
by creating a table USER DEFINED TYPE, but this time it is defined in a specific manner.
We named this USER DEFINED TYPE the same as the TABLE object to reinforce that they
are different name spaces, which could be something confusing in an exam question
*/

CREATE TYPE Examples.Machine AS TABLE
(
    MachineId INT NOT NULL PRIMARY KEY,
    MachineNumber CHAR(3) NOT NULL
        UNIQUE,
    Description VARCHAR(50) NOT NULL
);



GO

CREATE PROCEDURE Examples.Machine_MultiInsert @MachineList Examples.Machine READONLY
AS
SET NOCOUNT ON;
INSERT INTO Examples.Machine
(
    MachineId,
    MachineNumber,
    Description
)
SELECT MachineId,
       MachineNumber,
       Description
FROM @MachineList;


--comando 
DECLARE @NewMachineRows Examples.Machine;
INSERT INTO @NewMachineRows
(
    MachineId,
    MachineNumber,
    Description
)
VALUES
(4, '004', 'NewThing4'),
(5, '005', 'NewThing5');

EXECUTE Examples.Machine_MultiInsert @MachineList = @NewMachineRows;

SELECT * FROM Examples.Machine AS M


