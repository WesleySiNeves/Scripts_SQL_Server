CREATE DATABASE ExamBook762Ch2;
GO

-- ==================================================================
/* GO não é um declaração no Transact-SQL é um separador de lote que divide suas consultas
 em múltiplos comunicações do servidor
 */
-- ==================================================================
CREATE SCHEMA Examples;
GO


CREATE TABLE Examples.Widget (
    WidgetCode VARCHAR(10) NOT NULL
        CONSTRAINT PKWidget PRIMARY KEY,
    WidgetName VARCHAR(100) NULL);


SELECT *
  FROM ExamBook762Ch2.Examples.Widget AS W;


CREATE TABLE Examples.Widget (
    WidgetCode VARCHAR(10) NOT NULL
        CONSTRAINT PKWidget PRIMARY KEY,
    WidgetName VARCHAR(100) NULL) ON FileGroupName;


-- ==================================================================
--Observação:Por exemplo, você pode adicionar uma coluna usando:
-- ==================================================================

ALTER TABLE Examples.Widget ADD NullableColumn INT NULL;




-- ==================================================================
--Observação: COluna computadas
-- ==================================================================
CREATE TABLE Examples.ComputedColumn (
    FirstName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    FullName AS CONCAT(LastName, ',' + FirstName));


ALTER TABLE Examples.ComputedColumn DROP COLUMN FullName;

ALTER TABLE Examples.ComputedColumn
ADD FullName AS CONCAT(ComputedColumn.LastName, ', ' + ComputedColumn.FirstName) PERSISTED;


INSERT INTO Examples.ComputedColumn
VALUES (NULL, 'Harris'),
('Waleed', 'Heloo');


SELECT *
  FROM Examples.ComputedColumn;