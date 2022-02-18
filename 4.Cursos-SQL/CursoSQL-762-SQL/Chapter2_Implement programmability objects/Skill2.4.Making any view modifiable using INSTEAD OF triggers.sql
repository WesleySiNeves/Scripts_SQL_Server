-- ==================================================================
--Observa��o:
/*
Um exemplo final de gatilhos do DML � aplicar um INSTEAD OF TRIGGER a uma View
 tornando-o edit�vel ,isso � uma solu��o quando temos views que n�o s�o editaveis
 */
-- ==================================================================

--Cria��o das tabelas

CREATE TABLE Examples.KeyTable1
(
KeyValue int NOT NULL CONSTRAINT PKKeyTable1 PRIMARY KEY,
Value1 varchar(10) NULL
);
CREATE TABLE Examples.KeyTable2
(
KeyValue int NOT NULL CONSTRAINT PKKeyTable2 PRIMARY KEY,
Value2 varchar(10) NULL
);

GO

--Codigo da View
CREATE VIEW Examples.KeyTable
AS
SELECT COALESCE(KeyTable1.KeyValue, KeyTable2.KeyValue) AS KeyValue,
       KeyTable1.Value1,
       KeyTable2.Value2
  FROM Examples.KeyTable1
  FULL OUTER JOIN Examples.KeyTable2
    ON KeyTable1.KeyValue = KeyTable2.KeyValue;


--Fazendo insert na View
INSERT INTO Examples.KeyTable (KeyValue, Value1, Value2)
VALUES (1,'Value1','Value2');

/*
Msg 4406, Level 16, State 1, Line 36
Falha na atualiza��o ou inser��o da vista ou fun��o 'Examples.KeyTable' devido a conter um campo derivado ou constante.

*/