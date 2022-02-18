/*
Até agora, no capítulo, adicionamos muitas restrições às tabelas. Nesta seção, analisamos
o básico deste processo brevemente, e então abrange alguns aspectos mais avançados da criação
e gerenciamento de restrições.
Ao criar uma tabela, existem duas maneiras de adicionar uma restrição: na mesma linha com uma
declaração de coluna, indicando que a restrição pertence a essa coluna, ou delimitada por uma
vírgula, o que significa que pode fazer referência a qualquer uma das colunas da tabela. Como um exemplo da
muitas maneiras de adicionar restrições na declaração, considere o seguinte:

*/

CREATE TABLE Examples.CreateTableExample
(
    --Uniqueness constraint referencing single column
    SingleColumnKey INT NOT NULL
        CONSTRAINT PKCreateTableExample PRIMARY KEY,
    --Uniqueness constraint in separate line
    TwoColumnKey1 INT NOT NULL,
    TwoColumnKey2 INT NOT NULL,
    CONSTRAINT AKCreateTableExample
        UNIQUE
        (
            TwoColumnKey1,
            TwoColumnKey2
        ),
    --CHECK constraint declare as column constraint
    PositiveInteger INT NOT NULL
        CONSTRAINT CHKCreateTableExample_PostiveInteger CHECK (PositiveInteger > 0),
    --CHECK constraint that could reference multiple columns
    NegativeInteger INT NOT NULL,
    CONSTRAINT CHKCreateTableExample_NegativeInteger CHECK (NegativeInteger > 0),
);


ALTER TABLE Examples.CreateTableExample DROP PKCreateTableExample;

ALTER TABLE Examples.CreateTableExample ADD CONSTRAINT PKCreateTableExample PRIMARY KEY (SingleColumnKey);


--Validacao
CREATE TABLE Examples.BadData
(
PositiveValue int NOT NULL
);


INSERT INTO Examples.BadData(PositiveValue)
VALUES (-1),(-2),(-3),(-4);


ALTER TABLE Examples.BadData
ADD CONSTRAINT CHKBadData_PostiveValue CHECK(PositiveValue >
0);



/*
A partir daqui, você tem duas opções. Você pode (idealmente) corrigir os dados, ou você pode criar o
restrição e deixar os dados incorretos. Isso pode ser feito especificando WITH NOCHECK que
ignora a verificação de dados:
*/


ALTER TABLE Examples.BadData WITH NOCHECK
ADD CONSTRAINT CHKBadData_PostiveValue CHECK(PositiveValue >
0);


UPDATE Examples.BadData
SET PositiveValue = PositiveValue;


/*
Msg 547, Level 16, State 0, Line 420
The UPDATE statement conflicted with the CHECK constraint
"CHKBadData_PostiveValue".
The conflict occurred in database "ExamBook762Ch2", table
"Examples.BadData",
column 'PositiveValue'
*/


DELETE FROM Examples.BadData
WHERE PositiveValue <= 0;


SELECT is_not_trusted, is_disabled
FROM sys.check_constraints --for a FOREIGN KEY, use sys.foreign_keys
WHERE OBJECT_SCHEMA_NAME(object_id) = 'Examples'
and OBJECT_NAME(object_id) = 'CHKBadData_PostiveValue';


/*
sso mostra como a restrição não é confiável, mas está habilitada. Agora que você
 sabe
Os dados na tabela estão corretos, você pode dizer a restrição para verificar
 os dados na tabela usando
o seguinte comando:
*/


ALTER TABLE Examples.BadData WITH CHECK CHECK
CONSTRAINT CHKBadData_PostiveValue;


/*
Se você verificar a restrição agora para ver se é confiável, é. Se você deseja desativar (virar
off) uma restrição CHECK ou FOREIGN KEY, você pode usar NOCHECK no ALTER
Comando TABLE:
*/

ALTER TABLE Examples.BadData
NOCHECK CONSTRAINT CHKBadData_PostiveValue;


USE WideWorldImporters

--Vamos Criar uma CONSTRAINT definindo um intervalo de 0 a 1000000 
ALTER TABLE Sales.Invoices
ADD CONSTRAINT CHKInvoices_OrderIdBetween0and1000000
CHECK (OrderId BETWEEN 0 AND 1000000);

--Como Criamos a restrição o Sql server sabe que na tabela 
--não existe nenhum dado com valor negativo 
--Liigue o plano de execução

SELECT *
FROM Sales.Invoices
WHERE OrderID = -100;



--Liigue o plano de execução
SELECT *
FROM Sales.Invoices
WHERE OrderID = 100;


